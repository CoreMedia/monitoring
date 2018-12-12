module CarbonData

  module Clients

    def clients_cap_connection( data = {} )

      result    = []
      mbean     = 'CapConnection'
      value     = data.dig('value')

      # defaults
      blob_cache_size    = 0
      blob_cache_level   = 0
      blob_cache_faults  = 0
      blob_cache_percent = 0
      heap_cache_size    = 0
      heap_cache_level   = 0
      heap_cache_faults  = 0
      heap_cache_percent = 0
      su_sessions        = 0

      # defines:
      #   0: false
      #   1: true
      #  -1: N/A
      open               = -1
      content_repository = -1
      workflow_repository = -1

      if( @mbean.checkBeanConsistency( mbean, data ) == true && value != nil )

        value = value.values.first

        blob_cache_size    = value.dig('BlobCacheSize')
        blob_cache_level   = value.dig('BlobCacheLevel')
        blob_cache_faults  = value.dig('BlobCacheFaults')
        blob_cache_percent = ( 100 * blob_cache_level.to_i / blob_cache_size.to_i ).to_i

        heap_cache_size    = value.dig('HeapCacheSize')
        heap_cache_level   = value.dig('HeapCacheLevel')
        heap_cache_faults  = value.dig('HeapCacheFaults')
        heap_cache_percent = ( 100 * heap_cache_level.to_i / heap_cache_size.to_i ).to_i

        su_sessions        = value.dig('NumberOfSUSessions')

        open_connections   = value.dig('Open')
        open_connections   = open_connections ? 1 : 0 unless( open_connections.nil? )

        content_repository = value.dig('ContentRepositoryAvailable')
        content_repository = content_repository ? 1 : 0 unless( content_repository.nil? )

        workflow_repository = value.dig('WorkflowRepositoryAvailable')
        workflow_repository = workflow_repository ? 1 : 0 unless( workflow_repository.nil? )

      end


      result << {
        key: format( '%s.%s.%s.%s.%s.%s', @identifier, @normalized_service_name, mbean, 'blob', 'cache', 'size' ),
        value: blob_cache_size
      } << {
        key: format( '%s.%s.%s.%s.%s.%s', @identifier, @normalized_service_name, mbean, 'blob', 'cache', 'used' ),
        value: blob_cache_level
      } << {
        key: format( '%s.%s.%s.%s.%s.%s', @identifier, @normalized_service_name, mbean, 'blob', 'cache', 'fault' ),
        value: blob_cache_faults
      } << {
        key: format( '%s.%s.%s.%s.%s.%s', @identifier, @normalized_service_name, mbean, 'blob', 'cache', 'used_percent' ),
        value: blob_cache_percent
      } << {
        key: format( '%s.%s.%s.%s.%s.%s', @identifier, @normalized_service_name, mbean, 'heap', 'cache', 'size' ),
        value: heap_cache_size
      } << {
        key: format( '%s.%s.%s.%s.%s.%s', @identifier, @normalized_service_name, mbean, 'heap', 'cache', 'used' ),
        value: heap_cache_level
      } << {
        key: format( '%s.%s.%s.%s.%s.%s', @identifier, @normalized_service_name, mbean, 'heap', 'cache', 'fault' ),
        value: heap_cache_faults
      } << {
        key: format( '%s.%s.%s.%s.%s.%s', @identifier, @normalized_service_name, mbean, 'heap', 'cache', 'used_percent' ),
        value: heap_cache_percent
      } << {
        key: format( '%s.%s.%s.%s.%s'   , @identifier, @normalized_service_name, mbean, 'su_sessions', 'sessions' ),
        value: su_sessions
      } << {
        key: format( '%s.%s.%s.%s'      , @identifier, @normalized_service_name, mbean, 'open' ),
        value: open_connections
      }

      unless( content_repository == -1 )
        result << {
          key: format( '%s.%s.%s.%s.%s'      , @identifier, @normalized_service_name, mbean, 'ContentRepository', 'available' ),
          value: content_repository
        }
      end
      unless( workflow_repository == -1 )
        result << {
          key: format( '%s.%s.%s.%s.%s'      , @identifier, @normalized_service_name, mbean, 'WorkflowRepository', 'available' ),
          value: workflow_repository
        }
      end

      result
    end


    def clients_memory_pool( key, data = {} )

      result  = []
      mbean   = 'MemoryPool'
      value   = data.dig('value')
      request = data.dig('request')
      bean    = data.dig('request', 'mbean')
      usage   = data.dig('value', 'Usage')

      # defaults
      init      = 0
      max       = 0
      used      = 0
      committed = 0
      percent   = 0
      mbean_name = @mbean.beanName( bean )
      mbean_name = mbean_name.strip.tr( ' ', '_' )

      if( @mbean.checkBeanConsistency( mbean, data ) == true && value != nil && usage != nil )

        init      = usage.dig('init')
        max       = usage.dig('max')
        used      = usage.dig('used')
        committed = usage.dig('committed')

        percent   = ( 100 * used / committed )
        percent   = ( 100 * used / max ) if( max != -1 )
      end

      result << {
        key: format( '%s.%s.%s.%s.%s', @identifier, @normalized_service_name, mbean, mbean_name, 'init' ),
        value: init
      } << {
        key: format( '%s.%s.%s.%s.%s', @identifier, @normalized_service_name, mbean, mbean_name, 'committed' ),
        value: committed
      } << {
        key: format( '%s.%s.%s.%s.%s', @identifier, @normalized_service_name, mbean, mbean_name, 'max' ),
        value: max
      } << {
        key: format( '%s.%s.%s.%s.%s', @identifier, @normalized_service_name, mbean, mbean_name, 'used_percent' ),
        value: percent
      } << {
        key: format( '%s.%s.%s.%s.%s', @identifier, @normalized_service_name, mbean, mbean_name, 'used' ),
        value: used
      }

      result
    end


  end

end
