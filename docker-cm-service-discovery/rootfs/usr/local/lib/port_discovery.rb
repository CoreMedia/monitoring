#!/usr/bin/ruby
#
# 08.01.2017 - Bodo Schulz
#
#
# v1.1.0
# -----------------------------------------------------------------------------

require 'net/http'
require 'rest-client'

require_relative 'logging'
require_relative 'utils/network'

module PortDiscovery

  class Client

    include Logging

    def initialize( params = {} )

      @Host     = params.dig(:host)
      @Port     = params.dig(:port) || 8088
      @Path     = params.dig(:path) || '/scan'

    end


    def post( params = {} )

      host    = params.dig(:host)
      ports   = params.dig(:ports)   || []
      timeout = params.dig(:timeout) || 10
      payload = nil

      headers = { 'Content-Type' => 'application/json', 'Accept' => 'application/json' }

      url = format( 'http://%s:%s%s/%s', @Host, @Port, @Path, host )

      rest_client = RestClient::Resource.new(
        URI.encode( url )
      )

      unless( ports.nil? )
        payload = { ports: ports }
      end

      begin

        data = rest_client.post(
          JSON.generate( payload ),
          headers
        )

        data    = JSON.parse( data )

        return data.dig('ports')

      rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH => e

        max_retries = 3
        retried     = 0

        if( retried < max_retries )
          retried += 1
          $stderr.puts(format("Cannot execute request against '%s': '%s' (retry %d / %d)", url, e, retried, max_retries))
          sleep(2)
          retry
        else

          message = format( "Maximum retries (%d) against '%s' reached. Giving up ...", max_retries, url )
          $stderr.puts( message )
        end

      rescue => e

        logger.debug( "ERROR: #{e}")
      end

      return nil
    end


    def isAvailable?( params = {} )

      host = params.dig(:host) ||  @Host
      port = params.dig(:port) ||  @Port

      # if our jolokia proxy available?
      if( ! Utils::Network.port_open?( host, port ) )
        logger.error( 'port discovery service is not available!' )
        return false
      end

      return true
    end

  end

end

