//
//  RMDatabaseCache.h
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

#import <UIKit/UIKit.h>
#import "RMTileCache.h"

typedef enum : NSUInteger {
    RMDatabaseCacheImageTypePNG      = 0, // default
    RMDatabaseCacheImageTypeJPEG     = 1
} RMDatabaseCacheImageType;

#pragma mark -

@class RMDatabaseCache;

/** The RMTileCacheBackgroundDelegate protocol is for receiving notifications about background tile cache download operations. */
@protocol RMDatabaseCacheBackgroundDelegate <NSObject>

@optional

/** Sent when the background caching operation begins.
 *   @param databaseCache The database cache.
 *   @param tileCount The total number of tiles required for coverage of the desired geographic area.
 *   @param tileSource The tile source providing the tiles.
 *   @param identifier Arbitrary object which is provided back to the delegate to identify the download operation. */
- (void)databaseCache:(RMDatabaseCache *)tileCache didBeginBackgroundCacheWithCount:(int)tileCount forTileSource:(id <RMTileSource>)tileSource withIdentifier:(id)identifier;

/** Sent upon caching of each tile in a background cache operation.
 *   @param databaseCache The database cache.
 *   @param tile A structure representing the tile in question.
 *   @param tileIndex The index of the tile in question, beginning with `1` and ending with totalTileCount.
 *   @param totalTileCount The total number of of tiles required for coverage of the desired geographic area.
 *   @param identifier Arbitrary object which is provided back to the delegate to identify the download operation. */
- (void)databaseCache:(RMDatabaseCache *)tileCache didBackgroundCacheTile:(RMTile)tile withIndex:(int)tileIndex ofTotalTileCount:(int)totalTileCount withIdentifier:(id)identifier;

/** Sent when all tiles have completed downloading and caching.
 *   @param databaseCache The database cache.
 *   @param identifier Arbitrary object which is provided back to the delegate to identify the download operation. */
- (void)databaseCacheDidFinishBackgroundCache:(RMDatabaseCache *)tileCache withIdentifier:(id)identifier;

/** Sent when the cache download operation has completed cancellation and the cache object is safe to dispose of.
 *   @param databaseCache The database cache.
 *   @param identifier Arbitrary object which is provided back to the delegate to identify the download operation. */
- (void)databaseCacheDidCancelBackgroundCache:(RMDatabaseCache *)tileCache withIdentifier:(id)identifier;

@end

/** An RMDatabaseCache object represents disk-based caching of map tile images. This cache is meant for longer-term storage than RMMemoryCache, potentially for long periods of time, allowing completely offline use of map view.
*
*   @warning The database cache is currently based on [SQLite](http://www.sqlite.org), a lightweight, cross-platform, file-based relational database system. The schema is independent of and unrelated to the [MBTiles](http://mbtiles.org) file format or the RMMBTilesSource tile source. */
@interface RMDatabaseCache : NSObject <RMTileCache>

/** @name Getting the Database Path */

/** The path to the SQLite database on disk that backs the cache. */
@property (nonatomic, strong) NSString *databasePath;

+ (NSString *)dbPathUsingCacheDir:(BOOL)useCacheDir;

/** @name Initializing Database Caches */

/** Initializes and returns a newly allocated database cache object at the given disk path.
*   @param path The path to use for the database backing.
*   @return An initialized cache object or `nil` if the object couldn't be created. */
- (id)initWithDatabase:(NSString *)path;

/** Initializes and returns a newly allocated database cache object.
*   @param useCacheDir If YES, use the temporary cache space for the application, meaning that the cache files can be removed when the system deems it necessary to free up space. If NO, use the application's document storage space, meaning that the cache will not be automatically removed and will be backed up during device backups. The default value is NO.
*   @return An initialized cache object or `nil` if the object couldn't be created. */
- (id)initUsingCacheDir:(BOOL)useCacheDir;

/** @name Configuring Cache Behavior */

/** Set the cache purge strategy to use for the database.
*   @param theStrategy The cache strategy to use. */
- (void)setPurgeStrategy:(RMCachePurgeStrategy)theStrategy;

/** Set the maximum tile count allowed in the database.
*   @param theCapacity The number of tiles to allow to accumulate in the database before purging begins. */
- (void)setCapacity:(NSUInteger)theCapacity;

/** A Boolean value indicating whether the database cache is read-only: tiles will not be added or removed from the cache. Defaults to NO. */
@property (nonatomic, assign) BOOL readOnly;

/** The type of images to store in the database, can be either PNG (default) or JPEG. */
@property (nonatomic, assign) RMDatabaseCacheImageType imageType;

/** The compression factor for JPEG images stored in the database. expressed as a value from 0.0 to 1.0. 
*   The value 0.0 represents the maximum compression (or lowest quality) while the value 1.0 represents 
*   the least compression (or best quality). Defaults to 0.8. This parameter is ignored for PNG images. */
@property (nonatomic, assign) CGFloat jpegQuality;

- (BOOL)containsTile:(RMTile)tile withCacheKey:(NSString *)aCacheKey;

- (void)addImageAndWait:(UIImage *)image forTile:(RMTile)tile withCacheKey:(NSString *)aCacheKey;

/** The capacity, in number of tiles, that the database cache can hold. */
@property (nonatomic, readonly, assign) NSUInteger capacity;

/** Set the minimum number of tiles to purge when clearing space in the cache.
*   @param thePurgeMinimum The number of tiles to delete at the time the cache is purged. */
- (void)setMinimalPurge:(NSUInteger)thePurgeMinimum;

/** Set the expiry period for cache purging.
*   @param theExpiryPeriod The amount of time to elapse before a tile should be removed from the cache. If set to zero, tile count-based purging will be used instead of time-based. */
- (void)setExpiryPeriod:(NSTimeInterval)theExpiryPeriod;

/** The current file size of the database cache on disk. */
- (unsigned long long)fileSize;

/** @name Background Downloading */

/** A delegate to notify of background tile cache download operations. */
@property (nonatomic, weak) id <RMDatabaseCacheBackgroundDelegate>backgroundCacheDelegate;

/** Whether or not the tile cache is currently background caching. */
@property (nonatomic, readonly, assign) BOOL isBackgroundCaching;

/** Tells the tile cache to begin background caching. Progress during the caching operation can be observed by implementing the RMTileCacheBackgroundDelegate protocol.
 *   @param tileSource The tile source from which to retrieve tiles.
 *   @param southWest The southwest corner of the geographic area to cache.
 *   @param northEast The northeast corner of the geographic area to cache.
 *   @param minZoom The minimum zoom level to cache.
 *   @param maxZoom The maximum zoom level to cache. 
 *   @param identifier Arbitrary object which will be provided back to the delegate to identify this download operation. */
- (void)beginBackgroundCacheForTileSource:(id <RMTileSource>)tileSource southWest:(CLLocationCoordinate2D)southWest northEast:(CLLocationCoordinate2D)northEast
                                  minZoom:(float)minZoom maxZoom:(float)maxZoom withIdentifier:(id)identifier;

/** Cancel any background caching.
 *
 *   This method returns immediately so as to not block the calling thread. If you wish to be notified of the actual cancellation completion, implement the tileCacheDidCancelBackgroundCache: delegate method. */
- (void)cancelBackgroundCache;

@end
