# Solr

## Standard Checks for **every** core

- `solr/%CORE%:type=/replication,id=org.apache.solr.handler.ReplicationHandler`

    * `errors` (Return number of errors)
    * `isMaster` (used for Replication Setup)
    * `isSlave` (used for Replication Setup)
    * `requests` (Return number of requests)
    * `medianRequestTime` (Median of all the request processing time.)
    * `indexVersion` (Returns the version of the latest replicatable index on the specified master or slave.)
    * `indexSize` (Size of the index at that particular instance (in KBs).)
    * `generation` (Return the Index generation)


- `solr/%CORE%:type=queryResultCache,id=org.apache.solr.search.LRUCache`

    * `cumulative_evictions` (Number of cache evictions across all caches since this node has been running.
    * `cumulative_hitratio` (Ratio of cache hits to lookups across all the caches since this node has been running.)
    * `cumulative_hits` (Number of cache hits across all the caches since this node has been running.)
    * `cumulative_inserts` (Number of cache insertions across all the caches since this node has been running.)
    * `cumulative_lookups` (Number of cache lookups across all the caches since this node has been running.)
    * `description` ()
    * `evictions` (Number of cache evictions for the current index searcher.)
    * `hitratio` (Ratio of cache hits to lookups for the current index searcher.)
    * `hits` (Number of hits for the current index searcher.)
    * `inserts` (Number of inserts into the cache.)
    * `lookups` (Number of lookups against the cache.)
    * `size` (Size of the cache at that particular instance (in KBs).)
    * `warmupTime` (Warm-up time for the registered index searcher. This time is taken in account for the “auto-warming” of caches.)


- `solr/%CORE%:type=documentCache,id=org.apache.solr.search.LRUCache`

    * `cumulative_evictions` (Number of cache evictions across all caches since this node has been running.
    * `cumulative_hitratio` (Ratio of cache hits to lookups across all the caches since this node has been running.)
    * `cumulative_hits` (Number of cache hits across all the caches since this node has been running.)
    * `cumulative_inserts` (Number of cache insertions across all the caches since this node has been running.)
    * `cumulative_lookups` (Number of cache lookups across all the caches since this node has been running.)
    * `description` ()
    * `evictions` (Number of cache evictions for the current index searcher.)
    * `hitratio` (Ratio of cache hits to lookups for the current index searcher.)
    * `hits` (Number of hits for the current index searcher.)
    * `inserts` (Number of inserts into the cache.)
    * `lookups` (Number of lookups against the cache.)
    * `size` (Size of the cache at that particular instance (in KBs).)
    * `warmupTime` (Warm-up time for the registered index searcher. This time is taken in account for the “auto-warming” of caches.)


- `solr/%CORE%:type=/select,id=org.apache.solr.handler.component.SearchHandler`

    * `avgRequestsPerSecond` (Average number of requests received per second.)
    * `avgTimePerRequest` (Average time taken for processing the requests. This parameter will decay over time, with a bias toward activity in the last 5 minutes.)
    * `medianRequestTime` (Median of all the request processing time.)
    * `requests` (Total number of requests made since the Solr process was started.)
    * `timeouts` (Number of responses received with partial results.)
    * `errors` (Number of error encountered by handler.)


*NOTE*
**Every** Solr Core has thes checks above!
