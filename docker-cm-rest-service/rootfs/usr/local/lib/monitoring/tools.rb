
module Monitoring

  module Tools

    def ns_lookup( name, expire = 120 )

      logger.debug( "ns_lookup( #{name}, #{expire} )" )

      # DNS
      #
      cache_key = format( 'dns::%s', name )

      dns = @redis.get(cache_key)
      dns = dns.deep_symbolize_keys unless(dns.nil?)

      logger.debug( "dns cache: #{dns} (#{dns.class.to_s})" )

      dns = nil

      if( dns.nil? )

        logger.debug( 'no cached DNS data' )

        dns = @database.dns_data( short: name, fqdn: name )

        unless( dns.nil? )

          logger.debug( 'use database entries' )

          dns = dns.deep_symbolize_keys unless(dns.nil?)

          logger.debug( "dba cache: #{dns} (#{dns.class.to_s})" )

          ip    = dns.dig(:ip)
          short = dns.dig(:name)
          fqdn  = dns.dig(:fqdn)

          @redis.set(cache_key, { ip: ip, short: short, fqdn: fqdn }.to_json, expire )

          return ip, short, fqdn
        end

        logger.debug( format( 'resolve dns name %s', name ) )

        # create DNS Information
        dns      = Utils::Network.resolv( name )

        ip    = dns.dig(:ip)
        short = dns.dig(:short)
        fqdn  = dns.dig(:fqdn)

        if( ip.nil? && short.nil? && fqdn.nil? )
          logger.error( 'no DNS data found!' )
          logger.error( " => #{dns}" )

          ip       = nil
          short    = nil
          fqdn     = nil
        else
          @redis.set(cache_key, { ip: ip, short: short, fqdn: fqdn }.to_json, expire )
        end
      else
        ip    = dns.dig(:ip)
        short = dns.dig(:short)
        fqdn  = dns.dig(:fqdn)
      end

      return ip, short, fqdn
    end


    def host_exists?( host )

      logger.debug( "host_exists?( #{host} )" )

      params = { short: host, fqdn: host, status: [ Storage::MySQL::ONLINE, Storage::MySQL::PREPARE ] }

      nodes = @database.nodes( params )

      return false if( nodes.nil? )

      true
    end

    # check availability and create an DNS entry into our redis
    #
    def host_avail?( host )

      logger.debug( "host_avail?( #{host} )" )

      ip, short, fqdn = ns_lookup(host)

      logger.debug( { ip: ip, short: short, fqdn: fqdn } )

      return false if( ip.nil? && short.nil? && fqdn.nil? )

      { ip: ip, short: short, fqdn: fqdn }
    end


    def message_queue( params = {} )

      logger.debug( "message_queue( #{params} )" )

      command = params.dig(:cmd)
      node    = params.dig(:node)
      queue   = params.dig(:queue)
      data    = params.dig(:payload)
      prio    = params.dig(:prio)  || 65536
      ttr     = params.dig(:ttr)   || 10
      delay   = params.dig(:delay) || 2

      job = {
        cmd:  command,
        node: node,
        timestamp: Time.now().strftime( '%Y-%m-%d %H:%M:%S' ),
        from: 'rest-service',
        uid: Digest::MD5.hexdigest(data.to_s),
        payload: data
      }.to_json

      result = @mq_producer.add_job( queue, job, prio, ttr, delay )
      result = JSON.parse( result ) if( result.is_a?( String ) )

      return { status: 404, message: 'job is already in the queue ..' } if(result.nil?)

      status = result.dig(:status)
      id = result.dig(:id)

      return { status: 200, message: 'annotation succesfull send.' }   if(status == 'INSERTED')
      return { status: 404, message: 'can\'t send annotation.' } unless(status == 'INSERTED')
    end

  end
end
