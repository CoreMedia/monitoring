
module CarbonData

  module Database

    module MongoDB

      def database_mongodb( value = {} )

        result = []

        unless( value.nil? )

          uptime         = value.dig('uptime')

          asserts        = value.dig('asserts')
          connections    = value.dig('connections')
          network        = value.dig('network')
          opcounters     = value.dig('opcounters')
          tcmalloc       = value.dig('tcmalloc')
          storage_engine = value.dig('storageEngine')
          metrics        = value.dig('metrics')
          mem            = value.dig('mem')
          extra_info     = value.dig('extra_info')
          wired_tiger    = value.dig('wiredTiger')
          global_lock    = value.dig('globalLock')

          result << {
            key: format( '%s.%s.%s', @identifier, @normalized_service_name, 'uptime' ),
            value: uptime
          }

          unless( asserts.nil? )

            regular   = asserts.dig('regular')
            warning   = asserts.dig('warning')
            message   = asserts.dig('msg')
            user      = asserts.dig('user')
            rollovers = asserts.dig('rollovers')

            result << {
              key: format( '%s.%s.%s.%s', @identifier, @normalized_service_name, 'asserts', 'regular' ),
              value: regular
            } << {
              key: format( '%s.%s.%s.%s', @identifier, @normalized_service_name, 'asserts', 'warning' ),
              value: warning
            } << {
              key: format( '%s.%s.%s.%s', @identifier, @normalized_service_name, 'asserts', 'message' ),
              value: message
            } << {
              key: format( '%s.%s.%s.%s', @identifier, @normalized_service_name, 'asserts', 'user' ),
              value: user
            } << {
              key: format( '%s.%s.%s.%s', @identifier, @normalized_service_name, 'asserts', 'rollovers' ),
              value: rollovers
            }

          end

          unless( connections.nil? )

            current        = connections.dig( 'current' )
            available      = connections.dig( 'available' )
            total_created  = connections.dig( 'totalCreated' )
            #total_created  = connections.dig( 'totalCreated', '$numberLong' ) if( total_created.is_a?( Hash ) )

            result << {
              key: format( '%s.%s.%s.%s'   , @identifier, @normalized_service_name, 'connections', 'current' ),
              value: current
            } << {
              key: format( '%s.%s.%s.%s'   , @identifier, @normalized_service_name, 'connections', 'available' ),
              value: available
            } << {
              key: format( '%s.%s.%s.%s.%s', @identifier, @normalized_service_name, 'connections', 'created', 'total' ),
              value: total_created
            }
          end

          unless( network.nil? )

            bytes_in   = network.dig('bytesIn')
            bytes_out  = network.dig('bytesOut')
            requests   = network.dig('numRequests')

#             bytes_in   = bytes_in.dig('$numberLong')    # RX - Receive TO this server
#             bytes_out  = bytes_out.dig('$numberLong')   # TX - Transmit FROM this server
#             requests   = requests.dig('$numberLong')

            result << {
              key: format( '%s.%s.%s.%s.%s', @identifier, @normalized_service_name, 'network', 'bytes', 'tx' ),
              value: bytes_out
            } << {
              key: format( '%s.%s.%s.%s.%s', @identifier, @normalized_service_name, 'network', 'bytes', 'rx' ),
              value: bytes_in
            } << {
              key: format( '%s.%s.%s.%s.%s', @identifier, @normalized_service_name, 'network', 'requests', 'total' ),
              value: requests
            }
          end

          unless( opcounters.nil? )

            insert  = opcounters.dig('insert')
            query   = opcounters.dig('query')
            update  = opcounters.dig('update')
            delete  = opcounters.dig('delete')
            getmore = opcounters.dig('getmore')
            command = opcounters.dig('command')

            result << {
              key: format( '%s.%s.%s.%s', @identifier, @normalized_service_name, 'opcounters', 'insert' ),
              value: insert
            } << {
              key: format( '%s.%s.%s.%s', @identifier, @normalized_service_name, 'opcounters', 'query' ),
              value: query
            } << {
              key: format( '%s.%s.%s.%s', @identifier, @normalized_service_name, 'opcounters', 'update' ),
              value: update
            } << {
              key: format( '%s.%s.%s.%s', @identifier, @normalized_service_name, 'opcounters', 'delete' ),
              value: delete
            } << {
              key: format( '%s.%s.%s.%s', @identifier, @normalized_service_name, 'opcounters', 'getmore' ),
              value: getmore
            } << {
              key: format( '%s.%s.%s.%s', @identifier, @normalized_service_name, 'opcounters', 'command' ),
              value: command
            }
          end

          unless( tcmalloc.nil? )

            generic = tcmalloc.dig('generic')

            heap_size  = generic.dig('heap_size')
            heap_used  = generic.dig('current_allocated_bytes')
            percent    = ( 100 * heap_used / heap_size )

            result << {
              key: format( '%s.%s.%s.%s.%s', @identifier, @normalized_service_name, 'memory', 'heap', 'size' ),
              value: heap_size
            } << {
              key: format( '%s.%s.%s.%s.%s', @identifier, @normalized_service_name, 'memory', 'heap', 'used' ),
              value: heap_used
            } << {
              key: format( '%s.%s.%s.%s.%s', @identifier, @normalized_service_name, 'memory', 'heap', 'used_percent' ),
              value: percent
            }

#             malloc  = tcmalloc.dig('tcmalloc')
#             unless( malloc.nil? )
#               page_map_free      = malloc.dig('pageheap_free_bytes')              || 0 # Bytes in page heap freelist
#               central_cache_free = malloc.dig('central_cache_free_bytes')         || 0 # Bytes in central cache freelist
#               transfer_cache_fee = malloc.dig('transfer_cache_free_bytes')        || 0 # Bytes in transfer cache freelist
#               thread_cache_size  = malloc.dig('current_total_thread_cache_bytes') || 0 # Bytes in thread cache freelists
#               thread_cache_free  = malloc.dig('thread_cache_free_bytes')          || 0 #
#               max_thread_cache   = malloc.dig('max_total_thread_cache_bytes','$numberLong')     || 0 #
#
#               result << {
#                 key: format( '%s.%s.%s.%s.%s', @identifier, @normalized_service_name, 'cache', 'thread', 'size' ),
#                 value: heap_size
#               } << {
#                 key: format( '%s.%s.%s.%s.%s', @identifier, @normalized_service_name, 'cache', 'thread', 'used' ),
#                 value: heap_used
#               } << {
#                 key: format( '%s.%s.%s.%s.%s', @identifier, @normalized_service_name, 'cache', 'thread', 'used_percent' ),
#                 value: percent
#               }
#             end
          end

          unless( storage_engine.nil? )

            storage_engine  = storage_engine.dig('name')

            unless( storage_engine.nil? )

              storage = value.dig( storage_engine )

              unless( storage.nil? )

                block_manager = storage.dig('block-manager')
                connection    = storage.dig('connection')

                storage_bytes_read            = block_manager.dig('bytes read')
                storage_bytes_written         = block_manager.dig('bytes written')
                storage_blocks_read           = block_manager.dig('blocks read')
                storage_blocks_written        = block_manager.dig('blocks written')
                storage_connection_io_read    = connection.dig('total read I/Os')
                storage_connection_io_write   = connection.dig('total write I/Os')
                storage_connection_files_open = connection.dig('files currently open')

                result << {
                  key: format( '%s.%s.%s.%s.%s.%s.%s'   , @identifier, @normalized_service_name, 'storage-engine', storage_engine, 'block-manager', 'bytes', 'rx' ),
                  value: storage_bytes_read
                } << {
                  key: format( '%s.%s.%s.%s.%s.%s.%s'   , @identifier, @normalized_service_name, 'storage-engine', storage_engine, 'block-manager', 'bytes', 'tx' ),
                  value: storage_bytes_written
                } << {
                  key: format( '%s.%s.%s.%s.%s.%s.%s'   , @identifier, @normalized_service_name, 'storage-engine', storage_engine, 'block-manager', 'blocks', 'rx' ),
                  value: storage_blocks_read
                } << {
                  key: format( '%s.%s.%s.%s.%s.%s.%s'   , @identifier, @normalized_service_name, 'storage-engine', storage_engine, 'block-manager', 'blocks', 'tx' ),
                  value: storage_blocks_written
                } << {
                  key: format( '%s.%s.%s.%s.%s.%s.%s.%s', @identifier, @normalized_service_name, 'storage-engine', storage_engine, 'connection', 'io', 'read', 'total' ),
                  value: storage_connection_io_read
                } << {
                  key: format( '%s.%s.%s.%s.%s.%s.%s.%s', @identifier, @normalized_service_name, 'storage-engine', storage_engine, 'connection', 'io', 'write', 'total' ),
                  value: storage_connection_io_write
                } << {
                  key: format( '%s.%s.%s.%s.%s.%s.%s'   , @identifier, @normalized_service_name, 'storage-engine', storage_engine, 'connection', 'files', 'open' ),
                  value: storage_connection_files_open
                }
              end
            end
          end

          unless( metrics.nil? )

            commands = metrics.dig('commands')

            unless( commands.nil? )

              ['authenticate','buildInfo','createIndexes','delete','drop','find','findAndModify','insert','listCollections','mapReduce','renameCollection','update'].each do |m|

                cmd = commands.dig( m )

                unless( cmd.nil? )
                  d  = cmd.dig( 'total')#, '$numberLong' )

                  result << {
                    key: format( '%s.%s.%s.%s'   , @identifier, @normalized_service_name, 'commands', m ),
                    value: d
                  }
                end
              end


              current_operation = commands.dig('currentOp')

              unless(current_operation.nil?)

                total  = current_operation.dig('total')#, '$numberLong')
                failed = current_operation.dig('failed')#, '$numberLong')

                result << {
                  key: format( '%s.%s.%s.%s.%s', @identifier, @normalized_service_name, 'commands', 'currentOp', 'total' ),
                  value: total
                } << {
                  key: format( '%s.%s.%s.%s.%s', @identifier, @normalized_service_name, 'commands', 'currentOp', 'failed' ),
                  value: failed
                }
              end

            end

            cursor = metrics.dig('cursor')

            unless( cursor.nil? )

              cursor_open      = cursor.dig('open')
              cursor_timed_out = cursor.dig('timedOut')

              unless( cursor_open.nil? && cursor_timed_out.nil? )

                open_no_timeout = cursor_open.dig( 'noTimeout')#, '$numberLong' )
                open_total      = cursor_open.dig( 'total')#    , '$numberLong' )
                #timed_out       = cursor_timed_out.dig( '$numberLong' )

                result << {
                  key: format( '%s.%s.%s.%s.%s', @identifier, @normalized_service_name, 'cursor', 'open', 'total' ),
                  value: open_total
                } << {
                  key: format( '%s.%s.%s.%s.%s', @identifier, @normalized_service_name, 'cursor', 'open', 'no-timeout' ),
                  value: open_no_timeout
                } << {
                  key: format( '%s.%s.%s.%s'   , @identifier, @normalized_service_name, 'cursor', 'timed-out' ),
                  value: cursor_timed_out
                }
              end

            end

          end

          unless( mem.nil? )

            virtual        = mem.dig('virtual')
            resident       = mem.dig('resident')

            result << {
              key: format( '%s.%s.%s.%s', @identifier, @normalized_service_name, 'memory', 'virtual' ),
              value: virtual
            } << {
              key: format( '%s.%s.%s.%s', @identifier, @normalized_service_name, 'memory', 'resident' ),
              value: resident
            }
          end

          unless( extra_info.nil? )

            page_faults        = extra_info.dig('page_faults')

            result << {
              key: format( '%s.%s.%s.%s', @identifier, @normalized_service_name, 'extra_info', 'page_faults' ),
              value: page_faults
            }
          end

          unless( wired_tiger.nil? )

            wired_tiger_cache       = wired_tiger.dig('cache')
            concurrent_transactions = wired_tiger.dig('concurrentTransactions')

            unless( wired_tiger_cache.nil? )

              bytes         = wired_tiger_cache.dig('bytes currently in the cache')
              maximum       = wired_tiger_cache.dig('maximum bytes configured')
              tracked       = wired_tiger_cache.dig('tracked dirty bytes in the cache')
              unmodified    = wired_tiger_cache.dig('unmodified pages evicted')
              modified      = wired_tiger_cache.dig('modified pages evicted')

              result << {
                key: format( '%s.%s.%s.%s.%s.%s', @identifier, @normalized_service_name, 'wiredTiger', 'cache', 'in-cache', 'bytes' ),
                value: bytes
              } << {
                key: format( '%s.%s.%s.%s.%s.%s', @identifier, @normalized_service_name, 'wiredTiger', 'cache', 'in-cache', 'tracked-dirty' ),
                value: tracked
              } << {
                key: format( '%s.%s.%s.%s.%s.%s', @identifier, @normalized_service_name, 'wiredTiger', 'cache', 'configured', 'max-bytes' ),
                value: maximum
              } << {
                key: format( '%s.%s.%s.%s.%s.%s', @identifier, @normalized_service_name, 'wiredTiger', 'cache', 'evicted-pages', 'modified' ),
                value: modified
              } << {
                key: format( '%s.%s.%s.%s.%s.%s', @identifier, @normalized_service_name, 'wiredTiger', 'cache', 'evicted-pages', 'unmodified' ),
                value: unmodified
              }
            end

            unless( concurrent_transactions.nil? )

              read        = concurrent_transactions.dig('read')
              write       = concurrent_transactions.dig('write')

              unless( read.nil? && write.nil? )

                read_out          = read.dig('out')
                read_available    = read.dig('available')

                write_out         = write.dig('out')
                write_available   = write.dig('available')

                result << {
                  key: format( '%s.%s.%s.%s.%s.%s', @identifier, @normalized_service_name, 'wiredTiger', 'concurrentTransactions', 'read', 'out' ),
                  value: read_out
                } << {
                  key: format( '%s.%s.%s.%s.%s.%s', @identifier, @normalized_service_name, 'wiredTiger', 'concurrentTransactions', 'read', 'available' ),
                  value: read_available
                } << {
                  key: format( '%s.%s.%s.%s.%s.%s', @identifier, @normalized_service_name, 'wiredTiger', 'concurrentTransactions', 'write', 'out' ),
                  value: write_out
                } << {
                  key: format( '%s.%s.%s.%s.%s.%s', @identifier, @normalized_service_name, 'wiredTiger', 'concurrentTransactions', 'write', 'available' ),
                  value: write_available
                }
              end

            end
          end

          unless( global_lock.nil? )

            current_queue  = global_lock.dig('currentQueue')
            active_clients = global_lock.dig('activeClients')

            unless( current_queue.nil? )

              readers       = current_queue.dig('readers')
              writers       = current_queue.dig('writers')
              total         = current_queue.dig('total')

              result << {
                key: format( '%s.%s.%s.%s.%s', @identifier, @normalized_service_name, 'globalLock', 'currentQueue', 'readers' ),
                value: readers
              } << {
                key: format( '%s.%s.%s.%s.%s', @identifier, @normalized_service_name, 'globalLock', 'currentQueue', 'writers' ),
                value: writers
              } << {
                key: format( '%s.%s.%s.%s.%s', @identifier, @normalized_service_name, 'globalLock', 'currentQueue', 'total' ),
                value: total
              }
            end

            unless( active_clients.nil? )

              readers     = active_clients.dig('readers')
              writers     = active_clients.dig('writers')
              total       = active_clients.dig('total')

              result << {
                key: format( '%s.%s.%s.%s.%s', @identifier, @normalized_service_name, 'globalLock', 'activeClients', 'readers' ),
                value: readers
              } << {
                key: format( '%s.%s.%s.%s.%s', @identifier, @normalized_service_name, 'globalLock', 'activeClients', 'writers' ),
                value: writers
              } << {
                key: format( '%s.%s.%s.%s.%s', @identifier, @normalized_service_name, 'globalLock', 'activeClients', 'total' ),
                value: total
              }
            end
          end

        end

        result
      end

    end

  end

end
