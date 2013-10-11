//
//  RMMaplyTileSource.m
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

#import "RMMaplyTileSource.h"

@implementation RMMaplyTileSource
{
    NSObject<RMTileSource> *tileSource;
    MaplyCoordinateSystem *coordSystem;
    RMTileCache *tileCache;
}

- (id)initWithTileSource:(NSObject<RMTileSource> *)inTileSource cache:(RMTileCache *)inTileCache
{
    self = [super init];
    if (!self)
        return nil;
    
    tileSource = inTileSource;
    tileCache = inTileCache;
    // Note: Should figure out the coordinate system here
    coordSystem = [[MaplySphericalMercator alloc] initWebStandard];
    
    return self;
}

- (MaplyCoordinateSystem *)getMaplyCoordSystem
{
    return coordSystem;
}

/// Minimum zoom level (e.g. 0)
- (int)minZoom
{
    return (int)[tileSource minZoom];
}

/// Maximum zoom level (e.g. 17)
- (int)maxZoom
{
    return (int)[tileSource maxZoom];
}

/// Number of pixels on the side of a single tile (e.g. 128, 256)
- (int)tileSize
{
    return [tileSource tileSideLength];
}

- (bool)tileIsLocal:(MaplyTileID)tileID
{
    return true;
}

/// Return the image for a given tile
- (UIImage *)imageForTile:(MaplyTileID)tileID
{
    int maxY = 1<<tileID.level;
    
    RMTile tile;
    tile.x = tileID.x;
    tile.y = maxY-tileID.y-1;
    tile.zoom = tileID.level;
    
    return [tileSource imageForTile:tile inCache:tileCache];
}

@end
