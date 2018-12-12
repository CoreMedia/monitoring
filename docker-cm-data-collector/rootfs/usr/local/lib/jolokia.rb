#!/usr/bin/ruby
#
# 08.01.2017 - Bodo Schulz
#
#
# v1.1.0
# -----------------------------------------------------------------------------

require 'net/http'

require_relative 'logging'
require_relative 'utils/network'

module Jolokia

  class Client

    include Logging

    def initialize( settings )

      raise ArgumentError.new( format( 'wrong type. settings must be an Hash, given %s', settings.class.to_s ) ) unless( settings.is_a?(Hash) )

      @Host     = settings.dig(:host) || 'localhost'
      @Port     = settings.dig(:port) || 8080
      @Path     = settings.dig(:path) || '/jolokia'
      @auth_user = settings.dig(:auth, :user)
      @auth_password = settings.dig(:auth, :pass)
    end


    def post( params )

      raise ArgumentError.new( format( 'wrong type. params must be an Hash, given %s', params.class.to_s ) ) unless( params.is_a?(Hash) )
      raise ArgumentError.new('missing params') if( params.size.zero? )

      payload       = params.dig(:payload)
      timeout       = params.dig(:timeout) || 10
      max_retries   = params.dig(:max_retries) || 5
      sleep_retries = params.dig(:sleep_retries) || 5
      times_retried = 0

      raise ArgumentError.new( format( 'wrong type. payload must be an Array, given %s', payload.class.to_s ) ) unless( payload.is_a?(Array) )
      raise ArgumentError.new( format( 'wrong type. timeout must be an Integer, given %s', timeout.class.to_s ) ) unless( timeout.is_a?(Integer) )
      raise ArgumentError.new( format( 'wrong type. max_retries must be an Integer, given %s', max_retries.class.to_s ) ) unless( max_retries.is_a?(Integer) )
      raise ArgumentError.new( format( 'wrong type. sleep_retries must be an Integer, given %s', sleep_retries.class.to_s ) ) unless( sleep_retries.is_a?(Integer) )

      # HINT or QUESTION
      # check payload if is an valid json?

      uri          = URI.parse( format( 'http://%s:%s%s', @Host, @Port, @Path ) )
      http         = Net::HTTP.new( uri.host, uri.port )

      request = Net::HTTP::Post.new(
        uri.request_uri,
        initheader = { 'Content-Type' =>'application/json' }
      )

      request.body = payload.to_json

      # default read timeout is 60 secs
      response = Net::HTTP.start(
        uri.hostname,
        uri.port,
        use_ssl: uri.scheme == "https",
        :read_timeout => timeout
      ) do |http|

        begin
          http.request( request )

        rescue Net::ReadTimeout => e

          if( times_retried < max_retries )

            times_retried += 1
            logger.warn( format( 'Cannot execute request to %s://%s:%s%s, cause: %s', uri.scheme, uri.hostname, uri.port, uri.request_uri, e ) )
            logger.warn( format( '   retry %s/%s', times_retried, max_retries ) )
            logger.debug( format( ' -> request body: %s', request.body ) )

            sleep( sleep_retries )
            retry
          else
            error = format( '%s for request %s://%s:%s%s, cause: %s, request: %s', error, uri.scheme, uri.hostname, uri.port, uri.request_uri, e, request.body )
            logger.error( 'Exiting request ...' )
            logger.error( error )

            { status: 500, message: error }
          end
        rescue Errno::EINVAL, Errno::ECONNRESET, EOFError, Net::HTTPBadResponse, Net::HTTPHeaderSyntaxError, Net::ProtocolError => e

          error = format( '%s for request %s://%s:%s%s, cause: %s, request: %s', error, uri.scheme, uri.hostname, uri.port, uri.request_uri, e, request.body )
          logger.error( error )

          { status: 500, message: error }
        end
      end

      body = JSON.parse( response.body )

      request_status = body.first.dig('status') || 500
      request_error  = body.first.dig('error')

      # stacktrace found! :(
      if( request_status != 200 )
        { status: request_status, message: request_error }
      end

      { status: 200, message: body }
    end


    def available?

      # if our jolokia proxy available?
      false if( ! Utils::Network.port_open?( @Host, @Port ) )

      true
    end

  end

end

