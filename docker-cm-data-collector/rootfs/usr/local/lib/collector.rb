#!/usr/bin/ruby
#
# 13.01.2017 - Bodo Schulz
#
#
# v1.8.0

# -----------------------------------------------------------------------------

require 'json'
require 'socket'
require 'timeout'
require 'fileutils'
require 'time'
require 'date'
require 'mini_cache'
require 'rufus-scheduler'

require_relative 'logging'
require_relative 'utils/network'
require_relative 'monkey'
require_relative 'jolokia'
require_relative 'job-queue'
require_relative 'message-queue'
require_relative 'storage'
require_relative 'external-clients'

require_relative 'collector/version'
require_relative 'collector/tools'
require_relative 'collector/config'
require_relative 'collector/prepare'

# -----------------------------------------------------------------------------

module DataCollector

  class Collector

    include Logging
    include DataCollector::Tools

    def initialize( settings = {} )

      jolokia_host        = settings.dig(:jolokia, :host)           || 'localhost'
      jolokia_port        = settings.dig(:jolokia, :port)           ||  8080
      jolokia_path        = settings.dig(:jolokia, :path)           || '/jolokia'
      jolokia_auth_user   = settings.dig(:jolokia, :auth, :user)
      jolokia_auth_pass   = settings.dig(:jolokia, :auth, :pass)
      mq_host             = settings.dig(:mq, :host)                || 'localhost'
      mq_port             = settings.dig(:mq, :port)                || 11300
      @mq_queue           = settings.dig(:mq, :queue)               || 'mq-collector'

      redis_host          = settings.dig(:redis, :host)
      redis_port          = settings.dig(:redis, :port)  || 6379

      application_config  = settings.dig(:configFiles, :application)
      service_config      = settings.dig(:configFiles, :service)

      mysql_host          = settings.dig(:mysql, :host)
      mysql_schema        = settings.dig(:mysql, :schema)
      mysql_user          = settings.dig(:mysql, :user)
      mysql_password      = settings.dig(:mysql, :password)

      version             = DataCollector::VERSION
      date                = DataCollector::DATE

      logger.info( '-----------------------------------------------------------------' )
      logger.info( ' CoreMedia - DataCollector' )
      logger.info( "  Version #{version} (#{date})" )
      logger.info( '  Copyright 2016-2018 CoreMedia' )
      logger.info( '  used Services:' )
      logger.info( "    - jolokia      : #{jolokia_host}:#{jolokia_port}" )
      logger.info( "    - redis        : #{redis_host}:#{redis_port}" )
      logger.info( "    - mysql        : #{mysql_host}@#{mysql_schema}" )
      logger.info( "    - message queue: #{mq_host}:#{mq_port}/#{@mq_queue}" )
      logger.info( '-----------------------------------------------------------------' )

      if( application_config.nil? || service_config.nil? )
        msg = 'no Configuration File given'
        logger.error( msg )
        fail msg
      end

      mq_settings = { beanstalkHost: mq_host, beanstalkPort: mq_port }
      prepareSettings = {
        configFiles: { application: application_config, service: service_config },
        redis: { host: redis_host, port: redis_port }
      }
      mysql_settings = { mysql: { host: mysql_host, user: mysql_user, password: mysql_password, schema: mysql_schema } }
      redis_settings = { redis: { host: redis_host } }
      jolokia_settings = { host: jolokia_host, port: jolokia_port, path: jolokia_path, auth: { user: jolokia_auth_user, pass: jolokia_auth_pass } }

      @cache     = MiniCache::Store.new()
      @redis     = Storage::RedisClient.new( redis_settings )
      @jolokia   = Jolokia::Client.new( jolokia_settings )
      @mq        = MessageQueue::Consumer.new( mq_settings )
      @cfg       = Config.new( application: application_config, service: service_config )
      @prepare   = Prepare.new( redis: @redis, config: @cfg )
      @jobs      = JobQueue::Job.new()
      @database  = Storage::MySQL.new( mysql_settings )

      # run internal scheduler to remove old data
      scheduler = Rufus::Scheduler.new

      scheduler.every( '10s', :first_in => 10 ) do
        clean()
      end

    end


    def mongodb_data( params )

      logger.debug( "mongodb_data( #{params} )" )

      host = params.dig(:host)
      port = params.dig(:port) || 27017

      return { status: 500, message: 'no host name for mongodb_data data' } if( host.nil? )

      begin
        m    = ExternalClients::MongoDb::Instance.new( host: host, port: port )
        return m.statistics_data()

      rescue => error
        logger.error("error: #{error} (file #{__FILE__} :: line #{__LINE__})")
        return JSON.parse( JSON.generate( status: 500, message: error.to_s ) )
      end
    end


    def mysql_data( params )

      logger.debug( "mysql_data( #{params} )" )

      host = params.dig(:host)
      port = params.dig(:port) || 3306
      user = params.dig(:username) || 'monitoring'
      pass = params.dig(:password) || 'monitoring'

      return { status: 500, message: 'no host name for mysql_data data' } if( host.nil? )

      cache_key   = format('mysql-%s', host)
      cached_data = @cache.get( cache_key )

      unless( cached_data.nil? )
        user = cached_data.dig(:user)
        pass = cached_data.dig(:pass)
        port = cached_data.dig(:port)
      end

      # TODO
      # we need an low-level-priv User for Monitoring!
      settings = { host: host, username: user, password: pass } unless( port.nil? )

      if( Utils::Network.port_open?( host, port ) == false )
        logger.warn( format( 'The Port \'%s\' on Host \'%s\' is not open, skip ...', port, host ) )
        return JSON.parse( JSON.generate( status: 500 ) )
      end

      #m = ExternalClients::MySQL.new( settings )
      m = ExternalClients::MySQL::Instance.new( settings )

      logger.debug(m.inspect)

      if( m.client.nil? )

        fallback = {
          coremedia: 'coremedia',
          cm_replication: 'cm_replication',
          cm_caefeeder: 'cm_caefeeder',
          cm_mcaefeeder: 'cm_mcaefeeder',
          cm_management: 'cm_management',
          cm_master: 'cm_master'
        }

        fallback.each do |u,p|

          settings = { host: host, username: u, password: p }

          m = ExternalClients::MySQL::Instance.new( settings )

          unless( m.client.nil? )
            user = u.clone
            pass = p.clone
            break
          end
        end

      end

      unless( m.client.nil? )
        @cache.set( cache_key , expires_in: 640 ) { MiniCache::Data.new( user: user, pass: pass, port: port ) }

        mysql_data = m.get()
        mysql_data = JSON.generate( status: 500 ) if( mysql_data == false || mysql_data.nil? )

        data       = JSON.parse( mysql_data )
      end

      data
    end


    def postgres_data( params )

      logger.debug( "postgres_data( #{params} )" )
      # WiP and nore sure
      return {}

      #logger.debug( "postgres_data( #{params} )" )
      #
      #host = params.dig(:host)
      #port = params.dig(:port) || 5432
      #user = params.dig(:username) || 'cm_management'
      #pass = params.dig(:password) || 'cm_management'
      #dbname = params.dig(:database) || 'coremedia'
      #
      #return { status: 500, message: 'no host name for mysql_data data' } if( host.nil? )
      #
      #unless( port.nil? )
      #
      #  settings = {
      #    'postgresHost'   => host,
      #    'postgresUser'   => user,
      #    'postgresPass'   => pass,
      #    'postgresPort'   => port,
      #    'postgresDBName' => dbname
      #  }
      #end
      #
      #result = Utils::Network.port_open?( host, port )
      #
      #if( result == false )
      #  logger.warn( format( 'The Port %s on Host %s is not open, skip sending data', port, host ) )
      #  return JSON.parse( JSON.generate( status: 500 ) )
      #else
      #  pgsql = ExternalClients::PostgresStatus.new( settings )
      #  data = pgsql.run()
      #end
    end


    def redis_data( params )

      logger.debug( "redis_data( #{params} )" )

      host = params.dig(:host)
      port = params.dig(:port) || 6379

      return { status: 500, message: 'no host name for redis_data data' } if( host.nil? )

      if( Utils::Network.port_open?( host, port ) == false )
        logger.warn( format( 'The Port %s on Host %s is not open, skip sending data', port, host ) )
        return JSON.parse( JSON.generate( status: 500 ) )
      end

      settings = { host: host, port: port } unless( port.nil? )
      logger.debug( 'read redis data ...' )
      @redis.monitoring
    end


    def node_exporter_data( params )

      logger.debug("node_exporter_data( #{params} )")

      host = params.dig(:host)
      port = params.dig(:port) || 9100

      return { status: 500, message: 'no host name for node_exporter data' } if( host.nil? )

      if( Utils::Network.port_open?( host, port ) == false )
        logger.warn( format( 'The Port %s for node_exporter on Host %s is not open, skip sending data', port, host ) )
        return JSON.parse( JSON.generate( status: 500 ) )
      end

      m = ExternalClients::NodeExporter::Instance.new( host: host, port: port )
      data = JSON.parse(JSON.generate( m.get() ))

      #logger.debug(data)
      #logger.debug(JSON.generate(data))
      #logger.debug(JSON.parse(JSON.generate(data)))

      data
      #result   = JSON.generate( m.get() )
      #JSON.parse( result )
    end


    def resourced_data( params )

      logger.debug("resourced_data( #{params} )")

      host = params.dig(:host)
      port = params.dig(:port) || 55555

      return { status: 500, message: 'no host name for resourced_data data' } if( host.nil? )

      if( Utils::Network.port_open?( host, port ) == false )
        logger.warn( format( 'The Port \'%s\' on Host \'%s\' is not open, skip ...', port, host ) )
        return JSON.parse( JSON.generate( status: 500 ) )
      end

      settings = { host: host, port: port } unless( port.nil? )

      m = ExternalClients::Resouced.new( settings )
      nodeData = m.get()

      result   = JSON.generate( nodeData )
      JSON.parse( result )
    end


    def apache_mod_status( params )

      logger.debug( "apache_mod_status( #{params} )" )

      host = params.dig(:host)
      port = params.dig(:port) || 8081

      return { status: 500, message: 'no host name for apache_mod_status data' } if( host.nil? )

      result = Utils::Network.port_open?( host, port )

      if( result == false )
        logger.warn( format( 'The Port \'%s\' on Host \'%s\' is not open, skip ...', port, host ) )

        JSON.parse( JSON.generate( status: 500 ) )
      else

        mod_status      = ExternalClients::ApacheModStatus.new( host: host, port: port )
        mod_status_data = mod_status.tick

        return { status: mod_status_data }
      end
    end


    # return all known and active (online) server for monitoring
    #
    def monitored_server()
      @database.nodes( status: [ Storage::MySQL::ONLINE ] )
    end

    # create a singulary json for every services to send them to the jolokia service
    #
    def create_bulkcheck( params )

      logger.debug( "create_bulkcheck( #{params} )" )

      ip   = params.dig(:ip)
      host = params.dig(:short)
      fqdn = params.dig(:fqdn)

      return { status: 404, message: 'no host name for bulk checks' } if( host.nil? )

      checks   = []
      array    = []
      services = nil

#       logger.debug( format( 'create bulk checks for \'%s\'', host ) )

      # to improve performance, read initial collector Data from Database and store them into Redis
      #
      key       = Storage::RedisClient.cacheKey( host: fqdn, pre: 'collector' )
      data      = @cache.get( key )

      if( data.nil? )
        data = @redis.measurements( short: host, fqdn: fqdn )

        if( data.nil? || data == false )
          @cache.unset( host )
          return
        else
          @cache.set( key ) { MiniCache::Data.new( data ) }
        end
      end

      return { status: 204, message: 'no services found. skip ...' } if( data.nil? )

      services      = data.keys
      servicesCount = services.count

      logger.info( format( '  with %d services', servicesCount ) )

      data.each do |s,d|

        port    = d.dig('port')    || -1
        metrics = d.dig('metrics') || []
        bulk    = []

        # only to see which service
        #
        logger.debug( format( '    %-25s with port %d', s, port ) )

        if( metrics != nil && metrics.count == 0 )
          case s
          when 'mysql'
            # MySQL
            bulk.push( '' )
          when 'mongodb'
            # MongoDB
            bulk.push( '' )
          when 'node-exporter'
            # Node Exporter (from Prometheus)
            bulk.push( '' )
          when 'postgres'
            # Postgres
            bulk.push( '' )
          when 'redis'
            # redis
            bulk.push('')
          when 'resourced'
            # resourced
          when 'http-status'
            bulk.push('')
          else
            # all others
          end
        else

          metrics.each do |e|

            mbean     = e.dig('mbean')
            attribute = e.dig('attribute')

            if( mbean.nil? )
              logger.error( '\'mbean\' are nil!' )
              next
            end

            target = {
              'type'   => 'read',
              'mbean'  => mbean.to_s,
              'config' => { 'ignoreErrors' => true, 'ifModifiedSince' => true, 'canonicalNaming' => true },
              'target' => { 'url' => format( 'service:jmx:rmi:///jndi/rmi://%s:%s/jmxrmi', fqdn, port ) }
            }

            attributes = []
            attributes = attribute.split(',') unless( attribute.nil? )

            # logger.debug("target: #{target}")

            bulk.push( target )
          end
        end

        checks.push( { s => bulk.flatten } ) if( bulk.count != 0 )
      end

      checks.flatten!

      logger.debug( "services: #{services} (#{services.class.to_s})" )

      #result = {
      #  timestamp: Time.now().to_i,
      #  ip: ip,
      #  hostname: host,
      #  fqdn: fqdn,
      #  services: services,
      #  checks: checks
      #}

      result = {}
      result[:timestamp] = Time.now().to_i
      result[:ip]       = ip
      result[:hostname] = host
      result[:fqdn]     = fqdn
      result[:services] = *services
      result[:checks]   = *checks

#      logger.debug( JSON.pretty_generate( result ) )
        # send json to jolokia
      begin
        collect_measurements( result )
      rescue => e
        logger.error(format('collect measurements failed, cause: %s', e ))
        logger.error( e.backtrace.join("\n") )
      end

      checks.clear()
      result.clear()

      return
    end


    # extract Host and Port of destination services from rmi uri
    #  - rmi uri are : "service:jmx:rmi:///jndi/rmi://moebius-16-tomcat:2222/jmxrmi"
    #    host: moebius-16-tomcat
    #    port: 2222
    def check_host_and_service( target_url )

      result = false

      regex = /
        ^                   # Starting at the front of the string
        (.*):\/\/           # all after the douple slashes
        (?<host>.+\S)       # our hostname
        :                   # seperator between host and port
        (?<port>\d+)        # our port
      /x

      # prepare
      parts     = target_url.match( regex )
      dest_host = parts['host'].to_s.strip
      dest_port = parts['port'].to_s.strip

#       logger.debug( format( 'check Port %s on Host %s for sending data', dest_port, dest_host ) )

      result = Utils::Network.port_open?( dest_host, dest_port )

      logger.warn( format( 'The Port %s on Host %s is not open, skip sending data', dest_port, dest_host ) ) if( result == false )

      return result

    end


    # collect measurements data
    #  - send json data to jolokia
    #  - or get data from external services
    # and save the result in an memory storage
    #
    def collect_measurements( params )

#       logger.debug( "collect_measurements( #{params} )" )
      # logger.error( 'jolokia service is not available!' )
      return { status: 500, message: 'jolokia service is not available!' } if( @jolokia.available? == false )

      ip        = params.dig(:ip)
      hostname  = params.dig(:hostname)
      fqdn      = params.dig(:fqdn)
      checks    = params.dig(:checks)

      result    = {
        hostname:  hostname,
        fqdn: fqdn,
        timestamp: Time.now().to_i
      }

#       logger.debug( result )
#       logger.debug( checks )
#       logger.debug( checks.count )
#
#       logger.debug('------------------------------------------')

      checks.each do |c|

        c.each do |v,i|

          logger.info( format( 'service \'%s\' with %s check%s', v, i.count, ( 's' if( i.count > 1 ) ) ) )

          result[v] ||= []

          cache_key = { host: fqdn, pre: 'result', service: v }
#           logger.debug( "plain cache_key: #{cache_key}" )

          cacheKey = Storage::RedisClient.cacheKey( cache_key )
#           logger.debug( "redis cache_key: #{cacheKey}" )

          #cacheKey = Storage::RedisClient.cacheKey( host: fqdn, pre: 'result', service: v )

          if( i.count > 1 )

            target_url = i.first.dig( 'target', 'url' )

            if( check_host_and_service( target_url ) == true )

              response       = @jolokia.post( payload: i, timeout: 15, sleep_retries: 3 )

              jolokia_status  = response.dig(:status)
              jolokia_message = response.dig(:message)

              if( jolokia_status != nil && jolokia_status.to_i == 200 )
                begin
                  data = reorganize_data( jolokia_message )

                  # get configured Content Server (RLS or MLS)
                  data = parse_content_server_url( fqdn: fqdn, service: v, data: data ) if( v =~ /^cae-(\blive|preview).*/ )

                  # get configured Master Live Server
                  data = parse_mls_ior( fqdn: fqdn, data: data ) if( v == 'replication-live-server' )

                  result[v] = data
                rescue => e
                  logger.error( "i can't store data into result for service #{v}" )
                  logger.error( e )
                  logger.debug( e.backtrace.join("\n") )
                end
              else
                logger.error( "jolokia status : #{jolokia_status}" )
                logger.error( "jolokia message: #{jolokia_message}" )
              end
            end

          else

            d = ''
            case v
            when 'mysql'
              # MySQL

              port     = config_data( host: hostname, service: v, value: 'port', default: 3306 )
              username = config_data( host: hostname, service: v, value: 'monitoring_user', default: 'monitoring' )
              password = config_data( host: hostname, service: v, value: 'monitoring_password', default: 'monitoring' )

              d = mysql_data( host: fqdn, port: port, username: username, password: password )
            when 'mongodb'
              # MongoDB
              port = config_data( host: hostname, service: v, value: 'port', default: 27017 )
              d = mongodb_data( host: fqdn, port: port )
            when 'postgres'
              # Postgres
              port = config_data( host: hostname, service: v, value: 'port', default: 5432 )
              username = config_data( host: hostname, service: v, value: 'monitoring_user', default: 'cm_management' )
              password = config_data( host: hostname, service: v, value: 'monitoring_password', default: 'cm_management' )
              database = config_data( host: hostname, service: v, value: 'monitoring_database', default: 'coremedia' )

              d = postgres_data( host: fqdn, port: port )
            when 'redis'
              # redis
              port = config_data( host: hostname, service: v, value: 'port', default: 6379 )
              d = redis_data( host: fqdn, port: port )
            when 'node-exporter'
              # node_exporter
              port = config_data( host: hostname, service: v, value: 'port', default: 9100 )
              d = node_exporter_data( host: fqdn, port: port )
            when 'resourced'
              #
              port = config_data( host: hostname, service: v, value: 'port', default: 55555 )
              d = resourced_data( host: fqdn, port: port )
            when 'http-status'
              # apache mod_status
              port = config_data( host: hostname, service: v, value: 'port', default: 8081 )
              d = apache_mod_status( host: fqdn, port: port )
            else
              # all others
            end

            begin
              result[v] = d
            rescue => e
              logger.error( "i can't create data for service #{v}" )
              logger.error( e )
              logger.error( e.backtrace.join("\n") )
            end

          end

          begin

            redis_result = @redis.set( cacheKey, result[v] )

            if( redis_result.is_a?( FalseClass ) || ( redis_result.is_a?( String ) && redis_result != 'OK' ) )
              logger.error( format( 'value for key %s can not be write', cacheKey ) )
              logger.error( host: fqdn, pre: 'result', service: v )
            end

          rescue => e

            logger.error( format( 'value for key \'%s\' can not be write', cacheKey ) )
            logger.error( host: fqdn, pre: 'result', service: v )
            # logger.error( result[v] )
            logger.error( e )
          end

        end
      end
    end


    # the RLS give us his MLS as URL: "MasterLiveServerIORUrl": "http://tomcat-centos7:40280/coremedia/ior"
    # we extract the value with the real hostname for later usage:
    # "MasterLiveServer": {
    #   "scheme": "http",
    #   "host": "tomcat-centos7",
    #   "port": 40280,
    #   "path": "/coremedia/ior"
    # }
    #
    def parse_mls_ior( params = {} )

      mlsIOR = nil

      fqdn    = params.dig(:fqdn)
      data    = params.dig(:data)
      mls_host = fqdn

      logger.info( '  search Master Live Server for this Replication Live Server' )

      d = data.select { |d| d.dig('Replicator') }

      return data unless( d.is_a?(Array) )

      value = d.first # hash
      replicator = value.dig('Replicator')

      status = replicator.dig('status')

      if( status.to_i != 200 )
        logger.error( format( '  [%s] - content server are not available!', status ) )
        return data
      end

      value = replicator.dig('value')

      return data unless( value.is_a?(Hash) )

      unless( value.nil? )

        value  = value.values.first

        return data unless( value.is_a?(Hash) )

        mlsIOR = value.dig( 'MasterLiveServerIORUrl' )

        return data if( mlsIOR.nil? )

        uri    = URI.parse( mlsIOR )
        scheme = uri.scheme
        host   = uri.host
        port   = uri.port
        path   = uri.path

        host = fqdn if(host == 'localhost')

        logger.debug( format('search dns entry for \'%s\'', host) )

        ip, short, fqdn = ns_lookup(host, 60)

        if( !ip.nil? && !short.nil? && !fqdn.nil? )

          logger.debug( "found: #{ip} , #{short} , #{fqdn}" )

          real_ip    = ip
          real_short = short
          mls_host   = fqdn
        else
          real_ip    = ''
          real_short = ''
          mls_host   = host
        end

        value['MasterLiveServer'] = {
          'scheme' => scheme,
          'host'   => mls_host,
          'port'   => port,
          'path'   => path
        }

        # logger.debug( JSON.pretty_generate(value.dig('MasterLiveServer')) )

      end

      logger.info( format( '  use \'%s\'', mls_host ) )

      data
    end


    # a CAE give us his Content Server as URL:
    #  - "Url": "http://tomcat-centos7:42080/coremedia/ior"
    #  - "Url": "http://tomcat-centos7:40180/coremedia/ior"

    def parse_content_server_url( params )

      content_server_ior = nil

      fqdn    = params.dig(:fqdn)
      service = params.dig(:service)
      data    = params.dig(:data)
      content_server = fqdn

      logger.info( format( '  search content server for this CAE (%s)', service ) )

      d = data.select {|d| d.dig('CapConnection') }

      return data unless( d.is_a?(Array) )

      value = d.first # hash
      cap_connection = value.dig('CapConnection')

#       logger.debug( value.class.to_s )
#       logger.debug(value)

      status = cap_connection.dig('status')
#       logger.debug(status)

      if( status.to_i != 200 )
        logger.error( format( '  [%s] - Contentserver are not available!', status ) )
        return data
      end

      value = cap_connection.dig('value')

      return data unless( value.is_a?(Hash) )

#       logger.debug( value ) #

      unless( value.nil? )

        value  = value.values.first

        return data unless( value.is_a?(Hash) )

        content_server_ior = value.dig( 'Url' )

        if( content_server_ior.nil? )
          logger.debug( 'no \'IOR URL\' found! :(' )
          logger.info( 'this CAE use an older version. we use the CAE Host as fallback' )

          return data
        else
          uri    = URI.parse( content_server_ior )
          scheme = uri.scheme
          host   = uri.host
          port   = uri.port
          path   = uri.path

          host = fqdn if(host == 'localhost')

          logger.debug( format('search dns entry for \'%s\'', host) )

          ip, short, fqdn = ns_lookup(host, 60)

          if( !ip.nil? && !short.nil? && !fqdn.nil? )

            logger.debug( "found: #{ip} , #{short} , #{fqdn}" )

            real_ip    = ip
            real_short = short
            content_server = fqdn

          else
            real_ip    = ''
            real_short = ''
            content_server = host
          end

          value['ContentServer'] = {
            'scheme' => scheme,
            'host'   => content_server,
            'port'   => port,
            'path'   => path
          }
          # logger.debug( JSON.pretty_generate(value.dig('ContentServer')) )
        end
      end

      logger.info( format( '  use \'%s\'', content_server ) )
      data
    end


    # reorganize data to later simple find
    #
    def reorganize_data( data )


      #  logger.error( "      no data for reorganize" )
      #  logger.error( "      skip" )
      return { status: 500, message: 'no data for reorganize' } if( data.nil? )

      result  = []

      # logger.debug("data: #{data} (#{data.class})")

      data.each do |c|

        request    = c.dig('request')

        if( request.nil? )
          logger.error( 'wrong data format ... skip reorganizing' )
          next
        end

        mbean      = request.dig('mbean')
        value      = c.dig('value')
        timestamp  = c.dig('timestamp')
        status     = c.dig('status')

#         logger.debug("request: #{request} (#{request.class})")
#         logger.debug("mbean  : #{mbean} (#{mbean.class})")
#         logger.debug("value  : #{value} (#{value.class})")

        # "service:jmx:rmi:///jndi/rmi://moebius-16-tomcat:2222/jmxrmi"
        regex = /
          ^                   # Starting at the front of the string
          (.*):\/\/           # all after the douple slashes
          (?<host>.+\S)       # our hostname
          :                   # seperator between host and port
          (?<port>\d+)        # our port
        /x

        uri   = request.dig('target', 'url')
        parts = uri.match( regex )
        host  = parts['host'].to_s.strip
        port  = parts['port'].to_s.strip

#         logger.debug(" port  : #{port} (#{port.class})")

        #if(port == '40099')
        #  logger.debug("request: #{request} (#{request.class})")
        #  logger.debug("mbean  : #{mbean} (#{mbean.class})")
        #  logger.debug("value  : #{value} (#{value.class})")
        #end

        if( mbean.include?( 'Cache.Classes' ) )

          regex = /
            CacheClass=
            "(?<type>.+[a-zA-Z])"
            /x
          parts           = mbean.match( regex )
          cache_class      = parts['type'].to_s

          format   = 'CacheClasses%s'
          format   = 'CacheClassesECommerce%s' if( cache_class.include?( 'ecommerce.' ) )

          cache_class     = cache_class.split('.').last
          cache_class[0]  = cache_class[0].to_s.capitalize
          mbean_type     = format( format, cache_class )


        elsif( mbean.include?( 'module=' ) )
          regex = /
            ^                     # Starting at the front of the string
            (.*)                  #
            module=               #
            (?<module>.+[a-zA-Z]) #
            (.*)                  #
            pool=                 #
            (?<pool>.+[a-zA-Z])   #
            (.*)                  #
            type=                 #
            (?<type>.+[a-zA-Z])   #
          /x

          parts           = mbean.match( regex )
          mbean_module    = parts['module'].to_s.strip.tr( '. ', '' )
          mbean_pool      = parts['pool'].to_s.strip.tr( '. ', '' )
          mbean_type      = parts['type'].to_s.strip.tr( '. ', '' )
          mbean_type      = format( '%s%s', mbean_type, mbean_pool )

        elsif( mbean.include?( 'bean=' ) )

          regex = /
            ^                     # Starting at the front of the string
            (.*)                  #
            bean=                 #
            (?<bean>.+[a-zA-Z])   #
            (.*)                  #
            type=                 #
            (?<type>.+[a-zA-Z])   #
            $
          /x

          parts           = mbean.match( regex )
          mbean_bean      = parts['bean'].to_s.strip.tr( '. ', '' )
          mbean_type      = parts['type'].to_s.strip.tr( '. ', '' )
          mbean_type      = format( '%s%s', mbean_type, mbean_bean )

        elsif( mbean.include?( 'solr') )
#           logger.debug("solr")

# solr/live:id=org.apache.solr.handler.ReplicationHandler,type=/replication (String)
# solr/live:id=org.apache.solr.search.LRUCache,type=queryResultCache (String)
# solr/live:id=org.apache.solr.search.LRUCache,type=documentCache (String)
# solr/live:id=org.apache.solr.handler.component.SearchHandler,type=/select (String)

# solr/preview:id=org.apache.solr.handler.ReplicationHandler,type=/replication (String)
# solr/preview:id=org.apache.solr.search.LRUCache,type=queryResultCache (String)
# solr/preview:id=org.apache.solr.search.LRUCache,type=documentCache (String)
# solr/preview:id=org.apache.solr.handler.component.SearchHandler,type=/select (String)

# solr/studio:id=org.apache.solr.handler.ReplicationHandler,type=/replication (String)
# solr/studio:id=org.apache.solr.search.LRUCache,type=queryResultCache (String)
# solr/studio:id=org.apache.solr.search.LRUCache,type=documentCache (String)
# solr/studio:id=org.apache.solr.handler.component.SearchHandler,type=/select (String)

## "solr/studio:id=org.apache.solr.search.LRUCache,type=queryResultCache" -> "core: studio | type: queryResultCache"


# solr:category=REPLICATION,dom1=core,dom2=live,name=*,scope=/replication (String)
# solr:category=QUERY,dom1=core,dom2=live,name=*,scope=/select (String)
# solr:category=CACHE,dom1=core,dom2=live,name=*,scope=searcher (String)
# solr:category=INDEX,dom1=core,dom2=live,name=* (String)

# solr:category=REPLICATION,dom1=core,dom2=preview,name=*,scope=/replication (String)
# solr:category=QUERY,dom1=core,dom2=preview,name=*,scope=/select (String)
# solr:category=CACHE,dom1=core,dom2=preview,name=*,scope=searcher (String)
# solr:category=INDEX,dom1=core,dom2=preview,name=* (String)

# solr:category=REPLICATION,dom1=core,dom2=studio,name=*,scope=/replication (String)
# solr:category=QUERY,dom1=core,dom2=studio,name=*,scope=/select (String)
# solr:category=CACHE,dom1=core,dom2=studio,name=*,scope=searcher (String)
# solr:category=INDEX,dom1=core,dom2=studio,name=* (String)

#

          if(mbean.include?('dom1=core'))
            logger.warn("unsupported solr mbeans (for solr 7) detected!")
            #  logger.debug("request: #{request} (#{request.class})")
#             logger.debug("mbean  : #{mbean} (#{mbean.class})")
#             logger.debug("value  : #{value} (#{value.class})")
          else

#             logger.debug("mbean  : #{mbean} (#{mbean.class})")
#             logger.debug("value  : #{value} (#{value.class})")

            regex = /
              ^                     # Starting at the front of the string
              solr\/                #
              (?<core>.+[a-zA-Z0-9]):  #
              (.*)                  #
              type=                 #
              (?<type>.+[a-zA-Z])   #
              $
            /x

            parts           = mbean.match( regex )
            if(parts.nil?)

            else
              mbean_core      = parts['core'].to_s.strip.tr( '. ', '' )
              mbean_core[0]   = mbean_core[0].to_s.capitalize
              mbean_type      = parts['type'].to_s.tr( '. /', '' )
              mbean_type[0]   = mbean_type[0].to_s.capitalize
              mbean_type      = format( 'Solr%s%s', mbean_core, mbean_type )
            end

          end

#           logger.debug("mbean_type  : #{mbean_type} (#{mbean_type.class})")

        elsif( mbean.include?( 'name=' ) )

          regex = /
            ^                     # Starting at the front of the string
            (.*)                  #
            name=                 #
            (?<name>.+[a-zA-Z])   #
            (.*)                  #
            type=                 #
            (?<type>.+[a-zA-Z])   #
            $
          /x

          parts           = mbean.match(regex)

          if(parts.nil?)

          else
            mbean_name      = parts['name'].to_s.strip.tr( '. ', '' )
            mbean_type      = parts['type'].to_s.strip.tr( '. ', '' )
            mbean_type      = format( '%s%s', mbean_type, mbean_name )
          end

        else
          regex = /
            ^                     # Starting at the front of the string
            (.*)                  #
            type=                 #
            (?<type>.+[a-zA-Z])   #
            $
          /x

          parts           = mbean.match( regex )
          mbean_type      = parts['type'].to_s.strip.tr( '. ', '' )
          mbean_type      = format( '%s', mbean_type )
        end

        result.push(

          mbean_type.to_s => {
            'status'    => status,
            'timestamp' => timestamp,
            'host'      => host,
            'port'      => port,
            'request'   => request,  # OBSOLETE, can be removed
            'value'     => value
          }
        )

      end

      return { status: 204, message: 'no data' } if( result.count == 0 )

      #logger.debug(result) # if(port == '40099')

      result
    end


    def clean()

      data = @mq.getJobFromTube( @mq_queue, true )

      if( data.count() != 0 )

        logger.debug( "clean: #{data}" )
        payload = data.dig( :body, 'payload' )
        hostname = payload.dig('host') unless( payload.nil? )

        unless( hostname.nil? )

          logger.debug('unset cached data')
          keys  = format( '%s-validate', hostname )

          [hostname, keys].each do |x|
            logger.debug( "  #{x}" )
            @cache.unset( x )
          end
        end
      end
    end


    def run()

      monitored_server = monitored_server()

      return { status: 204, message: 'no online server found' } if( monitored_server.nil? || monitored_server.is_a?( FalseClass ) || monitored_server.count == 0 )

      monitored_server.each do |h|

        # get dns data!
        #
        ip, short, fqdn = ns_lookup( h )

        discovery_data = nil

        next if( ip.nil? || short.nil? || fqdn.nil? )

        # add hostname to an blocking cache
        #
        if( @jobs.jobs( short: short, fqdn: fqdn ) == true )

          logger.warn( 'we are working on this job' )
          logger.debug( short: short, fqdn: fqdn )

          next
        end

#         logger.debug( 'block this job:' )
#         logger.debug( short: short, fqdn: fqdn )
        @jobs.add( short: short, fqdn: fqdn )

        start = Time.now

        logger.info( format( 'found host \'%s\' for monitoring', fqdn ) )

        # TODO
        # discussion
        # we need this in realtime, or can we cache this for ... 1 minute or more?
        #
        begin
          discovery_data    = @database.discoveryData( ip: ip, short: short, fqdn: fqdn )

          logger.debug("discovery_data: #{discovery_data} (#{discovery_data.class})")

          discovery_keys   = discovery_data.keys.sort
          discovery_count  = discovery_keys.count
          key = discovery_keys.clone
          key = discovery_keys.to_s if( discovery_keys.is_a?(Array) )

          discovery_checksum = Digest::MD5.hexdigest( key )
        rescue => e
          logger.error(e)
        end

        # build prepared datas
        #
        begin
          prepared_count, prepared_checksum, prepared_keys = @prepare.valid_data(fqdn).values

          logger.debug( format('current : %2d services / checksum: %s', discovery_count, discovery_checksum ) )
          logger.debug( format('cached  : %2d services / checksum: %s', prepared_count , prepared_checksum ) )

          options = { hostname: short, fqdn: fqdn, data: discovery_data }

          if( prepared_count != 0 && discovery_count > prepared_count )

            logger.info('new service detected ...')
            logger.debug( "current : #{discovery_keys}" )
            logger.debug( "cached  : #{prepared_keys}" )

            options[:force] = true
            key       = Storage::RedisClient.cacheKey( host: fqdn, pre: 'collector' )
            data      = @cache.unset( key )
          end

          result = @prepare.build_merged_data( options )
#           logger.debug( "merged_data: #{result}" )
        rescue => e
          logger.error(e)
        end

        # run checks
        #
        begin
          create_bulkcheck( ip: ip, short: short, fqdn: fqdn )
        rescue => e
          logger.error(e)
        end

        finish = Time.now
        logger.info( format( 'collect data in %s seconds', (finish - start).round(2) ) )

#         logger.debug( 'give job free:' )
#         logger.debug( short: short, fqdn: fqdn )
        @jobs.del( short: short, fqdn: fqdn )

      end

    end

  end

end

