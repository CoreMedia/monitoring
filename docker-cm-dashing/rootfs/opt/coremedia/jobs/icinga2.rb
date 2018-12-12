
require 'icinga2'

icinga_host          = ENV.fetch('ICINGA_MASTER'        , 'icinga2')
icinga_api_port      = ENV.fetch('ICINGA_API_PORT'      , 5665)
icinga_api_user      = ENV.fetch('ICINGA_API_USER'      , 'root')
icinga_api_password  = ENV.fetch('ICINGA_API_PASSWORD'  , nil)
icinga_api_pki_path  = ENV.fetch('ICINGA_API_PKI_PATH'  , nil)
icinga_api_node_name = ENV.fetch('ICINGA_API_NODE_NAME' , nil)
interval             = ENV.fetch('INTERVAL'             , '2m')
delay                = ENV.fetch('RUN_DELAY'            , '10s')

debug                = ENV.fetch('DEBUG'                , false)

# -----------------------------------------------------------------------------
# validate durations for the Scheduler

def validate_scheduler_values( duration, default )
  raise ArgumentError.new(format('wrong type. \'duration\' must be an String, given %s', duration.class.to_s )) unless( duration.is_a?(String) )
  raise ArgumentError.new(format('wrong type. \'default\' must be an Float, given %s', default.class.to_s )) unless( default.is_a?(Float) )
  i = Rufus::Scheduler.parse( duration.to_s )
  i = default.to_f if( i < default.to_f )
  Rufus::Scheduler.to_duration( i )
end

interval         = validate_scheduler_values( interval, 120.0 )
delay            = validate_scheduler_values( delay, 10.0 )

# -----------------------------------------------------------------------------

debug = debug.to_s.eql?('true') ? true : false

config = {
  icinga: {
    host: icinga_host,
    api: {
      port: icinga_api_port,
      username: icinga_api_user,
      password: icinga_api_password,
      pki_path: icinga_api_pki_path,
      node_name: icinga_api_node_name
    }
  }
}

begin
  icinga = Icinga2::Client.new( config )
rescue => error
  $stderr.puts( error )
  $stderr.puts( error.backtrace.join("\n") )
end

puts ' => enable debug output' if(debug)

SCHEDULER.every interval, :first_in => delay do |job|

  if( icinga.available? == true )

    begin

      icinga.application_data
      icinga.cib_data
      icinga.host_objects

      average_statistics = icinga.average_statistics
      puts "average_statistics    : #{average_statistics}" if(debug)
      avg_latency        = average_statistics.dig(:avg_latency)
      avg_execution_time = average_statistics.dig(:avg_execution_time)

      interval_statistics     = icinga.interval_statistics
      puts "interval_statistics : #{interval_statistics}" if(debug)
      hosts_active_checks     = interval_statistics.dig(:hosts_active_checks)
      hosts_passive_checks    = interval_statistics.dig(:hosts_passive_checks)
      services_active_checks  = interval_statistics.dig(:services_active_checks)
      services_passive_checks = interval_statistics.dig(:services_passive_checks)

      host_statistics    = icinga.host_statistics
      puts "host_statistics   : #{host_statistics}" if(debug)
      hosts_up           = host_statistics.dig(:up)
      hosts_down         = host_statistics.dig(:down)
      hosts_pending      = host_statistics.dig(:pending)
      hosts_unreachable  = host_statistics.dig(:unreachable)
      hosts_in_downtime  = host_statistics.dig(:in_downtime)
      hosts_acknowledged = host_statistics.dig(:acknowledged)

      host_problems          = icinga.host_problems
      puts "host_problems: #{host_problems}" if(debug)
      host_problems_all      = host_problems.dig(:all)
      host_problems_down     = host_problems.dig(:down)
      host_problems_critical = host_problems.dig(:critical)
      host_problems_unknown  = host_problems.dig(:unknown)
      host_problems_adjusted = host_problems.dig(:adjusted)

      service_statistics    = icinga.service_statistics
      puts "service_statistics: #{service_statistics}" if(debug)
      services_ok           = service_statistics.dig(:ok)
      services_warning      = service_statistics.dig(:warning)
      services_critical     = service_statistics.dig(:critical)
      services_unknown      = service_statistics.dig(:unknown)
      services_pending      = service_statistics.dig(:pending)
      services_in_downtime  = service_statistics.dig(:in_downtime)
      services_acknowledged = service_statistics.dig(:acknowledged)

      services_handled                  = icinga.service_problems
      puts "services_handled: #{services_handled}" if(debug)
      # service_problems_handled_all      = services_handled.dig(:ok)
      service_problems_handled_warning  = services_handled.dig(:handled_warning)
      service_problems_handled_critical = services_handled.dig(:handled_critical)
      service_problems_handled_unknown  = services_handled.dig(:handled_unknown)

#      a = @icinga2.service_problems
#      expect(a).to be_a(Hash)
#      expect(a.count).to be == 14
#      expect(a.dig(:ok)).to be_a(Integer)
#      expect(a.dig(:warning)).to be_a(Integer)
#      expect(a.dig(:critical)).to be_a(Integer)
#      expect(a.dig(:unknown)).to be_a(Integer)
#      expect(a.dig(:pending)).to be_a(Integer)
#      expect(a.dig(:in_downtime)).to be_a(Integer)
#      expect(a.dig(:acknowledged)).to be_a(Integer)
#      expect(a.dig(:adjusted_warning)).to be_a(Integer)
#      expect(a.dig(:adjusted_critical)).to be_a(Integer)
#      expect(a.dig(:adjusted_unknown)).to be_a(Integer)
#      expect(a.dig(:handled_all)).to be_a(Integer)
#      expect(a.dig(:handled_warning)).to be_a(Integer)
#      expect(a.dig(:handled_critical)).to be_a(Integer)
#      expect(a.dig(:handled_unknown)).to be_a(Integer)

      version, revision = icinga.version.values

      # meter widget
      # we'll update the patched meter widget with absolute values (set max dynamically)
      hosts_down          = hosts_down          # all hosts with problems (integer)
      hosts_all           = icinga.hosts_all           # all hosts (integer)
      service_problems    = icinga.count_services_with_problems   # all services with problems (integer)
      services_all        = icinga.services_all        # all services (integer)

      # check stats
      icinga_stats = [
        { label: 'Host checks/min'    , value: hosts_active_checks },
        { label: 'Service checks/min' , value: services_active_checks },
      ]

      # severity list
      problem_services, service_problems_severity = icinga.list_services_with_problems(10).values
      work_queue_stats = icinga.work_queue_statistics

      severity_stats = []
      service_problems_severity.each do |name,state|
        severity_stats.push({
          label: Icinga2::Converts.format_service(name),
          color: icinga.state_to_color(state.to_int, false),
          state: state.to_int
        })
      end

      order = [2,1,3]
      severity_stats = severity_stats.sort do |a, b|
        order.index(a[:state]) <=> order.index(b[:state])
      end

      work_queue_stats.each do |name, value|
        icinga_stats.push( { label: name, value: '%0.2f' % value } )
      end

      # -----------------------------------------------------------------------------------

      color_hosts_down            = hosts_down.to_i == 0            ? 'nothing' : 'red'
      color_hosts_pending         = hosts_pending.to_i == 0         ? 'nothing' : 'purple'
      color_hosts_unreachable     = hosts_unreachable.to_i == 0     ? 'nothing' : 'purple'
      color_hosts_in_downtime     = hosts_in_downtime.to_i == 0     ? 'nothing' : 'green'
      color_hosts_acknowledged    = hosts_acknowledged.to_i == 0    ? 'nothing' : 'green'

      color_services_warning      = services_warning.to_i == 0      ? 'nothing' : 'yellow'
      color_services_critical     = services_critical.to_i == 0     ? 'nothing' : 'red'
      color_services_unknown      = services_unknown.to_i == 0      ? 'nothing' : 'purple'
      color_services_pending      = services_pending.to_i == 0      ? 'nothing' : 'purple'
      color_services_in_downtime  = services_in_downtime.to_i == 0  ? 'nothing' : 'green'
      color_services_acknowledged = services_acknowledged.to_i == 0 ? 'nothing' : 'green'

      color_hosts_down_adjusted       = host_problems_adjusted.to_i == 0 ? 'blue' : 'red'
      color_services_handled_critical = service_problems_handled_critical.to_i == 0 ? 'blue' : 'red'
      color_services_handled_warning  = service_problems_handled_warning.to_i == 0 ? 'blue' : 'yellow'
      color_services_handled_unknown  = service_problems_handled_unknown.to_i == 0 ? 'blue' : 'purple'

      # ================================================================================================

      # handled stats
      handled_stats = [
        { label: 'Acknowledgements', color: 'blue' },
        { label: 'Hosts'           , value: hosts_acknowledged},
        { label: 'Services'        , value: services_acknowledged},
        { label: 'Downtimes'       , color: 'blue' },
        { label: 'Hosts'           , value: hosts_in_downtime},
        { label: 'Services'        , value: services_in_downtime},
      ]

      hosts_data = [
        { label: 'Up'          , value: hosts_up },
        { label: 'Down'        , value: hosts_down, handled: 0, color: color_hosts_down },
        { label: 'Pending'     , value: hosts_pending, color: color_hosts_pending },
        { label: 'Unreachable' , value: hosts_unreachable, color: color_hosts_unreachable },
        { label: 'In Downtime' , value: hosts_in_downtime, color: color_hosts_in_downtime },
        { label: 'Acknowledged', value: hosts_acknowledged, color: color_hosts_acknowledged },
      ]

      services_data = [
        { label: 'ok'          , value: services_ok },
        { label: 'warning'     , value: services_warning, color: color_services_warning },
        { label: 'critical'    , value: services_critical, color: color_services_critical },
        { label: 'unknown'     , value: services_unknown, color: color_services_unknown },
        { label: 'pending'     , value: services_pending, color: color_services_pending },
        { label: 'in downtime' , value: services_in_downtime, color: color_services_in_downtime },
        { label: 'Acknowledged', value: services_acknowledged, color: color_services_acknowledged }
      ]
      # -----------------------------------------------------------------------------------

      if(debug)
        puts "Severity: #{severity_stats}"
        puts "Icinga  : #{icinga_stats}"
        puts "Handled : #{handled_stats}"
        puts "hosts_adjusted    : #{icinga.hosts_adjusted}"
        puts "services_adjusted : #{icinga.services_adjusted}"
        puts "host_statistics   : #{icinga.host_statistics}"
        puts "service_statistics: #{icinga.service_statistics}"

        puts "service handled critical: " + service_problems_handled_critical.to_s
        puts "service handled warnings: " + service_problems_handled_warning.to_s
        puts "service handled unknowns: " + service_problems_handled_unknown.to_s

        puts format('Host Up             : %s', hosts_up)
        puts format('Host Down           : %s', hosts_down)
        puts format('Host pending        : %s', hosts_pending)
        puts format('Host unrechable     : %s', hosts_unreachable)
        puts format('Host in Downtime    : %s', hosts_in_downtime)
        puts format('Host acknowledged   : %s', hosts_acknowledged)

        puts format('Service Critical    : %s', services_critical)
        puts format('Service Warning     : %s', services_warning)
        puts format('Service Unknown     : %s', services_unknown )
        puts format('Service Acknowledged: %s', services_acknowledged)
        puts format('Host Acknowledged   : %s', hosts_acknowledged)
        puts format('Service In Downtime : %s', services_in_downtime)
        puts format('Host In Downtime    : %s', hosts_in_downtime)
      end
      # -----------------------------------------------------------------------------------

      send_event('icinga-host-meter', {
        value: hosts_down,
        max:   hosts_all,
        moreinfo: "Total hosts: #{hosts_all}",
        color: 'blue'
      })

      send_event('icinga-service-meter', {
        value: service_problems,
        max:   services_all,
        moreinfo: "Total services: #{services_all}",
        color: 'blue'
      })

      send_event('icinga-stats', {
        title: "version: #{version}",
        items: icinga_stats,
        moreinfo: "Avg latency: #{avg_latency.to_f.round(2)}s",
        color: 'blue'
      })

      send_event('handled-stats', {
        items: handled_stats,
        color: 'blue'
      })

      send_event('icinga-severity', {
        items: severity_stats,
        color: 'blue'
      })

      send_event('icinga-hosts', {
        title: format( '%d Hosts', icinga.hosts_all ),
        items: hosts_data
      })

      send_event('icinga-services', {
        title: format( '%d Services', icinga.services_all ),
        items: services_data
      })

      # down, critical, warning, unknown
      send_event('icinga-host-problems-down', {
        title: 'Hosts down',
        value: hosts_down,
        moreinfo: "All Problems: " + host_problems_all.to_s,
        color: color_hosts_down_adjusted
      })

      send_event('icinga-service-problems-critical', {
        title: 'Services critical',
        value: services_critical.to_s,
        moreinfo: "All Problems: " + service_problems_handled_critical.to_s,
        color: color_services_handled_critical
      })

      send_event('icinga-service-problems-warning', {
        title: 'Services warning',
        value: services_warning.to_s,
        moreinfo: "All Problems: " + service_problems_handled_warning.to_s,
        color: color_services_handled_warning
      })

      send_event('icinga-service-problems-unknown', {
        title: 'Services unknown',
        value: services_unknown.to_s,
        moreinfo: "All Problems: " + service_problems_handled_unknown.to_s,
        color: color_services_handled_unknown
      })

      # ack, downtime
      send_event('icinga-service-ack', {
        value: services_acknowledged.to_s,
        color: 'blue'
      })

      send_event('icinga-host-ack', {
        value: hosts_acknowledged.to_s,
        color: 'blue'
      })

      send_event('icinga-service-downtime', {
        value: services_in_downtime.to_s,
        color: 'orange'
      })

      send_event('icinga-host-downtime', {
        value: hosts_in_downtime.to_s,
        color: 'orange'
      })

    rescue => error
      $stderr.puts( error )
      $stderr.puts( error.backtrace.join("\n") )
    end

  else
    $stderr.puts( 'icinga are not available' )
  end

end
