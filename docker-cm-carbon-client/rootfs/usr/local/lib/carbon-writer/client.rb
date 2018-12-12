
require_relative 'version'
require_relative 'client'
require_relative '../logging'
require_relative '../carbon-data'

module CarbonWriter

  class Client

    include Logging

    def initialize( settings = {} )

      redis_host     = settings.dig(:redis, :host)   || 'localhost'
      redis_port     = settings.dig(:redis, :port)   || 6379

      mysql_host     = settings.dig(:mysql, :host)
      mysql_schema   = settings.dig(:mysql, :schema)
      mysql_user     = settings.dig(:mysql, :user)
      mysql_password = settings.dig(:mysql, :password)

      @graphite_host = settings.dig(:graphite, :host)
      @graphite_port = settings.dig(:graphite, :port)

      version             = CarbonWriter::VERSION
      date                = CarbonWriter::DATE

      logger.info( '-----------------------------------------------------------------' )
      logger.info( ' CoreMedia - Carbon Client' )
      logger.info( "  Version #{version} (#{date})" )
      logger.info( '  Copyright 2017-2018 CoreMedia' )
      logger.info( '  used Services:' )
      logger.info( "    - carbon       : #{@graphite_host}:#{@graphite_port}" )
      logger.info( '-----------------------------------------------------------------' )
      logger.info( '' )

      consumer_setting = {
        redis: { host: redis_host, port: redis_port },
        mysql: { host: mysql_host, schema: mysql_schema, user: mysql_user, password: mysql_password }
      }

      @carbon_data   = CarbonData::Consumer.new(consumer_setting)

    end


    def socket()

      if( ! @socket || @socket.closed? )

        begin
          @socket = TCPSocket.new( @graphite_host, @graphite_port )
        rescue => e
          logger.error( e )
        retry
          sleep( 5 )
        end
      end

      @socket
    end


    def run()

      start = Time.now
      nodes = @carbon_data.nodes()

      if( nodes.nil? || nodes.is_a?( FalseClass ) )
        logger.debug( 'no online server found' )
      else

        nodes.each do |n|

          data = @carbon_data.run( n )

          data.flatten! if( data.is_a?( Array ) )

          finish = Time.now

          logger.info( format( 'getting %s measurepoints in %s seconds', data.count, (finish - start).round(3) ) )

          data.each do |m|
            metric( m )
          end

        end
      end
    end


    def metric( metric = {} )
#      logger.debug("#{metric} - #{metric.class}")
      return if( metric.nil? )
      return unless( metric.is_a?(Hash) )

      key   = metric.dig(:key)
      value = metric.dig(:value)
      time  = metric.dig(:time) || Time.now

      # TODO
      # value must be an float!

      if( key.nil? || value.nil? )

        if( key.nil? )
          logger.debug( 'missing \'key\' entry' )
          logger.debug( "metric: #{metric}  (#{metric.class.to_s})")
        end

        if( value.nil? )
          logger.debug( 'missing \'value\' entry' )
          logger.debug( "metric: #{metric}  (#{metric.class.to_s})")
        end

        return
      end

      begin
#        logger.debug( " = carbon-writer.#{key} #{value.to_f} #{time.to_i}" )
        socket.write( "carbon-writer.#{key} #{value.to_f} #{time.to_i}\n" )
      rescue Errno::EPIPE, Errno::EHOSTUNREACH, Errno::ECONNREFUSED
        @socket = nil
        nil
      end
    end


    def close_socket()
      @socket.close if( @socket )
      @socket = nil
    end

  end

end
