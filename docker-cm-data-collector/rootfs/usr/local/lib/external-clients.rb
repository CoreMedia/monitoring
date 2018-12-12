#!/usr/bin/ruby

require 'json'
require 'rest-client'
require 'mysql2'


require_relative 'logging'

require_relative 'external-clients/mongodb'
require_relative 'external-clients/node_exporter'
require_relative 'external-clients/mysql'


module ExternalClients

  include MongoDb
  include NodeExporter
  include MySQL


  class Resourced

    include Logging

    def initialize( params = {} )

      @host      = params[:host]          ? params[:host]          : nil
      @port      = params[:port]          ? params[:port]          : 55555
    end


    def network( path )

      uri = URI( sprintf( 'http://%s:%s/r/%s', @host, @port, path ) )

      response = nil
      result   = {}

      begin

        Net::HTTP.start( uri.host, uri.port ) do |http|
          request = Net::HTTP::Get.new( uri.request_uri )

          response     = http.request( request )
          response_code = response.code.to_i

          # TODO
          # Errorhandling
          if( response_code != 200 )
            logger.error( sprintf( ' [%s] - Error', response_code ) )
            logger.error( response.body )
          elsif( response_code == 200 )

            body = response.body

            result = body.dig( "Data" )

          end
        end

      rescue => e

        logger.error( e )
        logger.error( e.backtrace )

      end

      return result

    end




    def collect_load( data )

      result = {}
      regex = /(?<load>(.*)) (?<mes>(.*))/x

      data = self.network( 'load-avg' )

      data.each do |c|

        if( parts = c.match( regex ) )

          c.gsub!('node_load15', 'longterm' )
          c.gsub!('node_load5' , 'midterm' )
          c.gsub!('node_load1' , 'shortterm' )

          parts = c.split( ' ' )
          result[parts[0]] = parts[1]
        end
      end

      return result
    end


    def get()

      puts @host
      puts @port

      begin

        self.call_service( )

        return {
          :load       => self.collect_load( 'load-avg' )
        }

      rescue Exception => e
        logger.error( "An error occurred for query: #{e}" )
        return false
      end

    end


  end


  class ApacheModStatus

    include Logging

    def initialize( params = {} )

      @host  = params.dig(:host)
      @port  = params.dig(:port) || 8081


      # Sample Response with ExtendedStatus On
      # Total Accesses: 20643
      # Total kBytes: 36831
      # CPULoad: .0180314
      # Uptime: 43868
      # ReqPerSec: .470571
      # BytesPerSec: 859.737
      # BytesPerReq: 1827.01
      # BusyWorkers: 6
      # IdleWorkers: 94
      # Scoreboard: ___K_____K____________W_

      @scoreboard_map  = {
        '_' => 'waiting',
        'S' => 'starting',
        'R' => 'reading',
        'W' => 'sending',
        'K' => 'keepalive',
        'D' => 'dns',
        'C' => 'closing',
        'L' => 'logging',
        'G' => 'graceful',
        'I' => 'idle',
        '.' => 'open'
      }

    end


    def get_scoreboard_metrics(response)

      results = Hash.new(0)

      response.slice! 'Scoreboard: '
      response.each_char do |char|
        results[char] += 1
      end

      Hash[results.map { |k, v| [@scoreboard_map[k], v] }]
    end


    def fetch( uri_str, limit = 10 )

      # You should choose better exception.
      raise ArgumentError, 'HTTP redirect too deep' if limit == 0

      p   = URI::Parser.new
      url = p.parse( uri_str.to_s )

      req      = Net::HTTP::Get.new( "#{url.path}?auto", { 'User-Agent' => 'CoreMedia Monitoring/1.0' })
      response = Net::HTTP.start( url.host, url.port ) { |http| http.request(req) }

      case response
        when Net::HTTPSuccess         then response
        when Net::HTTPRedirection     then fetch( response['location'], limit - 1 )
        when Net::HTTPNotFound        then response
        when Net::HTTPForbidden       then response
      else
        response.error!
      end

    end


    def tick

      a = []

      response = fetch( format('http://%s:%d/server-status', @host, @port), 2 )

      return {} if( response.code.to_i != 200 )

      response = response.body.split("\n")

      # blacklist
      response.reject! { |t| t[/#{@host}/] }
      response.reject! { |t| t[/^Server.*/] }
      response.reject! { |t| t[/.*Time/] }
      response.reject! { |t| t[/^ServerUptime/] }
      response.reject! { |t| t[/^Load.*/] }
      response.reject! { |t| t[/^CPU.*/] }
      response.reject! { |t| t[/^TLSSessionCacheStatus/] }
      response.reject! { |t| t[/^CacheType/] }

      response.each do |line|

        metrics = Hash.new

        if line =~ /Scoreboard/
          metrics = { scoreboard: get_scoreboard_metrics(line.strip) }
        else
          key, value = line.strip.split(':')

          key   = key.gsub(/\s/, '')
          value = value.strip.gsub('%','')

          metrics[key] = format( "%f", value ).sub(/\.?0*$/, "" ).to_f
        end

        a << metrics
      end

      a.reduce( :merge )

    end
  end


  class HttpVhosts

    include Logging

    def initialize( params = {} )
      @host  = params.dig(:host)
      @port  = params.dig(:port) || 8081
    end


    def fetch( uri_str, limit = 10 )

      # You should choose better exception.
      raise ArgumentError, 'HTTP redirect too deep' if limit == 0

      url = URI.parse(uri_str)
      req = Net::HTTP::Get.new(url.path, { 'User-Agent' => 'CoreMedia Monitoring/1.0' })
      response = Net::HTTP.start(url.host, url.port) { |http| http.request(req) }

      case response
        when Net::HTTPSuccess         then response
        when Net::HTTPRedirection     then fetch(response['location'], limit - 1)
        when Net::HTTPNotFound        then response
      else
        response.error!
      end

    end


    def tick

      response = fetch( format('http://%s:%d/vhosts.json', @host, @port), 2 )

      return {} if( response.code.to_i != 200 )

      response.body
    end
  end


end
