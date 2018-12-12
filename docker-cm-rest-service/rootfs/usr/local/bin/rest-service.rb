#!/usr/bin/ruby
#
# 05.10.2016 - Bodo Schulz
#
#
# v2.1.0

# -----------------------------------------------------------------------------

require 'rack'
require 'sinatra/base'
require 'logger'
require 'json'
require 'yaml'
require 'resolve/hostname'

require_relative '../lib/monitoring'

module Sinatra

  LOGGING_BLACKLIST = ['/health']

  class FilteredCommonLogger < Rack::CommonLogger
    def call(env)
      if filter_log(env)
        # default CommonLogger behaviour: log and move on
        super
      else
        # pass request to next component without logging
        @app.call(env)
      end
    end

    # return true if request should be logged
    def filter_log(env)
      !LOGGING_BLACKLIST.include?(env['PATH_INFO'])
    end
  end


  class MonitoringRest < Base

    include Logging

    configure do

      set :environment, :production

      @rest_service_port = ENV.fetch('REST_SERVICE_PORT'      , 8080 )
      @rest_service_bind = ENV.fetch('REST_SERVICE_BIND'      , '0.0.0.0' )
      @mq_host           = ENV.fetch('MQ_HOST'                , 'beanstalkd' )
      @mq_port           = ENV.fetch('MQ_PORT'                , 11300 )
      @mq_queue          = ENV.fetch('MQ_QUEUE'               , 'mq-rest-service' )
      @redis_host        = ENV.fetch('REDIS_HOST'             , 'redis' )
      @redis_port        = ENV.fetch('REDIS_PORT'             , 6379 )

      @mysql_host        = ENV.fetch('MYSQL_HOST'             , 'database')
      @mysql_schema      = ENV.fetch('DISCOVERY_DATABASE_NAME', 'discovery')
      @mysql_user        = ENV.fetch('DISCOVERY_DATABASE_USER', 'discovery')
      @mysql_password    = ENV.fetch('DISCOVERY_DATABASE_PASS', 'discovery')
    end

    set :logging, false
    set :app_file, caller_files.first || $0
    set :run, Proc.new { $0 == app_file }
    set :dump_errors, true
    set :show_exceptions, false
    set :public_folder, '/var/www/monitoring'

    set :bind, @rest_service_bind
    set :port, @rest_service_port.to_i

    use FilteredCommonLogger

    # -----------------------------------------------------------------------------

    config = {
      :mq       => {
        :host      => @mq_host,
        :port      => @mq_port,
        :queue     => @mq_queue
      },
      :redis    => {
        :host      => @redis_host,
        :port      => @redis_port
      },
      :mysql    => {
        :host      => @mysql_host,
        :schema    => @mysql_schema,
        :user      => @mysql_user,
        :password  => @mysql_password
      }
    }

    m = Monitoring::Client.new( config )

    # -----------------------------------------------------------------------------

    error do
      err = env['sinatra.error']
      msg = "ERROR\n\nThe monitoring-rest-service has nasty error - #{err}"
      logger.error(msg)
      # msg.message
    end

    # -----------------------------------------------------------------------------

    before do
      content_type :json
    end

    before '/v2/*/:host' do
      request.body.rewind
      @request_paylod = request.body.read
    end

    # -----------------------------------------------------------------------------
    # HELP

    get '/health' do
      status 200
    end


    # -----------------------------------------------------------------------------
    # HELP

    # prints out a little help about our ReST-API
    get '/v2/help' do

      send_file File.join( settings.public_folder, 'help' )
    end

#    # currently not supported
#    get '/' do
#      redirect '/v2/help'
#      # send_file File.join( settings.public_folder, 'help' )
#    end

    # -----------------------------------------------------------------------------
    # CONFIGURE

    #
    # curl -X POST http://localhost/api/v2/config/foo \
    #  --data '{ "ports": [200,300] }'
    #
#     post '/v2/config/:host' do
#
#       host            = params[:host]
#
#       payload         =  @request_paylod
#       @request_paylod = nil
#
#       result = m.writeHostConfiguration( host, paylod )
#
#       status result[:status]
#
#       result
#
#     end
#
#     #
#     # curl http://localhost/api/v2/config/foo
#     #
#     get '/v2/config/:host' do
#
#       host   = params[:host]
#       result = m.getHostConfiguration( host )
#
#       status result[:status]
#
#       result
#
#     end
#
#     #
#     # curl -X DELETE http://localhost/api/v2/config/foo
#     #
#     delete '/v2/config/:host' do
#
#       host   = params[:host]
#       result = m.removeHostConfiguration( host )
#
#       status result[:status]
#
#       result
#
#     end

    # -----------------------------------------------------------------------------
    # HOST

    #
    # curl -X POST http://localhost/api/v2/host/foo \
    #  --data '{ "force": false, "grafana": true, "icinga": false }'
    #
    post '/v2/host/:host' do

      host            = params[:host]
      payload         = @request_paylod

#       puts "host   : #{host} - #{host.class}"
#       puts "payload: #{payload} - #{payload.class}"

      @request_paylod = nil

      result = m.add_host( host, payload )

      r = JSON.parse( result ) if( result.is_a?( String ) )

      result_status = r.dig('status').to_i

      status result_status

      JSON.pretty_generate(r) + "\n"
    end

    # get information about all hosts
    get '/v2/host' do

      result = m.list_host( nil, request.env )

      r = JSON.parse( result ) if( result.is_a?( String ) )

      result_status = r.dig('status').to_i

      status result_status

      JSON.pretty_generate(r) + "\n"
    end

    # get information about given 'host'
    get '/v2/host/:host' do

      host   = params[:host]
      result = m.list_host( host, request.env )

      r = JSON.parse( result ) if( result.is_a?( String ) )

      result_status = r.dig('status').to_i

      status result_status

      JSON.pretty_generate(r) + "\n"
    end

    # remove named host from monitoring
    delete '/v2/host/:host' do

      host   = params[:host]
      result = m.delete_host( host, @request_paylod )

      r = JSON.parse( result ) if( result.is_a?( String ) )

      result_status = r.dig('status').to_i

      status result_status

      JSON.pretty_generate(r) + "\n"
    end

    # -----------------------------------------------------------------------------
    # ANNOTATIONS

    post '/v2/annotation/:host' do

      host   = params[:host]
      result = m.annotation( host: host, payload: @request_paylod )
      result = JSON.parse( result ) if( result.is_a?( String ) )

      result_status = result.dig(:status).to_i
      status result_status

      JSON.pretty_generate(result) + "\n"
    end

    # -----------------------------------------------------------------------------

    #
    # Webinterface
    #

    get '/' do
      content_type 'text/html'
      erb( :index )
    end

    post '/ajax/add-host/:host' do

      host   = params[:host]

      result = m.add_host( host, '' )

      r = JSON.parse( result ) if( result.is_a?( String ) )

      result_status = r.dig('status').to_i

      status result_status

      JSON.pretty_generate(r) + "\n"
    end

    get '/ajax/CHANGELOG' do
      status 200

      changelog = {
        "0001": {
          "version": "0001",
          "date": "01.01.1970",
          "changes": [
            "initial"
          ]
        }
      }

      file = format('%s/CHANGELOG', settings.public_folder)

      if(File.exist?(file))
        a = File.read(file)
        begin
          a = JSON.parse(a) if(a.is_a?(String))
          a = a.delete_if { |k, v| v.empty? }
          a = a.delete_if { |k, v| v.dig('date') == '' }
          sorted = a.keys.sort
#          puts "last: #{sorted.last}"
          changelog = a[sorted.last]
        rescue => error
          logger.error(error)
        end
      end

      JSON.pretty_generate(changelog) + "\n"
    end




    # -----------------------------------------------------------------------------
    run! if app_file == $0
    # -----------------------------------------------------------------------------
  end
end

# EOF
