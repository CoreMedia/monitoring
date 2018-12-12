#!/usr/bin/ruby
#
#
#
#

require 'icinga2'
require 'mini_cache'

require_relative 'logging'
require_relative 'utils/network'
require_relative 'job-queue'
require_relative 'message-queue'
require_relative 'storage'

require_relative 'icinga/version'
require_relative 'icinga/tools'
require_relative 'icinga/queue'
require_relative 'icinga/configure_server'

# -------------------------------------------------------------------------------------------------------------------

class CMIcinga2

  include Icinga2

  include CMIcinga2::Version
  include CMIcinga2::Tools
  include CMIcinga2::Queue
  include CMIcinga2::ServerConfiguration

  def initialize( settings = {} )

    @icinga_host           = settings.dig(:icinga, :host)            || 'localhost'
    @icinga_api_port       = settings.dig(:icinga, :api, :port)      || 5665
    @icinga_api_user       = settings.dig(:icinga, :api, :user)
    @icinga_api_pass       = settings.dig(:icinga, :api, :password)
#    @icinga_cluster        = settings.dig(:icinga, :cluster)         || false
    @icinga_satellite      = settings.dig(:icinga, :satellite)
    @icinga_notifications  = settings.dig(:icinga, :notifications)   || false

    server_config_file     = settings.dig(:icinga, :server_config_file)

    mq_host                = settings.dig(:mq, :host)
    mq_port                = settings.dig(:mq, :port)                || 11300
    @mq_queue              = settings.dig(:mq, :queue)               || 'mq-icinga'

    redis_host             = settings.dig(:redis, :host)
    redis_port             = settings.dig(:redis, :port)  || 6379

    mysql_host             = settings.dig(:mysql, :host)
    mysql_schema           = settings.dig(:mysql, :schema)
    mysql_user             = settings.dig(:mysql, :user)
    mysql_password         = settings.dig(:mysql, :password)

    @icinga_api_url_base   = format('https://%s:%d', @icinga_host, @icinga_api_port )
    @node_name             = Socket.gethostbyname(Socket.gethostname ).first

    super( settings )

    version              = CMIcinga2::Version::VERSION
    date                 = CMIcinga2::Date::DATE

    logger.info( '-----------------------------------------------------------------' )
    logger.info( " CoreMedia - Icinga2 Client - gem Version #{Icinga2::VERSION}" )
    logger.info( "  Version #{version} (#{date})" )
    logger.info( '  Copyright 2017-2018 CoreMedia' )
    logger.info( "  Backendsystem #{@icinga_api_url_base}" )
#    logger.info( format( '    cluster enabled: %s', @icinga_cluster ? 'true' : 'false' ) )
    unless( @icinga_satellite.nil? )
      logger.info( format('    satellite endpoint: %s', @icinga_satellite ) )
    end
    logger.info( format('    notifications enabled: %s', @icinga_notifications ? 'true' : 'false' ) )
    logger.info( '  used Services:' )
    logger.info( "    - redis        : #{redis_host}:#{redis_port}" )
    logger.info( "    - mysql        : #{mysql_host}@#{mysql_schema}" )
    logger.info( "    - message Queue: #{mq_host}:#{mq_port}/#{@mq_queue}" )
    logger.info( '-----------------------------------------------------------------' )
    logger.info( '' )

    logger.debug( format(' server   : %s', @icinga_host ) )
    logger.debug( format(' port     : %s', @icinga_api_port ) )
    logger.debug( format(' api url  : %s', @icinga_api_url_base ) )
    logger.debug( format(' api user : %s', @icinga_api_user ) )
    logger.debug( format(' api pass : %s', @icinga_api_pass ) )
    logger.debug( format(' node name: %s', @node_name ) )

    mq_settings    = { beanstalkHost: mq_host, beanstalkPort: mq_port, beanstalkQueue: @mq_queue }
    mysql_settings = { mysql: { host: mysql_host, user: mysql_user, password: mysql_password, schema: mysql_schema } }
    redis_settings = { redis: { host: redis_host } }

    @cache       = MiniCache::Store.new
    @jobs        = JobQueue::Job.new
    @redis       = Storage::RedisClient.new( redis_settings ) unless(redis_host.nil?)
    @mq_consumer = MessageQueue::Consumer.new( mq_settings ) unless(mq_host.nil?)
    @mq_producer = MessageQueue::Producer.new( mq_settings ) unless(mq_host.nil?)
    @database    = Storage::MySQL.new( mysql_settings ) unless(mysql_host.nil?)

  end
end

# EOF
