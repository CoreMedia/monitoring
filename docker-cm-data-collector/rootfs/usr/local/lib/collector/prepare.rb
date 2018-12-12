
require 'mini_cache'

module DataCollector

  class Prepare

    include Logging

    def initialize( settings )

      redis          = settings.dig(:redis)
      config         = settings.dig(:config)

      @cfg           = config.clone unless( config.nil? )
      @redis         = redis.clone  unless( redis.nil? )
      @cache         = MiniCache::Store.new()
    end


    def merge_solr_cores( metrics, cores = [] )

#       logger.debug("merge_solr_cores( #{metrics}, #{cores} )")

      work = []

      logger.error( "metrics or cores are empty!?" ) unless( metrics.is_a?(Array) || cores.is_a?(Array) || metrics.count == 0 || cores.count == 0 )

      return work unless( metrics.is_a?(Array) || cores.is_a?(Array) || metrics.count == 0 || cores.count == 0 )

      cores.each do |core|

        metric = Marshal.load( Marshal.dump( metrics ) )

        metric.each do |m|
          mb = m.dig('mbean')
          mb.sub!( '%CORE%', core )
        end

        work.push( metric )
      end

      work.flatten!
    end

    # merge Data between Property Files and discovered Services
    # creates mergedHostData.json for every Node
    def build_merged_data( params )

      #logger.debug( "build_merged_data( #{params} )" )

      short = params.dig(:hostname)
      fqdn  = params.dig(:fqdn)
      data  = params.dig(:data)
      force = params.dig(:force) || false

      return { status: 404, message: 'no hostname given' } if( fqdn.nil? )
      return { status: 404, message: 'no discovery data given' } if( data.nil? || data == false || data.count() == 0 )

      # check our cache for prepared data
      #
      prepared   = @cache.get( fqdn )

      if( force == false )
        return { status: 200, message: 'prepared data already created' } unless( prepared.nil? )
      end
      #
      # ----------------------------------

      start = Time.now

      #
      known_applications = @cfg.known_applications.clone

      redis_data = []

      data.each do |service,payload|

        unless( payload.is_a?( Hash ) )
          logger.error( " => #{service} - wrong format for payload!" )
          next
        end

        result      = merge_data( service.to_s, known_applications, payload )

        redis_data << { service.to_s => result }
      end

      redis_data = redis_data.deep_string_keys

      # http://stackoverflow.com/questions/11856407/rails-mapping-array-of-hashes-onto-single-hash
      # mapping array of hashes onto single hash
      redis_data = redis_data.reduce( {} , :merge )
      redis_data_keys          = redis_data.keys.sort
      redis_data_keys_count    = redis_data_keys.count

      key = redis_data_keys.clone
      key = redis_data_keys.to_s if( redis_data_keys.is_a?(Array) )

      redis_data_keys_checksum = Digest::MD5.hexdigest( key )

      validate_data = { prepared: true, fqdn: fqdn, count: redis_data_keys_count, keys: redis_data_keys, checksum: redis_data_keys_checksum }

      # this part is needed by
      #   DataCollector::Tools.config_data()
      @redis.createMeasurements( short: short, fqdn: fqdn, data: redis_data )

      @cache.set( fqdn, 'prepared', expires_in: 320 )
      @cache.set( format( '%s-validate', fqdn ) , expires_in: 320 ) { MiniCache::Data.new( validate_data ) }

      finish = Time.now
      logger.info( sprintf( 'build prepared data in %s seconds', (finish - start).round(2) ) )

      return { status: 200 }
    end


    def merge_data( service, applications, data = {} )

#       logger.debug( "merge_data( '#{service}', applications (#{applications.class} | #{applications.size}), data (#{data.class} | #{data.size}) )" )

      metrics_tomcat     = applications.dig('tomcat')      # standard metrics for Tomcat

      return {} if( metrics_tomcat.nil? )

      configured_application = applications.keys.sort

      # configured applications in cm-application.yaml
      # logger.debug( "configured applications: #{configured_application} (#{configured_application.class})" )
      # application configuration in cm-service.yaml
      # logger.debug( "data                   : #{data} (#{data.class})")

      return {} if( data.nil? || data.count() == 0 )

      if( data.dig(:data).nil? )
        application = data.dig('application')
        solr_cores  = data.dig('cores') || []
        metrics     = data.dig('metrics')
      end

      logger.debug( "service: '#{service}'" )
#       logger.debug( "application: '#{application}'" )
#       logger.debug( "solr_cores : '#{solr_cores}'" )

      data['metrics'] ||= []

      if( configured_application.include?( service ) )

        # found entry in cm-service.yml
        #
        logger.debug( "found '#{service}' in cm-service.yml" )

        _tomcat      = metrics_tomcat.dig('metrics')
        _application = applications.dig( service, 'metrics' )

        logger.debug( format( '  add %2d tomcat metrics from cm-application.yml', _tomcat.count ) )
        logger.debug( format( '  add %2d application metrics from cm-application.yml', _application.count ) )

        data['metrics'].push( _tomcat )
        data['metrics'].push( _application )
      end

      unless( application.nil? )

        _tomcat      = metrics_tomcat.dig('metrics')
        logger.debug( format( '  add %2d tomcat metrics from cm-application.yml', _tomcat.count ) )

        data['metrics'].push( _tomcat )

        application.each do |a|

          unless( applications.dig( a ).nil? )

            application_metrics = applications.dig( a, 'metrics' )

            if( solr_cores.is_a?(Array) && solr_cores.count != 0 )

              solr_cores_metrics = merge_solr_cores( application_metrics , solr_cores )

              logger.debug( format( '  add %2d solr core metrics', solr_cores_metrics.count ) )

              data['metrics'].push( solr_cores_metrics )
            end

            logger.debug( format( '  add %2d additional application metrics: %s', application_metrics.count, a ) )
            data['metrics'].push( application_metrics )
          end
        end

      end

      data['metrics'].compact!   # remove 'nil' from array
      data['metrics'].flatten!   # clean up and reduce depth
      # remove unneeded solr templates
      data['metrics'].delete_if { |key| key['mbean'].match( '%CORE%' ) } if( service =~ /solr-/ )
      data['metrics'].uniq!      # remove doubles

      #mbeans = data['metrics'].map {|x| x['mbean'] }
      #logger.debug( JSON.pretty_generate mbeans ) if( service =~ /solr-/ )
      # logger.debug( data['metrics'].count )
      # logger.debug( '----------------------------------------------------------------------')

      return data
    end


    def valid_data( fqdn )

      logger.debug( "valid_data( #{fqdn} )" )

      return { count: 0, checksum: '', keys: '' } if( !fqdn.is_a?(String) || fqdn.nil? )

      data  = @cache.get( format( '%s-validate', fqdn ) ) || nil
      #logger.debug( "valid_data: '#{data}' (#{data.class})" )

      return { count: 0, checksum: '', keys: '' } if( data.nil? )

      count    = data.dig(:count)    || 0
      checksum = data.dig(:checksum) || ''
      keys     = data.dig(:keys)     || ''

      { count: count, checksum: checksum, keys: keys }
    end


  end

end

