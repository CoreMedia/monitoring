#
#
#

require_relative 'monkey'
require 'storage'

module MBean

  class Client

    include Logging


    def initialize( params = {} )

      redis  = params.dig(:redis)
      @redis = redis if( redis != nil )

      logger.level = Logger::INFO
    end


    def bean( host, service, mbean )

      return false if( host.nil? || service.nil? || mbean.nil? )

      # logger.error( "no valid data:" )
      # logger.error( "  bean( #{host}, #{service}, #{mbean} )" )

      data = {}

      cache_key = { host: host, pre: 'result', service: service }

      logger.debug( "plain cache_key: #{cache_key}" )

      cacheKey = Storage::RedisClient.cache_key( cache_key )

      logger.debug( "redis cache_key: #{cacheKey}" )

      begin
        result = @redis.get( cacheKey )

        data = { service => result } if( result != nil )

      rescue => e
        logger.debug( 'retry ...')
        logger.error(e)
        sleep( 2 )
        retry
      end

#      for y in 1..10
#
#        result      = @redis.get( cache_key )
#
#        if( result != nil )
#          data = { service => result }
#          break
#        else
#          sleep( 3 )
#        end
#      end

      # ---------------------------------------------------------------------------------------

      begin

        logger.debug(data.keys)

        s   = data.dig(service)

        logger.debug(s)
        logger.debug(s.class.to_s)

        # logger.debug("no service '#{service}' found")
        return false if( s.nil? )
        return false unless( s.is_a?(Array) )
        return false if( s.is_a?(Array) && s.count == 0 )

        mbeanExists  = s.detect { |s| s[mbean] }

        # no mbean $mbean found
        # logger.debug("no mbean '#{mbean}' for service '#{service}' found")
        return false if( mbeanExists.nil? )

        result = mbeanExists.dig(mbean)

      rescue JSON::ParserError => e

        logger.error('wrong result (no json)')
        logger.error(e)

        result = false
      end

      result
    end


    def supportMbean?( data, service, mbean, key = nil )

      result = false

      # logger.error( 'no data given' )
      return false if( data.nil? )

      s   = data.dig(service)

      # no service found
      return false if( s.nil? )

      mbeanExists  = s.detect { |s| s[mbean] }

      # no mbean $mbean found
      return false if( mbeanExists.nil? )

      mbeanExists  = mbeanExists.dig(mbean)
      mbeanStatus  = mbeanExists.dig('status') || 999

      # mbean $mbean found, but status != 200
      return false if( mbeanStatus.to_i != 200 )

      return true if( mbeanExists != nil && key.nil? )

      if( mbeanExists != nil && key != nil )

        mbeanValue = mbeanExists.dig('value')

        return false if( mbeanValue.nil? )

        mbeanValue = mbeanValue.values.first if( mbeanValue.is_a?(Hash) )
        attribute = mbeanValue.dig(key)

        return false if( attribute.nil? || ( attribute.is_a?(String) && attribute.include?( 'ERROR' ) ) )

        result = true
      end

      result
    end


    def beanAvailable?( host, service, bean, key = nil )

      data     = nil

      cache_key = { host: host, pre: 'result', service: service }

      logger.debug( "plain cache_key: #{cache_key}" )

      cacheKey = Storage::RedisClient.cache_key( cache_key )

      logger.debug( "redis cache_key: #{cacheKey}" )

#      logger.debug( { :host => host, :pre => 'result', :service => service } )
#      cacheKey = Storage::RedisClient.cache_key( { :host => host, :pre => 'result', :service => service } )

      (1..15).each { |x|

        redis_data = @redis.get( cacheKey )

        if( redis_data.nil? )
          logger.debug(format('wait for discovery data for node \'%s\' ... %d', host, x))
          sleep(3)
        else
          data = { service => redis_data }
          break
        end
      }

      # ---------------------------------------------------------------------------------------

      # logger.error( 'no data found' )
      return false if( data.nil? )

      begin
        result = self.supportMbean?( data, service, bean, key )
      rescue JSON::ParserError => e

        logger.error('wrong result (no json)')
        logger.error(e)

        result = false
      end

      result
    end


    def beanName( mbean )

      regex = /
        ^                     # Starting at the front of the string
        (.*)                  #
        name=                 #
        (?<name>.+[a-zA-Z])   #
        (.*),                 #
        type=                 #
        (?<type>.+[a-zA-Z])   #
        $
      /x

      parts           = mbean.match( regex )
      mbeanName       = parts['name'].to_s
#       mbeanType       = parts['type'].to_s

      mbeanName
    end


    def beanTimeout?( timestamp )

      result = false
      quorum = 1 # in minutes

      if( timestamp.nil? || timestamp.to_s == 'null' )
        result = true
      else
        n = Time.now()
        t = Time.at( timestamp )
        t = t.addMinutes( quorum ) + 10

        difference = time_difference( t, n )
        difference = difference[:minutes].round(0)

        if( difference > quorum + 1 )

          logger.debug( format( ' now       : %s', n.to_datetime.strftime("%d %m %Y %H:%M:%S") ) )
          logger.debug( format( ' timestamp : %s', t.to_datetime.strftime("%d %m %Y %H:%M:%S") ) )
          logger.debug( format( ' difference: %d', difference ) )

          result = true
        end
      end

      result
    end


    def checkBeanConsistency( mbean, data = {} )

      status    = data.dig('status')    # ? data['status']    : 505
      timestamp = data.dig('timestamp') # ? data['timestamp'] : 0
      host      = data.dig('host')
      service   = data.dig('service')
      value     = data.dig('value')

      result = {
        mbean: mbean,
        status: status,
        timestamp: timestamp
      }

      return true if( status.to_i == 200 )

      logger.debug( format( '  status: %d: %s (Host: \'%s\' :: mbean: \'%s\')', status, timestamp, host, mbean ) )
      return false if( self.beanTimeout?( timestamp ) )

      true
    end


    def time_difference( start_time, end_time )

      seconds_diff = (start_time - end_time).to_i.abs

      {
        years: (seconds_diff / 31556952),
        months: (seconds_diff / 2628288),
        weeks: (seconds_diff / 604800),
        days: (seconds_diff / 86400),
        hours: (seconds_diff / 3600),
        minutes: (seconds_diff / 60),
        seconds: seconds_diff,
      }
    end


  end

end
