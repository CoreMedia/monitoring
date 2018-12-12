
require 'json'
require 'rest-client'

module ExternalClients

  module NodeExporter

    class Instance

      include Logging

      def initialize( params )

        @host      = params.dig(:host)
        @port      = params.dig(:port) ||  9100
      end


      def call_service()

        uri = URI( sprintf( 'http://%s:%s/metrics', @host, @port ) )

        response = nil

        begin
          Net::HTTP.start( uri.host, uri.port ) do |http|
            request = Net::HTTP::Get.new( uri.request_uri )

            response     = http.request( request )
            response_code = response.code.to_i

            # TODO
            # Errorhandling
            if( response_code != 200 )
              logger.error( sprintf( ' [%s] - Error', response_code ) )
              logger.error( response.body )
            elsif( response_code == 200 )

              body = response.body
  #             logger.debug( body )
              # remove all comments
              body        = body.each_line.reject{ |x| x.strip =~ /(^.*)#/ }.join
              # get groups
              @boot       = body.each_line.select { |name| name =~ /^node_boot_time/ }
              @cpu        = body.each_line.select { |name| name =~ /^node_cpu/ }
              @disk       = body.each_line.select { |name| name =~ /^node_disk/ }
              @filefd     = body.each_line.select { |name| name =~ /^node_filefd/ }
              @filesystem = body.each_line.select { |name| name =~ /^node_filesystem/ }
              @hwmon      = body.each_line.select { |name| name =~ /^node_hwmon/ }
              @forks      = body.each_line.select { |name| name =~ /^node_forks/ }
              @load       = body.each_line.select { |name| name =~ /^node_load/ }
              @memory     = body.each_line.select { |name| name =~ /^node_memory/ }
              @netstat    = body.each_line.select { |name| name =~ /^node_netstat/ }
              @network    = body.each_line.select { |name| name =~ /^node_network/ }
            end
          end
        rescue Exception => error
          logger.error( error )
          logger.error( error.backtrace )
          # raise( e )
        end

      end


      def collect_uptime( data )

        result    = {}
        parts    = data.last.split( ' ' )
        boot_time = parts[1].to_f.to_i
        # boot_time = sprintf( "%f", parts[1].to_s ).sub(/\.?0*$/, "" )
        uptime   = Time.at( Time.now() - Time.at( boot_time.to_i ) ).to_i

        { 'boot_time' => boot_time, 'uptime' => uptime }
      end


      def collect_cpu( data )

        result  = {}
        tmpCore = nil
        regex   = /(.*){cpu="(?<core>(.*))",mode="(?<mode>(.*))"}(?<mes>(.*))/x

        data.sort!.each do |c|

          if( parts = c.match( regex ) )

            core, mode, mes = parts.captures

            mes = mes.to_s.strip.to_f.to_i # sprintf( "%f", mes.to_s.strip ).sub(/\.?0*$/, "" )

            core = "cpu#{core}" unless core =~ /^cpu/

            if( core != tmpCore )
              result[core] = { mode => mes }
              tmpCore = core
            end

            result[core][mode] = mes
          end
        end

        result
      end


      def collect_load( data )

        result = {}
        regex = /(?<load>(.*)) (?<mes>(.*))/x

        data.each do |c|

          if( parts = c.match( regex ) )

            c.gsub!('node_load15', 'longterm' )
            c.gsub!('node_load5' , 'midterm' )
            c.gsub!('node_load1' , 'shortterm' )

            parts = c.split( ' ' )

            key   = parts[0]
            value = parts[1].to_f

            result[key] = value
          end
        end

        result
      end


      def collect_memory( data )

        result = {}
        data   = data.select { |name| name =~ /^node_memory_Swap|node_memory_Mem/ }
        regex  = /(?<load>(.*)) (?<mes>(.*))/x

        # OBSOLETE
        # remove in release > 1806!
        #
        data.each do |c|

          if( parts = c.match( regex ) )

            c.gsub!('node_memory_', ' ' )

            parts = c.split( ' ' )
            result[parts[0].to_s.gsub('_bytes', '')] = sprintf( "%f", parts[1].to_s ).sub(/\.?0*$/, "").to_i
          end
        end
        # ---------------------------------------------

        data.each do |c|
          c.gsub!('node_memory_', ' ' )
          if( parts = c.match( regex ) )
            parts = c.split( ' ' )
            key   = parts[0].downcase.gsub('_bytes', '')
            value = parts[1].to_f.to_i

            if( key =~ /^mem/ )
              _key = key.gsub('mem','')
              result['memory'] ||= {}
              result['memory'][_key] = value
            end

            if( key =~ /^swap/ )
              _key = key.gsub('swap','')
              result['swap'] ||= {}
              result['swap'][_key] = value
            end
          end
        end

        if(result.dig('memory','total') && result.dig('memory','available'))
          mem_total        = result.dig('memory','total')
          mem_available    = result.dig('memory','available')
          mem_used         = ( mem_total.to_i - mem_available.to_i )
          mem_used_percent = ( 100 * mem_used.to_i / mem_total.to_i ).to_i

          result['memory']['used'] = mem_used
          result['memory']['used_percent'] = mem_used_percent
        end

        if(result.dig('swap','total') && result.dig('swap','free'))
          swap_total   = result.dig('swap','total') || 0
          swap_free    = result.dig('swap','free')  || 0

          if( swap_total != 0 )
            swap_used        = ( swap_total.to_i - swap_free.to_i )
            swap_used_percent = 0
            swap_used_percent = ( 100 * swap_used.to_i / swap_total.to_i ).to_i if( swap_used.to_i > 0 && swap_total.to_i > 0 )

            result['swap']['used'] = swap_used
            result['swap']['used_percent'] = swap_used_percent
          end
        end

        result
      end


      def collect_network( data )

        result = {}
        r      = []

        existing_devices = []

        regex = /(.*){device="(?<device>(.*))"}(.*)/

        d = data.select { |name| name.match( regex ) }

        d.each do |devices|
          if( parts = devices.match( regex ) )
            existing_devices += parts.captures
          end
        end

        # regex = /^(?<direction>(.*))_(?<type>(.*)){device="(?<device>(.*))"}(?<mes>(.*))/x
        regex = /^node_network_(?<direction>(.*))_(?<type>(.*))_(.*){device="(?<device>(.*))"}(?<mes>(.*))/x

        existing_devices.each do |d|

          selected = data.select { |name| name.match( /(.*)device="#{d}(.*)/ ) }
          selected = selected.select { |name| name =~ /bytes|packets|err|drop/ }

          hash = {}

          selected.each do |s|
            if( parts = s.match( regex ) )
              direction, type, device, mes = parts.captures

              direction = direction.gsub('node_network_','')

              hash[d.to_s] ||= {}
              hash[d.to_s][direction.to_s] ||= {}
              hash[d.to_s][direction.to_s][type.to_s] ||= {}
              hash[d.to_s][direction.to_s][type.to_s] = mes.to_f.to_i # sprintf( "%f", mes.to_s ).sub(/\.?0*$/, "" )
            end
          end

          r.push( hash )
        end

        r.reduce( :merge )
      end


      def collect_disk( data )

        result = {}
        r      = []

        existing_devices = []

        regex = /(.*){device="(?<device>(.*))"}(.*)/

        d = data.select { |name| name.match( regex ) }

        d.each do |devices|
          parts = devices.match( regex )
          existing_devices += parts.captures if( parts )
        end

        existing_devices.uniq!

        regex = /^(?<type>(.*))_(?<direction>(.*)){device="(?<device>(.*))"}(?<mes>(.*))/x

        existing_devices.each do |d|

          selected = data.select     { |name| name.match( /(.*)device="#{d}(.*)/ ) }
          selected = selected.select { |name| name =~ /bytes_read|bytes_written|read_bytes|written_bytes|io_now/ }

          hash = {}

          selected.each do |s|

            if( parts = s.match( regex ) )

              type, direction, device, mes = parts.captures

              type = type.gsub('node_disk_','').gsub('_bytes','')

              hash[d.to_s] ||= {}
              hash[d.to_s][type.to_s] ||= {}
              hash[d.to_s][type.to_s][direction.to_s] ||= {}
              hash[d.to_s][type.to_s][direction.to_s] = mes.to_f.to_i # sprintf( "%f", mes.to_s ).sub(/\.?0*$/, "" )

            end
          end

          r.push( hash )
        end

        r.reduce( :merge )
      end


      def collect_filesystem( data )

        result = {}
        r      = []

        # blacklist | mount | egrep -v "(cgroup|none|sysfs|devtmpfs|tmpfs|devpts|proc)"
        data.reject! { |t| t[/-hosts/] }
        data.reject! { |t| t[/etc/] }
        data.reject! { |t| t[/iso9660/] }
        data.reject! { |t| t[/tmpfs/] }
        data.reject! { |t| t[/rpc_pipefs/] }
        data.reject! { |t| t[/nfs4/] }
        data.reject! { |t| t[/overlay/] }
        data.reject! { |t| t[/cgroup/] }
        data.reject! { |t| t[/devpts/] }
        data.reject! { |t| t[/devtmpfs/] }
        data.reject! { |t| t[/sysfs/] }
        data.reject! { |t| t[/sys\//] }
        data.reject! { |t| t[/proc/] }
        data.reject! { |t| t[/none/] }
        data.reject! { |t| t[/configfs/] }
        data.reject! { |t| t[/debugfs/] }
        data.reject! { |t| t[/hugetlbfs/] }
        data.reject! { |t| t[/mqueue/] }
        data.reject! { |t| t[/pstore/] }
        data.reject! { |t| t[/securityfs/] }
        data.reject! { |t| t[/selinuxfs/] }
        data.reject! { |t| t[/\/rootfs\/var\/run/] }
        data.reject! { |t| t[/\/var\/lib\/docker/] }
        data.flatten!

        existing_devices = []

        regex = /(.*){device="(?<device>(.*))"}(.*)/

        d = data.select { |name| name.match( regex ) }

        d.each do |devices|
          parts = devices.match( regex )
          existing_devices += parts.captures if( parts )
          # existing_devices += parts.captures if( parts = devices.match( regex ) )
        end

        existing_devices.uniq!

        regex = /^(?<type>(.*)){device="(?<device>(.*))",fstype="(?<fstype>(.*))",mountpoint="(?<mountpoint>(.*))"}(?<mes>(.*))/x

        existing_devices.each do |d|

          selected = data.select     { |name| name.match( /(.*)device="#{d}(.*)/ ) }

          hash = {}

          selected.each do |s|

            if( parts = s.match( regex ) )

              type, device, fstype, mountpoint, mes = parts.captures
              # fix breaking changes in node_exporter v0.16.x
              type = type.gsub('node_filesystem_','').gsub('_bytes','')

              device.gsub!( '/dev/', '' )

              # AWS / Xen special
              device = 'rootfs' if( device =~ /xvda/ )
              mountpoint = '/' if( device == 'rootfs' )

              # skip
              next if( mountpoint =~ /^\/rootfs/ )

              hash[device.to_s] ||= {}
              hash[device.to_s][type.to_s] ||= {}
              hash[device.to_s][type.to_s]  = mes.to_f.to_i # sprintf( "%f", mes.to_s ).sub(/\.?0*$/, "" )
              hash[device.to_s]['mountpoint'] = mountpoint
            end
          end

          r.push( hash )
        end

        result = r.reduce( :merge ).clone

        result.each do |k,v|
          if(v)
            avail = v.dig('avail')
            size  = v.dig('size')

            if( size.to_i > 0 )
              used          = ( size.to_i - avail.to_i )
              used_percent  = ( 100 * used.to_i / size.to_i ).to_i

              result[k]["used"] = used
              result[k]["used_percent"] = used_percent
            end

          end
        end

        result
      end


      def collect_filedescriptor(data)

        result = {}
        regex = /(?<key>(.*)) (?<mes>(.*))/x

        data.each do |c|

          if( parts = c.match( regex ) )

            c.gsub!('node_filefd_', '' )
            parts = c.split( ' ' )

            key   = parts[0]
            value = parts[1].to_f

            result[key] = value
          end
        end

        result
      end


      def get

        begin

          call_service

          {
            uptime: collect_uptime( @boot ),
            cpu: collect_cpu( @cpu ),
            load: collect_load( @load ),
            memory: collect_memory( @memory ),
            network: collect_network( @network ),
            disk: collect_disk( @disk ),
            filesystem: collect_filesystem( @filesystem ),
            filefd: collect_filedescriptor(@filefd)
          }
        rescue Exception => error
          logger.error( "An error occurred for query: #{error}" )
          return false
        end

      end


    end

  end

end
