#!/usr/bin/ruby
#
# 03.01.2017 - Bodo Schulz
#
#
# v0.7.0

# -----------------------------------------------------------------------------

require 'rufus-scheduler'

require_relative '../lib/discovery'

# -----------------------------------------------------------------------------

service_config_file  = '/etc/cm-service.yaml'

jolokia_host          = ENV.fetch('JOLOKIA_HOST'           , 'jolokia' )
jolokia_port          = ENV.fetch('JOLOKIA_PORT'           , 8080 )
jolokia_path          = ENV.fetch('JOLOKIA_PATH'           , '/jolokia' )
jolokia_auth_user     = ENV.fetch('JOLOKIA_AUTH_USER'      , nil )
jolokia_auth_password = ENV.fetch('JOLOKIA_AUTH_PASS'      , nil )
discovery_host        = ENV.fetch('DISCOVERY_HOST'         , 'jolokia' )
mq_host               = ENV.fetch('MQ_HOST'                , 'beanstalkd' )
mq_port               = ENV.fetch('MQ_PORT'                , 11300 )
mq_queue              = ENV.fetch('MQ_QUEUE'               , 'mq-discover' )
redis_host            = ENV.fetch('REDIS_HOST'             , 'redis' )
redis_port            = ENV.fetch('REDIS_PORT'             , 6379 )
mysql_host            = ENV.fetch('MYSQL_HOST'             , 'database')
mysql_schema          = ENV.fetch('DISCOVERY_DATABASE_NAME', 'discovery')
mysql_user            = ENV.fetch('DISCOVERY_DATABASE_USER', 'discovery')
mysql_password        = ENV.fetch('DISCOVERY_DATABASE_PASS', 'discovery')
refresh_enabled       = ENV.fetch('REFRESH_ENABLED'        , true)
refresh_interval      = ENV.fetch('REFRESH_INTERVAL'       , '5m')
interval              = ENV.fetch('INTERVAL'               , '20s' )
delay                 = ENV.fetch('RUN_DELAY'              , '10s' )

# -----------------------------------------------------------------------------
# validate durations for the Scheduler

def validate_scheduler_values( duration, default )
  raise ArgumentError.new(format('wrong type. \'duration\' must be an String, given %s', duration.class.to_s )) unless( duration.is_a?(String) )
  raise ArgumentError.new(format('wrong type. \'default\' must be an Float, given %s', default.class.to_s )) unless( default.is_a?(Float) )
  i = Rufus::Scheduler.parse( duration.to_s )
  i = default.to_f if( i < default.to_f )
  Rufus::Scheduler.to_duration( i )
end

interval         = validate_scheduler_values( interval, 20.0 )
delay            = validate_scheduler_values( delay, 0.0 )
refresh_interval = validate_scheduler_values( refresh_interval, 300.0 ) # 5m == 300

# -----------------------------------------------------------------------------

refresh_enabled    = refresh_enabled.to_s.eql?('true') ? true : false

config = {
  :jolokia     => {
    :host => jolokia_host,
    :port => jolokia_port,
    :path => jolokia_path,
    :auth => {
      :user => jolokia_auth_user,
      :pass => jolokia_auth_password
    }
  },
  :discovery   => {
    :host => discovery_host
  },
  :mq          => {
    :host  => mq_host,
    :port  => mq_port,
    :queue => mq_queue
  },
  :redis       => {
    :host => redis_host,
    :port => redis_port
  },
  :config_files => {
    :service     => service_config_file
  },
  :mysql    => {
    :host      => mysql_host,
    :schema    => mysql_schema,
    :user      => mysql_user,
    :password  => mysql_password
  },
  :refresh => {
    :enabled  => refresh_enabled,
    :interval => refresh_interval
  }
}

# ---------------------------------------------------------------------------------------
# NEVER FORK THE PROCESS!
# the used supervisord will control all
stop = false

Signal.trap('INT')  { stop = true }
Signal.trap('HUP')  { stop = true }
Signal.trap('TERM') { stop = true }
Signal.trap('QUIT') { stop = true }

# -----------------------------------------------------------------------------

sd = ServiceDiscovery::Client.new( config )

scheduler = Rufus::Scheduler.new

scheduler.every( interval, :first_in => delay, :overlap => false ) do
  sd.queue()
end

scheduler.every( 5 ) do
  if( stop == true )
    p 'shutdown scheduler ...'
    scheduler.shutdown(:kill)
  end
end

scheduler.join

# -----------------------------------------------------------------------------

# EOF
