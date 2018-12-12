# JMX - Standard Tomcat


- `java.lang:type=Memory`
    * `HeapMemoryUsage`
    * `NonHeapMemoryUsage`


- `java.lang:type=Threading`
    * `TotalStartedThreadCount`
    * `ThreadCount`
    * `DaemonThreadCount`
    * `PeakThreadCount`


- `java.lang:type=ClassLoading`
    * `TotalLoadedClassCount`
    * `LoadedClassCount`
    * `UnloadedClassCount`


- `java.lang:type=GarbageCollector,name=ParNew`
    * `CollectionCount`
    * `CollectionTime`
    * `LastGcInfo`
        - `GcThreadCount`
        - `duration`
        - `endTime`
        - `startTime`


- `java.lang:type=GarbageCollector,name=ConcurrentMarkSweep`
    * `CollectionCount`
    * `CollectionTime`
    * `LastGcInfo`
        - `GcThreadCount`
        - `duration`
        - `endTime`
        - `startTime`


- `Catalina:type=Executor,name=tomcatThreadPool`
    * `activeCount`
    * `completedTaskCount`
    * `corePoolSize`
    * `poolSize`
    * `queueSize`
    * `maxQueueSize`

