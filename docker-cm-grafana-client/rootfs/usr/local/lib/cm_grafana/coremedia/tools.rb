
require_relative '../../utils/network'

class CMGrafana

  module CoreMedia

    module Tools

      def ns_lookup( name, expire = 120 )

#         logger.debug( "ns_lookup( #{name}, #{expire} )" )

        # DNS
        #
        cache_key = format( 'dns::%s', name )

        ip       = nil
        short    = nil
        fqdn     = nil

        dns      = @cache.get( cache_key )

#         logger.debug("dns: #{dns}")

        unless( dns.nil? )
          ip    = dns.dig(:ip)
          short = dns.dig(:short)
          fqdn  = dns.dig(:fqdn)
        end

        # delete incomplete cache entry
        #
        dns = nil if( ip.nil? || short.nil? || fqdn.nil? )

        if( dns.nil? )
#           logger.debug( 'no cached DNS data' )
#           logger.debug( format( 'resolve dns name %s', name ) )

          # create DNS Information
          dns      = Utils::Network.resolv( name )
#           logger.debug("dns: #{dns}")

          ip    = dns.dig(:ip)
          short = dns.dig(:short)
          fqdn  = dns.dig(:fqdn)

          unless( ip.nil? || short.nil? || fqdn.nil? )
#             logger.debug('save dns data in our short term cache')
            @cache.set( cache_key , expires_in: expire ) { MiniCache::Data.new({ ip: ip, short: short, fqdn: fqdn } ) }
          else
            logger.error( 'no DNS data found!' )
            logger.error( " => #{dns}" )
          end
        else
#           logger.debug( 're-use cached DNS data' )
          ip    = dns.dig(:ip)
          short = dns.dig(:short)
          fqdn  = dns.dig(:fqdn)
        end
        #
        # ------------------------------------------------

#         logger.debug( format( ' ip    %s ', ip ) )
#         logger.debug( format( ' short %s ', short ) )
#         logger.debug( format( ' fqdn  %s ', fqdn ) )

        [ip, short, fqdn]
      end


      # cae-live-1 -> cae-live
      def remove_postfix( service )

        if( service =~ /\d/ )
          last = service.split( '-' ).last
          service  = service.chomp( "-#{last}" )
        end

        service
      end


      def normalize_service( service )

        # normalize service names for grafana
        service = case service
          when 'content-management-server'
            'CMS'
          when 'master-live-server'
            'MLS'
          when 'replication-live-server'
            'RLS'
          when 'workflow-server'
            'WFS'
#          when /^cae-live/
#            tr('-', '_').upcase
#            'CAE_LIVE'
#          when /^cae-preview/
#            'CAE_PREV'
          when 'solr-master'
            'SOLR_MASTER'
      #    when 'solr-slave'
      #      'SOLR_SLAVE'
          when 'content-feeder'
            'FEEDER_CONTENT'
          when 'caefeeder-live'
            'FEEDER_LIVE'
          when 'caefeeder-preview'
            'FEEDER_PREV'
          else
            service
        end

        service = service.gsub('iew','') if( service =~ /^cae-preview/ )
        service.tr('-', '_').upcase
      end


      def discovery_data( params )

        ip    = params.dig(:ip)
        short = params.dig(:short)
        fqdn  = params.dig(:fqdn)

        discovery = nil

        begin
          (1..15).each { |y|

            discovery = @database.discoveryData( ip: ip, short: short, fqdn: fqdn )

            logger.debug(discovery)
            logger.debug(discovery.class.to_s)

            if( discovery.nil? )
              logger.debug(sprintf('wait for discovery data for node \'%s\' ... %d', fqdn, y))
              sleep(4)
            else
              break
            end
          }

        rescue => e
          logger.error( e )
        end

        discovery
      end


      def parsed_response(r)

        return JSON.parse(r)
      rescue JSON::ParserError => e
        return r
      end
    end

  end

end

