
module CarbonData

  module Database

    module Postgres


      def database_postgres( value = {} )

        format = 'PUTVAL %s/%s-%s/%s-%s interval=%s N:%s'
        result = []

        if( value != nil )

          logger.debug( value )

        end

        return result
      end

    end

  end

end
