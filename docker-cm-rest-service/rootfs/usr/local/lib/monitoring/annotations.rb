
module Monitoring

  include Logging

  module Annotations

    # TODO
    # better sanity checks for the function parameters
    #
    def annotation( params )

      logger.debug( "annotation()" )

      dns     = params.dig(:dns )
      host    = params.dig(:host)
      payload = params.dig(:payload)

      payload = JSON.parse(payload) if( payload.is_a?(String) )
      payload = payload.deep_symbolize_keys

      logger.debug("payload: #{payload}")

      if(dns.nil?)
        ip, short, fqdn = ns_lookup(host)
      else
        ip    = dns.dig(:ip)
        short = dns.dig(:short)
        fqdn  = dns.dig(:fqdn)
      end

      logger.debug( "ip  : #{ip}" )
      logger.debug( "fqdn: #{fqdn}" )

#       result  = Hash.new
#       hash    = Hash.new

      return JSON.pretty_generate( status: 404, message: 'missing arguments for annotations' ) if( host.size.zero? && payload.size.zero? )

#       payload      = JSON.parse( payload ) if( payload.is_a?( String ) )
      logger.debug( JSON.pretty_generate(payload) )

      command      = payload.dig(:command)
      argument     = payload.dig(:argument)
      message      = payload.dig(:message)
      description  = payload.dig(:description)
      tags         = payload.dig(:tags)  || []
      config       = payload.dig(:config)
      timestamp    = payload.dig(:timestamp) || Time.now.to_i

      unless( %w[create remove].include?( command ) )

        params = {
          cmd: 'annotation',
          node: host,
          queue: 'mq-grafana',
          payload: {
            annotation: true,
            timestamp: timestamp,
            data: payload,
            type: command,
            message: message,
            argument: argument,
            tags: tags,
            config: config,
            dns: { ip: ip, short: short, fqdn: fqdn }
          },
          prio: 0
        }
        params.reject!{ |_, v| v.nil? }

        # send to grafana
        return message_queue(params)
      end

      { status: 204, message: 'not found' }
    end

  end
end
