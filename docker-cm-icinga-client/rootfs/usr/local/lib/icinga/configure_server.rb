
require 'yaml'

class CMIcinga2 < Icinga2::Client

  module ServerConfiguration

    public

    def read_config_file( params )

      logger.debug( "read_config_file( #{params} )" )

      config_file = params.dig(:config_file)
      config_file = File.expand_path( config_file )
      config = nil

      result = []

      if( !config_file.nil? && File.file?(config_file) )

        begin

          config = YAML.load_file( config_file )

        rescue Exception

          logger.error( 'wrong result (no yaml)')
          logger.error( "#{$!}" )

          raise( 'no valid yaml File' )
        end
      else
        logger.error( sprintf( 'Config File %s not found!', config_file ) )
      end

      config
    end

    def configure_server( params )

      logger.debug( "configure_server( #{params} )" )

      config_file = params.dig(:config_file)
      config_file = File.expand_path( config_file )
      config = read_config_file( params )

      result = []

      icinga2_available = false
      retries ||= 1

      while( icinga2_available == false || retries >= 20 )

        logger.debug(format('try to create the icinga2 connection (%d)', retries))
        begin
          icinga2_available = available?
        rescue => error
          logger.error(error)
        end
        retries += 1
        sleep( 5 )
      end

      raise( format( 'can\'t create a valid connection to the icinga master \'%s\'', @icinga_host ) ) if( icinga2_available == false )

      unless( config.nil? )

        logger.info( format( 'configure server \'%s\'', @icinga_host ) )

        groups          = config.select { |x| x == 'groups' }.values
        users           = config.select { |x| x == 'users' }.values
        configuration_packages = config.select { |x| x == 'configuration_packages' }.values
#         service_groups  = config.select { |x| x == 'service_groups' }.values
#         host_groups     = config.select { |x| x == 'host_groups' }.values

        raise ArgumentError.new(format( 'groups must be an Array, given an %s', groups.class.to_s ) ) unless( groups.is_a?(Array) )
        raise ArgumentError.new(format( 'users must be an Array, given an %s', users.class.to_s ) ) unless( users.is_a?(Array) )
        raise ArgumentError.new(format( 'configuration_packages must be an Array, given an %s', configuration_packages.class.to_s ) ) unless( configuration_packages.is_a?(Array) )

#         raise ArgumentError.new(format( 'service_groups must be an Array, given an %s', service_groups.class.to_s ) ) unless( service_groups.is_a?(Array) )
#         raise ArgumentError.new(format( 'host_groups must be an Array, given an %s', host_groups.class.to_s ) ) unless( host_groups.is_a?(Array) )

        result << icinga_groups( groups )
        result << icinga_users( users )
        result << icinga_configuration_packages(configuration_packages)
#         result << icinga_service_groups( service_groups )
#         result << icinga_host_groups( host_groups )

      end
#       logger.debug( JSON.pretty_generate( result ) )

      result
    end



    def icinga_groups( params )

      if( params.count >= 1 )

        result = []
        params.each do |p|

          p.each do |k,v|

            v = JSON.parse(v) if( v.is_a?(String) )

            group_name = k
            display_name = v.dig('display_name') || group_name

            unless( exists_usergroup?( group_name ) )

              logger.info( format('create group: %s (%s)', group_name, display_name ) )
              # create group
              result << add_usergroup( user_group: group_name, display_name: display_name )
            end

          end
        end

        result
      end
    end


    def icinga_users( params )

      if( params.count >= 1 )

        result = []

        params.each do |p|

          p.each do |k,v|

            v = JSON.parse(v) if( v.is_a?(String) )

            user_name    = k
            display_name = v.dig('display_name') || user_name
            email        = v.dig('email')
            pager        = v.dig('pager')
            groups       = v.dig('groups') || []
            enable_notifications = v.dig('enable_notifications')

            enable_notifications = enable_notifications.to_s.eql?('true') ? true : false

            unless( exists_user?( user_name ) )

              logger.info( format('create user: %s (%s)', user_name, display_name ) )
              logger.info( format( '  - as group member for: %s', groups.join(', ') ) )

              groups.each do |g|

                unless( exists_usergroup?( g ) )
                  logger.warn( format( '  => group %s is not present. i must create them first', g ) )

                  result << add_usergroup( user_group: g, display_name: g )
                end

              end


              # pflichtfelder
              options = {
                user_name: user_name,
                display_name: display_name,
                email: email,
                groups: groups
              }

              # optionaler kram
              options['enable_notifications'] = true if( enable_notifications )
              options['pager'] = pager unless( pager.nil? )

              logger.debug( options )

              # create user
              result << add_user( options )
            end

          end
        end

        result
      end
    end


    def icinga_configuration_packages( params )

      if( params.count >= 1 )

        result = []
        params.each do |p|

          p.each do |k,v|

            v = JSON.parse(v) if( v.is_a?(String) )

            package_type = k
#             display_name = v.dig('display_name') || group_name
#
#             unless( exists_usergroup?( group_name ) )
#
#               logger.info( format('create group: %s (%s)', group_name, display_name ) )
#               # create group
#               result << add_usergroup( user_group: group_name, display_name: display_name )
#            end

          end

        end
      end
    end

    def icinga_service_groups( params )

      if( params.count >= 1 )

        result = []
        params.each do |p|

          p.each do |k,v|

            v = JSON.parse(v) if( v.is_a?(String) )

            group_name = k
            display_name = v.dig('display_name') || group_name
            notes = v.dig('notes')
            assign  = v.dig('assign')
            ignore  = v.dig('ignore')

            unless( exists_servicegroup?( group_name ) )

              logger.info( format('create service group: %s (%s)', group_name, display_name ) )

              options = {
                service_group: group_name,
                display_name: display_name
              }

              options['notes'] ||= notes unless( notes.nil? )

              logger.debug( options )

              result << add_servicegroup( options )
            end

          end
        end

        result
      end
    end

    def icinga_host_groups( params )

      if( params.count >= 1 )

        result = []
        params.each do |p|

          p.each do |k,v|

            v = JSON.parse(v) if( v.is_a?(String) )

            group_name = k
            display_name = v.dig('display_name') || group_name
            notes = v.dig('notes')
            assign  = v.dig('assign')

            unless( exists_hostgroup?( group_name ) )

              logger.info( format('create host group: %s (%s)', group_name, display_name ) )

              options = {
                host_group: group_name,
                display_name: display_name
              }

              options['notes'] ||= notes unless( notes.nil? )

              logger.debug( options )

#               result << add_servicegroup( service_group: group_name, display_name: display_name )
            end

          end
        end

        result
      end



    end

  end
end
