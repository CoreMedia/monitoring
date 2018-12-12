#!/usr/bin/ruby
#
# 24.03.2017 - Bodo Schulz
# v1.3.0
#
# simplified API for Beanaeter (Client Class for beanstalk)

# -----------------------------------------------------------------------------

require 'beaneater'
require 'json'
require 'digest/md5'

require_relative 'logging'

# -----------------------------------------------------------------------------

module MessageQueue

  class Producer

    include Logging

    def initialize( params = {} )

      beanstalk_host       = params.dig(:beanstalk, :host) || 'beanstalkd'
      beanstalk_port       = params.dig(:beanstalk, :port) || 11300

      begin
        @b = Beaneater.new( sprintf( '%s:%s', beanstalk_host, beanstalk_port ) )
      rescue => e
        logger.error( e )
        @b = nil
#        raise sprintf( 'ERROR: %s' , e )
      end

#       logger.info( '-----------------------------------------------------------------' )
#       logger.info( ' MessageQueue::Producer' )
#       logger.info( '-----------------------------------------------------------------' )

    end

    # add an Job to an names Message Queue
    #
    # @param [String, #read] tube the Queue Name
    # @param [Hash, #read] job the Jobdata will send to Message Queue
    # @param [Integer, #read] prio is an integer < 2**32. Jobs with smaller priority values will be
    #        scheduled before jobs with larger priorities. The most urgent priority is 0;
    #        the least urgent priority is 4,294,967,295.
    # @param [Integer, #read] ttr time to run -- is an integer number of seconds to allow a worker
    #        to run this job. This time is counted from the moment a worker reserves
    #        this job. If the worker does not delete, release, or bury the job within
    # <ttr> seconds, the job will time out and the server will release the job.
    #        The minimum ttr is 1. If the client sends 0, the server will silently
    #        increase the ttr to 1.
    # @param [Integer, #read] delay is an integer number of seconds to wait before putting the job in
    #        the ready queue. The job will be in the "delayed" state during this time.
    # @example send a Job to Beanaeter
    #    add_job()
    # @return [Hash,#read]
    #
    def add_job( tube, job = {}, prio = 65536, ttr = 10, delay = 2 )

      if( @b )

        # check if job already in the queue
        #
        return if( job_exists?( tube.to_s, job ) == true )

        response = @b.tubes[ tube.to_s ].put( job , :prio => prio, :ttr => ttr, :delay => delay )
        logger.debug( response )

        response
      end
    end



    def job_exists?( tube, job )

      job = JSON.parse(job) if( job.is_a?( String ) )

      j_checksum = checksum(job)

      if( @b )
        t = @b.tubes[ tube.to_s ]

        while t.peek(:ready)

          j = t.reserve

          b = JSON.parse( j.body )
          b = JSON.parse( b ) if( b.is_a?( String ) )

          b_checksum = checksum(b)

          if( j_checksum == b_checksum )
            logger.warn( "  job '#{job}' already in queue .." )
            return true
          else
            return false
          end

        end
      end
    end


    def checksum( p )

      p.reject! { |k| k == 'timestamp' }
      p.reject! { |k| k == 'payload' }

      p = Hash[p.sort]
      Digest::MD5.hexdigest(p.to_s)
    end

  end


  class Consumer

    include Logging

    def initialize( params = {} )

      beanstalk_host         = params.dig(:beanstalk, :host)         || 'beanstalkd'
      beanstalk_port         = params.dig(:beanstalk, :port)         ||  11300
      beanstalk_queue        = params.dig(:beanstalk, :queue)
      release_buried_interval = params.dig(:beanstalk, :release_buried_interval) || 40

      begin
        @b = Beaneater.new( sprintf( '%s:%s', beanstalk_host, beanstalk_port ) )

        if( beanstalk_queue != nil )
          scheduler = Rufus::Scheduler.new
          scheduler.every( release_buried_interval ) do
            release_buried_jobs( beanstalk_queue )
          end
        else
          logger.info( 'no Queue defined. Skip release_buried_jobs() Part' )
        end

      rescue => e
        logger.error( e )
        raise sprintf( 'ERROR: %s' , e )
      end

#       logger.info( '-----------------------------------------------------------------' )
#       logger.info( ' MessageQueue::Consumer' )
#       logger.info( '-----------------------------------------------------------------' )

    end


    def statistics( tube )

      queue       = nil
      jobsTotal   = 0
      jobsReady   = 0
      jobsDelayed = 0
      jobsBuried  = 0
      tubeStats   = nil

      if( @b )

        begin
          tubeStats = @b.tubes[tube].stats

          if( tubeStats )

            queue       = tubeStats[ :name ]
            jobsTotal   = tubeStats[ :total_jobs ]
            jobsReady   = tubeStats[ :current_jobs_ready ]
            jobsDelayed = tubeStats[ :current_jobs_delayed ]
            jobsBuried  = tubeStats[ :current_jobs_buried ]
          end
        rescue Beaneater::NotFoundError

        end
      end

      {
        queue: queue,
        total: jobsTotal.to_i,
        ready: jobsReady.to_i,
        delayed: jobsDelayed.to_i,
        buried: jobsBuried.to_i,
        raw: tubeStats
      }
    end


    def clean_queue( tube )

      b = Array.new()

      sleep(0.3)
      timeout = nil
      jobs = []

      begin
        100.times do |i|
          jobs << @b.tubes[tube].reserve(timeout)
          timeout = 0
        end
      rescue Beaneater::TimedOutError
        # nothing to do
      end

      jobs.map do |j|

        logger.debug( JSON.pretty_generate(j))

#         logger.debug( JSON.pretty_generate( {
#                   'id'    => j.id,
#                   'tube'  => j.stats.tube,
#                   'state' => j.stats.state,
#                   'ttr'   => j.stats.ttr,
#                   'prio'  => j.stats.pri,
#                   'age'   => j.stats.age,
#                   'delay' => j.stats.delay,
#                   'body'  => JSON.parse( j.body )
#                 } )

        body = JSON.parse( j.body )

        body['id'] = j.id
        body.reject! { |k| k == 'timestamp' }
        body.reject! { |k| k == 'payload' }
        body = Hash[body.sort]

        logger.debug( body )
        b << body
      end

      # sort reverse
      #
      b = b.sort_by { |x| x['id'].to_i }.reverse

      logger.debug( b.count )
      logger.debug( b )

      # unique entries
      #
      c = b.uniq { |t| [ t['cmd'], t['node'] ] }

      identicalEntries      = b & c
      removedEntries        = b - c

      jobs.map do |j|
        removedEntries.each do |r|
          delete_job( tube, j.id ) if j.id == r.dig('id' )
        end
      end
    end



    def get_job_from_queue( tube, delete = false )

      result = {}

      if( @b )
        stats = statistics( tube )

        return result if( stats.dig( :ready ) == 0 )

        tube = @b.tubes.watch!( tube.to_s )

        begin
          job = @b.tubes.reserve(1)

          begin
            # processing job

            result = {
              id: job.id,
              tube: job.stats.tube,
              state: job.stats.state,
              ttr: job.stats.ttr,
              prio: job.stats.pri,
              age: job.stats.age,
              delay: job.stats.delay,
              body: JSON.parse( job.body )
            }

            job.delete if( delete == true )

          rescue Exception => e
            job.bury
          end

        rescue Beaneater::TimedOutError
          # nothing to do
        end
      end

      result
    end


    def release_buried_jobs( tube )

      if( @b )
        tube = @b.tubes.find( tube.to_s )

        buried = tube.peek( :buried )

        if( buried )
          logger.info( sprintf( 'found job: %d, kick them back into the \'ready\' queue', buried.id ) )

          tube.kick(1)
        end
      end
    end


    def delete_job( tube, id )

      logger.debug( sprintf( "delete_job( #{tube}, #{id} )" ) )

      if( @b )
        job = @b.jobs.find( id )
        response = job.delete if( job != nil )
      end
    end


    def bury_job( tube, id )

      logger.debug( sprintf( "bury_job( #{tube}, #{id} )" ) )

      if( @b )
        job = @b.jobs.find( id )
        response = job.bury if( job != nil )
      end
    end

  end

end

# -----------------------------------------------------------------------------
# TESTS

# settings = {
#   :beanstalk_host => 'localhost'
# }
#
# p = MessageQueue::Producer.new( settings )
#
#
# 100.times do |i|
#
#   job = {
#     cmd:   'add',
#     payload: sprintf( "foo-bar-%s.com", i )
#   }.to_json
#
#   p.add_job( 'test-tube', job )
# end
#
# c = MessageQueue::Consumer.new( settings )
#
# puts JSON.pretty_generate( c.statistics( 'test-tube' ) )
#
# loop do
#   j = c.get_job_from_queue( 'test-tube' )
#
#   if( j.count == 0 )
#     break
#   else
#     puts JSON.pretty_generate( j )
#   end
# end

# -----------------------------------------------------------------------------
