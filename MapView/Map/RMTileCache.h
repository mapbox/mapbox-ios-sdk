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

@end

#pragma mark -

/** An RMTileCache object manages memory-based and disk-based cache for map tiles that have been retrieved from the network. */
@interface RMTileCache : NSObject <RMTileCache>

/** @name Initializing a Cache Manager */

/** Initializes and returns a newly allocated cache object with specified expiry period.
*
*   If the `init` method is used to initialize a cache instead, a period of `0` is used. In that case, time-based expiration of tiles is not performed, but rather the cached tile count is used instead.
*
*   @param period A period of time after which tiles should be expunged from the cache.
*   @return An initialized cache object or `nil` if the object couldn't be created. */
- (id)initWithExpiryPeriod:(NSTimeInterval)period;

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

- (void)didReceiveMemoryWarning;

@end
