
require 'mini_cache'

module JobQueue

  class Job

    def initialize( settings = {} )
      @jobs  = MiniCache::Store.new()
    end

    def cacheKey( params = {} )
      Digest::MD5.hexdigest( Hash[params.sort].to_s )
    end

    def add( params = {} )

      checksum = self.cacheKey(params)

      @jobs.set( checksum ) { MiniCache::Data.new( 'true' ) } if( self.jobs( params ) == false )
    end


    def del( params = {} )

      checksum = self.cacheKey(params)

      @jobs.unset( checksum )
    end


    def jobs( params = {} )

      checksum = self.cacheKey(params)
      current  = @jobs.get( checksum )

      # no entry found
      return false if( current.nil? )

      return true
    end
  end
end

