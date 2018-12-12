#!/usr/bin/ruby
#
#
#
#

require 'grafana'
require 'grafana/tags'
require 'mini_cache'
require 'erb'

require_relative 'logging'
require_relative 'monkey'
require_relative 'job-queue'
require_relative 'message-queue'
require_relative 'storage'
require_relative 'mbean'

require_relative 'cm_grafana/version'
require_relative 'cm_grafana/configure_server'
require_relative 'cm_grafana/queue'
require_relative 'cm_grafana/coremedia/tools'
require_relative 'cm_grafana/coremedia/dashboard'
require_relative 'cm_grafana/coremedia/folder'
require_relative 'cm_grafana/coremedia/templates'
require_relative 'cm_grafana/coremedia/annotations'

class CMGrafana

  include Logging
  include Grafana
  include Grafana::Tags
  include CMGrafana::Version
  include CMGrafana::ServerConfiguration
  include CMGrafana::Queue
  include CMGrafana::CoreMedia::Tools
  include CMGrafana::CoreMedia::Dashboard
  include CMGrafana::CoreMedia::Folder
  include CMGrafana::CoreMedia::Templates
  include CMGrafana::CoreMedia::Annotations

  def initialize( settings )

    host                 = settings.dig(:grafana, :host)
    port                 = settings.dig(:grafana, :port)          || 80
    @user                = settings.dig(:grafana, :user)          || 'admin'
    @password            = settings.dig(:grafana, :password)
    url_path             = settings.dig(:grafana, :url_path)
    ssl                  = settings.dig(:grafana, :ssl)           || false
    @timeout             = settings.dig(:grafana, :timeout)       || 10
    @open_timeout        = settings.dig(:grafana, :open_timeout)  || 5
    @http_headers        = settings.dig(:grafana, :headers)       || {}
    @server_config_file  = settings.dig(:grafana, :server_config_file) || '/etc/grafana_config.yml'
    @template_directory  = settings.dig(:grafana, :template_directory) || '/usr/local/templates'

    mq_host              = settings.dig(:mq, :host)
    mq_port              = settings.dig(:mq, :port)
    @mq_queue            = settings.dig(:mq, :queue)              || 'mq-grafana'

    redis_host           = settings.dig(:redis, :host)
    redis_port           = settings.dig(:redis, :port)

    mysql_host           = settings.dig(:mysql, :host)
    mysql_schema         = settings.dig(:mysql, :schema)
    mysql_user           = settings.dig(:mysql, :user)
    mysql_password       = settings.dig(:mysql, :password)

    mq_settings    = { beanstalkHost: mq_host, beanstalkPort: mq_port, beanstalkQueue: @mq_queue }
    mysql_settings = { mysql: { host: mysql_host, user: mysql_user, password: mysql_password, schema: mysql_schema } }

    super( settings )

    @debug  = true
    @logger = logger

    version       = CMGrafana::Version::VERSION
    date          = CMGrafana::Date::DATE

    logger.info( '-----------------------------------------------------------------' )
    logger.info( " CoreMedia - Grafana Client - gem Version #{Grafana::VERSION}" )
    logger.info( "  Version #{version} (#{date})" )
    logger.info( '  Copyright 2016-2018 CoreMedia' )
    logger.info( '  used Services:' )
    logger.info( "    - grafana      : #{@url}" )
    logger.info( "    - redis        : #{redis_host}:#{redis_port}" )
    logger.info( "    - mysql        : #{mysql_host}@#{mysql_schema}" )
    logger.info( "    - message queue: #{mq_host}:#{mq_port}/#{@mq_queue}" )
    logger.info( '-----------------------------------------------------------------' )

#    grafana_login

    @redis        = Storage::RedisClient.new( redis: { host: redis_host } )
    @mbean        = MBean::Client.new( redis: @redis )
    @cache        = MiniCache::Store.new()
    @jobs         = JobQueue::Job.new()
    @mq_consumer  = MessageQueue::Consumer.new( mq_settings )
    @mq_producer  = MessageQueue::Producer.new( mq_settings )
    @database     = Storage::MySQL.new( mysql_settings )

  end

end

