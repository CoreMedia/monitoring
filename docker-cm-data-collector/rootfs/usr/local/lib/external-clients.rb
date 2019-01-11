#!/usr/bin/ruby

require 'json'
require 'rest-client'
require 'mysql2'


require_relative 'logging'

require_relative 'external-clients/mongodb'
require_relative 'external-clients/node_exporter'
require_relative 'external-clients/mysql'
require_relative 'external-clients/apache'


module ExternalClients

  include MongoDb
  include NodeExporter
  include MySQL
  include ApacheModStatus
  include HttpVhosts

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


end
