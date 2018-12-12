
module CarbonData

  module Http

    module Apache

      def http_server_status( value = {} )

        result = []

        value = value.dig('status') unless(value.nil?)

        return result if( value.is_a?(Integer) && value.to_i == 500 )

        unless(value.nil?)

          total_accesses         = value.dig('TotalAccesses') || 0
          total_kbytes           = value.dig('TotalkBytes')   || 0
          uptime                 = value.dig('Uptime') || 0
          req_per_sec            = value.dig('ReqPerSec') || 0
          bytes_per_sec          = value.dig('BytesPerSec') || 0
          bytes_per_req          = value.dig('BytesPerReq') || 0
          busy_workers           = value.dig('BusyWorkers') || 0
          idle_workers           = value.dig('IdleWorkers') || 0
#           conns_total            = value.dig('ConnsTotal') || 0
#           conns_async_writing    = value.dig('ConnsAsyncWriting') || 0
#           conns_async_keep_alive = value.dig('ConnsAsyncKeepAlive') || 0
#           conns_async_closing    = value.dig('ConnsAsyncClosing') || 0
          sb_waiting             = value.dig('scoreboard', 'waiting') || 0
          sb_sending             = value.dig('scoreboard', 'sending') || 0
          sb_open                = value.dig('scoreboard', 'open') || 0
          sb_starting            = value.dig('scoreboard', 'starting') || 0
          sb_reading             = value.dig('scoreboard', 'reading') || 0
          sb_keepalive           = value.dig('scoreboard', 'keepalive') || 0
          sb_dns                 = value.dig('scoreboard', 'dns') || 0
          sb_closing             = value.dig('scoreboard', 'closing') || 0
          sb_logging             = value.dig('scoreboard', 'logging') || 0
          sb_graceful            = value.dig('scoreboard', 'graceful') || 0
          sb_idle                = value.dig('scoreboard', 'idle') || 0
#           cache_shared_memory    = value.dig('CacheSharedMemory') || 0
#           cache_current_entries  = value.dig('CacheCurrentEntries') || 0
#           cache_subcaches        = value.dig('CacheSubcaches') || 0
#           cache_index_per_subcache = value.dig('CacheIndexesPerSubcaches') || 0
#           cache_index_usage      = value.dig('CacheIndexUsage') || 0
#           cache_usage            = value.dig('CacheUsage') || 0
#           cache_store            = value.dig('CacheStoreCount') || 0
#           cache_replace          = value.dig('CacheReplaceCount') || 0
#           cache_expire           = value.dig('CacheExpireCount') || 0
#           cache_discard          = value.dig('CacheDiscardCount') || 0
#           cache_retrieve_hit     = value.dig('CacheRetrieveHitCount') || 0
#           cache_retrieve_miss    = value.dig('CacheRetrieveMissCount') || 0
#           cache_remove_hit       = value.dig('CacheRemoveHitCount') || 0
#           cache_remove_miss      = value.dig('CacheRemoveMissCount') || 0

          result << {
            key: format( '%s.%s.%s'      , @identifier, @normalized_service_name, 'uptime' ),
            value: uptime
          } << {
            key: format( '%s.%s.%s.%s'   , @identifier, @normalized_service_name, 'workers', 'busy' ),
            value: busy_workers
          } << {
            key: format( '%s.%s.%s.%s'   , @identifier, @normalized_service_name, 'workers', 'idle' ),
            value: idle_workers
          } << {
            key: format( '%s.%s.%s.%s'   , @identifier, @normalized_service_name, 'scoreboard', 'waiting' ),
            value: sb_waiting
          } << {
            key: format( '%s.%s.%s.%s'   , @identifier, @normalized_service_name, 'scoreboard', 'sending' ),
            value: sb_sending
          } << {
            key: format( '%s.%s.%s.%s'   , @identifier, @normalized_service_name, 'scoreboard', 'open' ),
            value: sb_open
          } << {
            key: format( '%s.%s.%s.%s'   , @identifier, @normalized_service_name, 'scoreboard', 'starting' ),
            value: sb_starting
          } << {
            key: format( '%s.%s.%s.%s'   , @identifier, @normalized_service_name, 'scoreboard', 'reading' ),
            value: sb_reading
          } << {
            key: format( '%s.%s.%s.%s'   , @identifier, @normalized_service_name, 'scoreboard', 'keepalive' ),
            value: sb_keepalive
          } << {
            key: format( '%s.%s.%s.%s'   , @identifier, @normalized_service_name, 'scoreboard', 'dns' ),
            value: sb_dns
          } << {
            key: format( '%s.%s.%s.%s'   , @identifier, @normalized_service_name, 'scoreboard', 'closing' ),
            value: sb_closing
          } << {
            key: format( '%s.%s.%s.%s'   , @identifier, @normalized_service_name, 'scoreboard', 'logging' ),
            value: sb_logging
          } << {
            key: format( '%s.%s.%s.%s'   , @identifier, @normalized_service_name, 'scoreboard', 'graceful' ),
            value: sb_graceful
          } << {
            key: format( '%s.%s.%s.%s'   , @identifier, @normalized_service_name, 'scoreboard', 'idle' ),
            value: sb_idle
          } << {
            key: format( '%s.%s.%s.%s'   , @identifier, @normalized_service_name, 'bytes', 'per_sec' ),
            value: bytes_per_sec
          } << {
            key: format( '%s.%s.%s.%s'   , @identifier, @normalized_service_name, 'bytes', 'per_req' ),
            value: bytes_per_req
          } << {
            key: format( '%s.%s.%s.%s'   , @identifier, @normalized_service_name, 'requests', 'per_sec' ),
            value: req_per_sec
          }

        end

        result
      end
    end
  end
end
