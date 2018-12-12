
module ServiceDiscovery

  module Queue

    # Message-Queue Integration
    #
    #
    #
    def queue

      data = @mq_consumer.getJobFromTube(@mq_queue )

      if( data.count != 0 )

        stats = @mq_consumer.tubeStatistics(@mq_queue )
        logger.debug( {
          total: stats.dig(:total),
          ready: stats.dig(:ready),
          delayed: stats.dig(:delayed),
          buried: stats.dig(:buried)
        } )

        if( stats.dig(:ready).to_i > 10 )
          logger.warn( 'more then 10 jobs in queue ... just wait' )

          @mq_consumer.cleanQueue(@mq_queue )
          return
        end

        job_id  = data.dig(:id )

        result = self.process_queue(data )

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

      command = data.dig( :body, 'cmd' )
      node    = data.dig( :body, 'node' )
      payload = data.dig( :body, 'payload' )

      if( command == nil || node == nil || payload == nil )

        status = 500

        return {status: status, message: 'missing command'} if( command == nil )
        return {status: status, message: 'missing node'} if( node == nil )
        return {status: status, message: 'missing payload'} if( payload == nil )
      end

      payload  = JSON.parse( payload ) if( payload.is_a?( String ) && payload.to_s != '' )

      logger.debug( JSON.pretty_generate payload )

      dns      = payload.dig('dns') unless( payload.is_a?(String))
#       logger.info( format( '  %s node %s', command , node ) )
      ip, short, fqdn = ns_lookup( node ) if( dns.nil? )

      ip = dns.dig('ip')
      short = dns.dig('short')
      fqdn = dns.dig('fqdn')

      job_option = { command: command, ip: ip, short: short, fqdn: fqdn }

      return { status: 409, message: 'we are working on this job' } if( @jobs.jobs( job_option ) == true )

      @jobs.add( job_option )

      @cache.set(format( 'dns::%s', node ) , expires_in: 320 ) { MiniCache::Data.new( ip: ip, short: short, fqdn: fqdn ) }

      # add Node
      #
      if( command == 'add' )

        # TODO
        # check payload!
        # e.g. for 'force' ...
        result  = self.add_host( node, payload )

        status  = result.dig(:status)
        message = result.dig(:message)

        result = { status: status, message: message }

        logger.error( result ) if( result.dig(:status).to_i != 200 )

        @jobs.del( job_option )

        return result
      end

      # remove Node
      #
      if( command == 'remove' )

        # check first for existing node!
        #
        params = { ip: ip, short: short, fqdn: fqdn, status: Storage::MySQL::DELETE }
        result = @database.nodes(params)

        unless( result.is_a?( Array ) && result.count != 0 )
          logger.info( 'node not in monitoring. skipping delete' )
          @jobs.del( job_option )
          return { status: 200, message: format('node not in monitoring. skipping delete ...') }
        end

        begin

          # remove node also from data-collector!
          #
          self.send_message( cmd: command, node: node, queue: 'mq-collector', payload: { host: node, pre: 'prepare' }, ttr: 1, delay: 0 )

          result = self.delete_host( node, payload )
        rescue => e

          logger.error( e )
        end

        @jobs.del( job_option )

        return { status: 200 }
      end

      # information about Node
      #
      if( command == 'info' )

        result = @redis.nodes( short: node )

        logger.debug( "redis: '#{result}' | node: '#{node}'" )

        if( result.to_s != node.to_s )

          logger.info( 'node not in monitoring. skipping info' )

          @jobs.del( job_option )

          return { status: 200, message: format('node not in monitoring. skipping info ...') }
        end

        result = self.list_hosts(node )
        logger.debug( result )

        status  = result.dig(:status)
        message = result.dig(:message)

        self.send_message( cmd: 'info', node: node, queue: 'mq-discover-info', payload: result, ttr: 1, delay: 0 )

        @jobs.del( job_option )

        return { status: 200, message: 'information succesful send' }
      end

      # all others
      #
      logger.error( format( 'wrong command detected: %s', command ) )

      @jobs.del( job_option )

      return { status: 500, message: format('wrong command detected: %s', command) }
    end


    def send_message( params = {} )

      command = params.dig(:cmd)
      node    = params.dig(:node)
      queue   = params.dig(:queue)
      data    = params.dig(:payload)
      prio    = params.dig(:prio)  || 65536
      ttr     = params.dig(:ttr)   || 10
      delay   = params.dig(:delay) || 2

      job = {
          cmd:  command, # require
          node: node, # require
          timestamp: Time.now.strftime('%Y-%m-%d %H:%M:%S' ), # optional
          from: 'discovery', # optional
          payload: data # require
      }.to_json

      result = @mq_producer.addJob(queue, job, prio, ttr, delay )

      logger.debug( job )
      logger.debug( result )

    end

  end

end

