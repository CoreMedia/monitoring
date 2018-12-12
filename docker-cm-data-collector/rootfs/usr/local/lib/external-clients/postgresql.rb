
require 'pg'

module ExternalClients

  module Postgresql

    class Instance

      include Logging

      def initialize( settings = {} )

        logger.debug( settings )

        @logDirectory      = settings['log_dir']        ? settings['log_dir']        : '/tmp'
        @postgresHost      = settings['postgresHost']   ? settings['postgresHost']   : 'localhost'
        @postgresPort      = settings['postgresPort']   ? settings['postgresPort']   : 5432
        @postgresUser      = settings['postgresUser']   ? settings['postgresUser']   : 'root'
        @postgresPass      = settings['postgresPass']   ? settings['postgresPass']   : ''
        @postgresDBName    = settings['postgresDBName'] ? settings['postgresDBName'] : 'test'

      end

      def connect()

        params = {
          :host     => @postgresHost,
          :dbname   => @postgresDBName,
          :user     => @postgresUser,
          :port     => @postgresPort,
          :password => @postgresPass
        }

        begin

###          if( PG::Connection.ping( paranms ) )
          @connection = PG::Connection.new( params )

        rescue PG::Error => e
#          STDERR.puts "An error occurred #{e}"
          logger.error( sprintf( 'An error occurred \'%s\'', e ) )
        end

      end

      def run()

        self.connect()

        begin

          # https://www.postgresql.org/docs/9.6/static/monitoring-stats.html

          # uptime:
          #  SELECT EXTRACT(EPOCH FROM NOW() - stats_reset) from pg_stat_bgwriter;
          # starttime:
          #  SELECT pg_postmaster_start_time();
          # get connectable databases:
          #  SELECT datname FROM pg_database WHERE datallowconn = 't' AND pg_catalog.has_database_privilege(current_user, oid, 'CONNECT')


#
          result  = @connection.send_query( 'select * from pg_stat_database; SELECT * from pg_stat_all_tables where shemaname like \'cm%\';' )
          @connection.set_single_row_mode()

          @connection.get_result.stream_each do |row|

            logger.debug( row )
            # do something with the received row of the first query
          end

          @connection.get_result.stream_each do |row|

            logger.debug( row )
            # do something with the received row of the second query
          end

          @connection.get_result  # => nil   (no more results)

          # ('select * from pg_stat_database')

  #        rows = @sequel[ @mysqlQuery ].to_hash( :Variable_name,:Value )
  #        rows = self.valuesToNumeric(rows)
  #        rows = self.calculateRelative(rows) if @relative
  #        rows = self.scaleValues(rows)
  #        output_query(rows) unless first_run && @relative

        rescue PG::Error => err
          logger.debug( [
              err.result.error_field( PG::Result::PG_DIAG_SEVERITY ),
              err.result.error_field( PG::Result::PG_DIAG_SQLSTATE ),
              err.result.error_field( PG::Result::PG_DIAG_MESSAGE_PRIMARY ),
              err.result.error_field( PG::Result::PG_DIAG_MESSAGE_DETAIL ),
              err.result.error_field( PG::Result::PG_DIAG_MESSAGE_HINT ),
              err.result.error_field( PG::Result::PG_DIAG_STATEMENT_POSITION ),
              err.result.error_field( PG::Result::PG_DIAG_INTERNAL_POSITION ),
              err.result.error_field( PG::Result::PG_DIAG_INTERNAL_QUERY ),
              err.result.error_field( PG::Result::PG_DIAG_CONTEXT ),
              err.result.error_field( PG::Result::PG_DIAG_SOURCE_FILE ),
              err.result.error_field( PG::Result::PG_DIAG_SOURCE_LINE ),
              err.result.error_field( PG::Result::PG_DIAG_SOURCE_FUNCTION ),
          ] )


        rescue Exception => e
#          STDERR.puts "An error occurred #{e}"
          logger.error( sprintf( 'An error occurred \'%s\'', e ) )
        end

      end

    end
  end

end

