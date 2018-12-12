
require 'mongo'

module ExternalClients

  module MongoDb

    class Instance

      include Logging

      def initialize(config)

        # @name = name
        @port       = config.dig(:port)  || 27017
        @host       = config.dig(:host)  || 'localhost'
        @autoclose  = config.dig(:autoclose) || true

        @fields_to_ignore = %w(host version process pid uptimeMillis localTime extra_info.note backgroundFlushing.last_finished repl.setName repl.hosts repl.arbiters repl.primary repl.me ok tcmalloc.tcmalloc.formattedString)
        @white_list = %w(uptime asserts connections network opcounters tcmalloc storageEngine metrics mem extra_info wiredTiger globalLock)
        # @prefix_callback = nil
        @replacements = { /locks\.\.\./ => 'locks.global.' }

        @client = nil

        Mongo::Logger.logger.level = Logger::FATAL
      end


      #
      #
      def close
        @client.close
      end


      #
      #
      def to_s
        "Mongodb::Instance   #{@host}:#{@port}, #{@prefix_callback.class}"
      end


      #
      #
      def statistics_data

        @statistics = mongo_statistics

        # transform a hash of arrays into nested hash
        result = Hash.new { |h, k| h[k] = Hash.new(&h.default_proc) }

        #logger.debug("result: #{result} (#{result.class})")

        @statistics.each do |key, value|

          if( @white_list.partial_include?(key) )
            *nesting, leaf = key.split('.').map(&:to_sym)
            count = nesting.count
            if(count != 0)
              result.dig(*nesting)[leaf] = value
            else
              result[key] = value
            end
          end
        end

        result
      end


      # create a mongodb connection
      #
      def connection

        options = { :max_idle_time => 2, :max_pool_size => 2, :connect_timeout => 2.0, :app_name => 'CoreMedia Monitoring' }

        logger.debug( "use mongodb: #{@host}:#{@port} , #{options}" )


        # MongoClient in various languages is implemented as a "lazy stub", so that you will not get an immediate error,
        # if the connection is not possible.
        # Instead, you get the error when a concrete query goes over the line.

        begin
          @client = Mongo::Client.new([ "#{@host}:#{@port}" ] , options )
          # @client.database_names
        rescue Mongo::Auth::Unauthorized, Mongo::Error => error
          #logger.error("error: #{error} (file #{__FILE__} :: line #{__LINE__})")
          info_string  = "Error #{error.class}: #{error.message}"
          raise RuntimeError, info_string
        end
      end


      # return the serverStatus Data
      #
      # @return Hash
      #
      def mongo_statistics

        result = {}

        if(@client.nil?)
          begin
            connection
          rescue => error
            logger.error("error: #{error} (file #{__FILE__} :: line #{__LINE__})")
            return result
          end
        end

        begin
          server_status = @client.use("test").command({'serverStatus' => 1})

          #logger.debug("server_status: #{server_status} (#{server_status.class})")

          begin
            result = json_descent([], server_status.documents.first).flatten.reduce(:merge) if( server_status.ok? )
          rescue => error
            logger.error("error: #{error} (file #{__FILE__} :: line #{__LINE__})")
          end

        rescue => error
          logger.error("error: #{error} (file #{__FILE__} :: line #{__LINE__})")
        end

        @client.close if(@autoclose)

        # logger.debug("result: #{result} (#{result.class})")
        result
      end

      private
      #
      #
      def json_descent(pre, json)

        json.map do |k,v|
          # pp k.class
          #logger.debug("key: #{k.downcase}")
          #if( @fields_to_ignore.include?(k.downcase) )
          #  logger.debug(" found in ignore list")
          #  next
          #end
          # next if( @fields_to_ignore.include?(k.downcase) )

          key = pre + [k]
          if( v.is_a?( BSON::Document ) )
            json_descent(key, v)
          else
            # pp key
            { key.join('.') => v }
          end
        end
      end


#      #
#      #
#      def prefix
#        return @prefix_callback.call(@statistics) unless @prefix_callback.nil?
#        nil
#      end
#
#
#      #
#      #
#      def to_i(v)
#        return v.to_i if v.respond_to?('to_i')
#        case v
#        when TrueClass
#          1
#        when FalseClass
#          0
#        else
#          nil
#        end
#      end

#      #
#      #
#      def format_key(key)
#        @replacements.inject(key) do |modified_key, kvp|
#          modified_key.gsub(kvp[0], kvp[1])
#        end
#      end
#
#
#      #
#      #
#      def ignored_fields
#        @fields_to_ignore.map { |f| [prefix,f].join('.') }
#      end



    end
  end

end
