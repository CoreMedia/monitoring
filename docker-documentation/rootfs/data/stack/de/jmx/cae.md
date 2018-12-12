# CAE


## CapConnection

The management interface for the CapConnection to allow its configuration and profiling.

[siehe](./capconnection.md)


## DataViewFactory

Create a cached view of an otherwise uncached bean from a symbolic view name.

`com.coremedia:type=DataViewFactory,application=*`

- `ActiveTimeOfComputedDataViews` (the number of milliseconds spent computing dataviews since startup, excluding time spent computing other cache entries)
- `NumberOfCachedDataViews` (the number of data views currently in the cache)
- `NumberOfComputedDataViews` (the total number of data view computations (i.e. cache faults) since startup)
- `NumberOfDataViewLookups` (the total number of data view lookups since startup)
- `NumberOfEvictedDataViews` (the total number of data views evicted from the cache since startup)
- `NumberOfInvalidatedDataViews` (the total number of data views invalidations since startup)
- `TotalTimeOfComputedDataViews` (the number of milliseconds spent computing dataviews since startup, including time spent computing other cache entries)
