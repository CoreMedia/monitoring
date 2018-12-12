# CAE Feeder


## CapConnection

The management interface for the CapConnection to allow its configuration and profiling.

[siehe](./capconnection.md)


## <a name="ProactiveEngine"></a>ProactiveEngine

ProactiveEngine management component.

The "heart" of the Proactive Persistent Cache. It consists of these building blocks

`com.coremedia:type=ProactiveEngine,application=*`

- `KeysCount` (Number of (active) keys)
- `ValuesCount` (Number of (valid) values. It is less or equal to 'keysCount')
- `InvalidationCount` (Number of invalidations which have been received)
- `SendSuccessTimeLatest` (Latest time when any receiver has acknowledged an event successfully)
- `PurgeTimeLatest` (Time of the latest (manual or automatic) purge)
- `HeartBeat` (The heartbeat of this service: Milliseconds between now and the latest activity. A low value indicates that the service is alive. An constantly increasing value might be caused by a 'sick' or dead service)
- `QueueSize` (Number of items waiting in the queue for being processed. Less or equal than 'queueCapacity)
- `QueueCapacity` (The queue's capacity: Maximum number of items which can be enqueued)
- `QueueMaxSize` (Maximum number of items which had been waiting in the queue)
- `QueueProcessedPerSecond` (Number of processed queue items per second since startup)

## <a name="ContentDependencyInvalidator"></a>ContentDependencyInvalidator

An invalidator for content dependencies.

It maintains the current value of the DependencyClock for content dependencies.

- `InvalidationQueueCapacity` (The maximum number of invalidation events to be enqueued)
- `InvalidationQueueSize` (The number of invalidation events which are waiting to be processed. If this value exceeds 'InvalidationQueueCapacity' then the invalidator will be stopped temporarily)
- `InvalidationStopped` (Returns whether content dependency invalidation is stopped)
- `LastProcessedTimestamp` (The timestamp of the latest content event which has been processed by the invalidator)


## <a name="Health"></a>Health

Health management component

`com.coremedia:type=Health,application=*`

- `Healthy` (Checks whether the component is healthy or not based on the configuration of the parameters.)
- `MaximumHeartBeat` (The configured maximum allowed Heartbeat in milliseconds)
- `MaximumQueueExceededDuration` (The configured maximum duration the queue is allowed to be exceeded in milliseconds.)
- `MaximumQueueUtilization` (The configured maximum allowed utilization of the job queue)


## TransformedBlobCacheManager

Provided statistics for the persistent blob cache

`com.coremedia:type=TransformedBlobCacheManager,application=*`

- `AccessCount` (count of accesses since system start)
- `CacheSize` (the cache size in bytes)
- `FaultCount` (count of faults since system start)
- `FaultSizeSum` (sum of sizes in bytes of all blobs faulted since system start)
- `InitialLevel` (initial cache level in bytes)
- `Level` (cache level in bytes)
- `NewGenerationCacheSize` (cache size of new generation folder in bytes)
- `NewGenerationInitialLevel` (initial cache level of the new generation in bytes)
- `NewGenerationLevel` (cache level of the new generation in bytes)
- `OldGenerationInitialLevel` (initial cache level of the old generation level in bytes)
- `OldGenerationLevel` (cache level of the old generation in bytes)
- `RecallCount` (count of recalls since system start)
- `RecallSizeSum` (sum of sizes in bytes of all blobs recalled since system start)
- `RotateCount` (count of rotates since system start)
- `Uptime` (the uptime in milliseconds)


## Receiver

Receiver that is connected to the feeder.

maintains statistics about the times and numbers of events that have been received and processed.


`com.coremedia:type=Receiver,application=*`

- `AddProcessedCount` (Number of 'add' events which have been processed since startup)
- `AddReceivedCount` (Number of 'add' events which have been received since startup)
- `InitializeProcessedCount` (Number of 'initialize' events which have been processed since startup)
- `InitializeReceivedCount` (Number of 'initialize' events which have been received since startup)
- `ProcessedCount` (Number of 'add' events which have been processed since startup)
- `ReceivedCount` (Number of 'add' events which have been received since startup)
- `RemoveProcessedCount` (Number of 'remove' events which have been processed since startup)
- `RemoveReceivedCount` (Number of 'remove' events which have been received since startup)
- `UpdateProcessedCount` (Number of 'update' events which have been processed since startup)
- `UpdateReceivedCount` (Number of 'update' events which have been received since startup)


----

[CAE Feeder](https://documentation.coremedia.com/dxp8/7.5.42-10/manuals/search-en/webhelp/content/CAEFeederJMX.html)

