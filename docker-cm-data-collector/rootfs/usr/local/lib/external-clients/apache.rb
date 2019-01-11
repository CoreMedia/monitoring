

module ExternalClients

  module ApacheModStatus

    class Instance

      include Logging

      def initialize(params)

        @host  = params.dig(:host)
        @port  = params.dig(:port) || 8081


        # Sample Response with ExtendedStatus On
        # Total Accesses: 20643
        # Total kBytes: 36831
        # CPULoad: .0180314
        # Uptime: 43868
        # ReqPerSec: .470571
        # BytesPerSec: 859.737
        # BytesPerReq: 1827.01
        # BusyWorkers: 6
        # IdleWorkers: 94
        # Scoreboard: ___K_____K____________W_

        @scoreboard_map  = {
          '_' => 'waiting',
          'S' => 'starting',
          'R' => 'reading',
          'W' => 'sending',
          'K' => 'keepalive',
          'D' => 'dns',
          'C' => 'closing',
          'L' => 'logging',
          'G' => 'graceful',
          'I' => 'idle',
          '.' => 'open'
        }
      end


      def get_scoreboard_metrics(response)

        results = Hash.new(0)

        response.slice! 'Scoreboard: '
        response.each_char do |char|
          results[char] += 1
        end

        Hash[results.map { |k, v| [@scoreboard_map[k], v] }]
      end


      def fetch( uri_str, limit = 10 )

        logger.debug( "ApacheModStatus.fetch( #{uri_str}, #{limit} )" )

        # You should choose better exception.
        raise ArgumentError, 'HTTP redirect too deep' if limit == 0

        p   = URI::Parser.new
        url = p.parse( uri_str.to_s )

        req      = Net::HTTP::Get.new( "#{url.path}?auto", { 'User-Agent' => 'CoreMedia Monitoring/1.0' })
        response = Net::HTTP.start( url.host, url.port ) { |http| http.request(req) }

        case response
          when Net::HTTPSuccess         then response
          when Net::HTTPRedirection     then fetch( response['location'], limit - 1 )
          when Net::HTTPNotFound        then response
          when Net::HTTPForbidden       then response
        else
          response.error!
        end

      end


      def get

        a = []

        response = fetch( format('http://%s:%d/server-status', @host, @port), 2 )

        return {} if( response.code.to_i != 200 )

        response = response.body.split("\n")

        # blacklist
        response.reject! { |t| t[/#{@host}/] }
#        response.reject! { |t| t[/^Server.*/] }
#        response.reject! { |t| t[/.*Time/] }
#        response.reject! { |t| t[/^ServerUptime/] }
#         response.reject! { |t| t[/^Load.*/] }
#         response.reject! { |t| t[/^CPU.*/] }
#        response.reject! { |t| t[/^TLSSessionCacheStatus/] }
        response.reject! { |t| t[/^CacheType/] }

        logger.debug(" response: #{response} (#{response.class})")

        # response looks like:
        # ["Total Accesses: 41694", "Total kBytes: 682531", "CPULoad: .00240046", "Uptime: 6065088", "ReqPerSec: .00687443", "BytesPerSec: 115.235", "BytesPerReq: 16762.9", "BusyWorkers: 1", "IdleWorkers: 31"]
        #
        # transform this array into an hash like this:
        # {"TotalAccesses"=>"41694", "TotalkBytes"=>"682531", "CPULoad"=>".00240046", "Uptime"=>"6065088", "ReqPerSec"=>".00687443", "BytesPerSec"=>"115.235", "BytesPerReq"=>"16762.9", "BusyWorkers"=>"1", "IdleWorkers"=>"31" }
        #
        h = {}
        response.each do |l|
          t     = l.split(': ')
          key   = t.first.gsub(/\s/, '')
          value = t.last
          value = format( "%f", value ).sub(/\.?0*$/, "" ).to_f unless( key =~ /Scoreboard/ )

          h[key.to_sym] = value
        end

        # get original Scroreboard information
        # remove them from our hash
        # transform the scoreboard onformation int readable format
        # and add them back too our hash
        #
        # source:
        #  "_____________W_________._________..............................................................................................................................................................................................................................."
        # destination_
        #  :scoreboard=>{"waiting"=>31, "sending"=>1, "open"=>224}
        #
        scoreboard = h.dig(:Scoreboard)

        h.reject! { |t| t[/^Scoreboard/] }

        h[:scoreboard] = get_scoreboard_metrics(scoreboard)


        #response.each do |line|
        #
        #  metrics = {}
        #
        #  if line =~ /Scoreboard/
        #    metrics = { scoreboard: get_scoreboard_metrics(line.strip) }
        #  else
        #    key, value = line.strip.split(':')
        #
        #    key   = key.gsub(/\s/, '')
        #    value = value.strip.gsub('%','')
        #
        #    logger.debug( format( "   -> key: '%s' | value: '%s'", key, value ) )
        #
        #    metrics[key] = format( "%f", value ).sub(/\.?0*$/, "" ).to_f
        #  end
        #
        #  a << metrics
        #end
        #
        #logger.debug("#{a} (#{a.class})")
        #
        #a.reduce( :merge )
        #
        #logger.debug("#{a} (#{a.class})")

        #b = Hash[a.map { |k, v| [a[k], v] }]

        #logger.debug("#{b} (#{b.class})")

        # [{"TotalAccesses"=>41563.0}, {"TotalkBytes"=>682068.0}, {"CPULoad"=>0.002399}, {"Uptime"=>6061517.0}, {"ReqPerSec"=>0.006857}, {"BytesPerSec"=>115.225}, {"BytesPerReq"=>16804.3}, {"BusyWorkers"=>1.0}, {"IdleWorkers"=>31.0}, {:scoreboard=>{"waiting"=>31, "sending"=>1, "open"=>224}}]

        logger.debug("#{h} (#{h.class})")
        h
      end

    end
  end


  module HttpVhosts

    class Instance

      include Logging

      def initialize( params )
        @host  = params.dig(:host)
        @port  = params.dig(:port) || 8081
      end


      def fetch( uri_str, limit = 10 )

        logger.debug( "HttpVhosts.fetch( #{uri_str}, #{limit} )" )

        # You should choose better exception.
        raise ArgumentError, 'HTTP redirect too deep' if limit == 0

        url = URI.parse(uri_str)
        req = Net::HTTP::Get.new(url.path, { 'User-Agent' => 'CoreMedia Monitoring/1.0' })
        response = Net::HTTP.start(url.host, url.port) { |http| http.request(req) }

        case response
          when Net::HTTPSuccess         then response
          when Net::HTTPRedirection     then fetch(response['location'], limit - 1)
          when Net::HTTPNotFound        then response
        else
          response.error!
        end

      end


      def get

        response = fetch( format('http://%s:%d/vhosts.json', @host, @port), 2 )

        return {} if( response.code.to_i != 200 )

        response.body
      end
    end
  end



end
