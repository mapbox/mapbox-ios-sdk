//
//  RMTileCache.h
//
// Copyright (c) 2008-2009, Route-Me Contributors
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// * Redistributions of source code must retain the above copyright notice, this
//   list of conditions and the following disclaimer.
// * Redistributions in binary form must reproduce the above copyright notice,
//   this list of conditions and the following disclaimer in the documentation
//   and/or other materials provided with the distribution.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
// CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.

#import <Foundation/Foundation.h>
#import "RMTile.h"
#import "RMTileSource.h"
#import "RMCacheObject.h"

@class RMTileImage, RMMemoryCache;

typedef enum : short {
	RMCachePurgeStrategyLRU,
	RMCachePurgeStrategyFIFO,
} RMCachePurgeStrategy;

#pragma mark -

/** The RMTileCache protocol describes behaviors that tile caches should implement. */
@protocol RMTileCache <NSObject>

/** @name Querying the Cache */

/** Returns an image from the cache if it exists. 
*   @param tile A desired RMTile.
*   @param cacheKey The key representing a certain cache.
*   @return An image of the tile that can be used to draw a portion of the map. */
- (UIImage *)cachedImage:(RMTile)tile withCacheKey:(NSString *)cacheKey;

- (void)didReceiveMemoryWarning;

@optional

/** @name Adding to the Cache */

/** Adds a tile image to specified cache.
*   @param image A tile image to be cached.
*   @param tile The RMTile describing the map location of the image.
*   @param cacheKey The key representing a certain cache. */
- (void)addImage:(UIImage *)image forTile:(RMTile)tile withCacheKey:(NSString *)cacheKey;

/** @name Clearing the Cache */

/** Removes all tile images from a cache. */
- (void)removeAllCachedImages;
- (void)removeAllCachedImagesForCacheKey:(NSString *)cacheKey;

@end

#pragma mark -

/** An RMTileCache object manages memory-based and disk-based caches for map tiles that have been retrieved from the network. 
*
*   An RMMapView has one RMTileCache across all tile sources, which is further divided according to each tile source's uniqueTilecacheKey property in order to keep tiles separate in the cache.
*
*   @see [RMDatabaseCache initUsingCacheDir:] */
@interface RMTileCache : NSObject <RMTileCache>

/** @name Initializing a Cache Manager */

/** Initializes and returns a newly allocated cache object with specified expiry period.
*
*   The internal memory-based and disk-based caches will be initialized to default settings or according to a Route-Me property list included as a resource in your project. See "File-based cache configuration" in the SDK Guide for details.
*
*   If the `init` method is used to initialize a cache instead, a period of `0` is used. In that case, time-based expiration of tiles is not performed, but rather the cached tile count is used instead.
*
*   @param period A period of time after which tiles should be expunged from the cache.
*   @return An initialized cache object or `nil` if the object couldn't be created. */
- (id)initWithExpiryPeriod:(NSTimeInterval)period;

/** Initializes and returns a newly allocated cache object with the supplied tile caches.
 *
 *  The internal memory cache will be initialized with a default size and the expiry period is set to `0`
 *
 *   @param caches An array containing memory-based or disk-based caches implementing the `RMTileCache` protocol.
 *   @return An initialized cache object or `nil` if the object couldn't be created. */
- (id)initWithCaches:(NSArray *)caches;

/** Initializes and returns a newly allocated cache object with the supplied tile caches and expiry period.
 *
 *  The internal memory cache will be initialized with a default size.
 *
 *   @param caches An array containing memory-based or disk-based caches implementing the `RMTileCache` protocol.
 *   @param period A period of time after which tiles should be expunged from the cache.
 *   @return An initialized cache object or `nil` if the object couldn't be created. */
- (id)initWithCaches:(NSArray *)caches andExpiryPeriod:(NSTimeInterval)period;

/** Initializes and returns a newly allocated cache object with the supplied memory cache, other tile caches and expiry period.
 *
 *   @param memoryCache RMMemoryCache object to be used for fast memory-based caching of the most recently used tiles.
 *   @param caches An array containing memory-based or disk-based caches implementing the `RMTileCache` protocol.
 *   @param period A period of time after which tiles should be expunged from the cache.
 *   @return An initialized cache object or `nil` if the object couldn't be created. */
- (id)initWithMemoryCache:(RMMemoryCache *)memoryCache otherCaches:(NSArray *)caches andExpiryPeriod:(NSTimeInterval)period;

/** @name Identifying Cache Objects */

/** Return an identifying hash number for the specified tile.
*
*   @param tile A tile image to hash.
*   @return A unique number for the specified tile. */
+ (NSNumber *)tileHash:(RMTile)tile;

/** @name Adding Caches to the Cache Manager */

/** Adds a given cache to the cache management system.
*
*   @param cache A memory-based or disk-based cache. */
- (void)addCache:(id <RMTileCache>)cache;
- (void)insertCache:(id <RMTileCache>)cache atIndex:(NSUInteger)index;

/** Removes a given cache from the cache management system.
 *
 *   @param cache A memory-based or disk-based cache. */
- (void)removeCache:(id <RMTileCache>)cache;

/** The list of caches managed by a cache manager. This could include memory-based, disk-based, or other types of caches conforming to the RMTileCache protocol. */
@property (nonatomic, strong) NSArray *tileCaches;

- (void)didReceiveMemoryWarning;

@end
