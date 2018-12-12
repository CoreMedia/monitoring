# Replication-Live-Server

## Replicator

The replicator is an active service that repeats the actions it
receives from a publication server via the RepositoryListener interface.

It's an object living in the server process and accesses internal server interfaces.


`com.coremedia:type=Replicator,application=*`

- `ConnectionUp` (whether the connection to the master live server is up)
- `ControllerState` (the current state of the replicator, one of:
    * `failed`
    * `stopped`
    * `running`
    * `not started`)
- `Enabled` (whether the continuous replication of content changes is enabled)
- `PipelineUp` (whether the replicator event processing pipeline is up and running)
- `IncomingCount` (Total number of events that have arrived since server startup)
- `CompletedCount` (Total number of events that have been completed since server startup)
- `UncompletedCount` ()
- `LatestCompletedSequenceNumber` (Sequence number of the latest completed event)
- `LatestCompletedArrival` (Date of the latest completion of an event)
- `LatestCompletionDuration` (Difference in milliseconds between the arrival and the completion of the latest completed event since server startup)
- `LatestIncomingSequenceNumber` (Sequence number of the latest incoming event)
- `LatestIncomingArrival` (Date of the latest arrival of an incoming event)
- `LatestCompletedStampedNumber` (Sequence number of the latest completion of a StampedEvent (indicates the end of a publication))
- `LatestIncomingStampedNumber` (Sequence number of the latest incoming StampedEvent (indicates the end of a publication))
- `MasterLiveServerIORUrl` (Master Liver Server IOR Url)

----

[Analyzing the Replicator State](https://documentation.coremedia.com/cms-9/artifacts/1801/webhelp/contentserver-en/content/AnalyzingtheReplicatorState.html)
