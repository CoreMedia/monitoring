# Base Measurement Points for ALL Content Servers

## <a name="Server"></a>Server

Alle Content Server (CMS, MLS, RLS) stellen die unten aufgeführten Beans zur Verfügung.

`com.coremedia:type=Server,application=*`

- `RunLevel` (The current run level of the Content Server:
    * `offline`
    * `maintenance`
    * `administration`
    * `online`)
- `RunLevelNumeric` (the current run level of the Content Server, which is one of
    *  0 = `offline`
    *  1 = `maintenance`
    *  2 = `administration` or
    *  3 = `online`)
- `Uptime` ("the time since the Content Server was started in milliseconds)
- `ResourceCacheHits` (the number of cache hits since the cache utilization was last logged)
- `ResourceCacheEvicts` (the number of cache evictions since the cache utilization was last logged)
- `ResourceCacheEntries` (the number of cache faults since the cache utilization was last logged)
- `ResourceCacheInterval` (the time between two log messages reporting the current state of the resource cache in seconds)
- `ResourceCacheSize` (the current number of entries in the resource cache of the Content Server)
- `RepositorySequenceNumber` (the sequence number of the latest successful repository transaction, useful for comparison between MLS and RLS)
- `ConnectionCount` (get the number of connections from clients that are currently open)
- `ServiceInfos` (the allowed and current usage of login services:
    * `analytics`
    * `background`
    * `dashboard`
    * `debug`
    * `editor`
    * `feeder`
    * `filesystem`
    * `importer`
    * `publisher`
    * `replicator`
    * `system`
    * `webserver`
    * `workflow`)
- `LicenseValidFrom` (validity of the server license (`valid from`))
- `LicenseValidUntilHard` (validity of the server license (`valid until hard`))
- `LicenseValidUntilSoft` (validity of the server license (`valid until soft`))


## <a name="ConnectionPool"></a>ConnectionPool

The connection pool holds the database connections and schedules all incoming shared or exclusive transactions.

`com.coremedia:type=Store,bean=ConnectionPool,application=*`

- `BusyConnections` (the number of busy connections)
- `OpenConnections` (the number of open connections)
- `IdleConnections` (the number of idle connections)
- `MaxConnections` (the maximum number of pooled connections)
- `MinConnections` (the minimum number of pooled connections)


## <a name="QueryPool"></a>QueryPool

A pool of threads evaluating queries.

In contrast to the connection pool, which executes every transaction within
the scheduling thread, each query must be run by a separate thread allowing
them to be asynchronous and support user requested cancellation and
timeouts.

`com.coremedia:type=Store,bean=QueryPool,application=*`

- `IdleExecutors` (the number of idle query executors)
- `RunningExecutors` (the number of running query executors)
- `WaitingQueries` (the number of queries in the queue)
- `MaxQueries` (the maximum number of allowed queries)

## <a name="Publisher"></a>Publisher

The publisher component managing configurations and statistics related to publishing content.
All statistics are repeatedly reset after a configurable time period typically 5 minutes.
That means that counters cannot be expected to be rising monotonously.

`com.coremedia:type=Publisher,target=*,application=coremedia`

- `Connected` (returns whether we have currently an open and usable remote connection for the named publication target.)
- `IorUrl`
- `QueueSize` (the number of publication and publication preview operations that are queued for execution, but not yet started)
- `PublCount` (the number of publications since the last statistics reset)
- `PublPrevCount` (the number of publication previews since the last statistics reset)
- `FailedPublCount` (the number of failed publications since the last statistics reset)
- `FailedPublPrevCount` (the number for failed publication previews since the last statistics reset)
- `LastPublTime` (the time needed for executing the last completed publication excluding wait time, in milliseconds)
- `LastPublSize` (the size of the initial publication set of the last publication)
- `LastPublResult` (either 'success' or 'failure' depending on whether the last completed publication was successful)
