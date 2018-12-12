
class CMGrafana

  module CoreMedia

    module Templates

      # return valid template file name for service_name
      #
      # looks into the following directories:
      #  - #{@template_directory}/
      #  - #{@template_directory}/services/
      #
      def template_for_service( service_name )

        # logger.debug("template_for_service(#{service_name})")

        # TODO
        # look for '%s/%s.json'  and  '%s/services/%s.json'
        # first match wins

        template      = nil
        template_array = []
        template_array << "#{@template_directory}/#{service_name}.erb"
        template_array << "#{@template_directory}/cm-#{service_name}.erb"
        template_array << "#{@template_directory}/services/#{service_name}.erb"
        template_array << "#{@template_directory}/services/cm-#{service_name}.erb"

        logger.debug(template_array)

        template_array.each do |tpl|
          logger.debug(tpl)
          if( File.exist?( tpl ) )
            template = tpl
            break
          end
        end

        logger.warn( sprintf( 'no template for service %s found', service_name ) ) if( template.nil? )

        template
      end

      #
      #
      #
      def create_service_template( params )

        logger.debug("create_service_template( #{params} )")

        description               = params.dig(:description)
        service_name              = params.dig(:service_name)
        normalized_name           = params.dig(:normalized_name)
        service_template          = params.dig(:service_template)
        additional_template_paths = params.dig(:additional_template_paths) || []
        tomcat_dashboard_url      = params.dig(:tomcat_dashboard_url)
        memorypools_dashboard_url = params.dig(:memorypools_dashboard_url)
        mls_identifier            = @graphite_identifier
        slug                      = @slug
        graphite_identifier       = @graphite_identifier
        icinga_identifier         = graphite_identifier.gsub('.','_')
        short_hostname            = @short_hostname
        grafana_title             = format('%s - %s', slug, description )
        uuid                      = format('%s-%s', @dashboard_uuid, normalized_name ).downcase

        ## -------------------------------------------------------
        logger.debug( sprintf( '  service_name         \'%s\'', service_name ) )
        logger.debug( sprintf( '  description          \'%s\'', description ) )
        logger.debug( sprintf( '  normalized_name      \'%s\'', normalized_name ) )
        logger.debug( sprintf( '  service_template     \'%s\'', service_template ) )
        logger.debug( sprintf( '  additional_template_paths    \'%s\'', additional_template_paths ) )
        logger.debug( sprintf( '  slug                 \'%s\'', slug ) )
        logger.debug( sprintf( '  graphite_identifier  \'%s\'', graphite_identifier ) )
        logger.debug( sprintf( '  short_hostname       \'%s\'', short_hostname ) )
        logger.debug( sprintf( '  mls_identifier       \'%s\'', mls_identifier ) )
        logger.debug( sprintf( '  tomcat_dashboard_url \'%s\'', tomcat_dashboard_url ) )
        logger.debug( sprintf( '  icinga_identifier    \'%s\'', icinga_identifier ) )
        logger.debug( sprintf( '  grafana_title        \'%s\'', grafana_title ) )
        logger.debug( sprintf( '  uuid                 \'%s\'', uuid ) )
        ## -------------------------------------------------------

        logger.info( sprintf( '  - creating dashboard for \'%s\'', service_name ) )

        if( service_name == 'replication-live-server' )

          logger.info( '    search Master Live Server IOR for the Replication Live Server' )

          # 'Server'
          ip, short, fqdn = ns_lookup(@short_hostname)

          logger.debug("RLS: #{@short_hostname} - #{ip} | #{short} | #{fqdn}")

          bean = @mbean.bean( fqdn, service_name, 'Replicator' )

          if( bean != nil && bean != false )

            value = bean.dig( 'value' )
            unless( value.nil? )

              value = value.values.first

              mls = value.dig( 'MasterLiveServer', 'host' )

              unless( mls.nil? )

                ip, short, fqdn = ns_lookup(mls)

                dns = @database.dnsData( ip: ip, short: short, fqdn: fqdn )

                if( dns.nil? )
                  logger.warn(format('no DNS Entry for the Master Live Server \'%s\' found!', mls))
                else

                  real_ip    = dns.dig('ip')
                  real_short = dns.dig('name')
                  real_fqdn  = dns.dig('fqdn')

                  if( @short_hostname == real_short )
                    logger.info( '    the Master Live Server runs on the same host as the Replication Live Server' )
                  else
                    mls_identifier = real_fqdn

                    identifier     = @database.config( ip: real_ip, short: real_short, fqdn: real_fqdn, key: 'graphite_identifier' )

                    # found custom config
                    unless( identifier.nil? )
                      mls_identifier = identifier.dig( 'graphite_identifier' )

                      unless( mls_identifier.nil? )
                        mls_identifier.to_s
                        logger.info( "    use custom storage identifier from config: '#{mls_identifier}'" )
                      end
                    end
                  end
                end
              end
            end
          end
        end

        template_file = File.read( service_template )

        template = ERB.new(template_file, nil, '-' )
        template = template.result(binding)

        template_json = JSON.parse( template ) if( template.is_a?( String ) )

        rows         = template_json.dig( 'dashboard', 'rows' )

        unless( rows.nil? )

          logger.debug("additional_template_paths: #{additional_template_paths}")

          additional_template_paths.each do |additional_template|

            logger.debug(additional_template)

            next if( additional_template.nil? )
            next unless( File.exist?( additional_template ) )

            additional_template_file = File.read( additional_template )
            additional_template_json = JSON.parse( additional_template_file )

            template_json['dashboard']['rows'] = additional_template_json['dashboard']['rows'].concat(rows) if( additional_template_json['dashboard']['rows'] )
          end
        end

        # TODO
        # switch to gem
        json  = add_annotations(template_json)
        json  = JSON.parse( json ) if( json.is_a?(String) )
        title = json.dig('dashboard','title')

        logger.debug( "create dashboard: #{title} / #{json.class} / #{@folder_uuid}" )

        response = {}
        begin
          response         = create_dashboard( title: title, dashboard: json, folderId: @folder_uuid )
        rescue => error
          logger.error("------------------------------------------------")
          logger.error(error)
          logger.error("------------------------------------------------")
          logger.debug(JSON.pretty_generate(json))
          logger.error("------------------------------------------------")
        end

        response_status  = response.dig('status').to_i
        response_message = response.dig('message')

        logger.warn( format('template can\'t be add: [%s] %s', response_status, response_message ) ) if( response_status != 200 )

        {
          status: response_status,
          message: response,
          slug: response.dig('slug'),
          uid: response.dig('uid'),
          url: response.dig('url')
        }
      end

      #
      #
      #
      def overview_template_rows(services = [])

        rows = []
        dir  = []
        srv  = []

        services.each do |s|
          srv << remove_postfix( s )
        end

        regex = /
          ^                       # Starting at the front of the string
          \d\d-                   # 2 digit
          (?<service>.+[a-zA-Z0-9])  # service name
          \.erb                   #
        /x

        Dir.chdir( sprintf( '%s/overview', @template_directory )  )

        dirs = Dir.glob( '**.erb' ).sort

        dirs.each do |f|
          if( f =~ regex )
            part = f.match(regex)
            dir << part['service'].to_s.strip
          end
        end

        # TODO
        # add overwriten templates!
        intersect = dir & srv

        intersect.each do |service|
          template = Dir.glob( sprintf( '%s/overview/**%s.erb', @template_directory, service ) ).first
          rows << File.read( template ) if( File.exist?( template ) )
        end

        rows
      end

      #
      #
      #
      def normalize_template(params = {})

        logger.debug("normalize_template(params = {})")

        template                  = params.dig(:template)
        service_name              = params.dig(:service_name)
        description               = params.dig(:description)
        normalized_name           = params.dig(:normalized_name)
        slug                      = params.dig(:slug)
        graphite_identifier       = params.dig(:graphite_identifier)
        short_hostname            = params.dig(:short_hostname)
        mls_identifier            = params.dig(:mls_identifier)
        tomcat_dashboard_url      = params.dig(:tomcat_dashboard_url)
        memorypools_dashboard_url = params.dig(:memorypools_dashboard_url)
        icinga_identifier         = graphite_identifier.gsub('.','_')
        uuid                      = format( '%s-%s', @dashboard_uuid, service_name )

        grafana_title = format('%s - %s', slug, description )

        ## -------------------------------------------------------
        #logger.debug( sprintf( '  service_name         \'%s\'', service_name ) )
        #logger.debug( sprintf( '  description          \'%s\'', description ) )
        #logger.debug( sprintf( '  normalized_name      \'%s\'', normalized_name ) )
        #logger.debug( sprintf( '  slug                 \'%s\'', slug ) )
        #logger.debug( sprintf( '  uuid                 \'%s\'', uuid ) )
        #logger.debug( sprintf( '  graphite_identifier  \'%s\'', graphite_identifier ) )
        #logger.debug( sprintf( '  short_hostname       \'%s\'', short_hostname ) )
        #logger.debug( sprintf( '  mls_identifier       \'%s\'', mls_identifier ) )
        #logger.debug( sprintf( '  tomcat_dashboard_url \'%s\'', tomcat_dashboard_url ) )
        #logger.debug( sprintf( '  icinga_identifier    \'%s\'', icinga_identifier ) )
        #logger.debug( sprintf( '  grafana_title        \'%s\'', grafana_title ) )
        ## -------------------------------------------------------

        return false if( template.nil? )

        template = JSON.generate(template) if( template.is_a?( Hash ) )

        # use ruby internal template engine ERB
        template = ERB.new(template, nil, '-' )
        template = template.result(binding)

        begin
          template = JSON.parse( template ) if( template.is_a?( String ) )
        rescue => error
          logger.error(error)
          logger.debug(template)
        end

        template = expand_tags( dashboard: template, additional_tags: @additional_tags ) if( @additional_tags.count > 0 )
        template = JSON.parse( template ) if( template.is_a?( String ) )

        # now we must recreate *all* panel IDs for an propper import
        #
        regenerate_template_ids( template )
      end

      #
      #
      #
      def overview_host_header(host)

        host_header = %(
          {
            "collapse": false,
            "height": "35",
            "panels": [
              {
                "content": "<h4>#{host}</h4>",
                "id": 111,
                "mode": "html",
                "span": 12,
                "transparent": true,
                "type": "text"
              }
            ],
            "repeat": null,
            "repeatIteration": null,
            "repeatRowId": null,
            "showTitle": false,
            "title": "#{host}",
            "titleSize": "h5"
          }
        )

      end



      def create_license_template()

      end


    end

  end
end
