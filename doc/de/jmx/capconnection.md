# CapConnection

*Cap* ist der Einstiegspunkt für eine Verbindung zum CMS Remote-Service.

Im Vergleich zur CMS Unified API in Java hat die `CapConnection` keinen Bezug zu einer `CapSession`.


`com.coremedia:type=CapConnection,application=*`

- `BlobCacheSize` (The total number of bytes used by the disk cache )
- `BlobCacheLevel` (the number of bytes of disk space that is currently used for caching blobs)
- `BlobCacheFaults` (the number of times a blob was downloaded to local disk)
- `HeapCacheSize` (The total number of bytes used by the main memory cache)
- `HeapCacheLevel` (the number of bytes of main memory space that is currently used for caching)
- `HeapCacheFaults` (the number of times a value was requested from the heap cache that had to be fetched or computed)
- `NumberOfSUSessions` (the number of lightweight sessions)
- `Open` (whether the CapConnection has been opened and has not been closed since)
- `WorkflowRepositoryAvailable` (whether the workflow repository is currently available)
- `ContentRepositoryAvailable` (whether the content repository is currently available)

(Die Beans `WorkflowRepositoryAvailable` und `ContentRepositoryAvailable` stehen nicht bei allen Applikationen zur Verfügung.)
