
module CarbonData

  module Solr


    def solr_cache( mbean, data = {} )

      result    = []
      value     = data.dig('value')
      request   = data.dig('request')
      solr_mbean = data.dig('request', 'mbean' )
      solr_core  = solr_core( solr_mbean )

      # defaults
      warmup_time          = 0
      lookups              = 0
      evictions            = 0
      inserts              = 0
      hits                 = 0
      size                 = 0
      hitratio             = 0

      if( @mbean.checkBeanConsistency( mbean, data ) == true && value != nil )

        warmup_time          = value.dig('warmupTime')
        lookups              = value.dig('lookups')
        evictions            = value.dig('evictions')
        inserts              = value.dig('inserts')
        hits                 = value.dig('hits')
        size                 = value.dig('size')
        hitratio             = value.dig('hitratio')
      end

      result << {
        key: format( '%s.%s.%s.%s.%s', @identifier, @normalized_service_name, solr_core, mbean, 'warmupTime' ),
        value: warmup_time
      } << {
        key: format( '%s.%s.%s.%s.%s', @identifier, @normalized_service_name, solr_core, mbean, 'lookups' ),
        value: lookups
      } << {
        key: format( '%s.%s.%s.%s.%s', @identifier, @normalized_service_name, solr_core, mbean, 'evictions' ),
        value: evictions
      } << {
        key: format( '%s.%s.%s.%s.%s', @identifier, @normalized_service_name, solr_core, mbean, 'inserts' ),
        value: inserts
      } << {
        key: format( '%s.%s.%s.%s.%s', @identifier, @normalized_service_name, solr_core, mbean, 'hits' ),
        value: hits
      } << {
        key: format( '%s.%s.%s.%s.%s', @identifier, @normalized_service_name, solr_core, mbean, 'size' ),
        value: size
      } << {
        key: format( '%s.%s.%s.%s.%s', @identifier, @normalized_service_name, solr_core, mbean, 'hitratio' ),
        value: hitratio
      }

      result
    end


    def solr_query_result_cache( data = {} )

      solr_cache( 'QueryResultCache', data )
    end


    def solr_document_cache( data = {} )

      solr_cache( 'DocumentCache', data )
    end


    def solr_replication( data = {} )

      result    = []
      mbean     = 'Replication'
      value     = data.dig('value')
      request   = data.dig('request')
      solr_mbean = data.dig('request', 'mbean' )
      solr_core  = solr_core( solr_mbean )

      # defaults
      generation          = 0
      is_master           = 0
      is_slave            = 0
      index_version       = 0
      requests            = 0
      median_request_time = 0
      timeouts            = 0
      errors              = 0
      index_size          = 0

      if( @mbean.checkBeanConsistency( mbean, data ) == true && value != nil )

        generation          = value.dig('generation')
        index_version       = value.dig('indexVersion')
        generation          = value.dig('generation')
        requests            = value.dig('requests')
        median_request_time = value.dig('medianRequestTime')
        errors              = value.dig('errors')
        index_size          = value.dig('indexSize')
        is_master           = value.dig('isMaster')  || 1
        is_slave            = value.dig('isSlave')   || 0

        logger.debug(format( '-- SOLR -- %s --------------------------------------', solr_core))
        logger.debug("index_size: #{index_size} (#{index_size.class.to_s})")

        # ACHTUNG!
        # index_size ist irrsinnigerweise als human readable ausgeführt worden!
        index_size = index_size.gsub!( 'ytes','' ) if( index_size != nil && ( index_size.include?( 'bytes' ) ) )
        logger.debug("index_size: #{index_size} (#{index_size.class.to_s})")

        index_size         = Filesize.from( index_size ).to_i
        logger.debug("index_size: #{index_size} (#{index_size.class.to_s})")
        logger.debug('------------------------------------------------')
      end

      result << {
        key: format( '%s.%s.%s.%s.%s.%s', @identifier, @normalized_service_name, solr_core, mbean, 'index', 'size' ),
        value: index_size.to_s
      } << {
        key: format( '%s.%s.%s.%s.%s.%s', @identifier, @normalized_service_name, solr_core, mbean, 'index', 'version' ),
        value: index_version
      } << {
        key: format( '%s.%s.%s.%s.%s'   , @identifier, @normalized_service_name, solr_core, mbean, 'errors' ),
        value: errors
      } << {
        key: format( '%s.%s.%s.%s.%s'   , @identifier, @normalized_service_name, solr_core, mbean, 'requests' ),
        value: requests
      } << {
        key: format( '%s.%s.%s.%s.%s'   , @identifier, @normalized_service_name, solr_core, mbean, 'errors' ),
        value: errors
      }

      result
    end


    def solr_select( data = {} )

      result    = []
      mbean     = 'Select'
      value     = data.dig('value')
      request   = data.dig('request')
      solr_mbean = data.dig('request', 'mbean' )
      solr_core  = solr_core( solr_mbean )

      # defaults
      avg_requests_per_second = 0
      avg_time_per_request    = 0
      median_request_time     = 0
      requests                = 0
      timeouts                = 0
      errors                  = 0

      if( @mbean.checkBeanConsistency( mbean, data ) == true && value != nil )

        avg_requests_per_second = value.dig('avgRequestsPerSecond')
        avg_time_per_request    = value.dig('avgTimePerRequest')
        median_request_time     = value.dig('medianRequestTime')
        requests                = value.dig('requests')
        timeouts                = value.dig('timeouts')
        errors                  = value.dig('errors')
      end


      result << {
        key: format( '%s.%s.%s.%s.%s'   , @identifier, @normalized_service_name, solr_core, mbean, 'requests' ),
        value: requests
      } << {
        key: format( '%s.%s.%s.%s.%s'   , @identifier, @normalized_service_name, solr_core, mbean, 'timeouts' ),
        value: timeouts
      } << {
        key: format( '%s.%s.%s.%s.%s'   , @identifier, @normalized_service_name, solr_core, mbean, 'errors' ),
        value: errors
      } << {
        key: format( '%s.%s.%s.%s.%s.%s', @identifier, @normalized_service_name, solr_core, mbean, 'requestPerSecond', 'avg' ),
        value: avg_requests_per_second
      } << {
        key: format( '%s.%s.%s.%s.%s.%s', @identifier, @normalized_service_name, solr_core, mbean, 'timePerRequest', 'avg' ),
        value: avg_time_per_request
      } << {
        key: format( '%s.%s.%s.%s.%s.%s', @identifier, @normalized_service_name, solr_core, mbean, 'RequestTime', 'median' ),
        value: median_request_time
      }

      result
    end


    private
    def solr_core( mbean )

      regex = /
        ^                     # Starting at the front of the string
        solr\/                #
        (?<core>.+[a-zA-Z0-9]):  #
        (.*)                  #
        type=                 #
        (?<type>.+[a-zA-Z])   #
        $
      /x

      parts          = mbean.match( regex )

      format( 'core_%s', parts['core'].to_s.strip.tr( '. ', '' ).downcase )
    end

  end
end
