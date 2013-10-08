//
//  RMDatabaseCacheDownloadOperation.m
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

#import "RMDatabaseCacheDownloadOperation.h"
#import "RMDatabaseCache.h"

@implementation RMDatabaseCacheDownloadOperation
{
    RMTile _tile;
    id <RMTileSource>_source;
    RMDatabaseCache *_cache;
}

- (id)initWithTile:(RMTile)tile forTileSource:(id <RMTileSource>)source usingCache:(RMDatabaseCache *)cache
{
    if (!(self = [super init]))
        return nil;

    _tile   = tile;
    _source = source;
    _cache  = cache;
    self.tileExisted = NO;
    
    return self;
}

- (void)main
{
    if ( ! _source || ! _cache)
        [self cancel];

    if ([self isCancelled])
        return;

    if ([_cache containsTile:_tile withCacheKey:[_source uniqueTilecacheKey]])
    {
        self.tileExisted = YES;
    }
    else
    {
        if ([self isCancelled])
            return;

        UIImage *image = [_source imageForTile:_tile inCache:nil];
        if (image)
            [_cache addImageAndWait:image forTile:_tile withCacheKey:[_source uniqueTilecacheKey]];
        else
            [self cancel];
    }
}

@end
