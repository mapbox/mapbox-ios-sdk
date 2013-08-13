//
//  RMDatabaseCache.m
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

#import "RMDatabaseCache.h"
#import "FMDatabase.h"
#import "FMDatabaseQueue.h"
#import "RMTileImage.h"
#import "RMTile.h"
#import "RMDatabaseCacheDownloadOperation.h"

#define kWriteQueueLimit 15

@interface RMDatabaseCache ()

- (NSUInteger)count;
- (NSUInteger)countTiles;
- (void)touchTile:(RMTile)tile withKey:(NSString *)cacheKey;
- (void)purgeTiles:(NSUInteger)count;

@end

#pragma mark -

@implementation RMDatabaseCache
{
    // Database
    FMDatabaseQueue *_queue;

    NSUInteger _tileCount;
    NSOperationQueue *_writeQueue;
    NSRecursiveLock *_writeQueueLock;

    // Cache
    RMCachePurgeStrategy _purgeStrategy;
    NSUInteger _capacity;
    NSUInteger _minimalPurge;
    NSTimeInterval _expiryPeriod;

    id <RMTileSource> _activeTileSource;
    NSOperationQueue *_backgroundFetchQueue;
    id _backgroundCacheIdentifier;
}

@synthesize databasePath                = _databasePath;
@synthesize backgroundCacheDelegate     = _backgroundCacheDelegate;
@synthesize readOnly                    = _readOnly;

+ (NSString *)dbPathUsingCacheDir:(BOOL)useCacheDir
{
	NSArray *paths;

	if (useCacheDir)
		paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
	else
		paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);

	if ([paths count] > 0) // Should only be one...
	{
		NSString *cachePath = [paths objectAtIndex:0];

		// check for existence of cache directory
		if ( ![[NSFileManager defaultManager] fileExistsAtPath: cachePath])
		{
			// create a new cache directory
			[[NSFileManager defaultManager] createDirectoryAtPath:cachePath withIntermediateDirectories:NO attributes:nil error:NULL];
		}

		return [cachePath stringByAppendingPathComponent:@"RMTileCache.db"];
	}

	return nil;
}

- (void)configureDBForFirstUse
{
    [_queue inDatabase:^(FMDatabase *db) {
        [[db executeQuery:@"PRAGMA synchronous=OFF"] close];
        [[db executeQuery:@"PRAGMA journal_mode=OFF"] close];
        [[db executeQuery:@"PRAGMA cache-size=100"] close];
        [[db executeQuery:@"PRAGMA count_changes=OFF"] close];
        [db executeUpdate:@"CREATE TABLE IF NOT EXISTS ZCACHE (tile_hash INTEGER NOT NULL, cache_key VARCHAR(25) NOT NULL, last_used DOUBLE NOT NULL, data BLOB NOT NULL)"];
        [db executeUpdate:@"CREATE UNIQUE INDEX IF NOT EXISTS main_index ON ZCACHE(tile_hash, cache_key)"];
        [db executeUpdate:@"CREATE INDEX IF NOT EXISTS last_used_index ON ZCACHE(last_used)"];
    }];
}

- (id)initWithDatabase:(NSString *)path
{
	if (!(self = [super init]))
		return nil;

	self.databasePath = path;
    self.backgroundCacheDelegate = nil;
    self.readOnly = NO;

    _activeTileSource = nil;
    _backgroundFetchQueue = nil;
    _backgroundCacheIdentifier = nil;
    
    _imageType = RMDatabaseCacheImageTypePNG;
    _jpegQuality = 0.8;
    
    _writeQueue = [NSOperationQueue new];
    [_writeQueue setMaxConcurrentOperationCount:1];
    _writeQueueLock = [NSRecursiveLock new];

	RMLog(@"Opening database at %@", path);

    _queue = [FMDatabaseQueue databaseQueueWithPath:path];

	if (!_queue)
	{
		RMLog(@"Could not connect to database");

        [[NSFileManager defaultManager] removeItemAtPath:path error:NULL];

        return nil;
	}

    [_queue inDatabase:^(FMDatabase *db) {
        [db setCrashOnErrors:NO];
        [db setShouldCacheStatements:TRUE];
    }];

	[self configureDBForFirstUse];

    _tileCount = [self countTiles];

	return self;	
}

- (id)initUsingCacheDir:(BOOL)useCacheDir
{
	return [self initWithDatabase:[RMDatabaseCache dbPathUsingCacheDir:useCacheDir]];
}

- (void)dealloc
{
    if (self.isBackgroundCaching)
        [self cancelBackgroundCache];
    
    [_writeQueueLock lock];
     _writeQueue = nil;
    [_writeQueueLock unlock];
     _writeQueueLock = nil;
     _queue = nil;
}

- (void)setPurgeStrategy:(RMCachePurgeStrategy)theStrategy
{
	_purgeStrategy = theStrategy;
}

- (void)setCapacity:(NSUInteger)theCapacity
{
	_capacity = theCapacity;
}

- (NSUInteger)capacity
{
    return _capacity;
}

- (void)setMinimalPurge:(NSUInteger)theMinimalPurge
{
	_minimalPurge = theMinimalPurge;
}

- (void)setExpiryPeriod:(NSTimeInterval)theExpiryPeriod
{
    _expiryPeriod = theExpiryPeriod;
    
    srand(time(NULL));
}

- (unsigned long long)fileSize
{
    return [[[NSFileManager defaultManager] attributesOfItemAtPath:self.databasePath error:NULL] fileSize];
}

- (UIImage *)cachedImage:(RMTile)tile withCacheKey:(NSString *)aCacheKey
{
//	RMLog(@"DB cache check for tile %d %d %d", tile.x, tile.y, tile.zoom);

    __block UIImage *cachedImage = nil;

    [_writeQueueLock lock];

    [_queue inDatabase:^(FMDatabase *db)
     {
         FMResultSet *results = [db executeQuery:@"SELECT data FROM ZCACHE WHERE tile_hash = ? AND cache_key = ? LIMIT 1", [RMTileCache tileHash:tile], aCacheKey];

         if ([db hadError])
         {
             RMLog(@"DB error while fetching tile data: %@", [db lastErrorMessage]);
             return;
         }

         NSData *data = nil;

         if ([results next])
         {
             data = [results dataForColumnIndex:0];
             if (data) cachedImage = [UIImage imageWithData:data];
         }

         [results close];
     }];

    [_writeQueueLock unlock];

    if (_capacity != 0 && _purgeStrategy == RMCachePurgeStrategyLRU)
        [self touchTile:tile withKey:aCacheKey];

    if (_expiryPeriod > 0)
    {
        if (rand() % 100 == 0)
        {
            [_writeQueueLock lock];

            [_queue inDatabase:^(FMDatabase *db)
             {
                 BOOL result = [db executeUpdate:@"DELETE FROM ZCACHE WHERE last_used < ?", [NSDate dateWithTimeIntervalSinceNow:-_expiryPeriod]];

                 if (result == NO)
                     RMLog(@"DB error while expiring cache: %@", [db lastErrorMessage]);

                 [[db executeQuery:@"VACUUM"] close];
             }];

            [_writeQueueLock unlock];

            _tileCount = [self countTiles];
        }
    }

//    RMLog(@"DB cache     hit    tile %d %d %d (%@)", tile.x, tile.y, tile.zoom, [RMTileCache tileHash:tile]);

	return cachedImage;
}

- (BOOL)containsTile:(RMTile)tile withCacheKey:(NSString *)aCacheKey
{
    __block BOOL result = NO;
    
    [_writeQueueLock lock];
    
    [_queue inDatabase:^(FMDatabase *db)
     {
         FMResultSet *results = [db executeQuery:@"SELECT 1 FROM ZCACHE WHERE tile_hash = ? AND cache_key = ? LIMIT 1", [RMTileCache tileHash:tile], aCacheKey];
         
         if ([db hadError])
         {
             RMLog(@"DB error while fetching tile data: %@", [db lastErrorMessage]);
             return;
         }
         
         if ([results next])
             result = YES;
         
         [results close];
     }];
    
    
    [_writeQueueLock unlock];
    
    return result;
}

- (void)addImage:(UIImage *)image forTile:(RMTile)tile withCacheKey:(NSString *)aCacheKey
{
    [self addImage:image forTile:tile withCacheKey:aCacheKey useQueue:YES];
}

- (void)addImageAndWait:(UIImage *)image forTile:(RMTile)tile withCacheKey:(NSString *)aCacheKey
{
    [self addImage:image forTile:tile withCacheKey:aCacheKey useQueue:NO];
}

- (void)addImage:(UIImage *)image forTile:(RMTile)tile withCacheKey:(NSString *)aCacheKey useQueue:(BOOL)useQueue
{
    if (self.readOnly || self.capacity == 0) return;

    // TODO: Converting the image here (again) is not so good...
    NSData *data;
    if (self.imageType == RMDatabaseCacheImageTypePNG)
        data = UIImagePNGRepresentation(image);
    else if (self.imageType == RMDatabaseCacheImageTypeJPEG)
        data = UIImageJPEGRepresentation(image, self.jpegQuality);
    
    NSUInteger tilesInDb = [self count];
    
    if (_capacity <= tilesInDb && _expiryPeriod == 0)
        [self purgeTiles:MAX(_minimalPurge, 1+tilesInDb-_capacity)];
    
    //        RMLog(@"DB cache     insert tile %d %d %d (%@)", tile.x, tile.y, tile.zoom, [RMTileCache tileHash:tile]);
    
    // Don't add new images to the database while there are still more than kWriteQueueLimit
    // insert operations pending. This prevents some memory issues.
    
    BOOL skipThisTile = NO;
    
    [_writeQueueLock lock];
    
    if (useQueue && [_writeQueue operationCount] > kWriteQueueLimit) {
        RMLog(@"RMDatabaseCache write queue limit exceeded, skipped writing tile to cache.");
        skipThisTile = YES;
    }
    
    [_writeQueueLock unlock];
    
    if (skipThisTile)
        return;

    void (^dbBlock) (void) = ^{
        [_writeQueueLock lock];
        
        [_queue inDatabase:^(FMDatabase *db)
         {
             BOOL result = [db executeUpdate:@"INSERT OR IGNORE INTO ZCACHE (tile_hash, cache_key, last_used, data) VALUES (?, ?, ?, ?)", [RMTileCache tileHash:tile], aCacheKey, [NSDate date], data];
             if (result == NO)
                 RMLog(@"DB error while adding tile data: %@", [db lastErrorMessage]);
             else
                 _tileCount++;
         }];
        
        [_writeQueueLock unlock];
    };
    
    if (useQueue)
        [_writeQueue addOperationWithBlock:dbBlock];
    else
        dbBlock();
}

#pragma mark -

- (NSUInteger)count
{
    return _tileCount;
}

- (NSUInteger)countTiles
{
    __block NSUInteger count = 0;

    [_writeQueueLock lock];

    [_queue inDatabase:^(FMDatabase *db)
     {
         FMResultSet *results = [db executeQuery:@"SELECT COUNT(tile_hash) FROM ZCACHE"];

         if ([results next])
             count = [results intForColumnIndex:0];
         else
             RMLog(@"Unable to count columns");

         [results close];
     }];

    [_writeQueueLock unlock];

	return count;
}

- (void)purgeTiles:(NSUInteger)count
{
    if (self.readOnly) return;

    RMLog(@"purging %u old tiles from the db cache", count);

    [_writeQueueLock lock];

    [_queue inDatabase:^(FMDatabase *db)
     {
         BOOL result = [db executeUpdate:@"DELETE FROM ZCACHE WHERE tile_hash IN (SELECT tile_hash FROM ZCACHE ORDER BY last_used LIMIT ?)", [NSNumber numberWithUnsignedInt:count]];

         if (result == NO)
             RMLog(@"Error purging cache");

         [[db executeQuery:@"VACUUM"] close];
     }];

    [_writeQueueLock unlock];

    _tileCount = [self countTiles];
}

- (void)removeAllCachedImages 
{
    if (self.readOnly) return;

    RMLog(@"removing all tiles from the db cache");

    [_writeQueue addOperationWithBlock:^{
        [_writeQueueLock lock];

        [_queue inDatabase:^(FMDatabase *db)
         {
             BOOL result = [db executeUpdate:@"DELETE FROM ZCACHE"];

             if (result == NO)
                 RMLog(@"Error purging cache");

             [[db executeQuery:@"VACUUM"] close];
         }];

        [_writeQueueLock unlock];

        _tileCount = [self countTiles];
    }];
}

- (void)removeAllCachedImagesForCacheKey:(NSString *)cacheKey
{
    if (self.readOnly) return;

    RMLog(@"removing tiles for key '%@' from the db cache", cacheKey);

    [_writeQueue addOperationWithBlock:^{
        [_writeQueueLock lock];

        [_queue inDatabase:^(FMDatabase *db)
         {
             BOOL result = [db executeUpdate:@"DELETE FROM ZCACHE WHERE cache_key = ?", cacheKey];

             if (result == NO)
                 RMLog(@"Error purging cache");
         }];

        [_writeQueueLock unlock];

        _tileCount = [self countTiles];
    }];
}

- (void)touchTile:(RMTile)tile withKey:(NSString *)cacheKey
{
    if (self.readOnly) return;

    [_writeQueue addOperationWithBlock:^{
        [_writeQueueLock lock];

        [_queue inDatabase:^(FMDatabase *db)
         {
             BOOL result = [db executeUpdate:@"UPDATE ZCACHE SET last_used = ? WHERE tile_hash = ? AND cache_key = ?", [NSDate date], [RMTileCache tileHash:tile], cacheKey];

             if (result == NO)
                 RMLog(@"Error touching tile");
         }];

        [_writeQueueLock unlock];
    }];
}

- (BOOL)isBackgroundCaching
{
    return (_activeTileSource || _backgroundFetchQueue);
}

- (void)beginBackgroundCacheForTileSource:(id <RMTileSource>)tileSource southWest:(CLLocationCoordinate2D)southWest northEast:(CLLocationCoordinate2D)northEast
                                  minZoom:(float)minZoom maxZoom:(float)maxZoom withIdentifier:(id)identifier
{
    if (self.isBackgroundCaching || self.readOnly)
        return;
    
    _activeTileSource = tileSource;
    _backgroundCacheIdentifier = identifier;
    
    _backgroundFetchQueue = [[NSOperationQueue alloc] init];
    [_backgroundFetchQueue setMaxConcurrentOperationCount:6];
    
    int   minCacheZoom = (int)minZoom;
    int   maxCacheZoom = (int)maxZoom;
    float minCacheLat  = southWest.latitude;
    float maxCacheLat  = northEast.latitude;
    float minCacheLon  = southWest.longitude;
    float maxCacheLon  = northEast.longitude;
    
    if (maxCacheZoom < minCacheZoom || maxCacheLat <= minCacheLat || maxCacheLon <= minCacheLon)
        return;
    
    int n, xMin, yMax, xMax, yMin;
    
    int totalTiles = 0;
    
    for (int zoom = minCacheZoom; zoom <= maxCacheZoom; zoom++)
    {
        n = pow(2.0, zoom);
        xMin = floor(((minCacheLon + 180.0) / 360.0) * n);
        yMax = floor((1.0 - (logf(tanf(minCacheLat * M_PI / 180.0) + 1.0 / cosf(minCacheLat * M_PI / 180.0)) / M_PI)) / 2.0 * n);
        xMax = floor(((maxCacheLon + 180.0) / 360.0) * n);
        yMin = floor((1.0 - (logf(tanf(maxCacheLat * M_PI / 180.0) + 1.0 / cosf(maxCacheLat * M_PI / 180.0)) / M_PI)) / 2.0 * n);
        
        totalTiles += (xMax + 1 - xMin) * (yMax + 1 - yMin);
    }
    
    [_backgroundCacheDelegate databaseCache:self didBeginBackgroundCacheWithCount:totalTiles forTileSource:_activeTileSource withIdentifier:_backgroundCacheIdentifier];
    
    __block int progTile = 0;
    
    for (int zoom = minCacheZoom; zoom <= maxCacheZoom; zoom++)
    {
        n = pow(2.0, zoom);
        xMin = floor(((minCacheLon + 180.0) / 360.0) * n);
        yMax = floor((1.0 - (logf(tanf(minCacheLat * M_PI / 180.0) + 1.0 / cosf(minCacheLat * M_PI / 180.0)) / M_PI)) / 2.0 * n);
        xMax = floor(((maxCacheLon + 180.0) / 360.0) * n);
        yMin = floor((1.0 - (logf(tanf(maxCacheLat * M_PI / 180.0) + 1.0 / cosf(maxCacheLat * M_PI / 180.0)) / M_PI)) / 2.0 * n);
        
        for (int x = xMin; x <= xMax; x++)
        {
            for (int y = yMin; y <= yMax; y++)
            {
                RMDatabaseCacheDownloadOperation *operation = [[RMDatabaseCacheDownloadOperation alloc] initWithTile:RMTileMake(x, y, zoom)
                                                                                               forTileSource:_activeTileSource
                                                                                                  usingCache:self];
                
                __block RMDatabaseCacheDownloadOperation *internalOperation = operation;
                
                [operation setCompletionBlock:^(void)
                 {
                     dispatch_sync(dispatch_get_main_queue(), ^(void)
                                   {
                                       if ( ! [internalOperation isCancelled])
                                       {
                                           progTile++;
                                           
                                           if ( ! internalOperation.tileExisted )
                                           {
                                               [_backgroundCacheDelegate databaseCache:self didBackgroundCacheTile:RMTileMake(x, y, zoom)
                                                                             withIndex:progTile ofTotalTileCount:totalTiles withIdentifier:_backgroundCacheIdentifier];
                                           }
                                           
                                           if (progTile == totalTiles)
                                           {
                                               _backgroundFetchQueue = nil;
                                               
                                               _activeTileSource = nil;
                                               
                                               [_backgroundCacheDelegate databaseCacheDidFinishBackgroundCache:self  withIdentifier:_backgroundCacheIdentifier];
                                           }
                                       }
                                       
                                       internalOperation = nil;
                                   });
                 }];
                
                [_backgroundFetchQueue addOperation:operation];
            }
        }
    };
}

- (void)cancelBackgroundCache
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void)
                   {
                       @synchronized (self)
                       {
                           BOOL didCancel = NO;
                           
                           if (_backgroundFetchQueue)
                           {
                               [_backgroundFetchQueue cancelAllOperations];
                               [_backgroundFetchQueue waitUntilAllOperationsAreFinished];
                               _backgroundFetchQueue = nil;
                               
                               didCancel = YES;
                           }
                           
                           if (_activeTileSource)
                               _activeTileSource = nil;
                           
                           if (didCancel)
                           {
                               dispatch_sync(dispatch_get_main_queue(), ^(void)
                                             {
                                                 [_backgroundCacheDelegate databaseCacheDidCancelBackgroundCache:self withIdentifier:_backgroundCacheIdentifier];
                                             });
                           }
                       }
                   });
}


- (void)didReceiveMemoryWarning
{
    RMLog(@"Low memory in the database tilecache");

    [_writeQueueLock lock];
    [_writeQueue cancelAllOperations];
    [_writeQueueLock unlock];
}

@end
