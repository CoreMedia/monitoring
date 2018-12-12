module CarbonData

  module Feeder


    def feeder_health( data = {} )

      result      = []
      mbean       = 'Health'
      value       = data.dig('value')

      # defines:
      #   0: false
      #   1: true
      #  -1: N/A
      healthy = -1

      if( @mbean.checkBeanConsistency( mbean, data ) == true && value != nil )

        value = value.values.first

        healthy   = value.dig('Healthy')
        healthy   = healthy == true ? 1 : 0 if ( healthy != nil )
      end

      result << {
        key: format( '%s.%s.%s.%s', @identifier, @normalized_service_name, mbean, 'healthy' ),
        value: healthy
      }

      result
    end


    # Check for the CAEFeeder
    def feeder_proactive_engine( data = {} )

      result      = []
      mbean       = 'ProactiveEngine'
      value       = data.dig('value')

      # defaults
      max_entries     = 0  # (KeysCount) Number of (active) keys
      current_entries = 0  # (ValuesCount) Number of (valid) values. It is less or equal to 'keysCount'
      diff_entries    = 0  #
      invalidations   = 0  # (InvalidationCount) Number of invalidations which have been received
      heartbeat       = 0  # (HeartBeat) The heartbeat of this service: Milliseconds between now and the latest activity. A low value indicates that the service is alive. An constantly increasing value might be caused by a 'sick' or dead service
      queue_capacity  = 0  # (QueueCapacity) The queue's capacity: Maximum number of items which can be enqueued
      queue_max_size  = 0  # (QueueMaxSize) Maximum number of items which had been waiting in the queue
      queue_size      = 0  # (QueueSize) Number of items waiting in the queue for being processed. Less or equal than 'queue_capacity'. Zero means that ProactiveEngine is idle.

      if( @mbean.checkBeanConsistency( mbean, data ) == true && value != nil )

        value = value.values.first

        max_entries     = value.dig('KeysCount')   || 0
        current_entries = value.dig('ValuesCount') || 0
        diff_entries    = ( max_entries - current_entries ).to_i
        invalidations   = value.dig('InvalidationCount')
        heartbeat       = value.dig('HeartBeat')
        queue_capacity  = value.dig('QueueCapacity')
        queue_max_size  = value.dig('QueueMaxSize')
        queue_size      = value.dig('QueueSize')
      end

      result << {
        key: format( '%s.%s.%s.%s.%s.%s', @identifier, @normalized_service_name, mbean, 'feeder', 'entries', 'max' ),
        value: max_entries
      } << {
        key: format( '%s.%s.%s.%s.%s.%s', @identifier, @normalized_service_name, mbean, 'feeder', 'entries', 'current' ),
        value: current_entries
      } << {
        key: format( '%s.%s.%s.%s.%s.%s', @identifier, @normalized_service_name, mbean, 'feeder', 'entries', 'diff' ),
        value: diff_entries
      } << {
        key: format( '%s.%s.%s.%s.%s'   , @identifier, @normalized_service_name, mbean, 'feeder', 'invalidations' ),
        value: invalidations
      } << {
        key: format( '%s.%s.%s.%s.%s'   , @identifier, @normalized_service_name, mbean, 'feeder', 'heartbeat' ),
        value: heartbeat
      } << {
        key: format( '%s.%s.%s.%s.%s'   , @identifier, @normalized_service_name, mbean, 'queue', 'capacity' ),
        value: queue_capacity
      } << {
        key: format( '%s.%s.%s.%s.%s'   , @identifier, @normalized_service_name, mbean, 'queue', 'max_waiting' ),
        value: queue_max_size
      } << {
        key: format( '%s.%s.%s.%s.%s'   , @identifier, @normalized_service_name, mbean, 'queue', 'waiting' ),
        value: queue_size
      }

      result
    end


    def feeder_feeder( data = {} )

      result = []
      mbean  = 'Feeder'
      value  = data.dig('value')

      # defaults
      pending_events            = 0
      index_documents           = 0
      index_content_documents   = 0
      current_pending_documents = 0

      if( @mbean.checkBeanConsistency( mbean, data ) == true && value != nil )

        value = value.values.first

        pending_events            = value.dig('PendingEvents')
        index_documents           = value.dig('IndexDocuments')
        index_content_documents   = value.dig('IndexContentDocuments')
        current_pending_documents = value.dig('CurrentPendingDocuments')
      end

      result << {
        key: format( '%s.%s.%s.%s'   , @identifier, @normalized_service_name, mbean, 'pending_events' ),
        value: pending_events
      } << {
        key: format( '%s.%s.%s.%s'   , @identifier, @normalized_service_name, mbean, 'index_documents' ),
        value: index_documents
      } << {
        key: format( '%s.%s.%s.%s'   , @identifier, @normalized_service_name, mbean, 'index_content_documents' ),
        value: index_content_documents
      } << {
        key: format( '%s.%s.%s.%s'   , @identifier, @normalized_service_name, mbean, 'current_pending_documents' ),
        value: current_pending_documents
      }

      result
    end


    def feeder_transformed_blobcache_manager( data = {} )

      result    = []
      mbean     = 'TransformedBlobCacheManager'
      value     = data.dig('value')

      # defaults
      cache_size                  = 0   # set the cache size in bytes
      cache_level                 = 0   # cache level in bytes
      cache_initial_level         = 0   # initial cache level in bytes
      new_gen_cache_size          = 0   # cache size of new generation folder in bytes
      new_gen_cache_level         = 0   # cache level of the new generation in bytes
      new_gen_cache_initial_level = 0   # initial cache level of the new generation in bytes
      old_gen_cache_level         = 0   # cache level of the old generation in bytes
      old_gen_cache_initial_level = 0   # initial cache level of the old generation level in bytes
      fault_size_summary          = 0   # sum of sizes in bytes of all blobs faulted since system start
      fault_count                 = 0   # count of faults since system start
      recall_size_summary         = 0   # sum of sizes in bytes of all blobs recalled since system start
      recall_count                = 0   # count of recalls since system start
      rotate_count                = 0   # count of rotates since system start
      access_count                = 0   # count of accesses since system start

      if( @mbean.checkBeanConsistency( mbean, data ) == true && value != nil )

        value = value.values.first

        cache_size                  = value.dig('CacheSize')
        cache_level                 = value.dig('Level')
        cache_initial_level         = value.dig('InitialLevel')
        new_gen_cache_size          = value.dig('NewGenerationCacheSize')
        new_gen_cache_level         = value.dig('NewGenerationLevel')
        new_gen_cache_initial_level = value.dig('NewGenerationInitialLevel')
        old_gen_cache_level         = value.dig('OldGenerationLevel')
        old_gen_cache_initial_level = value.dig('OldGenerationInitialLevel')
        fault_size_summary          = value.dig('FaultSizeSum')
        fault_count                 = value.dig('FaultCount')
        recall_size_summary         = value.dig('RecallSizeSum')
        recall_count                = value.dig('RecallCount')
        rotate_count                = value.dig('RotateCount')
        access_count                = value.dig('AccessCount')
      end

      result << {
        key: format( '%s.%s.%s.%s.%s'   , @identifier, @normalized_service_name, mbean, 'cache', 'size' ),
        value: cache_size
      } << {
        key: format( '%s.%s.%s.%s.%s'   , @identifier, @normalized_service_name, mbean, 'cache', 'level' ),
        value: cache_level
      } << {
        key: format( '%s.%s.%s.%s.%s'   , @identifier, @normalized_service_name, mbean, 'cache', 'initial_level' ),
        value: cache_initial_level
      } << {
        key: format( '%s.%s.%s.%s.%s.%s', @identifier, @normalized_service_name, mbean, 'cache', 'new_gen', 'size' ),
        value: new_gen_cache_size
      } << {
        key: format( '%s.%s.%s.%s.%s.%s', @identifier, @normalized_service_name, mbean, 'cache', 'new_gen', 'level' ),
        value: new_gen_cache_level
      } << {
        key: format( '%s.%s.%s.%s.%s.%s', @identifier, @normalized_service_name, mbean, 'cache', 'new_gen', 'initial_level' ),
        value: new_gen_cache_initial_level
      } << {
        key: format( '%s.%s.%s.%s.%s.%s', @identifier, @normalized_service_name, mbean, 'cache', 'old_gen', 'size' ),
        value: old_gen_cache_level
      } << {
        key: format( '%s.%s.%s.%s.%s.%s', @identifier, @normalized_service_name, mbean, 'cache', 'old_gen', 'initial_level' ),
        value: old_gen_cache_initial_level
      } << {
        key: format( '%s.%s.%s.%s.%s'   , @identifier, @normalized_service_name, mbean, 'fault', 'count' ),
        value: fault_count
      } << {
        key: format( '%s.%s.%s.%s.%s'   , @identifier, @normalized_service_name, mbean, 'fault', 'size' ),
        value: fault_size_summary
      } << {
        key: format( '%s.%s.%s.%s.%s'   , @identifier, @normalized_service_name, mbean, 'recall', 'count' ),
        value: recall_count
      } << {
        key: format( '%s.%s.%s.%s.%s'   , @identifier, @normalized_service_name, mbean, 'recall', 'size' ),
        value: recall_size_summary
      } << {
        key: format( '%s.%s.%s.%s'      , @identifier, @normalized_service_name, mbean, 'rotate' ),
        value: rotate_count
      } << {
        key: format( '%s.%s.%s.%s'      , @identifier, @normalized_service_name, mbean, 'access' ),
        value: access_count
      }

      result
    end


    def feeder_background_feed( data = {} )

      result    = []
      mbean     = 'BackgroundFeed'
      value     = data.dig('value')

      parts     = data.dig('request','mbean').match( /.*type=(?<feed>(.*))/ )
      mbean     = parts['feed']
      mbean     = mbean.to_s.strip

      if( @mbean.checkBeanConsistency( mbean, data ) == true && value != nil )

        case mbean
        when /Admin.*/
          result << {
            key: format( '%s.%s.%s.%s'   , @identifier, @normalized_service_name, mbean, 'pending_contents' ),
            value: value.dig('NumberOfPendingContents')
          }
        else
          result << {
            key: format( '%s.%s.%s.%s'   , @identifier, @normalized_service_name, mbean, 'pending_contents' ),
            value: value.dig('CurrentPendingContents')
          }
        end
      end

      result
    end

  end
end
