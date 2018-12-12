#!/usr/bin/env ruby
#
#
#

require 'aws-sdk'
require 'logger'
require 'erb'

@aws_region         = ENV.fetch('AWS_REGION'        , 'us-east-1')
@aws_sns_account_id = ENV.fetch('AWS_SNS_ACCOUNT_ID', nil)
@aws_sns_topic      = ENV.fetch('AWS_SNS_TOPIC'     , nil)
@icingaweb_url      = ENV.fetch('ICINGAWEB_URL'     , 'http://localhost/icinga')

# -----------------------------------------------------------------------------

logFile         = '/tmp/notification.log'
file            = File.open( logFile, File::WRONLY | File::APPEND | File::CREAT )
file.sync       = true
@logger         = Logger.new( file, 'weekly', 1024000 )

@logger.level           = Logger::INFO
@logger.datetime_format = "%Y-%m-%d %H:%M:%S::%3N"
@logger.formatter       = proc do |severity, datetime, progname, msg|
  "[#{datetime.strftime( @logger.datetime_format )}] #{severity.ljust(5)} : #{msg}\n"
end

# -----------------------------------------------------------------------------

def sns
  @sns = Aws::SNS::Client.new( region: @aws_region )
end

# Returns a subject for a Notification
#
# @param [String, #read] notification_type the type of a notification
# @param [String, #read] state the state of a notification (OK, WARNING, CRITICAL)
# @param [String, #read] host_name the host name
# @param [String, #read] service_display_name (optional) view a display name
#
# @return [String, #read] 'CRITICAL : CUSTOM - ip-172-33-41-54.ec2.internal / License - master_live_server'
#
def subject( params = {} )

  notification_type = params.dig(:notification_type)
  customer = params.dig(:customer)
  environment = params.dig(:environment)
  state = params.dig(:state)
  service_display_name = params.dig(:service_display_name)

  subject = format(
    '%s - %s - %s ',
    notification_type,
    customer,
    environment
  )

  # service
  unless( service_display_name.nil? )
    subject = format(
      '%s / %s',
      subject,
      service_display_name
    )
  end

  # host

  # finalize
  subject = format(
    '%s : (%s)',
    subject, state
  )
end


def create_message

  env = {}
  begin
    # transform ENV to an hash
    env = Hash[*ENV.to_a.flatten!]
  rescue => e
    @logger.error(e)
  end

  notification_type    = env.dig('NOTIFICATION_TYPE')
  notification_author  = env.dig('NOTIFICATION_AUTHORNAME')
  notification_comment = env.dig('NOTIFICATION_COMMENT')
  last_check           = env.dig('LAST_CHECK')
  last_state           = env.dig('LAST_STATE')
  last_state_type      = env.dig('LAST_STATETYPE')

  host_name            = env.dig('HOST_NAME')
  host_address         = env.dig('HOST_ADDRESS')
  host_display_name    = env.dig('HOST_DISPLAYNAME')
  host_state_type      = env.dig('HOST_STATETYPE')
  host_output          = env.dig('HOST_OUTPUT')
  host_perfdata        = env.dig('HOST_PERFDATA')
  host_customer        = env.dig('HOST_CUSTOMER')
  host_environment     = env.dig('HOST_ENVIORNMENT')
  host_team            = env.dig('HOST_TEAM')
  host_tier            = env.dig('HOST_TIER')

  service_name         = env.dig('SERVICE_NAME')
  service_display_name = env.dig('SERVICE_DISPLAYNAME')
  service_state_type   = env.dig('SERVICE_STATETYPE')
  service_output       = env.dig('SERVICE_OUTPUT')
  service_perfdata     = env.dig('SERVICE_PERFDATA')

  aws_name             = env.dig('AWS_NAME')
  aws_region           = env.dig('AWS_REGION')
  aws_instance_id      = env.dig('AWS_INSTANCE_ID')

  if( service_name )

    state                 = env.dig('SERVICE_STATE')
    duration              = env.dig('SERVICE_DURATION')

    link_details = format(
      '%s/monitoring/service/show?host=%s&service=%s',
      @icingaweb_url,
      host_name,
      service_name
    )

    link_ack = format(
      '%s/monitoring/service/acknowledge-problem?host=%s&service=%s',
      @icingaweb_url,
      host_name,
      service_name
    )
  else

    state           = env.dig('HOST_STATE')
    duration        = env.dig('HOST_DURATION')

    link_details = format(
      '%s/monitoring/host/show?host=%s',
      @icingaweb_url,
      host_name
    )

    link_ack = format(
      '%s/monitoring/host/acknowledge-problem?host=%s',
      @icingaweb_url,
      host_name
    )
  end

  failed_since          = Time.at(duration.to_f).strftime('%H:%M:%S')
  last_check_datetime   = Time.at(last_check.to_f)
  last_check            = last_check_datetime.strftime('%F %H:%M:%S %Z')
  problem_time_datetime = Time.now().to_i - Time.at( duration.to_i ).to_i
  problem_time          = Time.at(problem_time_datetime).strftime('%F %H:%M:%S %Z')

  template = File.read( '/etc/icinga2/scripts/notification.erb')
  renderer = ERB.new( template, nil, '-' )
  # render the template
  body     = renderer.result(binding)
  subject  = subject(
    notification_type: notification_type,
    state: state,
    host_name: host_name,
    service_display_name: service_display_name,
    customer: host_customer,
    environment: host_environment
  )

  [subject,body]

end


def publish( params = {} )

  subject = params.dig(:subject)  || 'This is a test subject'
  message = params.dig(:body)     || 'This is a test message'

  topic_arn = sprintf( 'arn:aws:sns:%s:%s:%s', @aws_region, @aws_sns_account_id, @aws_sns_topic )

  @logger.info( subject )
  @logger.info( message )
  @logger.debug(topic_arn)

  begin
    resp = sns.publish(
      topic_arn: topic_arn,
      subject: subject,
      message: message
    )

    @logger.debug(resp)
  rescue => e
    @logger.error(e)
  end

end


subject, body = create_message

publish( subject: subject, body: body )

# -----------------------------------------------------------------------------

