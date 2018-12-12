module Monitoring

  module Future

    # -- FUTURE ---------------------------------------------------------------------------
    #

    def addGrafanaGroupOverview( hosts, force = false )

      grafanaResult = @grafana.addGroupOverview( hosts, force )
  #    grafanaStatus = grafanaResult[:status]

      return {
        :status  => grafanaResult[:status],
        :message => grafanaResult[:message]
      }

    end

  end
end
