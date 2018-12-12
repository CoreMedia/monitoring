
module ServiceDiscovery

  module Refresh


    def refresh_host_data

      monitored_server = @database.nodes( status: [ Storage::MySQL::ONLINE ] )

      return { status: 204,  message: 'no online server found' } if( monitored_server.nil? || monitored_server.is_a?( FalseClass ) || monitored_server.count == 0 )

      monitored_server.each do |h|

        # get a DNS record
        #
        ip, short, fqdn = self.ns_lookup( h )

        # no dns entries found
        #
        return { status: 503,  message: format( 'Host %s are unavailable', h ) } if( ip.nil? || short.nil? || fqdn.nil? )

        # if the destination host available (simple check with ping)
        #
        # 503 Service Unavailable
        return { status: 503,  message: format( 'Host %s are unavailable', fqdn ) } unless( Utils::Network.is_running?( fqdn ) )

        logger.info(format('refresh services for host \'%s\'', fqdn))

        known_services_count, known_services_array             = known_services( ip: ip, short: short, fqdn: fqdn ).values
        actually_services_count, actually_services_array, data = actually_services( ip: ip, short: short, fqdn: fqdn ).values
        identical_services                                     = known_services_array & actually_services_array

        # only for debugging:
        #

        # new_entries             = actually_services_array - known_services_array
        # removed_entries         = known_services_array - identical_services
        #
        # known_data_count        = known_services_array.count
        # actually_data_count     = actually_services_array.count
        # identical_services_count = identical_services.count
        # removed_entries_count   = removed_entries.count
        # new_entries_count       = new_entries.count
        #
        # logger.debug( '------------------------------------------------------------' )
        # logger.info( format( 'identical entries %d', identical_services_count ) )
        # logger.debug(  "  #{identical_services}" )
        # logger.debug( '------------------------------------------------------------' )
        # logger.info( format( 'new entries %d', new_entries_count ) )
        # logger.debug(  "  #{new_entries}" )
        # logger.debug( '------------------------------------------------------------' )
        # logger.info( format( 'removed entries %d', removed_entries_count ) )
        # logger.debug(  "  #{removed_entries}" )
        # logger.debug( '------------------------------------------------------------' )
        # logger.info( format( 'known_services_count    %d', known_services_count ) )
        # logger.info( format( 'actually_services_count %d', actually_services_count ) )
        # logger.debug( '------------------------------------------------------------' )

        if( actually_services_count == known_services_count )
          logger.debug( 'equal services' )
        else

          if( known_services_count < actually_services_count )

            new_entries            = actually_services_array - known_services_array

            logger.info( format( '%d new service detected (%s)', actually_services_count.to_i - known_services_count.to_i, new_entries.join(', ') ) )

            # step 1
            # update our database
            result    = @database.create_discovery( ip: ip, short: short, fqdn: fqdn, data: data )

            options = { dns: { ip: ip, short: short, fqdn: fqdn } }
#             host    = fqdn

            # step 2
            # create a job for update icinga
            logger.info( 'create message for grafana to create or update dashboards' )
            send_message( cmd: 'update', node: fqdn, queue: 'mq-grafana', payload: options, prio: 10, ttr: 15, delay: 25 )

            # step 3
            # create a job for update grafana
            logger.info( 'create message for icinga to update host and apply checks and notifications' )
            send_message( cmd: 'update', node: fqdn, queue: 'mq-icinga', payload: options, prio: 10, ttr: 15, delay: 25 )

          elsif( known_services_count > actually_services_count )

            removed_entries        = known_services_array - identical_services
            logger.warn( format( '%d less services (will be ignored) (%s)', removed_entries.count, removed_entries.join(', ') ) )
          end

        end
      end
    end


    def known_services( params )

      ip    = params.dig(:ip)
      short = params.dig(:short)
      fqdn  = params.dig(:fqdn)

      # check discovered datas from the past
      #
#       discovery_data   = @database.discoveryData( ip: ip, short: short, fqdn: fqdn )
      discovery_data   = @database.discovery_data( ip: ip, short: short, fqdn: fqdn )

      logger.debug("discovery_data: #{discovery_data} (#{discovery_data.class})")

      return { count: 0, services: [] } unless( discovery_data.is_a?(Hash) )
      return { count: 0, services: [] } if( discovery_data.count == 0 )

      services = discovery_data.keys.sort
      services_count   = services.count

      logger.debug({ count: services_count, services: services, type: services.class })

      { count: services_count, services: services }
    end


    def actually_services( params )

      ip    = params.dig(:ip)
      short = params.dig(:short)
      fqdn  = params.dig(:fqdn)

      # get customized configurations of ports and services
      #
      logger.debug( 'ask for custom configurations' )

      ports    = @database.config( ip: ip, short: short, fqdn: fqdn, key: 'ports' )
      services = @database.config( ip: ip, short: short, fqdn: fqdn, key: 'services' )

      ports    = (ports != nil)    ? ports.dig( 'ports' )       : ports
      services = (services != nil) ? services.dig( 'services' ) : services

      # our default known ports
      ports = @scan_ports if( ports.nil? )

      # our default known ports
      services = [] if( services.nil? )

      logger.debug( "use ports          : #{ports}" )
      logger.debug( "additional services: #{services}" )

      discovered_services = discover( ip: ip, short: short, fqdn: fqdn, ports: ports )
      discovered_services = merge_services( discovered_services, services )
      discovered_services = create_host_config( ip: ip, short: short, fqdn: fqdn, data: discovered_services )

      services = discovered_services.keys.sort
      services_count = services.count

      { count: services_count, services: services, discovery_data: discovered_services }
    end

  end
end
