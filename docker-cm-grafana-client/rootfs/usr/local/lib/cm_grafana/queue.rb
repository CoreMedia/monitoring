
class CMGrafana < Grafana::Client

  module Queue

    # Message-Queue Integration
    #
    #
    #
    def queue

      if(!@logged_in)
        logger.debug( 'client are not logged in, skip' )
        return
      end

      data    = @mq_consumer.getJobFromTube( @mq_queue )

      if( data.count != 0 )

        stats = @mq_consumer.tubeStatistics( @mq_queue )
        logger.debug( {
          :total   => stats.dig(:total),
          :ready   => stats.dig(:ready),
          :delayed => stats.dig(:delayed),
          :buried  => stats.dig(:buried)
        } )

        if( stats.dig(:ready).to_i > 10 )
          logger.warn( 'more then 10 jobs in queue ... just wait' )

          @mq_consumer.cleanQueue( @mq_queue )
          return
        end

        job_id  = data.dig( :id )

        result = self.process_queue(data)

        logger.debug(result)

        status = result.dig(:status).to_i

        if( status == 200 || status == 409 || status == 500 || status == 503 )

          @mq_consumer.deleteJob( @mq_queue, job_id )
        else

          @mq_consumer.buryJob( @mq_queue, job_id )
        end
      end

    end


    def process_queue(data = {} )

      logger.debug( format( 'process Message ID %d from Queue \'%s\'', data.dig(:id), data.dig(:tube) ) )

      command  = data.dig( :body, 'cmd' )
      node     = data.dig( :body, 'node' )
      payload  = data.dig( :body, 'payload' )
      tags     = []
      overview = true
      dns      = nil

      if( command.nil? || node.nil? || payload.nil? )
        return { :status  => 500, :message => 'missing command' } if( command.nil? )
        return { :status  => 500, :message => 'missing node' } if( node.nil? )
        return { :status  => 500, :message => 'missing payload' } if( payload.nil? )
      end

      payload  = JSON.parse( payload ) if( payload.is_a?( String ) && payload.to_s != '' )
      hash     = Digest::MD5.hexdigest(payload.to_s)

      logger.debug( JSON.pretty_generate( payload ))
      logger.debug( "hash: #{hash}")

      tags       = payload.dig('tags')
      overview   = payload.dig('overview') || true
      dns        = payload.dig('dns')
      annotation = payload.dig('annotation') || true
      timestamp  = payload.dig('timestamp') || Time.now.to_i
      type       = payload.dig('type')
      argument   = payload.dig('argument')
      message    = payload.dig('message')
      tags       = payload.dig('tags')
      data       = payload.dig('data')

      logger.info( format( '%s%s host \'%s\'', command, command == 'annotation' ? ' for' : '', node ) )

      if( dns.is_a?(Hash) )
        ip    = dns.dig('ip')
        short = dns.dig('short')
        fqdn  = dns.dig('fqdn')
      end

      ip, short, fqdn = ns_lookup(node) if( ip.nil? && short.nil? && fqdn.nil? )

      # no DNS data?
      #
      if( ip.nil? && short.nil? && fqdn.nil? )

        logger.warn( 'we found no dns data!' )

        # ask grafana
        #
        result = self.list_dashboards( host: node )
        logger.debug( result )
        return { status: 500, message: 'no dns data found' }
      end

      job_option = { command: command, hash: hash }

      return { status: 409, message: 'we are working on this job' } if( @jobs.jobs( job_option ) == true )

      @jobs.add( job_option )

      @cache.set(format( 'dns::%s', node ) , expires_in: 320 ) { MiniCache::Data.new( ip: ip, short: short, fqdn: fqdn ) }

      identifier  = @database.config( ip: ip, short: short, fqdn: fqdn, key: 'graphite_identifier' )

      if( identifier != nil && identifier.dig( 'graphite_identifier' ) != nil )
        identifier = identifier.dig( 'graphite_identifier' ).to_s
        logger.info( "use custom storage identifier from config: '#{identifier}'" )
      else
        identifier = short
      end

      # use grafana annotations
      #
      if( command == 'annotation' )

        time   = Time.at( timestamp ).strftime( '%Y-%m-%d %H:%M:%S' )
        status  = 500
        message = 'internal server error'

        unless(data.nil?)

          data  = JSON.parse(data) if(data.is_a?( String ))
          logger.debug( JSON.pretty_generate(data) )

          annotation_message  = data.dig('message')
          annotation_tags     = data.dig('tags') || []
          annotation_type     = data.dig('command')   # old style
          annotation_argument = data.dig('argument')  # old style

          c = data.reject { |k,v| k == 'message' || k == 'tags' }

          # old style annotation
          if(c.count != 0 && !c.include?('command'))
            annotation_type     = c.keys.first
            annotation_argument = c.values.first
          end

          # free style annotation
          #
          if(annotation_type.nil? && annotation_argument.nil? && c.count == 0)
            annotation_type = 'free'
            annotation_tags = ['free']
          end

          if( %w[create destroy].include?(annotation_type) )
            annotation_argument = annotation_type
            annotation_type = 'host'
          end

          if( %w[add remove].include?(annotation_type) )
            annotation_argument = annotation_type
            annotation_type     = 'monitoring'
          end

          logger.debug("type    : #{annotation_type}")
          logger.debug("argument: #{annotation_argument}")
          logger.debug("message : #{annotation_message}")
          logger.debug("tags    : #{annotation_tags}")

#           logger.debug( JSON.pretty_generate(c) )

          annotation_what = nil
          annotation_data = nil

          if( annotation_type == 'loadtest' )
            logger.debug( 'loadtest annotation' )

            if( %w[start stop end].include?(annotation_argument) )
              annotation_what = format( 'loadtest %s', annotation_argument )
              annotation_tags += [ identifier, 'loadtest', annotation_argument ]
              annotation_data = sprintf( 'Loadtest for Host <b>%s</b> %sed', node, annotation_argument)
            end

          elsif( annotation_type == 'contentimport' )
            logger.debug( 'contentimport annotation' )

            if( %w[start stop end].include?(annotation_argument) )
              annotation_what = format( 'contentimport %s', annotation_argument )
              annotation_tags += [ identifier, 'contentimport', annotation_argument ]
              annotation_data = sprintf( 'Contentimport for Host <b>%s</b> %sed', node, annotation_argument)
            end

          elsif( annotation_type == 'deployment' )
            logger.debug( 'deployment annotation' )

            if( %w[start stop end].include?(annotation_argument) )
              annotation_what = format( 'deployment %s', annotation_argument )
              annotation_data = sprintf( 'Deployment on Host <b>%s</b> %sed', node, annotation_argument)
            else
              annotation_what = format( 'deployment %s', annotation_message )
              annotation_data = sprintf( 'Deployment on Host <b>%s</b> started', node)
            end

            annotation_tags += [ identifier, 'deployment' ]
            annotation_tags += [annotation_argument] if(annotation_argument.is_a?(String) && !annotation_argument.size.zero?)

          elsif( annotation_type == 'host' )
            logger.debug( 'host annotation' )

            if( %w[create destroy].include?(annotation_argument) )

              txt = 'created'   if(annotation_argument == 'create')
              txt = 'destroyed' if(annotation_argument == 'destroy')

              annotation_what = format( 'host %s', txt )
              annotation_tags = [ identifier, 'host', annotation_argument ]
              annotation_data = sprintf( 'Host <b>%s</b> %s', node, txt)
            end

          elsif( annotation_type == 'monitoring' )
            logger.debug( 'monitoring annotation' )

            if( %w[add remove].include?(annotation_argument) )

              txt = 'added to'     if(annotation_argument == 'add')
              txt = 'removed from' if(annotation_argument == 'remove')

              annotation_what = format( 'host %s monitoring', txt )
              annotation_tags = [ identifier, 'monitoring', annotation_argument ]
              annotation_data = sprintf( 'Host <b>%s</b> %s monitoring', node, txt)
            end
          else
            logger.debug( 'other annotation' )

            annotation_what = annotation_message
            annotation_tags = [ identifier, 'free' ]
            annotation_tags += [ annotation_argument ] if(annotation_argument.is_a?(String) && !annotation_argument.size.zero?)
            annotation_data = sprintf( 'Host <b>%s</b>', node)
          end

          unless( annotation_what.nil? && annotation_tags.nil? && annotation_data.nil? )

            params = {
              what: annotation_what,
              when: timestamp,
              tags: annotation_tags,
              data: annotation_data
            }

            logger.debug( JSON.pretty_generate(params) )


            begin
              result = create_annotation_graphite( params )
              logger.debug(result)
              status  = result.dig('status')
              message = result.dig('message')
            rescue => error
              logger.error(error)
            end
          end

          @jobs.del( job_option )

          return { status: status, message: message }
        end
      end


      # add Host
      #
      if( command == 'add' )

        # add annotation
        if(annotation == true)

          annotation_argument = 'create'
          txt                 = 'created'
          annotation_what = format( 'host %s', txt )
          annotation_tags = [ identifier, 'host', annotation_argument ]
          annotation_data = sprintf( 'Host <b>%s</b> %s', node, txt)

          params = {
            what: annotation_what,
            when: timestamp,
            tags: annotation_tags,
            data: annotation_data
          }

          begin
            result = create_annotation_graphite( params )
            logger.debug(params)
            logger.debug(result)
          rescue => error
            logger.error(error)
          end
        end

        ##
        # get all group_by entrys for us
        #
        group_by = @database.config( ip: ip, short: short, fqdn: fqdn, key: 'group_by' )

        # disable the general overview site, when a 'group_by' is ordered
        #
        overview = true
        overview = false if(group_by.is_a?(Hash))

        # TODO
        # check payload!
        # e.g. for 'force' ...
        result = self.create_dashboard_for_host( host: node, tags: tags, overview: overview )

        logger.debug(result)

        if(group_by.is_a?(Hash))

          group_by = group_by.dig('group_by')

          begin
            group_by.sort!
            group_by_hosts = @database.config( key: 'group_by', value: group_by )

            create_overview_dashboard_for_hosts( group_by_hosts.keys, group_by )
          rescue => error
            logger.error(error)
          end
        end

        @jobs.del( job_option )

        return { status: 200, message: result }
      end

      # remove Host
      #
      if( command == 'remove' )

        # add annotation
        if( annotation == true )

          annotation_argument = 'destroy'
          txt                 = 'destroyed'

          annotation_what = format( 'host %s', txt )
          annotation_tags = [ identifier, 'host', annotation_argument ]
          annotation_data = sprintf( 'Host <b>%s</b> %s', node, txt)

          params = {
            what: annotation_what,
            when: timestamp,
            tags: annotation_tags,
            data: annotation_data
          }

          begin
            result = create_annotation_graphite( params )
            logger.debug(params)
            logger.debug( result )
          rescue => error
            logger.error( error)
          end
        end

        result = self.delete_dashboards( ip: ip, host: node, fqdn: fqdn )
        logger.debug( result )

        @jobs.del( job_option )

        return { status: 200, message: result }
      end

      # information about Host
      #
      if( command == 'info' )

#         logger.info( format( 'give dashboards for %s back', node ) )
        result = self.list_dashboards( host: node )

        self.send_message( cmd: 'info', host: node, queue: 'mq-grafana-info', payload: result, ttr: 1, delay: 0 )

        @jobs.del( job_option )

        return { status: 200, message: result }
      end

      #
      #
      if( command == 'update' )

        result = update_dashboards( host: node )

        logger.debug( result )

        @jobs.del( job_option )

        return { status: 200, message: result }
      end


      # all others
      #
      logger.error( format( 'wrong command detected: %s', command ) )

      @jobs.del( job_option )

      { status: 500, message: format( 'wrong command detected: %s', command ) }
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
          cmd:  command, # require
          node: node, # require
          timestamp: Time.now.strftime('%Y-%m-%d %H:%M:%S' ), # optional
          from: 'grafana', # optional
          payload: data # require
      }.to_json

      result = @mq_Producer.addJob( queue, job, prio, ttr, delay )

      logger.debug( job )
      logger.debug( result )

    end

  end

end
