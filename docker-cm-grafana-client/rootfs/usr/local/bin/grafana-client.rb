#!/usr/bin/ruby
#
# 13.01.2017 - Bodo Schulz
#
#
# v1.0.0

# -----------------------------------------------------------------------------

require 'rufus-scheduler'

require_relative '../lib/cm_grafana'

# -----------------------------------------------------------------------------

grafana_host          = ENV.fetch('GRAFANA_HOST'           , 'grafana')
grafana_port          = ENV.fetch('GRAFANA_PORT'           , 80)
grafana_url_path      = ENV.fetch('GRAFANA_URL_PATH'       , '/grafana')
grafana_api_user      = ENV.fetch('GRAFANA_API_USER'       , 'admin')
grafana_api_password  = ENV.fetch('GRAFANA_API_PASSWORD'   , 'admin')
grafana_template_path = ENV.fetch('GRAFANA_TEMPLATE_PATH'  , '/usr/local/templates')
grafana_version       = ENV.fetch('GRAFANA_VERSION'        , 5)
mq_host               = ENV.fetch('MQ_HOST'                , 'beanstalkd')
mq_port               = ENV.fetch('MQ_PORT'                , 11300)
mq_queue              = ENV.fetch('MQ_QUEUE'               , 'mq-grafana')
redis_host            = ENV.fetch('REDIS_HOST'             , 'redis' )
redis_port            = ENV.fetch('REDIS_PORT'             , 6379 )
mysql_host            = ENV.fetch('MYSQL_HOST'             , 'database')
mysql_schema          = ENV.fetch('DISCOVERY_DATABASE_NAME', 'discovery')
mysql_user            = ENV.fetch('DISCOVERY_DATABASE_USER', 'discovery')
mysql_password        = ENV.fetch('DISCOVERY_DATABASE_PASS', 'discovery')
interval              = ENV.fetch('INTERVAL'               , '20s' )
delay                 = ENV.fetch('RUN_DELAY'              , '35s' )
server_config_file    = ENV.fetch('SERVER_CONFIG_FILE'     , '/etc/grafana_config.yml' )

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
delay_config     = validate_scheduler_values( delay, 30.0 )
delay            = validate_scheduler_values( delay, 50.0 )

# -----------------------------------------------------------------------------

config = {
  grafana: {
    host: grafana_host,
    port: grafana_port,
    user: grafana_api_user,
    password: grafana_api_password,
    url_path: grafana_url_path,
    template_directory: format('%s/%s',grafana_template_path,grafana_version)
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

# -----------------------------------------------------------------------------

g = CMGrafana.new( config )

cfg_scheduler = Rufus::Scheduler.singleton

cfg_scheduler.every( '60m', :first_in => delay_config ) do

  g.configure_server( config_file: server_config_file ) unless( server_config_file.nil? )
  cfg_scheduler.shutdown(:kill)
end

scheduler = Rufus::Scheduler.new

scheduler.every( interval, :first_in => delay, :overlap => false ) do

  g.queue()
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
