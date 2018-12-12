
class CMGrafana

  module CoreMedia

    module Annotations

      # add standard annotations to all Templates
      #
      #
      def add_annotations(template_json)

        # color-picker: https://www.w3schools.com/colors/colors_picker.asp
        #
        # - host (created / destroyed)   : green     #33cc33
        # - monitoring (added / removed) : yellow    #e6e600
        # - loadtest                     : orange    #ff9933
        # - deployment                   :           #8080ff
        # - contentimport                : blue      #0099ff

        # add or overwrite annotations
        annotations = %(
          {
            "list": [
              {
                "datasource": "-- Grafana --",
                "enable": true,
                "hide": false,
                "iconColor": "#33cc33",
                "limit": 10,
                "name": "Host created / destroyed",
                "showIn": 0,
                "tags": [ "<%= short_hostname %>", "host" ],
                "type": "tags"
              },
              {
                "datasource": "-- Grafana --",
                "enable": true,
                "hide": false,
                "iconColor": "#e6e600",
                "limit": 10,
                "name": "Monitoring added / removed",
                "showIn": 0,
                "tags": [ "<%= short_hostname %>", "monitoring" ],
                "type": "tags"
              },
              {
                "datasource": "-- Grafana --",
                "enable": true,
                "hide": false,
                "iconColor": "#ff9933",
                "limit": 10,
                "name": "Load Tests",
                "showIn": 0,
                "tags": [ "<%= short_hostname %>", "loadtest" ],
                "type": "tags"
              },
              {
                "datasource": "-- Grafana --",
                "enable": true,
                "hide": false,
                "iconColor": "#8080ff",
                "limit": 10,
                "name": "Deployments",
                "showIn": 0,
                "tags": [ "<%= short_hostname %>", "deployment" ],
                "type": "tags"
              },
              {
                "datasource": "-- Grafana --",
                "enable": true,
                "hide": false,
                "iconColor": "#0099ff",
                "limit": 10,
                "name": "Content Import",
                "showIn": 0,
                "tags": [ "<%= short_hostname %>", "contentimport" ],
                "type": "tags"
              }
            ]
          }
        )

        short_hostname           = @short_hostname
        renderer = ERB.new(annotations)
        template = renderer.result(binding)
        annotations = JSON.parse( template ) if( template.is_a?( String ) )

        template_json = JSON.parse( template_json ) if( template_json.is_a?( String ) )
        annotation    = template_json.dig( 'dashboard', 'annotations' )

#         logger.debug( "annotation: #{annotation.size} #{annotation.class.to_s}" )

        begin
          template_json['dashboard']['annotations'] = annotations unless( annotation.nil? )
        rescue => error
          logger.error( error )
        end

        template_json
      end
    end
  end
end

