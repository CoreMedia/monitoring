
module DataCollector

  class Config

    include Logging

    attr_accessor :config
    attr_accessor :known_applications
    attr_accessor :service_config

    def initialize( settings )

      application_config  = settings.dig( :application )
      service_config      = settings.dig( :service )

      @config             = nil
      @known_applications = nil
      @service_config     = nil

      application_config_file  = File.expand_path( application_config )
      service_config_file      = File.expand_path( service_config )

      logger.debug( format( 'read config file: %s', service_config_file ) )
      begin
        if( File.exist?( service_config_file ) )
          @service_config = YAML.load_file( service_config_file )
        else
          logger.error( sprintf( 'service config file %s not found!', service_config_file ) )
        end
      rescue => e
        logger.error(e)
      end

      logger.debug( format( 'read config file: %s', application_config_file ) )
      begin
        if( File.exist?( application_config_file ) )
          @config      = YAML.load_file( application_config_file )
          @known_applications = @config.dig( 'jolokia', 'applications' )
        else
          logger.error( sprintf( 'Application Config File %s not found!', application_config_file ) )
          raise( sprintf( 'Application Config File %s not found!', application_config_file ) )
        end
      rescue => e
        logger.error(e)
      end
    end
  end
end
