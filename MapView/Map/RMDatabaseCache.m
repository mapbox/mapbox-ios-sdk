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
#import "FMDB.h"
#import "RMTileImage.h"
#import "RMTile.h"

#define kWriteQueueLimit 15

@interface RMDatabaseCache ()

@property (nonatomic, strong) NSFileManager *fileManager;
@property (atomic) NSUInteger tileCount;

- (NSUInteger)count;
- (NSUInteger)countTiles;
- (void)touchTile:(RMTile)tile withKey:(NSString *)cacheKey;
- (void)purgeTiles:(NSUInteger)count;

@end

#pragma mark -

@implementation RMDatabaseCache
{
    // Cache
    RMCachePurgeStrategy _purgeStrategy;
    NSUInteger _capacity;
    NSUInteger _minimalPurge;
    NSTimeInterval _expiryPeriod;
}

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

	self.tileCachePath = path;
    self.fileManager = [NSFileManager new];

    self.tileCount = [self countTiles];

	return self;	
}

- (id)initUsingCacheDir:(BOOL)useCacheDir
{
	return [self initWithTileCachePath:[RMDatabaseCache tileCachePathUsingCacheDir:useCacheDir]];
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
    UIImage *cachedImage = [UIImage imageWithContentsOfFile:[self pathForCachedTileWithHash:[RMTileCache tileHash:tile] andKey:aCacheKey]];

    if (_capacity != 0 && _purgeStrategy == RMCachePurgeStrategyLRU)
        [self touchTile:tile withKey:aCacheKey];

    if (_expiryPeriod > 0)
    {
        if (rand() % 100 == 0)
        {
            [self.fileManager removeItemAtPath:[self pathForCachedTileWithHash:[RMTileCache tileHash:tile] andKey:aCacheKey] error:nil];

            _tileCount = [self countTiles];
        }
    }

	return cachedImage;
}

- (void)addImage:(UIImage *)image forTile:(RMTile)tile withCacheKey:(NSString *)aCacheKey
{
    // TODO: Converting the image here (again) is not so good...
	NSData *data = UIImagePNGRepresentation(image);

    if (_capacity != 0)
    {
        NSUInteger tilesInDb = [self count];

        if (_capacity <= tilesInDb && _expiryPeriod == 0)
            [self purgeTiles:MAX(_minimalPurge, 1+tilesInDb-_capacity)];
        
        [self constrainFileSize];

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
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
    RMLog(@"purging %lu old tiles from the file cache", (unsigned long)count);

    NSMutableArray *items = [NSMutableArray new];
    [[self.fileManager contentsOfDirectoryAtPath:[self tileCachePath] error:nil] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSDate *date = [[self.fileManager attributesOfItemAtPath:[[self tileCachePath] stringByAppendingPathComponent:obj] error:nil] fileModificationDate];
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
}

- (void)constrainFileSize
{
    if ([self folderSize:[self tileCachePath]] > _capacityBytes) {
        RMLog(@"constraining db cache size %lluM", (unsigned long)[self folderSize:[self tileCachePath]] / (1024 * 1024));
        [self purgeTiles:_minimalPurge];
    }
}

- (unsigned long long int)folderSize:(NSString *)folderPath {
    NSArray *filesArray = [[NSFileManager defaultManager] subpathsOfDirectoryAtPath:folderPath error:nil];
    NSEnumerator *filesEnumerator = [filesArray objectEnumerator];
    NSString *fileName;
    unsigned long long int fileSize = 0;
    
    while (fileName = [filesEnumerator nextObject]) {
        NSDictionary *fileDictionary = [[NSFileManager defaultManager] attributesOfItemAtPath:[folderPath stringByAppendingPathComponent:fileName] error:nil];
        fileSize += [fileDictionary fileSize];
    }
    
    return fileSize;
}

- (void)removeAllCachedImages 
{
    RMLog(@"removing all tiles from the file cache");

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
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

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
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
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        NSString *tilePath = [self pathForCachedTileWithHash:[RMTileCache tileHash:tile] andKey:cacheKey];
        [self.fileManager setAttributes:@{NSFileModificationDate: [NSDate date]} ofItemAtPath:tilePath error:nil];
    });
}

@end
