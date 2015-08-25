//
//  RMFileCache.m
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

#import "RMFileUtils.h"
#import "RMFileCache.h"
#import "FMDB.h"
#import "RMTileImage.h"
#import "RMTile.h"

#import <Reachability/Reachability.h>

#define kWriteQueueLimit 15

@interface RMFileCache ()

@property (nonatomic, strong) NSFileManager *fileManager;
@property (atomic) NSUInteger tileCount;

- (NSUInteger)count;
- (NSUInteger)countTiles;
- (void)touchTile:(RMTile)tile withKey:(NSString *)cacheKey;
- (void)purgeTiles:(NSUInteger)count;

@end

#pragma mark -

@implementation RMFileCache
{
    // Cache
    RMCachePurgeStrategy _purgeStrategy;
    NSUInteger _capacity;
    NSUInteger _minimalPurge;
    NSTimeInterval _expiryPeriod;
    BOOL _reachable;
}

static dispatch_queue_t queue;

@synthesize tileCachePath = _tileCachePath;

+ (NSString *)tileCachePathUsingCacheDir:(BOOL)useCacheDir
{
	NSArray *paths;

	if (useCacheDir)
		paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
	else
		paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);

	if ([paths count] > 0) // Should only be one...
	{
		NSString *cachePath = [paths objectAtIndex:0];
        cachePath = [cachePath stringByAppendingPathComponent:@"/tiles/"];

		// check for existence of cache directory
		if ( ![[NSFileManager defaultManager] fileExistsAtPath: cachePath])
		{
			// create a new cache directory
			[[NSFileManager defaultManager] createDirectoryAtPath:cachePath withIntermediateDirectories:NO attributes:nil error:nil];
		}

		return cachePath;
	}

	return nil;
}

- (void)didReceiveMemoryWarning
{
    //RMLog(@"Received memory warning in file cache");
}

- (id)initWithTileCachePath:(NSString *)path
{
	if (!(self = [super init]))
		return nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        queue = dispatch_queue_create("com.mapbox.filecache", 0);
        dispatch_set_target_queue(queue, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0));
    });

	self.tileCachePath = path;
    self.fileManager = [NSFileManager new];

    self.tileCount = [self countTiles];
    
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(reachabilityChanged:) name:kReachabilityChangedNotification object:nil];
    _reachable = [Reachability.reachabilityForInternetConnection isReachable];

	return self;	
}

- (id)initUsingCacheDir:(BOOL)useCacheDir
{
	return [self initWithTileCachePath:[RMFileCache tileCachePathUsingCacheDir:useCacheDir]];
}

- (void)dealloc
{
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

- (void)reachabilityChanged:(NSNotification *)notification
{
    Reachability *reachability = (Reachability *)notification.object;
    _reachable = reachability.isReachable;
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

- (void)setCapacityBytes:(NSUInteger)theCapacityBytes
{
    _capacityBytes = theCapacityBytes;
    
    [self constrainFileSize];
}

- (void)setMinimalPurge:(NSUInteger)theMinimalPurge
{
	_minimalPurge = theMinimalPurge;
}

- (void)setExpiryPeriod:(NSTimeInterval)theExpiryPeriod
{
    _expiryPeriod = theExpiryPeriod;
    
    srand((unsigned int)time(NULL));
}

- (NSString *)pathForCachedTileWithHash:(NSNumber *)tileHash andKey:(NSString *)key
{
    return [[self tileCachePath] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@-%@", key, tileHash]];
}

- (UIImage *)cachedImage:(RMTile)tile withCacheKey:(NSString *)aCacheKey
{
    if (_capacity != 0 && _purgeStrategy == RMCachePurgeStrategyLRU)
        [self touchTile:tile withKey:aCacheKey];
    
    if (_expiryPeriod > 0)
    {
        NSString *path = [self pathForCachedTileWithHash:[RMTileCache tileHash:tile] andKey:aCacheKey];
        
        if ([RMFileUtils ageOfFileAtPath:path] > _expiryPeriod && _reachable) {
            [self.fileManager removeItemAtPath:path error:nil];
        }
        
        _tileCount = self.countTiles;
    }
    
    return [UIImage imageWithContentsOfFile:[self pathForCachedTileWithHash:[RMTileCache tileHash:tile] andKey:aCacheKey]];
}

- (void)addImageWithData:(NSData *)data forTile:(RMTile)tile withCacheKey:(NSString *)aCacheKey
{
	static skipper = 0;

    if (_capacity != 0)
    {
        NSUInteger tilesInDb = [self count];

        if (_capacity <= tilesInDb && _expiryPeriod == 0)
            [self purgeTiles:MAX(_minimalPurge, 1+tilesInDb-_capacity)];
        
        if (skipper >= 10) { //Only check file size every nth tile because its a costy process
            [self constrainFileSize];
            skipper = 0;
        }
        skipper++;

        dispatch_async(queue, ^{
            [data writeToFile:[self pathForCachedTileWithHash:[RMTileCache tileHash:tile] andKey:aCacheKey] atomically:YES];
            _tileCount++;
        });
	}
}

#pragma mark -

- (NSUInteger)count
{
    return _tileCount;
}

- (NSUInteger)countTiles
{
    NSUInteger count = 0;

    count = [[self.fileManager contentsOfDirectoryAtPath:[self tileCachePath] error:nil] count];

	return count;
}

- (void)purgeTiles:(NSUInteger)count
{
    dispatch_async(queue, ^{
        RMLog(@"purging %lu old tiles from the file cache", (unsigned long)count);
        
        NSMutableArray *items = [NSMutableArray new];
        [[self.fileManager contentsOfDirectoryAtPath:[self tileCachePath] error:nil] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            NSDate *date = [RMFileUtils modificationDateForFileAtPath:[[self tileCachePath] stringByAppendingPathComponent:obj]];
            if (date) {
                NSDictionary *item = @{obj: date};
                [items addObject:item];
            }
        }];
        
        [items sortUsingComparator:^NSComparisonResult(NSDictionary *obj1, NSDictionary *obj2) {
            NSDate* obj1Date = obj1.allValues[0];
            NSDate* obj2Date = obj2.allValues[0];
            
            return [obj1Date compare:obj2Date];
        }];
        
        NSUInteger deletedFiles = 0;
        for (NSDictionary *fileDictionary in items) {
            NSString *filePath = [[self tileCachePath] stringByAppendingPathComponent:fileDictionary.allKeys[0]];
            [self.fileManager removeItemAtPath:filePath error:nil];
            deletedFiles++;
            
            if (deletedFiles >= count) {
                break;
            }
        }
        
        _tileCount = [self countTiles];
    });
}

- (void)constrainFileSize
{
    dispatch_async(queue, ^{
        unsigned long long int folderSize = [RMFileUtils folderSize:[self tileCachePath]];
        if (folderSize > _capacityBytes) {
            RMLog(@"constraining db cache size %lluM", folderSize / (1024 * 1024));
            [self purgeTiles:_minimalPurge];
        }
    });
}

- (void)removeAllCachedImages
{
    RMLog(@"removing all tiles from the file cache");

    dispatch_async(queue, ^{
        NSArray *items = [self.fileManager contentsOfDirectoryAtPath:[self tileCachePath] error:nil];
        for (NSString *file in items) {
            [self.fileManager removeItemAtPath:[[self tileCachePath] stringByAppendingPathComponent:file] error:nil];
        }
        
        self.tileCount = [self countTiles];
    });
}

- (void)removeAllCachedImagesForCacheKey:(NSString *)cacheKey
{
    RMLog(@"removing tiles for key '%@' from the file cache", cacheKey);

    dispatch_async(queue, ^{
        NSArray *items = [self.fileManager contentsOfDirectoryAtPath:[self tileCachePath] error:nil];
        for (NSString *file in items) {
            if ([file rangeOfString:cacheKey].location != NSNotFound) {
                [self.fileManager removeItemAtPath:[[self tileCachePath] stringByAppendingPathComponent:file] error:nil];
            }
        }
        
        _tileCount = [self countTiles];
    });
}

- (void)touchTile:(RMTile)tile withKey:(NSString *)cacheKey
{
    dispatch_async(queue, ^{
        NSString *tilePath = [self pathForCachedTileWithHash:[RMTileCache tileHash:tile] andKey:cacheKey];
        [self.fileManager setAttributes:@{NSFileModificationDate: [NSDate date]} ofItemAtPath:tilePath error:nil];
    });
}

@end
