#!/usr/bin/ruby
#
# 03.01.2017 - Bodo Schulz
#
#
# v0.7.0

# -----------------------------------------------------------------------------

require 'rufus-scheduler'

require_relative '../lib/icinga'

# -----------------------------------------------------------------------------

icinga_host          = ENV.fetch('ICINGA_HOST'             , 'localhost' )
icinga_api_port      = ENV.fetch('ICINGA_API_PORT'         , 5665 )
icinga_api_user      = ENV.fetch('ICINGA_API_USER'         , 'admin' )
icinga_api_password  = ENV.fetch('ICINGA_API_PASSWORD'     , 'icinga' )
icinga_api_pki_path  = ENV.fetch('ICINGA_API_PKI_PATH'     , nil )
icinga_api_node_name = ENV.fetch('ICINGA_API_NODE_NAME'    , nil )
# icinga_cluster       = ENV.fetch('ICINGA_CLUSTER'          , false )
icinga_satellite     = ENV.fetch('ICINGA_CLUSTER_SATELLITE', nil )
icinga_notifications = ENV.fetch('ENABLE_NOTIFICATIONS'    , false )
mq_host              = ENV.fetch('MQ_HOST'                 , 'beanstalkd' )
mq_port              = ENV.fetch('MQ_PORT'                 , 11300 )
mq_queue             = ENV.fetch('MQ_QUEUE'                , 'mq-icinga' )
redis_host           = ENV.fetch('REDIS_HOST'              , 'redis' )
redis_port           = ENV.fetch('REDIS_PORT'              , 6379 )
mysql_host           = ENV.fetch('MYSQL_HOST'              , 'database')
mysql_schema         = ENV.fetch('DISCOVERY_DATABASE_NAME' , 'discovery')
mysql_user           = ENV.fetch('DISCOVERY_DATABASE_USER' , 'discovery')
mysql_password       = ENV.fetch('DISCOVERY_DATABASE_PASS' , 'discovery')
interval             = ENV.fetch('INTERVAL'                , '30s' )
delay                = ENV.fetch('RUN_DELAY'               , '35s' )

server_config_file  = ENV.fetch('SERVER_CONFIG_FILE'     , '/etc/icinga_server_config.yml' )

# -----------------------------------------------------------------------------
# validate durations for the Scheduler

def validate_scheduler_values( duration, default )
  raise ArgumentError.new(format('wrong type. \'duration\' must be an String, given %s', duration.class.to_s )) unless( duration.is_a?(String) )
  raise ArgumentError.new(format('wrong type. \'default\' must be an Float, given %s', default.class.to_s )) unless( default.is_a?(Float) )
  i = Rufus::Scheduler.parse( duration.to_s )
  i = default.to_f if( i < default.to_f )
  Rufus::Scheduler.to_duration( i )
end

interval         = validate_scheduler_values( interval, 30.0 )
delay            = validate_scheduler_values( delay, 35.0 )

# -----------------------------------------------------------------------------

# convert string to bool
# icinga_cluster       = icinga_cluster.to_s.eql?('true') ? true : false
icinga_notifications = icinga_notifications.to_s.eql?('true') ? true : false

config = {
  icinga: {
    host: icinga_host,
    api: {
      port: icinga_api_port,
      user: icinga_api_user,
      password: icinga_api_password,
      pki_path: icinga_api_pki_path,
      node_name: icinga_api_node_name
    },
    satellite: icinga_satellite,
    server_config_file: server_config_file,
    notifications: icinga_notifications
  },
  mq: {
    host: mq_host,
    port: mq_port,
    queue: mq_queue
  },
  redis: {
    host: redis_host,
    port: redis_port
  },
  mysql: {
    host: mysql_host,
    schema: mysql_schema,
    user: mysql_user,
    password: mysql_password
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

# ---------------------------------------------------------------------------------------

i = CMIcinga2.new( config )

unless(server_config_file.nil?)

  cfg_scheduler = Rufus::Scheduler.singleton
  cfg_scheduler.every( '60m', :first_in => delay.to_i ) do
    i.configure_server( config_file: server_config_file )
    cfg_scheduler.shutdown(:kill)
  end
end

scheduler = Rufus::Scheduler.new

scheduler.every( interval, :first_in => delay.to_i + 5, :overlap => false ) do

  i.queue()
end


scheduler.every( 5 ) do

  if( stop == true )

    p 'shutdown scheduler ...'

    scheduler.shutdown(:kill)
  end

end


scheduler.join


# EOF
