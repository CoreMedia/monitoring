
require 'mini_cache'

class CMIcinga2 < Icinga2::Client

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

#         dns = @database.dnsData( short: name, fqdn: name )
#
#         unless( dns.nil? )
#
#           logger.debug( 'use database entries' )
#
#           ip    = dns.dig('ip')
#           short = dns.dig('name')
#           fqdn  = dns.dig('fqdn')
#
#           @cache.set( hostname , expires_in: expire ) { MiniCache::Data.new( ip: ip, short: short, fqdn: fqdn ) }
#
#           return ip, short, fqdn
#         end

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


    def node_information( params )

#       logger.debug( "node_information( #{params} )" )

      ip      = params.dig(:ip)
      short   = params.dig(:short)
      fqdn    = params.dig(:fqdn)
      org_payload = params.dig(:payload)

#       full_config        = @database.config( ip: ip, short: short, fqdn: fqdn )
      team_config        = @database.config( ip: ip, short: short, fqdn: fqdn, key: 'team' )
      environment_config = @database.config( ip: ip, short: short, fqdn: fqdn, key: 'environment' )
      aws_config         = @database.config( ip: ip, short: short, fqdn: fqdn, key: 'aws' )
      vhost_http_config  = @database.config( ip: ip, short: short, fqdn: fqdn, key: 'vhost_http' )
      vhost_https_config = @database.config( ip: ip, short: short, fqdn: fqdn, key: 'vhost_https' )

      logger.debug( "team_config       : #{team_config}" )
      logger.debug( "environment_config: #{environment_config}" )
      logger.debug( "aws_config        : #{aws_config}" )
      logger.debug( "vhost_http_config : #{vhost_http_config}" )
      logger.debug( "vhost_https_config: #{vhost_https_config}" )
      logger.debug('---------------------------------------------------------------------')

      # in first, we need the discovered services ...
      #
      for y in 1..30

        logger.debug( format( 'get data for \'%s\' ...', fqdn ) )

        result = @database.discoveryData( ip: ip, short: short, fqdn: fqdn )

#         logger.debug( format( '  result %s (%s)', result, result.class.to_s ) )

        if( result.is_a?( Hash ) && result.count != 0 )
          services = result
          break
        else
          logger.debug( format( 'waiting for data for \'%s\' ... %d', fqdn, y ) )
          sleep( 5 )
        end
      end

      payload = {}

#       logger.debug( JSON.pretty_generate(services) )

      unless( services.nil?  )

        # check, for RLS and CAE(live|preview)
        unless( services.dig('replication-live-server').nil? )

          replicator_value = content_server( fqdn: fqdn, mbean: 'Replicator', service: 'replication-live-server' )
#           logger.debug(replicator_value)
          unless( replicator_value.nil? )

            master_live_server = replicator_value.dig('MasterLiveServer','host')
            master_live_server_port = replicator_value.dig('MasterLiveServer','port')

            if( Utils::Network.is_running?( master_live_server ) && Utils::Network.port_open?( master_live_server, master_live_server_port ) )

              unless( master_live_server.nil? )
                services['replication-live-server']['master_live_server'] = master_live_server
                services['replication-live-server']['sequencenumbers'] = true
              end

              logger.debug( "content server for replication-live-server: #{master_live_server}" )
            else
              # TODO
              # create an job, when we found no MLS to update this host

              services['replication-live-server'].delete('sequencenumbers') if( services['replication-live-server']['sequencenumbers'] )

              logger.warn( 'content server for replication-live-server is current not available' )
              logger.info( 'i create an node rescan job to complete my job.' )

              send_message(
                cmd: 'rescan',
                node: fqdn,
                queue: @mq_queue,
                payload: org_payload,
                delay: 120
              )
            end
          end
        end

        unless( services.dig('cae-live').nil? )

          cap_connection_value = content_server( fqdn: fqdn, mbean: 'CapConnection', service: 'cae-live' )

          unless( cap_connection_value.nil? )

            content_server = cap_connection_value.dig('ContentServer','host')
            logger.debug( "content server for cae-live: #{content_server}" )

            services['cae-live']['content_server'] = content_server unless( content_server.nil? )
          end
        end

        unless( services.dig('cae-preview').nil? )

          cap_connection_value = content_server( fqdn: fqdn, mbean: 'CapConnection', service: 'cae-preview' )

          unless( cap_connection_value.nil? )

            content_server = cap_connection_value.dig('ContentServer','host')
            logger.debug( "content server for cae-preview: #{content_server}" )

            services['cae-preview']['content_server'] = content_server unless( content_server.nil? )
          end
        end

        services.each do |s|
          next if( s.last.nil? )

          s.last.reject! { |k| k == 'template' }
          s.last.reject! { |k| k == 'application' }
          s.last.reject! { |k| k == 'description' }
        end

        if( services.include?('http-proxy') )
          vhosts = services.dig('http-proxy','vhosts')

          payload['http_vhosts'] = vhosts  if( vhosts.is_a?(Hash) )

          payload['http'] = true
          services.reject! { |k| k == 'http-proxy' }
        end

        if( services.include?('https-proxy') )
          vhosts = services.dig('https-proxy','vhosts')

          payload['https_vhosts'] = vhosts if( vhosts.is_a?(Hash) )
          payload['https'] = true
          services.reject! { |k| k == 'https-proxy' }
        end

        if( services.include?('http-status') )
          payload['http_status'] = true
          services.reject! { |k| k == 'http-status' }
        end

        services.each do |k,v|
          payload[k] = v
        end
      end

      if( aws_config )
#        logger.debug(aws_config.class.to_s)
        aws_config = aws_config.dig('aws')
        aws_config = aws_config.gsub( '=>', ':' )
        aws_config = parsed_response( aws_config )

        aws_config.each do |k,v|
          payload["aws_#{k}"] = v
        end
      end

      payload['team']        = parsed_response( team_config )        if( team_config )
      payload['environment'] = parsed_response( environment_config ) if( environment_config )

      # rename all keys
      # replace '-' with '_'
      #
      payload.inject({ }) { |x, (k,v)| x[k.gsub('-', '_')] = v; x }
    end


    def content_server( params )

      fqdn    = params.dig(:fqdn)
      service = params.dig(:service)
      mbean   = params.dig(:mbean)
      content_server = nil

      # get data from redis
      cache_key = Storage::RedisClient.cacheKey( host: fqdn, pre: 'result', service: service )

      redis_data = @redis.get( cache_key )
      redis_data = JSON.parse(redis_data) if redis_data.is_a?(String)

      unless( redis_data.nil? )
        bean_data  = redis_data.select { |k,_v| k.dig( mbean ) }
        bean_data  = bean_data.first if( bean_data.is_a?(Array) )

        content_server = bean_data.dig(mbean,'value') unless( bean_data.nil? )
        content_server.values.first unless( content_server.nil? )
      end
    end


    def parsed_response( r )

      return JSON.parse( r )
    rescue JSON::ParserError => e
      logger.error(e)
      return r # do smth
    end

  end

end

