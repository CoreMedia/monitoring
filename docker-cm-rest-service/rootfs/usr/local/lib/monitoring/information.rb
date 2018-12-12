module Monitoring

  module Information

    # get informations for one or all nodes back
    #
    def host_informations( params = {} )

      logger.debug( "host_informations( #{params} )" )

      host            = params.dig(:host)
      status          = params.dig(:status) || [ Storage::MySQL::ONLINE, Storage::MySQL::PREPARE ]
      full_information = params.dig(:full)  || false

      ip      = nil
      short   = nil
      fqdn    = nil

      result  = {}

      if( host.nil? )
        params = { status: status }
      else
        ip, short, fqdn = ns_lookup(host)

        return nil if( ip.nil? && short.nil? && fqdn.nil? )

        params = { ip: ip, short: short, fqdn: fqdn, status: status }
      end

      # get nodes with ONLINE or PREPARE state
      #
      nodes = @database.nodes( params )

      if( nodes.is_a?( Array ) && nodes.count != 0 )

        nodes.each do |n|

          if( ip.nil? && short.nil? && fqdn.nil? )

            ip, short, fqdn = ns_lookup(n)

            if( ip.nil? && short.nil? && fqdn.nil? )
              logger.warn( { status: 400, message: format( 'Host \'%s\' are not available (DNS Problem)', n ) } )
              next
            end

          end

          result[n.to_s] ||= {}

          # DNS data
          #
          result[n.to_s][:dns] ||= { ip: ip, short: short, fqdn: fqdn }

          status  = @database.status( ip: ip, short: short, fqdn: fqdn )

          created = status.dig('creation')
          message = status.dig('status')

          # STATUS data
          #
          result[n.to_s][:status] ||= { created: created, status: message }

          host_configuration = @database.config( ip: ip, short: short, fqdn: fqdn )

          result[n.to_s][:custom_config] = host_configuration if( host_configuration != nil )

          # get discovery data
          #
          discovery_data = @database.discovery_data( ip: ip, short: short, fqdn: fqdn )

          unless( discovery_data.nil? )

            discovery_data.each do |a,d|

              d = JSON.generate(d) if(d.is_a?(String))

              d.reject! { |k| k == 'application' }
              d.reject! { |k| k == 'template' }
            end

            result[n.to_s][:services] ||= discovery_data
          end

          # realy needed?
          #
          if( full_information != nil && full_information == true )

            # get data from external services
            #
            message_queue( cmd: 'info', node: n, queue: 'mq-grafana' , prio: 1, payload: {}, ttr: 1, delay: 0 )
            message_queue( cmd: 'info', node: n, queue: 'mq-icinga'  , prio: 1, payload: {}, ttr: 1, delay: 0 )

            sleep( 1 )

            status_grafana   = {}
            status_icinga    = {}

            for y in 1..4

              r      = @mq_consumer.get_job_from_queue('mq-grafana-info')

#               logger.debug( r.dig( :body, 'payload' ) )

              if( r.is_a?( Hash ) && r.count != 0 && r.dig( :body, 'payload' ) != nil )

                status_grafana = r
                break
              else
#                 logger.debug( format( 'Waiting for data %s ... %d', 'mq-grafana-info', y ) )
                sleep( 2 )
              end
            end

            for y in 1..4

              r      = @mq_consumer.get_job_from_queue('mq-icinga-info')

#               logger.debug( r.dig( :body, 'payload' ) )

              if( r.is_a?( Hash ) && r.count != 0 && r.dig( :body, 'payload' ) != nil )

                status_icinga = r
                break
              else
#                 logger.debug( format( 'Waiting for data %s ... %d', 'mq-icinga-info', y ) )
                sleep( 2 )
              end
            end

            if( status_grafana )
              status_grafana = status_grafana.dig( :body, 'payload' ) || {}
              result[n.to_s][:grafana] ||= status_grafana
            end

            if( status_icinga )
              status_icinga = status_icinga.dig( :body, 'payload' ) || {}
              result[n.to_s][:icinga] ||= status_icinga
            end
          end


          ip    = nil
          short = nil
          fqdn  = nil
        end
      end

      result
    end
  end
end
