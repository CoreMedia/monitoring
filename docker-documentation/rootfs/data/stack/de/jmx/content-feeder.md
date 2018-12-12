# Contentfeeder


## CapConnection

The management interface for the CapConnection to allow its configuration and profiling.

[siehe](./capconnection.md)



## Feeder

The management interface for the Feeder and its Index.


`com.coremedia:type=Feeder,application=*`

- `State` (the state of the feeder.)
- `StateNumeric` (the state of the feeder:
    * 0 = `stopped`
    * 1 = `starting`
    * 2 = `initializing`
    * 3 = `running`
    * 4 = `failed`)
- `Uptime` (the uptime in seconds.)
- `CurrentPendingDocuments` (The number of documents in the currently feeded folder to re-index after rights rule changes.) (**outdated since 1710**)
- `IndexDocuments` (the number of persisted index documents in the last interval.)
- `IndexContentDocuments` (Number of persisted index documents representing content)
- `IndexBytes` (the persisted bytes in the last interval.)
- `PendingEvents` (Number of events behind most recent event)
- `PendingFolders` (The number of contents in the currently processed folder still to be reindexed after rights rule changes.) (**outdated since 1710**)
- `PersistedEvents` (Returns the persisted events in the last interval.)


## Background Feeds

Triggers feeding of index changes in the background with lower priority than changes directly caused by
content repository events.

### AdminBackgroundFeed

`com.coremedia:type=AdminBackgroundFeed,application=content-feeder`

- `NumberOfPendingContents` (Number of contents left for current reindexing)


### AssetTaxonomyIdsBackgroundFeed

`com.coremedia:type=AssetTaxonomyIdsBackgroundFeed,application=content-feeder`

- `CurrentPendingContents` (The number of contents below the currently processed tree node)


### LocationTaxonomyIdsBackgroundFeed

`com.coremedia:type=LocationTaxonomyIdsBackgroundFeed,application=content-feeder`

- `CurrentPendingContents` (The number of contents below the currently processed tree node)


### SubjectTaxonomyIdsBackgroundFeed

`com.coremedia:type=SubjectTaxonomyIdsBackgroundFeed,application=content-feeder`

- `CurrentPendingContents` (The number of contents below the currently processed tree node)


### UpdateGroupsBackgroundFeed

`com.coremedia:type=UpdateGroupsBackgroundFeed,application=content-feeder`

- `CurrentPendingContents` (The number of contents in the currently processed folder)





