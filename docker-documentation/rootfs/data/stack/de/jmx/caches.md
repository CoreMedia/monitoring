# Caches

The cache capacity is set per key partition, defined by a key's `CacheKey.cacheClass`,
Whenever the total sum of all `CacheKey.weight` value weights of a particular cache class exceeds the configured capacity,
an eviction is performed for this cache class and some of its values will be evicted from the cache, freeing some heap space.



## Caches for CAE and Studio

- `com.coremedia:type=Cache.Classes,CacheClass="ALWAYS_STAY_IN_CACHE",application=*`
- `com.coremedia:type=Cache.Classes,CacheClass="DIGEST",application=*`
- `com.coremedia:type=Cache.Classes,CacheClass="com.coremedia.blueprint.assets.contentbeans.AMAsset",application=*`
- `com.coremedia:type=Cache.Classes,CacheClass="com.coremedia.blueprint.cae.layout.ContentBeanBackedPageGridPlacement",application=*`
- `com.coremedia:type=Cache.Classes,CacheClass="com.coremedia.blueprint.cae.layout.PageGridImpl",application=*`
- `com.coremedia:type=Cache.Classes,CacheClass="com.coremedia.blueprint.cae.search.solr.SolrQueryCacheKey",application=*`
- `com.coremedia:type=Cache.Classes,CacheClass="com.coremedia.blueprint.common.contentbeans.Page",application=*`
- `com.coremedia:type=Cache.Classes,CacheClass="com.coremedia.cae.aspect.Aspect",application=*`
- `com.coremedia:type=Cache.Classes,CacheClass="com.coremedia.cap.disk",application=*`
- `com.coremedia:type=Cache.Classes,CacheClass="com.coremedia.cap.heap",application=*`
- `com.coremedia:type=Cache.Classes,CacheClass="com.coremedia.cap.unlimited",application=*`
- `com.coremedia:type=Cache.Classes,CacheClass="com.coremedia.objectserver.dataviews.AssumesIdentity",application=*`
- `com.coremedia:type=Cache.Classes,CacheClass="com.coremedia.objectserver.view.ViewLookup",application=*`
- `com.coremedia:type=Cache.Classes,CacheClass="com.coremedia.transform.image.java2d.LoadedImageCacheKey",application=*`
- `com.coremedia:type=Cache.Classes,CacheClass="java.lang.Object",application=*`


## eCommerce Caches

- `com.coremedia:type=Cache.Classes,CacheClass="com.coremedia.livecontext.ecommerce.cache.Availability",application=*`
- `com.coremedia:type=Cache.Classes,CacheClass="com.coremedia.livecontext.ecommerce.cache.Category",application=*`
- `com.coremedia:type=Cache.Classes,CacheClass="com.coremedia.livecontext.ecommerce.cache.CommerceUser",application=*`
- `com.coremedia:type=Cache.Classes,CacheClass="com.coremedia.livecontext.ecommerce.cache.Contract",application=*`
- `com.coremedia:type=Cache.Classes,CacheClass="com.coremedia.livecontext.ecommerce.cache.ContractIdsByUser",application=*`
- `com.coremedia:type=Cache.Classes,CacheClass="com.coremedia.livecontext.ecommerce.cache.ContractsByUser",application=*`
- `com.coremedia:type=Cache.Classes,CacheClass="com.coremedia.livecontext.ecommerce.cache.DynamicPrice",application=*`
- `com.coremedia:type=Cache.Classes,CacheClass="com.coremedia.livecontext.ecommerce.cache.MarketingSpot",application=*`
- `com.coremedia:type=Cache.Classes,CacheClass="com.coremedia.livecontext.ecommerce.cache.MarketingSpots",application=*`
- `com.coremedia:type=Cache.Classes,CacheClass="com.coremedia.livecontext.ecommerce.cache.PreviewToken",application=*`
- `com.coremedia:type=Cache.Classes,CacheClass="com.coremedia.livecontext.ecommerce.cache.Product",application=*`
- `com.coremedia:type=Cache.Classes,CacheClass="com.coremedia.livecontext.ecommerce.cache.ProductsByCategory",application=*`
- `com.coremedia:type=Cache.Classes,CacheClass="com.coremedia.livecontext.ecommerce.cache.Segment",application=*`
- `com.coremedia:type=Cache.Classes,CacheClass="com.coremedia.livecontext.ecommerce.cache.Segments",application=*`
- `com.coremedia:type=Cache.Classes,CacheClass="com.coremedia.livecontext.ecommerce.cache.SegmentsByUser",application=*`
- `com.coremedia:type=Cache.Classes,CacheClass="com.coremedia.livecontext.ecommerce.cache.StaticPrice",application=*`
- `com.coremedia:type=Cache.Classes,CacheClass="com.coremedia.livecontext.ecommerce.cache.StoreInfo",application=*`
- `com.coremedia:type=Cache.Classes,CacheClass="com.coremedia.livecontext.ecommerce.cache.SubCategories",application=*`
- `com.coremedia:type=Cache.Classes,CacheClass="com.coremedia.livecontext.ecommerce.cache.TopCategories",application=*`
- `com.coremedia:type=Cache.Classes,CacheClass="com.coremedia.livecontext.ecommerce.cache.UserIsLoggedIn",application=*`
- `com.coremedia:type=Cache.Classes,CacheClass="com.coremedia.livecontext.ecommerce.cache.Workspaces",application=*`


## eCommerce Fragment Resolver

- `com.coremedia:type=Cache.Classes,CacheClass="com.coremedia.livecontext.fragment.resolver.SearchTermExternalReferenceResolver",application=*`


## Studio Caches

- `com.coremedia:type=Cache.Classes,CacheClass="ALWAYS_STAY_IN_CACHE",application=*`
- `com.coremedia:type=Cache.Classes,CacheClass="DIGEST",application=*`
- `com.coremedia:type=Cache.Classes,CacheClass="com.coremedia.blueprint.cae.search.solr.SolrQueryCacheKey",application=*`
- `com.coremedia:type=Cache.Classes,CacheClass="com.coremedia.cap.disk",application=*`
- `com.coremedia:type=Cache.Classes,CacheClass="com.coremedia.cap.heap",application=*`
- `com.coremedia:type=Cache.Classes,CacheClass="com.coremedia.cap.unlimited",application=*`
- `com.coremedia:type=Cache.Classes,CacheClass="com.coremedia.transform.image.java2d.LoadedImageCacheKey",application=*`
- `com.coremedia:type=Cache.Classes,CacheClass="java.lang.Object",application=*`




Alle oben aufgeführten Caches haben folgende Attribute:

- `Updated` (Total number of updated values of this class due to recomputation)
- `Evaluated` (Total number of key evaluations of this class)
- `Evicted` (Total number of values of this class evicted due to limited capacity)
- `Removed` (Total number of keys/values of this class removed due to invalidations)
- `AverageEvaluationTime` (Average time spent to evaluate keys of this class, taking into account all evaluations [ms])
- `Utilization` (Cache utilization, i.e. level relative to current capacity (1 min average) [%])
- `Capacity` (Capacity for this cache class (in class specific weight))
- `Level` (Current fill level for this class (in class specific weight))
- `Inserted` (Total number of inserted cache values of this class)
- `MissRate` (Miss rate, i.e. number of inserts per lookup (1 min average) [%])

