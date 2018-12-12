
module ServiceDiscovery

  module Discovery

    # discover application
    #
    def discover_application( params = {} )

      logger.debug("discover_application( #{params} )")

      host = params.dig(:fqdn)
      port = params.dig(:port)

      fixed_ports = [80, 443, 8081, 3306, 5432, 6379, 9100, 19100, 27017, 55555]
      services   = Array.new

      if( fixed_ports.include?( port ) )

        case port
        when 80
          services.push('http-proxy')
        when 443
          services.push('https-proxy')
        when 8081
          services.push('http-status')
        when 3306
          services.push('mysql')
        when 5432
          services.push('postgres')
        when 6379
          services.push('redis')
        when 9100, 19100
          services.push('node-exporter')
        when 27017
          services.push('mongodb')
        when 55555
          services.push('resourced')
        else
          # type code here
        end
      else

        array = []

        # hash for the NEW Port-Schema
        # since cm160x every application runs in his own container with unique port schema
        #
        target_url = format('service:jmx:rmi:///jndi/rmi://%s:%s/jmxrmi', host, port )

        array << {
          type: 'read',
          mbean: 'java.lang:type=Runtime',
          attribute: ['ClassPath','InputArguments'],
          target: {url: target_url},
          config: {'ignoreErrors' => true, 'ifModifiedSince' => true, 'canonicalNaming' => true}
        } << {
          type: 'read',
          mbean: 'Catalina:type=Manager,context=*,host=*',
          target: {url: target_url},
          config: {'ignoreErrors' => true, 'ifModifiedSince' => true, 'canonicalNaming' => true}
        } << {
          type: 'read',
          mbean: 'Catalina:type=Engine',
          attribute: %w(baseDir jvmRoute),
          target: {url: target_url},
          config: {'ignoreErrors' => true, 'ifModifiedSince' => true, 'canonicalNaming' => true}
        } << {
          type: 'read',
          mbean: 'com.coremedia:type=serviceInfo,application=*',
          target: {url: target_url},
          config: {'ignoreErrors' => true, 'ifModifiedSince' => true, 'canonicalNaming' => true}
        }

        response        = @jolokia.post( payload: array )
        response_status = response.dig(:status).to_i
        response_body   = response.dig(:message)

        if( response_status != 200 )

#           logger.error( response )
#           logger.error( responseStatus )

          if( response_body.nil? )

            response_body = 'bad status'
          else

            response_body.delete!("\t" )
            response_body.delete!("\n" )

            if( response_body.include?('ConnectException') )

              parts = response_body.match( '^(.*)ConnectException :(?<error>.+[a-zA-Z0-9-]);(.*)' )
              hostname = host
              hostname = parts['error'].to_s.strip if( parts )

              response_body = format('jolokia error: \'%s\'. Possibly a DNS or configuration problem', hostname )
            end

            if( response_body.include?('UnknownHostException' ) )

              parts = response_body.match( '^(.*)Unknown host:(?<hostname>.+[a-zA-Z0-9-]);(.*)' )
              hostname = host
              hostname = parts['hostname'].to_s.strip if( parts )

              response_body = format('jolokia error: jolokia becomes \'%s\' as FQDN! Possibly a DNS or configuration problem', hostname )
            end
          end

          logger.error(
            status: response_status,
            message: response_body,
            target_url: target_url
          )

          return nil
        else
          body = response.dig(:message)

          unless( body.nil? )

            runtime     = body[0]  # #1  == Runtime
            manager     = body[1]  # #2  == Manager
            engine      = body[2]  # #3  == engine
            information = body[3]  # #4  == serviceInfo

            # since 1706 (maybe), we support an special bean to give us a unique and static application name
            # thanks to Frauke!
            #
            status = information.dig('status') || 500

            if( status == 200 )

#               logger.debug("information for #{port} : #{information}")

              value = information.dig('value')
              value = value.values.first
              value = value.dig('ServiceType')

              if( value != 'to be defined' )

                # special handling for more than one CAE
                if(value =~ /cae-(live|preview)/ )

                  known_services = @service_config.clone

                  #logger.debug("service_config: #{@service_config} (#{@service_config})")

                  if(known_services.nil?)
                    value = "#{value}_#{port}"
                  else
                    # TODO test for 'services'
                    name = known_services['services'].select { |x,y| y['port'] == port }

#                     logger.debug( "detected name: #{name}")
#                     logger.debug( "detected name: #{name.keys.last}")

                    value = name.keys.last.to_s
                  end
                end
#                 logger.debug( "Application are '#{value}'" )
                services.push( value )
                # clear other results
                #
                runtime = nil
                manager = nil
                engine  = nil
              end

            end

            unless( runtime.nil? )

              status = runtime.dig('status') || 500
              value  = runtime.dig('value')

              if( status == 200 )

                if( value != nil )

                  class_path      = value.dig('ClassPath')
                  input_arguments = value.dig('InputArguments')

                  logger.debug("class_path     : #{class_path}")
                  logger.debug("input_arguments: #{input_arguments}")

                  # CoreMedia 7.x == classPath 'cm7-tomcat-installation'
                  # Solr 6.5      == classPath 'solr-6'
                  # SpringBoot    == classPath '*.war'
                  # others        == CoreMedia > 9
                  #
                  # CoreMedia 7.x Installation
                  if( class_path.include?('cm7-tomcat-installation' ) )

                    logger.debug( 'found pre cm160x Portstyle (‎possibly cm7.x)' )
                    value = manager.dig('value')

                    regex = /context=(.*?),/

                    value.each do |context, _|

                      part = context.match( regex )

                      if( part != nil && part.length > 1 )

                        app_name = part[1].gsub!('/', '' )

                        if( app_name == 'manager' )
                          # skip 'manager'
                          next
                        end

                        logger.debug( format(' - recognized application: %s', app_name ) )
                        services.push(app_name )
                      end
                    end

                    # coremedia = cms, mls, rls?
                    # caefeeder = caefeeder-preview, cae-feeder-live?
                    #
                    if( ( services.include?( 'coremedia' ) ) || ( services.include?( 'caefeeder' ) ) )

                      value = engine.dig('value')

                      if( engine.dig('status').to_i == 200 )

                        base_dir = value.dig('baseDir')

                        regex = /
                          ^                           # Starting at the front of the string
                          (.*)                        #
                          \/cm7-                      #
                          (?<service>.+[a-zA-Z0-9-])  #
                          (.*)-tomcat                 #
                          $
                        /x

                        parts = base_dir.match(regex )

                        if( parts )
                          service = parts['service'].to_s.strip.tr('. ', '')
                          services.delete('coremedia')
                          services.delete('caefeeder')
                          services.push( service )

                          logger.debug( format( '  => %s', service ) )
                        else

                          logger.error( 'unknown error' )

                          logger.error( parts )
                        end
                      else
                        logger.error( format( 'response status %d', engine['status'].to_i ) )
                      end

                    # blueprint = cae-preview or delivery?editor
                    #
                    elsif( services.include?( 'blueprint' ) )

                      value = engine.dig('value')

                      if( engine.dig('status').to_i == 200 )

                        jvm_route = value.dig('jvmRoute')

                        if( ( jvm_route != nil ) && ( jvm_route.include?('studio' ) ) )
                          services.delete( 'blueprint' )
                          services.push( 'cae-preview' )
                        else
                          services.delete( 'blueprint' )
                          services.push( 'delivery' )
                        end
                      else
                        logger.error( format( 'response status %d', engine['status'].to_i ) )
                        logger.error( engine )
                      end
                    else

                      logger.warn( 'unknown service:' )
                      logger.warn( services )
                    end

                  # Solr - Standalone Support
                  #
                  elsif( class_path.include?('solr-6' ) || class_path.include?('solr/server') || input_arguments.any? { |s| s.include?('solr') } )

                    services.push( 'solr' )

                  # Solr - Standalone Support
                  #
                  elsif( class_path.include?('solr/server') )

                    services.push( 'solr' )

                  # solr 7.x
                  #
#                  elsif( class_path.include?('start.jar') )
#                    services.push( 'solr' )

                  # CoreMedia on Cloud / SpringBoot
                  #
                  elsif( class_path.include?('.war' ) )

                    regex = /
                      ^
                      \/(?<service>.+[a-zA-Z0-9-])\.war$
                    /x

                    parts = class_path.match(regex)

                    if( parts )
                      service = parts['service'].to_s.strip
                      services.push( service )
                    else
                      logger.error( 'parse error for ClassPath' )
                      logger.error( " => classPath: #{class_path}" )
                      logger.error( parts )
                    end

                  # cm160x - or all others
                  #
                  else

                    logger.debug('detect other services ...')

                    regex = /
                      ^                           # Starting at the front of the string
                      (.*)                        #
                      \/coremedia\/               #
                      (?<service>.+[a-zA-Z0-9-])  #
                      \/current                   #
                      (.*)                        #
                      $
                    /x

                    parts = class_path.match(regex)

                    logger.debug("parts: #{parts}")

                    if( parts )
                      service = parts['service'].to_s.strip.tr('. ', '')
                      services.push( service )
                    else
                      logger.error( 'parse error for ClassPath' )
                      logger.error( " => classPath: #{class_path}" )
                      logger.error( parts )
                    end
                  end

                end
              end

            end
          end

        end

        # normalize service names
        #
        services.map! {|service|

          case service
            when 'cms'
              'content-management-server'
            when 'mls'
              'master-live-server'
            when 'rls'
              'replication-live-server'
            when 'wfs'
              'workflow-server'
            when 'delivery'
              'cae-live'
            when 'solr'
              'solr-master'
            when 'contentfeeder'
              'content-feeder'
            when 'workflow'
              'workflow-server'
            else
              service
          end
        }

      end

      services
    end

    # get open ports and call 'discover_application'
    #
    def discover( params )

      ip    = params.dig(:ip)
      short = params.dig(:short)
      fqdn  = params.dig(:fqdn)
      ports = params.dig(:ports)

      discovered_services = Hash.new

      # TODO
      # check if @discoveryHost and @discoveryPort setStatus
      # then use the new
      # otherwise use the old code
      start = Time.now

      if( @discovery_host.nil? )

        open = false

        # check open ports and ask for application behind open ports
        #
        ports.each do |p|

          open = Utils::Network.port_open?( fqdn, p )

          logger.debug( sprintf( 'Host: %s | Port: %s   %s', fqdn, p, open ? 'open' : 'closed' ) )

          if( open == true )

            names = discover_application( fqdn: fqdn, port: p )

            # logger.debug( "discovered services: #{names}" )

            unless( names.nil? )

              names.each do |name|
                discovered_services.merge!( { name => { 'port' => p } } )
              end
            end
          end
        end

      else
        # our new port discover service
        #
        open_ports = []

        pd = PortDiscovery::Client.new( host: @discovery_host, port: @discovery_port )

        if( pd.isAvailable?() )

          logger.debug("check ports: #{ports}")

          open_ports = pd.post( host: fqdn, ports: ports )

          if( open_ports.nil? )
            logger.error( format( 'can\'t detect open ports for %s', fqdn ) )
          else

            logger.info("open ports found: #{open_ports}")

            open_ports.each do |p|

              names = discover_application( fqdn: fqdn, port: p )

              logger.debug("discovered services: #{names}")

              unless( names.nil? )
                names.each do |name|
                  discovered_services.merge!( { name => { 'port' => p } } )
                end
              end
            end
          end

        end
      end

      finish = Time.now
      logger.info( sprintf( 'runtime for application discovery: %s seconds', (finish - start).round(2) ) )

      # ---------------------------------------------------------------------------------------------------

      discovered_services

    end

    # merge discovered services with additional services
    #
    def merge_services( discovered_services, additional_services )

      if( additional_services.is_a?( Array ) && additional_services.count >= 1 )

        additional_services.each do |s|
          service_data = @service_config.dig( 'services', s )
          unless( service_data.nil? )
            discovered_services[s] ||= service_data.filter('port')
            next
          end
        end

        found_services = discovered_services.keys

        logger.info( format( '%d usable services: %s', found_services.count, found_services.to_s ) )
      end

      discovered_services
    end

  end


  class HttpVhosts

    include Logging

    def initialize( params = {} )

      @host  = params.dig(:host)
      @port  = params.dig(:port) || 8081
    end


    def fetch( uri_str, limit = 10 )

      # You should choose better exception.
      raise ArgumentError, 'HTTP redirect too deep' if limit == 0

      url = URI.parse(uri_str)
      req = Net::HTTP::Get.new( url.path, { 'User-Agent' => 'CoreMedia Monitoring/1.0' } )
      response = Net::HTTP.start( url.host, url.port, { read_timeout: 5, open_timeout: 5 } ) { |http| http.request(req) }

      case response
        when Net::HTTPSuccess         then response
        when Net::OpenTimeout         then response
        when Net::HTTPRedirection     then fetch(response['location'], limit - 1)
        when Net::HTTPNotFound        then response
      else
        response.error!
      end

    end


    def tick

      response = fetch( format('http://%s:%d/vhosts.json', @host, @port) )

      if( response.code.to_i == 200 )
        response.body
      else
        {}
      end

    end
  end

end
