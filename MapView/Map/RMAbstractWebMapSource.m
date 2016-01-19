//
// RMAbstractWebMapSource.m
//
// Copyright (c) 2008-2013, Route-Me Contributors
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

#import "RMAbstractWebMapSource.h"

#import "RMTileCache.h"
#import "RMConfiguration.h"

#import "RMTileCacheDownloadOperation.h"

#define HTTP_404_NOT_FOUND 404

@implementation RMAbstractWebMapSource {
    NSOperationQueue *_downloadQueue;
    NSMapTable *_enqueuedOperations;
}

@synthesize retryCount, requestTimeoutSeconds;

- (id)init
{
    if (!(self = [super init]))
        return nil;

    self.retryCount = RMAbstractWebMapSourceDefaultRetryCount;
    self.requestTimeoutSeconds = RMAbstractWebMapSourceDefaultWaitSeconds;
    
    _downloadQueue = [[NSOperationQueue alloc] init];
    _downloadQueue.maxConcurrentOperationCount = 6;
    
    _enqueuedOperations = [[NSMapTable alloc] initWithKeyOptions:NSPointerFunctionsCopyIn valueOptions:NSPointerFunctionsWeakMemory capacity:64];

    return self;
}

- (void)cancelAllDownloads
{
    [_downloadQueue cancelAllOperations];
}

- (BOOL)operationExistsForTile:(RMTile)tile
{
    BOOL exists = NO;
    
    @synchronized(_enqueuedOperations) {
        NSOperation *operation = [_enqueuedOperations objectForKey:[RMTileCache tileHash:tile]];
        exists = operation != NULL && ![operation isCancelled];
    }
    
    return exists;
}

- (void)cancelDownloadsIrrelevantToTile:(RMTile)tile visibleMapRect:(RMIntegralRect)mapRect
{
    NSArray *operations = nil;
    
    @synchronized(_enqueuedOperations) {
        operations = [_enqueuedOperations.objectEnumerator.allObjects copy];
    }
    
    for (RMTileCacheDownloadOperation *operation in operations) {
        if ([operation isCancelled]) {
            continue;
        }
        
        if (operation.tile.zoom != tile.zoom) {
            [operation cancel];
        } else if (!RMIntegralRectContainsPoint(mapRect, RMIntegralPointMake(operation.tile.x, operation.tile.y))){
            [operation cancel];
        }
    }
}

- (void)registerOperation:(RMTileCacheDownloadOperation *)operation
{
    @synchronized(_enqueuedOperations) {
        [_enqueuedOperations setObject:operation forKey:[RMTileCache tileHash:operation.tile]];
    }
}

- (void)downloadImageForTile:(RMTile)tile cache:(RMTileCache *)cache visibleMapRect:(RMIntegralRect)mapRect completion:(void (^)(void))completion
{
    if ([self operationExistsForTile:tile]) {
        return;
    }
    
    [self cancelDownloadsIrrelevantToTile:tile visibleMapRect:mapRect];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:RMTileRequested object:[NSNumber numberWithUnsignedLongLong:RMTileKey(tile)]];
    });
    
    RMTileCacheDownloadOperation *operation = [[RMTileCacheDownloadOperation alloc] initWithTile:tile forTileSource:self usingCache:cache completion:^(NSError *error){
        if (!error) {
            [[NSNotificationCenter defaultCenter] postNotificationName:RMTileRetrieved object:[NSNumber numberWithUnsignedLongLong:RMTileKey(tile)]];
            if (completion) {
                completion();
            }
        }
    }];
    
    [_downloadQueue addOperation:operation];
    [self registerOperation:operation];
}

- (NSURL *)URLForTile:(RMTile)tile
{
    @throw [NSException exceptionWithName:@"RMAbstractMethodInvocation"
                                   reason:@"URLForTile: invoked on RMAbstractWebMapSource. Override this method when instantiating an abstract class."
                                 userInfo:nil];
}

- (NSArray *)URLsForTile:(RMTile)tile
{
    return [NSArray arrayWithObjects:[self URLForTile:tile], nil];
}

- (UIImage *)imageForTile:(RMTile)tile inCache:(RMTileCache *)tileCache
{
    // This method only considers the cache. Use downloadImageForTile: to download a
    // tile nonexistant in the cache.
    return [tileCache cachedImage:tile withCacheKey:[self uniqueTilecacheKey]];
}

@end
