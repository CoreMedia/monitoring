
class CMIcinga2 < Icinga2::Client

  module Queue

    # Message-Queue Integration
    #
    #
    #
    def queue()

      return if(@mq_consumer.nil?)

#       logger.debug( "CMIcinga2::Queue.queue()" )
      data = @mq_consumer.getJobFromTube(@mq_queue )

      if( data.count() != 0 )

        stats = @mq_consumer.tubeStatistics(@mq_queue )
        logger.debug( {
          total: stats.dig(:total),
          ready: stats.dig(:ready),
          delayed: stats.dig(:delayed),
          buried: stats.dig(:buried)
        } )

        if( stats.dig(:ready).to_i > 10 )
          logger.warn( 'more then 10 jobs in queue ... just wait' )

          @mq_consumer.cleanQueue(@mq_queue)
          return
        end

        job_id = data.dig(:id )
        result = process_queue(data)
        status = result.dig(:status).to_i

        if( status == 200 || status == 409 || status == 500 || status == 503 )
          @mq_consumer.deleteJob(@mq_queue, job_id )
        else
          @mq_consumer.buryJob(@mq_queue, job_id )
        end
      end

    end


    def process_queue( data = {} )

      logger.info( format( 'process Message ID %d from Queue \'%s\'', data.dig(:id), data.dig(:tube) ) )

      command     = data.dig( :body, 'cmd' )
      node        = data.dig( :body, 'node' )
      payload     = data.dig( :body, 'payload' )
#       @identifier = nil
      dns         = nil
      tags        = nil

      if( command.nil? || node.nil? || payload.nil? )

        status = 500

        return { status: status, message: 'missing command' } if( command.nil? )
        return { status: status, message: 'missing node' } if( node.nil? )
        return { status: status, message: 'missing payload' } if( payload.nil? )
      end

      payload  = JSON.parse( payload ) if( payload.is_a?( String ) == true && payload.to_s != '' )

#       logger.debug( 'payload:' )
#       logger.debug( JSON.pretty_generate( payload ) )
#       logger.debug( '----------------------------------' )

      unless( payload.is_a?( String ) )
        dns      = payload.dig('dns')
        tags     = payload.dig('tags')
      end

      logger.info( format( '  %s node %s', command , node ) )

      if( dns.nil? )
        ip, short, fqdn = self.ns_lookup(node)
      else
        ip = dns.dig('ip')
        short = dns.dig('short')
        fqdn = dns.dig('fqdn')
      end

      job_option = { command: command, ip: ip, short: short, fqdn: fqdn }

      return { status: 409, message: 'we are working on this job' } if( @jobs.jobs( job_option ) == true )

      @jobs.add( job_option )

      @cache.set(format( 'dns::%s', node ) , expires_in: 320 ) { MiniCache::Data.new( ip: ip, short: short, fqdn: fqdn ) }


      # 'default-host-ping'

      # rescan services and update host object
      #

      # add Node
      #
      if( command == 'add' || command == 'rescan' )

        services     = node_information( ip: ip, short: short, fqdn: fqdn, payload: payload )
        display_name = @database.config( ip: ip, short: short, fqdn: fqdn, key: 'display_name' )

        if( display_name.nil? )
          display_name = fqdn
        else
          display_name = display_name.dig('display_name') || fqdn
        end

        # TODO: add groups
        #
        payload = {}
        payload = services unless( services.empty? )

        payload['tags'] = tags unless( tags.nil? )

        # TODO
        # full API support
        #
        # BUG
        # miss zone entry for distributed monitoring
        #
        params = {
          name: fqdn,
          address: fqdn,
          display_name: display_name,
          enable_notifications: @icinga_notifications,
          vars: payload,
        }

        params[:merge_vars] = true if( command == 'rescan' )
        params[:templates] = ['default-host-ping'] unless( @icinga_satellite.nil? )
        params[:zone] = @icinga_satellite unless( @icinga_satellite.nil? )

#         logger.debug(JSON.pretty_generate(params))

        result = add_host(params)    if( command == 'add' )
        result = modify_host(params) if( command == 'rescan' )

        return { status: status } if( result.nil? )

        status = result.dig('code') || 500

        logger.debug( result )
        logger.error( result ) if( status != 200 )

        sleep 8

        logger.debug( ' => restart_process' ) if( command == 'add' )
        logger.debug( ' => shutdown_process' ) if( command == 'rescan' )

        restart_process if( command == 'add' )
#         shutdown_process if( command == 'rescan' )

        @jobs.del( job_option )

        return { status: status }
      end

      # remove Node
      #
      if( command == 'remove' )

#         logger.info( format( 'remove checks for node %s', node ) )

        result = delete_host( name: fqdn, cascade: true )

        logger.debug( result )

        @jobs.del( job_option )

        return { status: 200 }
      end

      # information about Node
      #
      if( command == 'info' )

#         logger.info( format( 'give information for node %s', node ) )

        result = hosts( name: fqdn )

        logger.debug( result )

        @jobs.del( job_option )

        return { status: 200 }
      end

      #
      #
      if( command == 'update' )

        services     = node_information( ip: ip, short: short, fqdn: fqdn, payload: payload )
        display_name = @database.config( ip: ip, short: short, fqdn: fqdn, key: 'display_name' )

        if( display_name.nil? )
          display_name = fqdn
        else
          display_name = display_name.dig('display_name') || fqdn
        end

        # TODO: add groups
        #
        payload = {}
        payload = services unless( services.empty? )

        unless( tags.nil? )
          tags.each do |t,v|
            payload[t] = v
          end
        end

        # TODO
        # full API support
        params = {
          name: fqdn,
          address: fqdn,
          display_name: display_name,
          enable_notifications: @icinga_notifications,
          vars: payload,
          merge_vars: true
        }

        params[:templates] = ['default-host-ping'] unless( @icinga_satellite.nil? )
        params[:zone] = @icinga_satellite unless( @icinga_satellite.nil? )

        result = delete_host( name: fqdn, cascade: true )

        status = result.dig('code') || 500

        logger.debug( result )
        logger.error( result ) if( status != 200 )

        result = add_host(params)

        # result = modify_host(params)

        status = result.dig('code') || 500

        logger.debug( result )
        logger.error( result ) if( status != 200 )

#        sleep 8
#        logger.debug( ' => shutdown_process' ) if( command == 'update' )
#        shutdown_process

        @jobs.del( job_option )

        return { status: status }
      end

      # all others
      #
      logger.error( format( 'wrong command detected: %s', command ) )

      @jobs.del( job_option )

      return { status: 500, message: format( 'wrong command detected: %s', command ) }
    end


    def send_message(params = {} )

      command = params.dig(:cmd)
      node    = params.dig(:node)
      queue   = params.dig(:queue)
      data    = params.dig(:payload)
      prio    = params.dig(:prio)  || 65536
      ttr     = params.dig(:ttr)   || 10
      delay   = params.dig(:delay) || 2

      job = {
        cmd:  command,      # require
        node: node,         # require
        timestamp: Time.now().strftime( '%Y-%m-%d %H:%M:%S' ), # optional
        from: 'icinga',     # optional
        payload: data       # require
      }.to_json

      result = @mq_producer.addJob( queue, job, prio, ttr, delay )

      logger.debug( job )
      logger.debug( result )

    end


  end

end
