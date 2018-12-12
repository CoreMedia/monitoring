module CarbonData

  module Cae

    def cae_dataview_factory( data = {} )

      result    = []
      mbean     = 'DataViewFactory'
      value     = data.dig('value')

      # defaults
      lookups      = 0
      computed     = 0
      cached       = 0
      invalidated  = 0
      evicted      = 0
      active_time   = 0
      total_time    = 0

      if( @mbean.checkBeanConsistency( mbean, data ) == true && value != nil )

        value = value.values.first

        lookups      = value.dig('NumberOfDataViewLookups')
        computed     = value.dig('NumberOfComputedDataViews')
        cached       = value.dig('NumberOfCachedDataViews')
        invalidated  = value.dig('NumberOfInvalidatedDataViews')
        evicted      = value.dig('NumberOfEvictedDataViews')
        active_time  = value.dig('ActiveTimeOfComputedDataViews')
        total_time   = value.dig('TotalTimeOfComputedDataViews')

      end

      result << {
        key: format( '%s.%s.%s.%s', @identifier, @normalized_service_name, mbean, 'lookups' ),
        value: lookups
      } << {
        key: format( '%s.%s.%s.%s', @identifier, @normalized_service_name, mbean, 'computed' ),
        value: computed
      } << {
        key: format( '%s.%s.%s.%s', @identifier, @normalized_service_name, mbean, 'cached' ),
        value: cached
      } << {
        key: format( '%s.%s.%s.%s', @identifier, @normalized_service_name, mbean, 'invalidated' ),
        value: invalidated
      } << {
        key: format( '%s.%s.%s.%s', @identifier, @normalized_service_name, mbean, 'evicted' ),
        value: evicted
      } << {
        key: format( '%s.%s.%s.%s', @identifier, @normalized_service_name, mbean, 'activeTime' ),
        value: active_time
      } << {
        key: format( '%s.%s.%s.%s', @identifier, @normalized_service_name, mbean, 'totalTime' ),
        value: total_time
      }

      result
    end


    def cae_cache_classes( key, data = {} )

      result      = []
      mbean       = 'CacheClasses'
      value       = data.dig('value')
      status      = data.dig('status') || 404

      # we habe more CacheClasses Types:
      #   com.coremedia:CacheClass=\"com.coremedia.blueprint...\"
      #
      #   com.coremedia:CacheClass=\"com.coremedia.livecontext.ecommerce...\"
      #
      # the livecontext.ecommerce Caches are only available with an ecommerce system
      #
      return if( status == 404 )

      cache_class  = key.gsub( mbean, '' )

      data['service'] = @normalized_service_name

      # defaults
      capacity  = 0
      evaluated = 0
      evicted   = 0
      inserted  = 0
      removed   = 0
      level     = 0
      miss_rate  = 0

      if( @mbean.checkBeanConsistency( key, data ) == true && value != nil )

        value = value.values.first

        capacity  = value.dig('Capacity')
        evaluated = value.dig('Evaluated')
        evicted   = value.dig('Evicted')
        inserted  = value.dig('Inserted')
        removed   = value.dig('Removed')
        level     = value.dig('Level')
        miss_rate  = value.dig('MissRate')
      end

      result << {
        key: format( '%s.%s.%s.%s.%s', @identifier, @normalized_service_name, mbean, cache_class, 'evaluated' ),
        value: evaluated
      } << {
        key: format( '%s.%s.%s.%s.%s', @identifier, @normalized_service_name, mbean, cache_class, 'evicted' ),
        value: evicted
      } << {
        key: format( '%s.%s.%s.%s.%s', @identifier, @normalized_service_name, mbean, cache_class, 'inserted' ),
        value: inserted
      } << {
        key: format( '%s.%s.%s.%s.%s', @identifier, @normalized_service_name, mbean, cache_class, 'removed' ),
        value: removed
      } << {
        key: format( '%s.%s.%s.%s.%s', @identifier, @normalized_service_name, mbean, cache_class, 'level' ),
        value: level
      } << {
        key: format( '%s.%s.%s.%s.%s', @identifier, @normalized_service_name, mbean, cache_class, 'capacity' ),
        value: capacity
      } << {
        key: format( '%s.%s.%s.%s.%s', @identifier, @normalized_service_name, mbean, cache_class, 'missRate' ),
        value: miss_rate
      }

      result
    end
  end
end

