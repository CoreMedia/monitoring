
module CarbonData

  module Tomcat

    def tomcat_runtime( data = {} )

      result    = []
      mbean     = 'Runtime'
      value     = data.dig('value')

      # defaults
      uptime  = 0
      start   = 0

      if( @mbean.checkBeanConsistency( mbean, data ) == true && value != nil )
        uptime   = value.dig('Uptime')
        start    = value.dig('StartTime')
      end

      result << {
        key: format( '%s.%s.%s.%s', @identifier, @normalized_service_name, mbean, 'uptime' ),
        value: uptime
      } << {
        key: format( '%s.%s.%s.%s', @identifier, @normalized_service_name, mbean, 'starttime' ),
        value: start
      }

      result
    end


    def tomcat_operating_system( data = {} )

      result    = []
      mbean     = 'OperatingSystem'
      value     = data.dig('value')

      # defaults
      open_file_descriptor    = 0
      max_file_descriptor     = 0
      system_cpu_load         = 0
      committed_virt_mem_size = 0
      system_cpu_load         = 0

#      logger.info(JSON.pretty_generate value) if( @normalized_service_name == 'CMS' )

      if( @mbean.checkBeanConsistency( mbean, data ) == true && value != nil )
        open_file_descriptor    = value.dig('OpenFileDescriptorCount')
        max_file_descriptor     = value.dig('MaxFileDescriptorCount')
        system_cpu_load         = value.dig('SystemCpuLoad')
        committed_virt_mem_size = value.dig('CommittedVirtualMemorySize')
        process_cpu_load        = value.dig('ProcessCpuLoad')
      end

      result << {
        key: format( '%s.%s.%s.%s.%s', @identifier, @normalized_service_name, mbean, 'file_descriptor', 'open' ),
        value: open_file_descriptor
      } << {
        key: format( '%s.%s.%s.%s.%s', @identifier, @normalized_service_name, mbean, 'file_descriptor', 'max' ),
        value: max_file_descriptor
      } << {
        key: format( '%s.%s.%s.%s', @identifier, @normalized_service_name, mbean, 'system_cpu_load' ),
        value: system_cpu_load
      } << {
        key: format( '%s.%s.%s.%s', @identifier, @normalized_service_name, mbean, 'process_cpu_load' ),
        value: process_cpu_load
      } << {
        key: format( '%s.%s.%s.%s', @identifier, @normalized_service_name, mbean, 'commited_virtual_memory_size' ),
        value: committed_virt_mem_size
      }

      result.reject! { |k| k[:value].nil? }

#      logger.info(JSON.pretty_generate result) if( @normalized_service_name == 'CMS' )

      result
    end


    def tomcat_manager( data = {} )

      result    = []
      mbean     = 'Manager'
      value     = data.dig('value')
      status    = data.dig('status') || 404

      # solr 6 has no tomcat and also no manager mbean
      # logger.debug( "status 404 for service #{@normalized_service_name} and bean #{mbean}" )
      return if( status == 404 )

      # defaults
      processing_time            = 0       # Time spent doing housekeeping and expiration
      duplicates                 = 0       # Number of duplicated session ids generated
      max_active_sessions        = 0       # The maximum number of active Sessions allowed, or -1 for no limit
      session_max_alive_time     = 0       # Longest time an expired session had been alive
      max_inactive_interval      = 3600    # The default maximum inactive interval for Sessions created by this Manager
      session_expire_rate        = 0       # Session expiration rate in sessions per minute
      session_average_alive_time = 0       # Average time an expired session had been alive
      rejected_sessions          = 0       # Number of sessions we rejected due to maxActive beeing reached
      process_expires_frequency  = 0       # The frequency of the manager checks (expiration and passivation)
      active_sessions            = 0       # Number of active sessions at this moment
      session_create_rate        = 0       # Session creation rate in sessions per minute
      expired_sessions           = 0       # Number of sessions that expired ( doesn't include explicit invalidations )
      session_counter            = 0       # Total number of sessions created by this manager
      max_active                 = 0       # Maximum number of active sessions so far

      if( @mbean.checkBeanConsistency( mbean, data ) == true && value != nil )

        value = value.values.first

        processing_time            = value.dig('processingTime')
        duplicates                 = value.dig('duplicates')
        max_active_sessions        = value.dig('maxActiveSessions')
        session_max_alive_time     = value.dig('sessionMaxAliveTime')
        max_inactive_interval      = value.dig('maxInactiveInterval')
        session_expire_rate        = value.dig('sessionExpireRate')
        session_average_alive_time = value.dig('sessionAverageAliveTime')
        rejected_sessions          = value.dig('rejectedSessions')
        process_expires_frequency  = value.dig('processExpiresFrequency')
        active_sessions            = value.dig('activeSessions')
        session_create_rate        = value.dig('sessionCreateRate')
        expired_sessions           = value.dig('expiredSessions')
        session_counter            = value.dig('sessionCounter')
        max_active                 = value.dig('maxActive')
      end

      result << {
        # PUTVAL master-17-tomcat/WFS-Manager-processing/count-time interval=15 N:4
        key: format( '%s.%s.%s.%s.%s', @identifier, @normalized_service_name, mbean, 'processing', 'time' ),
        value: processing_time
      } << {
        key: format( '%s.%s.%s.%s.%s', @identifier, @normalized_service_name, mbean, 'sessions', 'count' ),
        value: session_counter
      } << {
        key: format( '%s.%s.%s.%s.%s', @identifier, @normalized_service_name, mbean, 'sessions', 'expired' ),
        value: expired_sessions
      } << {
        key: format( '%s.%s.%s.%s.%s', @identifier, @normalized_service_name, mbean, 'sessions', 'alive_avg' ),
        value: session_average_alive_time
      } << {
        key: format( '%s.%s.%s.%s.%s', @identifier, @normalized_service_name, mbean, 'sessions', 'rejected' ),
        value: rejected_sessions
      } << {
        key: format( '%s.%s.%s.%s.%s', @identifier, @normalized_service_name, mbean, 'sessions', 'duplicates' ),
        value: duplicates
      } << {
        key: format( '%s.%s.%s.%s.%s', @identifier, @normalized_service_name, mbean, 'sessions', 'max_alive' ),
        value: session_max_alive_time
      } << {
        key: format( '%s.%s.%s.%s.%s', @identifier, @normalized_service_name, mbean, 'sessions', 'expire_rate' ),
        value: session_expire_rate
      } << {
        key: format( '%s.%s.%s.%s.%s', @identifier, @normalized_service_name, mbean, 'sessions', 'create_rate' ),
        value: session_create_rate
      } << {
        key: format( '%s.%s.%s.%s.%s', @identifier, @normalized_service_name, mbean, 'sessions', 'max_active' ),
        value: max_active
      } << {
        key: format( '%s.%s.%s.%s.%s', @identifier, @normalized_service_name, mbean, 'sessions', 'expire_freq' ),
        value: process_expires_frequency
      }

      if( max_active_sessions.to_i != -1 )
        result << {
          key: format( '%s.%s.%s.%s.%s', @identifier, @normalized_service_name, mbean, 'sessions', 'max_active_allowed' ),
          value: max_active_sessions
        }
      end

      result
    end


    def tomcat_memory_usage( data = {} )

      result    = []
      mbean     = 'Memory'
      value     = data.dig('value')

      memory_types = ['HeapMemoryUsage', 'NonHeapMemoryUsage']

      # defaults
      init      = 0
      max       = 0
      used      = 0
      committed = 0
      percent   = 0

      if( @mbean.checkBeanConsistency( mbean, data ) == true && value != nil )

        memory_types.each do |m|

          init      = value.dig( m, 'init' )
          max       = value.dig( m, 'max' )
          used      = value.dig( m, 'used' )
          committed = value.dig( m, 'committed' )

          percent   = ( 100 * used / committed )

          type      = case m
            when 'HeapMemoryUsage'
              'heap_memory'
            else
              'perm_memory'
            end

          result << {
            key: format( '%s.%s.%s.%s.%s', @identifier, @normalized_service_name, mbean, type, 'init' ),
            value: init
          } << {
            key: format( '%s.%s.%s.%s.%s', @identifier, @normalized_service_name, mbean, type, 'max' ),
            value: max
          } << {
            key: format( '%s.%s.%s.%s.%s', @identifier, @normalized_service_name, mbean, type, 'used' ),
            value: used
          } << {
            key: format( '%s.%s.%s.%s.%s', @identifier, @normalized_service_name, mbean, type, 'used_percent' ),
            value: percent
          } << {
            key: format( '%s.%s.%s.%s.%s', @identifier, @normalized_service_name, mbean, type, 'committed' ),
            value: committed
          }
        end
      end

      result
    end


    def tomcat_threading( data = {} )

      result    = []
      mbean     = 'Threading'
      value     = data.dig('value')

      # defaults
      peak   = 0
      count  = 0

      if( @mbean.checkBeanConsistency( mbean, data ) == true && value != nil )
        peak   = value.dig('PeakThreadCount')
        count  = value.dig('ThreadCount')
      end

      result << {
        key: format( '%s.%s.%s.%s'   , @identifier, @normalized_service_name, mbean, 'peak' ),
        value: peak
      } << {
        key: format( '%s.%s.%s.%s'   , @identifier, @normalized_service_name, mbean, 'count' ),
        value: count
      }

      result
    end


    def tomcat_gc_parnew( data = {} )

      tomcat_gc_memory_usage( 'GCParNew', data )
    end


    def tomcat_gc_concurrentmarksweep( data = {} )

      tomcat_gc_memory_usage( 'GCConcurrentMarkSweep', data )
    end


    def tomcat_class_loading( data = {} )

      result    = []
      mbean     = 'ClassLoading'
      value     = data.dig('value')

      # defaults
      loaded       = 0
      total_loaded = 0
      unloaded     = 0

      if( @mbean.checkBeanConsistency( mbean, data ) == true && value != nil )
        loaded       = value.dig('LoadedClassCount')
        total_loaded = value.dig('TotalLoadedClassCount')
        unloaded     = value.dig('UnloadedClassCount')
      end

      result << {
        key: format( '%s.%s.%s.%s'   , @identifier, @normalized_service_name, mbean, 'loaded' ),
        value: loaded
      } << {
        key: format( '%s.%s.%s.%s'   , @identifier, @normalized_service_name, mbean, 'total' ),
        value: total_loaded
      } << {
        key: format( '%s.%s.%s.%s'   , @identifier, @normalized_service_name, mbean, 'unloaded' ),
        value: unloaded
      }

      result
    end

    # not used
    def tomcat_thread_pool( data = {} ) ; end


    private
    def tomcat_gc_memory_usage( mbean, data )

      value     = data.dig('value')
      result    = []

      if( @mbean.checkBeanConsistency( mbean, data ) == true && value != nil )

        last_gc_info = value.dig('LastGcInfo')

        if( last_gc_info != nil )

          thread_count  = last_gc_info.dig('GcThreadCount')   # The number of GC threads.
          duration      = last_gc_info.dig('duration')        # The elapsed time of this GC. (milliseconds)

          mbean.gsub!( 'GC', 'GarbageCollector.' )

          result << {
            key: format( '%s.%s.%s.%s.%s'   , @identifier, @normalized_service_name, mbean, 'threads', 'count' ),
            value: thread_count
          } << {
            key: format( '%s.%s.%s.%s.%s'   , @identifier, @normalized_service_name, mbean, 'duration', 'time' ),
            value: duration
          }

          # currently not needed
          # activate if you need
          #
          # memoryUsageAfterGc  - The memory usage of all memory pools at the end of this GC.
          # memoryUsageBeforeGc - The memory usage of all memory pools at the beginning of this GC.
          #
#          ['memoryUsageBeforeGc', 'memoryUsageAfterGc'].each do |gc|
#
#            case gc
#            when 'memoryUsageBeforeGc'
#              gcType = 'before'
#            when 'memoryUsageAfterGc'
#              gcType = 'after'
#            end
#
#            ['Par Survivor Space', 'CMS Perm Gen', 'Code Cache', 'Par Eden Space', 'CMS Old Gen', 'Compressed Class Space', 'Metaspace' ].each do |type|
#
#              last_gc_infoType = last_gc_info.dig( gc, type )
#
#              if( last_gc_infoType != nil )
#
#                init      = last_gc_infoType.dig( 'init' )
#                committed = last_gc_infoType.dig( 'committed' )
#                max       = last_gc_infoType.dig( 'max' )
#                used      = last_gc_infoType.dig( 'used' )
#
#                type      = type.strip.tr( ' ', '_' ).downcase
#
#                result << {
#                  key: format( '%s.%s.%s.%s.%s.%s.%s'   , @identifier, @normalized_service_name, mbean, 'duration', gcType, type, 'init' ),
#                  value: init
#                } << {
#                  key: format( '%s.%s.%s.%s.%s.%s.%s'   , @identifier, @normalized_service_name, mbean, 'duration', gcType, type, 'committed' ),
#                  value: committed
#                } << {
#                  key: format( '%s.%s.%s.%s.%s.%s.%s'   , @identifier, @normalized_service_name, mbean, 'duration', gcType, type, 'max' ),
#                  value: max
#                } << {
#                  key: format( '%s.%s.%s.%s.%s.%s.%s'   , @identifier, @normalized_service_name, mbean, 'duration', gcType, type, 'used' ),
#                  value: used
#                }
#
#              end
#            end
#          end

        end
      end

      result
    end


  end
end
