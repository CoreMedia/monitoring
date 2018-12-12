
module ServiceDiscovery

  # noinspection ALL
  module Tools

    def ns_lookup( name, expire = 120 )

      logger.debug( "ns_lookup( #{name}, #{expire} )" )

      # DNS
      #
      cache_key = format( 'dns::%s', name )

      ip       = nil
      short    = nil
      fqdn     = nil

      dns      = @cache.get( cache_key )

      logger.debug("dns: #{dns}")

      unless( dns.nil? )
        ip    = dns.dig(:ip)
        short = dns.dig(:short)
        fqdn  = dns.dig(:fqdn)
      end

      # delete incomplete cache entry
      #
      dns = nil if( ip.nil? || short.nil? || fqdn.nil? )

      if( dns.nil? )

        logger.debug( 'no cached DNS data' )
        logger.debug( format( 'resolve dns name %s', name ) )

        # create DNS Information
        dns      = Utils::Network.resolv( name )
        logger.debug("dns: #{dns}")

        ip    = dns.dig(:ip)
        short = dns.dig(:short)
        fqdn  = dns.dig(:fqdn)

        unless( ip.nil? || short.nil? || fqdn.nil? )

          logger.debug('save dns data in our short term cache')
          @cache.set( cache_key , expires_in: expire ) { MiniCache::Data.new({ ip: ip, short: short, fqdn: fqdn } ) }
        else
          logger.error( 'no DNS data found!' )
          logger.error( " => #{dns}" )
        end
      else

        logger.debug( 're-use cached DNS data' )

        ip    = dns.dig(:ip)
        short = dns.dig(:short)
        fqdn  = dns.dig(:fqdn)
      end
      #
      # ------------------------------------------------

      logger.debug( format( ' ip    %s ', ip ) )
      logger.debug( format( ' short %s ', short ) )
      logger.debug( format( ' fqdn  %s ', fqdn ) )

      [ip, short, fqdn]
    end

  end

end

