#!/usr/bin/ruby
#
# 13.09.2016 - Bodo Schulz
#
#
# v1.6.0
# -----------------------------------------------------------------------------

require 'json'
require 'yaml'
require 'fileutils'
require 'mini_cache'
require 'storage'

require_relative 'logging'
require_relative 'utils/network'
require_relative 'jolokia'
require_relative 'port_discovery'
require_relative 'job-queue'
require_relative 'message-queue'
# require_relative 'storage'
require_relative 'discovery/version'
require_relative 'discovery/tools'
require_relative 'discovery/queue'
require_relative 'discovery/discovery'
require_relative 'discovery/refresh'

# -------------------------------------------------------------------------------------------------------------------

module ServiceDiscovery

  class Client

    include Logging
    include ServiceDiscovery::Tools
    include ServiceDiscovery::Queue
    include ServiceDiscovery::Discovery
    include ServiceDiscovery::Refresh

    def initialize( settings = {} )

      ports = [
        80,       # http
        443,      # https
        3306,     # mysql
        5432,     # postgres
        6379,     # redis
        8081,     # Apache mod_status
        9100,     # node_exporter (standard port)
        19100,    # node_exporter (CoreMedia internal)
        27017,    # mongodb
        38099,
        40099,
        40199,
        40299,
        40399,
        40499,
        40599,
        40699,
        40799,
        40899,
        40999,
        41099,
        41199,
        41299,
        41399,
        42099,
        42199,
        42299,
        42399,
        42499,
        42599,
        42699,
        42799,
        42899,
        42999,
        43099,
        44099,
        45099,
        46099,
        47099,
        48099,
        49099,
        55555     # resourced (https://github.com/resourced/resourced)
      ]

      jolokia_host         = settings.dig(:jolokia, :host)           || 'localhost'
      jolokia_port         = settings.dig(:jolokia, :port)           ||  8080
      jolokia_path         = settings.dig(:jolokia, :path)           || '/jolokia'
      jolokia_auth_user    = settings.dig(:jolokia, :auth, :user)
      jolokia_auth_pass    = settings.dig(:jolokia, :auth, :pass)

      @discovery_host      = settings.dig(:discovery, :host)
      @discovery_port      = settings.dig(:discovery, :port)        || 8088
      @discovery_path      = settings.dig(:discovery, :path)        # default: /scan

      mq_host              = settings.dig(:mq, :host)                || 'localhost'
      mq_port              = settings.dig(:mq, :port)                || 11300
      @mq_queue            = settings.dig(:mq, :queue)               || 'mq-discover'

      redis_host           = settings.dig(:redis, :host)
      redis_port           = settings.dig(:redis, :port)             || 6379

      mysql_host           = settings.dig(:mysql, :host)
      mysql_schema         = settings.dig(:mysql, :schema)
      mysql_user           = settings.dig(:mysql, :user)
      mysql_password       = settings.dig(:mysql, :password)

      @service_config      = settings.dig(:config_files, :service)

      refresh_enabled      = settings.dig(:refresh, :enabled) || false
      refresh_interval     = settings.dig(:refresh, :interval)

      mq_settings      = { beanstalkHost: mq_host, beanstalkPort: mq_port, beanstalkQueue: @mq_queue }
      jolokia_settings = { host: jolokia_host, port: jolokia_port, path: jolokia_path, auth: {user: jolokia_auth_user, pass: jolokia_auth_pass} }
      mysql_settings   = { mysql: { host: mysql_host, user: mysql_user, password: mysql_password, schema: mysql_schema } }

      @scan_ports         = ports

      version             = ServiceDiscovery::VERSION
      date                = ServiceDiscovery::DATE

      logger.info( '-----------------------------------------------------------------' )
      logger.info( ' CoreMedia - Service Discovery' )
      logger.info( "  Version #{version} (#{date})" )
      logger.info( '  Copyright 2016-2018 CoreMedia' )
      logger.info( '  used Services:' )
      logger.info( "    - jolokia      : #{jolokia_host}:#{jolokia_port}" )
      logger.info( "    - mysql        : #{mysql_host}@#{mysql_schema}" )
      logger.info( "    - message queue: #{mq_host}:#{mq_port}/#{@mq_queue}" )
      if(refresh_enabled == true)
        logger.info( "  scheduler for service freshness starts every: #{refresh_interval}" )
      end
      logger.info( '-----------------------------------------------------------------' )
      logger.info( '' )

      @cache       = MiniCache::Store.new
      @jobs        = JobQueue::Job.new
      @jolokia     = Jolokia::Client.new( jolokia_settings)
      @mq_consumer = MessageQueue::Consumer.new(mq_settings)
      @mq_producer = MessageQueue::Producer.new(mq_settings)

      @database    = Storage::MySQL.new(mysql_settings)

      self.read_configurations

      if( refresh_enabled == true )
        scheduler = Rufus::Scheduler.new
        scheduler.every( refresh_interval, :first_in => '15s', :overlap => false ) do
          refresh_host_data
        end
      end
    end

    # read Service Configuration
    #
    def read_configurations

      if( @service_config.nil? )
        puts 'missing service config file'
        logger.error( 'missing service config file' )

        raise( 'missing service config file' )
      end

      begin

        if( File.exist?(@service_config ) )
          @service_config      = YAML.load_file(@service_config )
        else
          logger.error( format('Config File %s not found!', @service_config ) )

          raise( format('Config File %s not found!', @service_config ) )
        end

      rescue Exception

        logger.error( 'wrong result (no yaml)')
        logger.error( "#{$!}" )

        raise( 'no valid yaml File' )
      end

    end


    # merge hashes of configured (cm-service.yaml) and discovered data (discovery.json)
    #
    def create_host_config( data )

      return nil unless( data.is_a?(Hash) )

      ip    = data.dig(:ip)
      short = data.dig(:short)
      fqdn  = data.dig(:fqdn)
      data  = data.dig(:data)

      return nil if( data.nil? )

      data.each do |d,v|

        # merge data between discovered Services and our base configuration,
        # the dicovered ports are IMPORTANT
        #
        service_data = @service_config.dig('services', d )

        if( service_data.nil? )
          logger.warn(format('missing entry \'%s\' in cm-service.yaml for merge with discovery data', d))
          logger.warn(format('  remove \'%s\' from data', d))
          data.reject! { |x| x == d }
        else

          data[d].merge!(service_data) {|key, port| port}

          port = data.dig(d, 'port')
          port_http = data.dig(d, 'port_http')

          # when we provide a vhost.json
          #
          unless (service_data.dig('vhosts').nil?)

            logger.debug('try to get vhost data')

            begin
              http_vhosts = ServiceDiscovery::HttpVhosts.new({host: fqdn, port: port})
              http_vhosts_data = http_vhosts.tick

              if (http_vhosts_data.is_a?(String))
                http_vhosts_data = JSON.parse(http_vhosts_data)

                http_vhosts_data = http_vhosts_data.dig('vhosts')

                data[d]['vhosts'] = http_vhosts_data
              end
            rescue => e
              logger.error(format('  can\'t get vhost data, error: %s', e))
            end
          end

          if( port != nil && port_http != nil )
            # ATTENTION
            # the RMI Port ends with 99
            # here we subtract 19 from this to get the HTTP Port
            #
            # thist part is hard-coded and VERY ugly!
            #
            data[d]['port_http'] = (port.to_i - 19)
          end

        end
      end
      # logger.debug( data )

      data
    end

    # delete the directory with all files inside
    #
    def delete_host( host, payload = {} )

      logger.info( format( 'delete Host \'%s\'',  host ) )

      # get a DNS record
      #
      ip, short, fqdn = ns_lookup( host )

      # DELETE ONLY WHEN THES STATUS ARE DELETED!
      #
      params = { ip: ip, short: short, fqdn: fqdn, status: Storage::MySQL::DELETE }
      nodes = @database.nodes( params )

      logger.debug( "nodes: #{nodes} (#{nodes.class.to_s})" )

      if( nodes.is_a?( Array ) && nodes.count != 0 )

#        payload = {
#          dns: {
#            ip: ip,
#            short: short,
#            fqdn: fqdn
#          },
#          force: true,
#          timestamp: Time.now.to_i,
#          annotation: true
#        }

        logger.debug( JSON.pretty_generate( payload ) )

        logger.info( 'create message for grafana to remove dashboards and annotations' )
        send_message( cmd: 'remove', node: host, queue: 'mq-grafana', payload: payload, prio: 1, ttr: 1, delay: 0 )

        logger.info( 'create message for icinga to remove host, apply checks and notifications' )
        send_message( cmd: 'remove', node: host, queue: 'mq-icinga', payload: payload, prio: 1, ttr: 1, delay: 0 )

        logger.debug( 'set node status to OFFLINE' )
        status = @database.set_status( ip: ip, short: short, fqdn: fqdn, status: Storage::MySQL::OFFLINE )
        logger.debug(status)

        logger.debug( 'remove configuration' )
        status  = @database.remove_config( ip: ip, short: short, fqdn: fqdn )
        logger.debug(status)

        logger.debug( 'remove dns' )
        result  = @database.remove_dns( ip: ip, short: short, fqdn: fqdn )

        logger.debug( result )
        return { status: 200, message: 'Host successful removed' } unless( result.nil? )
      end

      { status: 200, message: 'no hosts in database found' }
    end

    # add Host and discovery applications
    #
    def add_host( host, options = {} )

      logger.info( format( 'Adding host \'%s\'', host ) )

      if( @jolokia.available? == false )
        logger.error( 'jolokia service is not available!' )
        return { status: 500, message: 'jolokia service is not available!' }
      end

      start = Time.now

      # get a DNS record
      #
      ip, short, fqdn = ns_lookup( host )

      # if the destination host available (simple check with ping)
      #
      unless( Utils::Network.is_running?( ip ) )
        # delete dns entry
        #result  = @database.removeDNS( ip: ip, short: short, fqdn: fqdn )
        result  = @database.remove_dns( ip: ip, short: short, fqdn: fqdn )
        # 503 Service Unavailable
        return { status: 503,  message: format('Host %s are unavailable', host) }
      end

      # check discovered datas from the past
      #
      #discovery_data    = @database.discoveryData( ip: ip, short: short, fqdn: fqdn )
      discovery_data  = @database.discovery_data( ip: ip, short: short, fqdn: fqdn )

      unless( discovery_data.nil? )
        logger.warn( 'Host already created' )

        # look for online status ...
        #
        status = @database.status( ip: ip, short: short, fqdn: fqdn )

        if( status.nil? )
          logger.warn( 'host not found' )
          return { status: 404, message: 'Host not found' }
        end

        if( status == false )
          logger.warn( 'no valid database connection' )
          return { status: 404, message: 'no valid database connection' }
        end

        status = status.dig(:status)

        if( status != nil || status != Storage::MySQL::OFFLINE )

          logger.debug( 'set host status to ONLINE' )
          #status = @database.setStatus( ip: ip, short: short, fqdn: fqdn, status: Storage::MySQL::ONLINE )
          status = @database.set_status( ip: ip, short: short, fqdn: fqdn, status: Storage::MySQL::ONLINE )
        end

        # 409 Conflict
        return { status: 409,  message: 'Host already created' }
      end

      # -----------------------------------------------------------------------------------

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

      # use our new external function
      discovered_services = discover( ip: ip, short: short, fqdn: fqdn, ports: ports, known_services: @service_config )

#       logger.debug( "discovered_services #1 : #{discovered_services}" )

      discovered_services = merge_services( discovered_services, services )

#       logger.debug( "discovered_services #2 : #{discovered_services}" )

      discovered_services = create_host_config( ip: ip, short: short, fqdn: fqdn, data: discovered_services )

#       logger.debug( "discovered_services #3 : #{discovered_services}" )

      result    = @database.create_discovery( ip: ip, short: short, fqdn: fqdn, data: discovered_services )
#       logger.debug( "createDiscovery : #{result}" )

      logger.debug( 'set host status to ONLINE' )
      result    = @database.set_status( ip: ip, short: short, fqdn: fqdn, status: Storage::MySQL::ONLINE )

      finish = Time.now
      logger.info( format( 'overall runtime: %s seconds', (finish - start).round(2) ) )

      status = { status: 200, message: 'Host successful created', services: services }

      # inform other services ...
      logger.debug( "host: #{host}" )
      logger.debug( "options: #{options}" )

      logger.info( 'create message for grafana to create dashboards and annotations' )
      send_message( cmd: 'add', node: host, queue: 'mq-grafana', payload: options, prio: 10, ttr: 15, delay: 20 )

      logger.info( 'create message for icinga to insert host and apply checks and notifications' )
      send_message( cmd: 'add', node: host, queue: 'mq-icinga', payload: options, prio: 10, ttr: 15, delay: 20 )

      status
    end


    # TODO test!
    # ASAP
    def list_hosts( host = nil )

      logger.debug( "list_hosts( #{host} )" )

      hosts    = Array.new
      result   = Hash.new
      services = Hash.new

      # all nodes, no filter
      #
      # TODO
      # what is with offline or other hosts?
      return @database.nodes if( host.nil? )

      # get a DNS record
      #
      ip, short, fqdn = self.ns_lookup( host )

      discovery_data   = @database.discovery_data( ip: ip, short: short, fqdn: fqdn )

      return { status: 204, message: 'no node data found' } if( discovery_data.nil? )

      discovery_data.each do |s|
        data = s.last

        unless( data.nil? )
          data.reject! { |k| k == 'application' }
          data.reject! { |k| k == 'template' }
        end

        services[s.first.to_sym] ||= {}
        services[s.first.to_sym] = data
      end

      status = nil

      # get node data from redis cache
      #
      (1..15).each {|y|

        result = @database.status( ip: ip, short: short, fqdn: fqdn )

        if( result != nil )
          status = result
          break
        else
          logger.debug(format('Waiting for data ... %d', y))
          sleep(4)
        end
      }

      # parse the creation date
      #
      created_status = status.dig( :created )
      created      = 'unknown'
      created      = Time.parse( created_status ).strftime( '%Y-%m-%d %H:%M:%S' ) if( created_status.nil? )


      unless( status.ia_a?( String ) )

        # parse the online state
        #
        online         = status.dig( :status )

        # and transform the state to human readable
        #
        status = case online
        when Storage::MySQL::OFFLINE
          'offline'
        when Storage::MySQL::ONLINE
          'online'
        when Storage::MySQL::DELETE
          'delete'
        when Storage::MySQL::PREPARE
          'prepare'
        else
          'unknown'
        end

      end

      { status: 200, mode: status, services: services, created: created }
    end

  end
end
