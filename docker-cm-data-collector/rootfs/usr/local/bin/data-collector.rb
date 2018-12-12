#!/usr/bin/ruby
#
# 14.03.2017 - Bodo Schulz
#
#
# v1.3.0

# -----------------------------------------------------------------------------

require 'rufus-scheduler'

require_relative '../lib/collector'

# -----------------------------------------------------------------------------

applicationConfigFile = '/etc/cm-application.yaml'
serviceConfigFile     = '/etc/cm-service.yaml'


jolokiaHost       = ENV.fetch('JOLOKIA_HOST'           , 'jolokia' )
jolokiaPort       = ENV.fetch('JOLOKIA_PORT'           , 8080 )
jolokiaPath       = ENV.fetch('JOLOKIA_PATH'           , '/jolokia' )
jolokiaAuthUser   = ENV.fetch('JOLOKIA_AUTH_USER'      , nil )
jolokiaAuthPass   = ENV.fetch('JOLOKIA_AUTH_PASS'      , nil )
mqHost            = ENV.fetch('MQ_HOST'                , 'beanstalkd' )
mqPort            = ENV.fetch('MQ_PORT'                , 11300 )
mqQueue           = ENV.fetch('MQ_QUEUE'               , 'mq-collector' )
redisHost         = ENV.fetch('REDIS_HOST'             , 'redis' )
redisPort         = ENV.fetch('REDIS_PORT'             , 6379 )
mysqlHost         = ENV.fetch('MYSQL_HOST'             , 'database')
mysqlSchema       = ENV.fetch('DISCOVERY_DATABASE_NAME', 'discovery')
mysqlUser         = ENV.fetch('DISCOVERY_DATABASE_USER', 'discovery')
mysqlPassword     = ENV.fetch('DISCOVERY_DATABASE_PASS', 'discovery')
interval          = ENV.fetch('INTERVAL'               , 45 )

config = {
  :jolokia     => {
    :host => jolokiaHost,
    :port => jolokiaPort,
    :path => jolokiaPath,
    :auth => {
      :user => jolokiaAuthUser,
      :pass => jolokiaAuthPass
    }
  },
  :mq          => {
    :host  => mqHost,
    :port  => mqPort,
    :queue => mqQueue
  },
  :redis       => {
    :host => redisHost,
    :port => redisPort
  },
  :configFiles => {
    :application => applicationConfigFile,
    :service     => serviceConfigFile
  },
  :mysql    => {
    :host      => mysqlHost,
    :schema    => mysqlSchema,
    :user      => mysqlUser,
    :password  => mysqlPassword
  }
}

# -----------------------------------------------------------------------------

# NEVER FORK THE PROCESS!
# the used supervisord will control all
stop = false

Signal.trap('INT')  { stop = true }
Signal.trap('HUP')  { stop = true }
Signal.trap('TERM') { stop = true }
Signal.trap('QUIT') { stop = true }

# -----------------------------------------------------------------------------

r = DataCollector::Collector.new( config )

scheduler = Rufus::Scheduler.new

scheduler.every( interval.to_i, :first_in => 1 ) do

  r.run()

end


scheduler.every( '5s' ) do

  if( stop == true )

    p "shutdown scheduler ..."

    scheduler.shutdown(:kill)
  end

end

scheduler.join

# -----------------------------------------------------------------------------

# EOF
