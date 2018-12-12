
module CarbonData

  module Utils

    # return all known and active (online) server for monitoring
    #
    def monitored_server()

      @database.nodes( status: [ Storage::MySQL::ONLINE ] )
    end


    def output( data = [] )

      data.each do |d|

        puts d if( d )
      end
    end


    def normalize_service( s )

      # normalize service names for grafana
      service = case s
        when 'content-management-server'
          'CMS'
        when 'master-live-server'
          'MLS'
        when 'replication-live-server'
          'RLS'
        when 'workflow-server'
          'WFS'
        when 'solr-master'
          'SOLR_MASTER'
        when 'content-feeder'
          'FEEDER_CONTENT'
        when 'caefeeder-live'
          'FEEDER_LIVE'
        when 'caefeeder-preview'
          'FEEDER_PREV'
        when 'node-exporter'
          'NODE_EXPORTER'
        when 'http-status'
          'HTTP_STATUS'
        else
          s
      end
      service = service.gsub('iew','') if( service =~ /^cae-preview/ )
      service.tr('-', '_').upcase
    end


    def time_parser( start_time, end_time )

      seconds_diff = (start_time - end_time).to_i.abs

      {
        years: (seconds_diff / 31556952),
        months: (seconds_diff / 2628288),
        weeks: (seconds_diff / 604800),
        days: (seconds_diff / 86400),
        hours: (seconds_diff / 3600),
        minutes: (seconds_diff / 60),
        seconds: seconds_diff,
      }
    end

  end

end
