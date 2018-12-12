
module CarbonData

  module Database

    module MySQL

      def database_mysql( value = {} )

        result = []

        unless( value.nil? )

          result += innodb_values(value.select { |k| k[/Innodb.*/] })
          result += thread_values(value.select { |k| k[/Threads.*/] })
          result += qcache_values(value.select { |k| k[/Qcache.*/] })
          result += handler_values(value.select { |k| k[/Handler.*/] })
          result += command_values(value.select { |k| k[/Com.*/] })
          result += command_values(value.select { |k| k[/Open.*/] })
          result += select_values(value.select { |k| k[/Select.*/] })

          # READ THIS : http://dev.mysql.com/doc/refman/5.7/en/server-status-variables.html

          #questions                            = value.dig('Questions')    # http://dev.mysql.com/doc/refman/5.7/en/server-status-variables.html#statvar_Questions
          #slow_queries                         = value.dig('Slow_queries')
          #sort_merge_passes                    = value.dig('Sort_merge_passes')
          #sort_range                           = value.dig('Sort_range')
          #sort_rows                            = value.dig('Sort_rows')
          #sort_scan                            = value.dig('Sort_scan')
          #table_locks_immediate                = value.dig('Table_locks_immediate')
          #table_locks_waited                   = value.dig('Table_locks_waited')
          #table_open_cache_hits                = value.dig('Table_open_cache_hits')
          #table_open_cache_misses              = value.dig('Table_open_cache_misses')
          #table_open_cache_overflows           = value.dig('Table_open_cache_overflows')

          result << {
                   key: format('%s.%s.%s'         , @identifier, @normalized_service_name, 'uptime')                                        , value: value.dig('Uptime')
            } << { key: format('%s.%s.%s'         , @identifier, @normalized_service_name, 'locked_connects')                               , value: value.dig('Locked_connects')
            } << { key: format('%s.%s.%s.%s.%s'   , @identifier, @normalized_service_name, 'network', 'bytes', 'tx')                        , value: value.dig('Bytes_received')
            } << { key: format('%s.%s.%s.%s.%s'   , @identifier, @normalized_service_name, 'network', 'bytes', 'rx')                        , value: value.dig('Bytes_sent')
            } << { key: format('%s.%s.%s'         , @identifier, @normalized_service_name, 'connections')                                   , value: value.dig('Connections')
            } << { key: format('%s.%s.%s.%s.%s'   , @identifier, @normalized_service_name, 'connection', 'errors', 'internal')              , value: value.dig('Connection_errors_internal')
            } << { key: format('%s.%s.%s.%s.%s'   , @identifier, @normalized_service_name, 'connection', 'errors', 'max_connections')       , value: value.dig('Connection_errors_max_connections')

            } << { key: format('%s.%s.%s'         , @identifier, @normalized_service_name, 'queries')                                       , value: value.dig('Queries')
            } << { key: format('%s.%s.%s.%s.%s'   , @identifier, @normalized_service_name, 'created', 'tmp', 'disk_tables')                 , value: value.dig('Created_tmp_disk_tables')
            } << { key: format('%s.%s.%s.%s.%s'   , @identifier, @normalized_service_name, 'created', 'tmp', 'files')                       , value: value.dig('Created_tmp_files')
            } << { key: format('%s.%s.%s.%s.%s'   , @identifier, @normalized_service_name, 'created', 'tmp', 'tables')                      , value: value.dig('Created_tmp_tables')
            }

        end

        result.reject! { |k| k[:value].nil? }
      end


      private
      def innodb_values(value)

        result = []

        #innodb_dblwr_pages_written           = value.dig('Innodb_dblwr_pages_written')
        #innodb_dblwr_writes                  = value.dig('Innodb_dblwr_writes')
        #
        #innodb_row_lock_current_waits        = value.dig('Innodb_row_lock_current_waits')
        #innodb_row_lock_time                 = value.dig('Innodb_row_lock_time')
        #innodb_row_lock_time_avg             = value.dig('Innodb_row_lock_time_avg')
        #innodb_row_lock_time_max             = value.dig('Innodb_row_lock_time_max')
        #innodb_row_lock_waits                = value.dig('Innodb_row_lock_waits')


        result << {
               key: format('%s.%s.%s.%s.%s.%s'   , @identifier, @normalized_service_name, 'innodb', 'buffer_pool', 'pages', 'data')        , value: value.dig('Innodb_buffer_pool_pages_data')
        } << { key: format('%s.%s.%s.%s.%s.%s'   , @identifier, @normalized_service_name, 'innodb', 'buffer_pool', 'pages', 'dirty')       , value: value.dig('Innodb_buffer_pool_pages_dirty')
        } << { key: format('%s.%s.%s.%s.%s.%s'   , @identifier, @normalized_service_name, 'innodb', 'buffer_pool', 'pages', 'flushed')     , value: value.dig('Innodb_buffer_pool_pages_flushed')
        } << { key: format('%s.%s.%s.%s.%s.%s'   , @identifier, @normalized_service_name, 'innodb', 'buffer_pool', 'pages', 'free')        , value: value.dig('Innodb_buffer_pool_pages_free')
        } << { key: format('%s.%s.%s.%s.%s.%s'   , @identifier, @normalized_service_name, 'innodb', 'buffer_pool', 'pages', 'misc')        , value: value.dig('Innodb_buffer_pool_pages_misc')
        } << { key: format('%s.%s.%s.%s.%s.%s'   , @identifier, @normalized_service_name, 'innodb', 'buffer_pool', 'pages', 'total')       , value: value.dig('Innodb_buffer_pool_pages_total')
        } << { key: format('%s.%s.%s.%s.%s.%s'   , @identifier, @normalized_service_name, 'innodb', 'buffer_pool', 'pages', 'data')        , value: value.dig('Innodb_buffer_pool_bytes_data')
        } << { key: format('%s.%s.%s.%s.%s.%s'   , @identifier, @normalized_service_name, 'innodb', 'buffer_pool', 'pages', 'dirty')       , value: value.dig('Innodb_buffer_pool_bytes_dirty')
        } << { key: format('%s.%s.%s.%s.%s.%s'   , @identifier, @normalized_service_name, 'innodb', 'buffer_pool', 'read', 'ahead')        , value: value.dig('Innodb_buffer_pool_read_ahead')
        } << { key: format('%s.%s.%s.%s.%s.%s'   , @identifier, @normalized_service_name, 'innodb', 'buffer_pool', 'read', 'ahead_rnd')    , value: value.dig('Innodb_buffer_pool_read_ahead_rnd')
        } << { key: format('%s.%s.%s.%s.%s.%s'   , @identifier, @normalized_service_name, 'innodb', 'buffer_pool', 'read', 'ahead_evicted'), value: value.dig('Innodb_buffer_pool_read_ahead_evicted')
        } << { key: format('%s.%s.%s.%s.%s.%s'   , @identifier, @normalized_service_name, 'innodb', 'buffer_pool', 'read', 'requests')     , value: value.dig('Innodb_buffer_pool_read_requests')
        } << { key: format('%s.%s.%s.%s.%s'      , @identifier, @normalized_service_name, 'innodb', 'buffer_pool', 'reads')                , value: value.dig('Innodb_buffer_pool_reads')
        } << { key: format('%s.%s.%s.%s.%s'      , @identifier, @normalized_service_name, 'innodb', 'buffer_pool', 'wait_free')            , value: value.dig('Innodb_buffer_pool_wait_free')
        } << { key: format('%s.%s.%s.%s.%s'      , @identifier, @normalized_service_name, 'innodb', 'buffer_pool', 'write_requests')       , value: value.dig('Innodb_buffer_pool_write_requests')
        } << { key: format('%s.%s.%s.%s.%s'      , @identifier, @normalized_service_name, 'innodb', 'page', 'size')                        , value: value.dig('Innodb_page_size')
        } << { key: format('%s.%s.%s.%s.%s'      , @identifier, @normalized_service_name, 'innodb', 'pages', 'created')                    , value: value.dig('Innodb_pages_created')
        } << { key: format('%s.%s.%s.%s.%s'      , @identifier, @normalized_service_name, 'innodb', 'pages', 'read')                       , value: value.dig('Innodb_pages_read')
        } << { key: format('%s.%s.%s.%s.%s'      , @identifier, @normalized_service_name, 'innodb', 'pages', 'written')                    , value: value.dig('Innodb_pages_written')
        } << { key: format('%s.%s.%s.%s.%s'      , @identifier, @normalized_service_name, 'innodb', 'rows', 'deleted')                     , value: value.dig('Innodb_rows_deleted')
        } << { key: format('%s.%s.%s.%s.%s'      , @identifier, @normalized_service_name, 'innodb', 'rows', 'inserted')                    , value: value.dig('Innodb_rows_inserted')
        } << { key: format('%s.%s.%s.%s.%s'      , @identifier, @normalized_service_name, 'innodb', 'rows', 'read')                        , value: value.dig('Innodb_rows_read')
        } << { key: format('%s.%s.%s.%s.%s'      , @identifier, @normalized_service_name, 'innodb', 'rows', 'updated')                     , value: value.dig('Innodb_rows_updated')
        } << { key: format('%s.%s.%s.%s.%s'      , @identifier, @normalized_service_name, 'innodb', 'num', 'open_files')                   , value: value.dig('Innodb_num_open_files')
        } << { key: format('%s.%s.%s.%s.%s'      , @identifier, @normalized_service_name, 'innodb', 'data', 'fsyncs')                      , value: value.dig('Innodb_data_fsyncs')
        } << { key: format('%s.%s.%s.%s.%s.%s'   , @identifier, @normalized_service_name, 'innodb', 'data', 'pending', 'fsyncs')           , value: value.dig('Innodb_data_pending_fsyncs')
        } << { key: format('%s.%s.%s.%s.%s.%s'   , @identifier, @normalized_service_name, 'innodb', 'data', 'pending', 'reads')            , value: value.dig('Innodb_data_pending_reads')
        } << { key: format('%s.%s.%s.%s.%s.%s'   , @identifier, @normalized_service_name, 'innodb', 'data', 'pending', 'writes')           , value: value.dig('Innodb_data_pending_writes')
        } << { key: format('%s.%s.%s.%s.%s'      , @identifier, @normalized_service_name, 'innodb', 'data', 'read')                        , value: value.dig('Innodb_data_read')
        } << { key: format('%s.%s.%s.%s.%s'      , @identifier, @normalized_service_name, 'innodb', 'data', 'reads')                       , value: value.dig('Innodb_data_reads')
        } << { key: format('%s.%s.%s.%s.%s'      , @identifier, @normalized_service_name, 'innodb', 'data', 'writes')                      , value: value.dig('Innodb_data_writes')
        } << { key: format('%s.%s.%s.%s.%s'      , @identifier, @normalized_service_name, 'innodb', 'data', 'written')                     , value: value.dig('Innodb_data_written')
        } << { key: format('%s.%s.%s.%s.%s'      , @identifier, @normalized_service_name, 'innodb', 'log', 'waits')                        , value: value.dig('Innodb_log_waits')
        } << { key: format('%s.%s.%s.%s.%s'      , @identifier, @normalized_service_name, 'innodb', 'log', 'write_requests')               , value: value.dig('Innodb_log_write_requests')
        } << { key: format('%s.%s.%s.%s.%s'      , @identifier, @normalized_service_name, 'innodb', 'log', 'writes')                       , value: value.dig('Innodb_log_writes')
        } << { key: format('%s.%s.%s.%s.%s.%s'   , @identifier, @normalized_service_name, 'innodb', 'os', 'log', 'fsyncs')                 , value: value.dig('Innodb_os_log_fsyncs')
        } << { key: format('%s.%s.%s.%s.%s.%s.%s', @identifier, @normalized_service_name, 'innodb', 'os', 'log', 'pending', 'fsyncs')      , value: value.dig('Innodb_os_log_pending_fsyncs')
        } << { key: format('%s.%s.%s.%s.%s.%s.%s', @identifier, @normalized_service_name, 'innodb', 'os', 'log', 'pending', 'writes')      , value: value.dig('Innodb_os_log_pending_writes')
        } << { key: format('%s.%s.%s.%s.%s.%s'   , @identifier, @normalized_service_name, 'innodb', 'os', 'log', 'written')                , value: value.dig('Innodb_os_log_written')
        }
        result
      end


      def thread_values(value)

        result = []

        result << {
               key: format('%s.%s.%s.%s'      , @identifier, @normalized_service_name, 'threads', 'cached')                             , value: value.dig('Threads_cached')
        } << { key: format('%s.%s.%s.%s'      , @identifier, @normalized_service_name, 'threads', 'connected')                          , value: value.dig('Threads_connected')
        } << { key: format('%s.%s.%s.%s'      , @identifier, @normalized_service_name, 'threads', 'created')                            , value: value.dig('Threads_created')
        } << { key: format('%s.%s.%s.%s'      , @identifier, @normalized_service_name, 'threads', 'running')                            , value: value.dig('Threads_running')
        }

        result
      end


      def qcache_values(value)

        result = []

        result << {
               key: format('%s.%s.%s.%s.%s'   , @identifier, @normalized_service_name, 'qcache', 'free', 'blocks')                      , value: value.dig('Qcache_free_blocks')
        } << { key: format('%s.%s.%s.%s.%s'   , @identifier, @normalized_service_name, 'qcache', 'free', 'memory')                      , value: value.dig('Qcache_free_memory')
        } << { key: format('%s.%s.%s.%s'      , @identifier, @normalized_service_name, 'qcache', 'hits')                                , value: value.dig('Qcache_hits')
        } << { key: format('%s.%s.%s.%s'      , @identifier, @normalized_service_name, 'qcache', 'inserts')                             , value: value.dig('Qcache_inserts')
        } << { key: format('%s.%s.%s.%s'      , @identifier, @normalized_service_name, 'qcache', 'lowmem_prunes')                       , value: value.dig('Qcache_lowmem_prunes')
        } << { key: format('%s.%s.%s.%s'      , @identifier, @normalized_service_name, 'qcache', 'not_cached')                          , value: value.dig('Qcache_not_cached')
        } << { key: format('%s.%s.%s.%s'      , @identifier, @normalized_service_name, 'qcache', 'queries_in_cache')                    , value: value.dig('Qcache_queries_in_cache')
        } << { key: format('%s.%s.%s.%s'      , @identifier, @normalized_service_name, 'qcache', 'total_blocks')                        , value: value.dig('Qcache_total_blocks')
        }

        result
      end


      def handler_values(value)

        result = []
        #handler_savepoint                    = value.dig('Handler_savepoint')
        #handler_savepoint_rollback           = value.dig('Handler_savepoint_rollback')
        result << {
               key: format('%s.%s.%s.%s'    , @identifier, @normalized_service_name, 'handler', 'commit')                , value: value.dig('Handler_commit')
        } << { key: format('%s.%s.%s.%s'    , @identifier, @normalized_service_name, 'handler', 'delete')                , value: value.dig('Handler_delete')
        } << { key: format('%s.%s.%s.%s'    , @identifier, @normalized_service_name, 'handler', 'discover')              , value: value.dig('Handler_discover')
        } << { key: format('%s.%s.%s.%s'    , @identifier, @normalized_service_name, 'handler', 'prepare')               , value: value.dig('Handler_prepare')
        } << { key: format('%s.%s.%s.%s'    , @identifier, @normalized_service_name, 'handler', 'rollback')              , value: value.dig('Handler_rollback')
        } << { key: format('%s.%s.%s.%s'    , @identifier, @normalized_service_name, 'handler', 'update')                , value: value.dig('Handler_update')
        } << { key: format('%s.%s.%s.%s'    , @identifier, @normalized_service_name, 'handler', 'write')                 , value: value.dig('Handler_write')
        } << { key: format('%s.%s.%s.%s.%s' , @identifier, @normalized_service_name, 'handler', 'read', 'first')         , value: value.dig('Handler_read_first')
        } << { key: format('%s.%s.%s.%s.%s' , @identifier, @normalized_service_name, 'handler', 'read', 'last')          , value: value.dig('Handler_read_last')
        } << { key: format('%s.%s.%s.%s.%s' , @identifier, @normalized_service_name, 'handler', 'read', 'key')           , value: value.dig('Handler_read_key')
        } << { key: format('%s.%s.%s.%s.%s' , @identifier, @normalized_service_name, 'handler', 'read', 'next')          , value: value.dig('Handler_read_next')
        } << { key: format('%s.%s.%s.%s.%s' , @identifier, @normalized_service_name, 'handler', 'read', 'prev')          , value: value.dig('Handler_read_prev')
        } << { key: format('%s.%s.%s.%s.%s' , @identifier, @normalized_service_name, 'handler', 'read', 'rnd')           , value: value.dig('Handler_read_rnd')
        } << { key: format('%s.%s.%s.%s.%s' , @identifier, @normalized_service_name, 'handler', 'read', 'rnd_next')      , value: value.dig('Handler_read_rnd_next')
        }

        result
      end


      def command_values(value)

        result = []
        result << {
               key: format('%s.%s.%s.%s'    , @identifier, @normalized_service_name, 'commands', 'alter_db')              , value: value.dig('Com_alter_db')
        } << { key: format('%s.%s.%s.%s'    , @identifier, @normalized_service_name, 'commands', 'commit')                , value: value.dig('Com_commit')
        } << { key: format('%s.%s.%s.%s'    , @identifier, @normalized_service_name, 'commands', 'delete')                , value: value.dig('Com_delete')
        } << { key: format('%s.%s.%s.%s'    , @identifier, @normalized_service_name, 'commands', 'delete_multi')          , value: value.dig('Com_delete_multi')
        } << { key: format('%s.%s.%s.%s'    , @identifier, @normalized_service_name, 'commands', 'grant')                 , value: value.dig('Com_grant')
        } << { key: format('%s.%s.%s.%s'    , @identifier, @normalized_service_name, 'commands', 'insert')                , value: value.dig('Com_insert')
        } << { key: format('%s.%s.%s.%s'    , @identifier, @normalized_service_name, 'commands', 'insert_select')         , value: value.dig('Com_insert_select')
        } << { key: format('%s.%s.%s.%s'    , @identifier, @normalized_service_name, 'commands', 'purge')                 , value: value.dig('Com_purge')
        } << { key: format('%s.%s.%s.%s'    , @identifier, @normalized_service_name, 'commands', 'replace')               , value: value.dig('Com_replace')
        } << { key: format('%s.%s.%s.%s'    , @identifier, @normalized_service_name, 'commands', 'replace_select')        , value: value.dig('Com_replace_select')
        } << { key: format('%s.%s.%s.%s'    , @identifier, @normalized_service_name, 'commands', 'rollback')              , value: value.dig('Com_rollback')
        } << { key: format('%s.%s.%s.%s'    , @identifier, @normalized_service_name, 'commands', 'select')                , value: value.dig('Com_select')
        } << { key: format('%s.%s.%s.%s'    , @identifier, @normalized_service_name, 'commands', 'set_option')            , value: value.dig('Com_set_option')
        } << { key: format('%s.%s.%s.%s'    , @identifier, @normalized_service_name, 'commands', 'lock_tables')           , value: value.dig('Com_lock_tables')
        } << { key: format('%s.%s.%s.%s'    , @identifier, @normalized_service_name, 'commands', 'unlock_tables')         , value: value.dig('Com_unlock_tables')
        } << { key: format('%s.%s.%s.%s'    , @identifier, @normalized_service_name, 'commands', 'truncate')              , value: value.dig('Com_truncate')
        } << { key: format('%s.%s.%s.%s'    , @identifier, @normalized_service_name, 'commands', 'update')                , value: value.dig('Com_update')
        } << { key: format('%s.%s.%s.%s'    , @identifier, @normalized_service_name, 'commands', 'update_multi')          , value: value.dig('Com_update_multi')
        } << { key: format('%s.%s.%s.%s.%s' , @identifier, @normalized_service_name, 'commands', 'create', 'database')    , value: value.dig('Com_create_db')
        } << { key: format('%s.%s.%s.%s.%s' , @identifier, @normalized_service_name, 'commands', 'create', 'index')       , value: value.dig('Com_create_index')
        } << { key: format('%s.%s.%s.%s.%s' , @identifier, @normalized_service_name, 'commands', 'create', 'table')       , value: value.dig('Com_create_table')
        } << { key: format('%s.%s.%s.%s.%s' , @identifier, @normalized_service_name, 'commands', 'drop', 'database')      , value: value.dig('Com_drop_db')
        } << { key: format('%s.%s.%s.%s.%s' , @identifier, @normalized_service_name, 'commands', 'drop', 'index')         , value: value.dig('Com_drop_index')
        } << { key: format('%s.%s.%s.%s.%s' , @identifier, @normalized_service_name, 'commands', 'drop', 'table')         , value: value.dig('Com_drop_table')
        }

        result
      end


      def open_values(value)

        result = []
        result << {
               key: format('%s.%s.%s.%s'      , @identifier, @normalized_service_name, 'open', 'files')                  , value: value.dig('Open_files')
        } << { key: format('%s.%s.%s.%s'      , @identifier, @normalized_service_name, 'open', 'streams')                , value: value.dig('Open_streams')
        } << { key: format('%s.%s.%s.%s'      , @identifier, @normalized_service_name, 'open', 'tables')                 , value: value.dig('Open_tables')
        } << { key: format('%s.%s.%s.%s'      , @identifier, @normalized_service_name, 'open', 'table_definitions')      , value: value.dig('Open_table_definitions')
        } << { key: format('%s.%s.%s.%s'      , @identifier, @normalized_service_name, 'opened', 'files')                , value: value.dig('Opened_files')
        } << { key: format('%s.%s.%s.%s'      , @identifier, @normalized_service_name, 'opened', 'streams')              , value: value.dig('Opened_streams')
        } << { key: format('%s.%s.%s.%s'      , @identifier, @normalized_service_name, 'opened', 'tables')               , value: value.dig('Opened_tables')
        } << { key: format('%s.%s.%s.%s'      , @identifier, @normalized_service_name, 'opened', 'table_definitions')    , value: value.dig('Opened_table_definitions')
        }

        result
      end


      def select_values(value)

        result = []
        result << {
               key: format('%s.%s.%s.%s'      , @identifier, @normalized_service_name, 'select', 'full_join')        , value: value.dig('Select_full_join')
        } << { key: format('%s.%s.%s.%s'      , @identifier, @normalized_service_name, 'select', 'full_range_join')  , value: value.dig('Select_full_range_join')
        } << { key: format('%s.%s.%s.%s'      , @identifier, @normalized_service_name, 'select', 'range')            , value: value.dig('Select_range')
        } << { key: format('%s.%s.%s.%s'      , @identifier, @normalized_service_name, 'select', 'range_check')      , value: value.dig('Select_range_check')
        } << { key: format('%s.%s.%s.%s'      , @identifier, @normalized_service_name, 'select', 'scan')             , value: value.dig('Select_scan')
        }

        result
      end

    end
  end
end
