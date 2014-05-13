//
//  RMMapTiledLayerView.m
//  MapView
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

#import "RMMapTiledLayerView.h"

#import "RMMapView.h"
#import "RMTileSource.h"
#import "RMTileImage.h"
#import "RMTileCache.h"
#import "RMMBTilesSource.h"
#import "RMDBMapSource.h"
#import "RMAbstractWebMapSource.h"
#import "RMDatabaseCache.h"
#import "RMTileCacheDownloadOperation.h"

#define IS_VALID_TILE_IMAGE(image) (image != nil && [image isKindOfClass:[UIImage class]])

@interface CATiledLayer(additions)
- (void) setNeedsDisplayInRect:(CGRect)r levelOfDetail:(int)level;
@end


@implementation RMMapTiledLayerView
{
    __weak RMMapView *_mapView;
    id <RMTileSource> _tileSource;
    //    dispatch_queue_t _queue;
    NSOperationQueue* _backgroundFetchQueue;
}

@synthesize useSnapshotRenderer = _useSnapshotRenderer;
@synthesize tileSource = _tileSource;

+ (Class)layerClass
{
    return [CATiledLayer class];
}

- (CATiledLayer *)tiledLayer
{
    return (CATiledLayer *)self.layer;
}

- (id)initWithFrame:(CGRect)frame mapView:(RMMapView *)aMapView forTileSource:(id <RMTileSource>)aTileSource
{
    if (!(self = [super initWithFrame:frame]))
        return nil;
    
    self.opaque = NO;
    _mapView = aMapView;
    _tileSource = aTileSource;
    self.useSnapshotRenderer = NO;
    _backgroundFetchQueue = [NSOperationQueue new];
    [_backgroundFetchQueue setMaxConcurrentOperationCount:10];
    
    CATiledLayer *tiledLayer = [self tiledLayer];
    size_t levelsOf2xMagnification = _mapView.tileSourcesMaxZoom;
    if (_mapView.adjustTilesForRetinaDisplay && _mapView.screenScale > 1.0) levelsOf2xMagnification += 1;
    tiledLayer.levelsOfDetail = levelsOf2xMagnification;
    tiledLayer.levelsOfDetailBias = levelsOf2xMagnification;
    
    return self;
}

- (void)dealloc
{
    [_tileSource cancelAllDownloads];
    [self cancelBackgroundOperations];
    self.layer.contents = nil;
    _mapView = nil;
}

- (void)didMoveToWindow
{
    self.contentScaleFactor = 1.0f;
}

- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)context {
    CGRect rect = CGContextGetClipBoundingBox(context);
    CGRect bounds = self.bounds;
    // get the scale from the context by getting the current transform matrix, then asking for
    // its "a" component, which is one of the two scale components. We could also ask for "d".
    // This assumes (safely) that the view is being scaled equally in both dimensions.
    //    CGFloat scale = CGContextGetCTM(context).a;
    
    //    CATiledLayer *tiledLayer = (CATiledLayer *)layer;
    //    CGSize tileSize = tiledLayer.tileSize;
    
    // Even at scales lower than 100%, we are drawing into a rect in the coordinate system of the full
    // image. One tile at 50% covers the width (in original image coordinates) of two tiles at 100%.
    // So at 50% we need to stretch our tiles to double the width and height; at 25% we need to stretch
    // them to quadruple the width and height; and so on.
    // (Note that this means that we are drawing very blurry images as the scale gets low. At 12.5%,
    // our lowest scale, we are stretching about 6 small tiles to fill the entire original image area.
    // But this is okay, because the big blurry image we're drawing here will be scaled way down before
    // it is displayed.)
    //    tileSize.width /= scale;
    //    tileSize.height /= scale;
    
    int zoom = log2(bounds.size.width / rect.size.width);
    int x = floor(rect.origin.x / rect.size.width),
    y = floor(fabs(rect.origin.y / rect.size.height));
    
    if (_mapView.adjustTilesForRetinaDisplay && _mapView.screenScale > 1.0)
    {
        zoom--;
        x >>= 1;
        y >>= 1;
    }
    
    RMTile tile = RMTileMake(x, y, zoom);
    if (self.useSnapshotRenderer)
    {
        zoom = (short)ceilf(_mapView.adjustedZoomForRetinaDisplay);
        CGFloat rectSize = bounds.size.width / powf(2.0, (float)zoom);
        
        int x1 = floor(rect.origin.x / rectSize),
        x2 = floor((rect.origin.x + rect.size.width) / rectSize),
        y1 = floor(fabs(rect.origin.y / rectSize)),
        y2 = floor(fabs((rect.origin.y + rect.size.height) / rectSize));
        
        //        NSLog(@"Tiles from x1:%d, y1:%d to x2:%d, y2:%d @ zoom %d", x1, y1, x2, y2, zoom);
        
        if (zoom >= _tileSource.minZoom && zoom <= _tileSource.maxZoom)
        {
            UIGraphicsPushContext(context);
            
            for (int x=x1; x<=x2; ++x)
            {
                for (int y=y1; y<=y2; ++y)
                {
                    UIImage *tileImage = [_tileSource imageForTile:RMTileMake(x, y, zoom) inCache:[_mapView tileCache]];
                    
                    if (IS_VALID_TILE_IMAGE(tileImage))
                        [tileImage drawInRect:CGRectMake(x * rectSize, y * rectSize, rectSize, rectSize)];
                }
            }
            
            UIGraphicsPopContext();
        }
    }
    else {
        //    NSString *tileName = [NSString stringWithFormat:@"%d_%d_%d.png", tile.zoom, tile.x, tile.y];
        //    NSLog(@"draw in rect %@, %@", NSStringFromCGRect(rect), tileName);
        UIImage* tileImage = [self imageForRect:rect tile:tile];
        if (IS_VALID_TILE_IMAGE(tileImage)) {
            
            if (_mapView.adjustTilesForRetinaDisplay && _mapView.screenScale > 1.0)
            {
                // Crop the image
                float xCrop = (floor(rect.origin.x / rect.size.width) / 2.0) - x;
                float yCrop = (floor(rect.origin.y / rect.size.height) / 2.0) - y;
                
                CGRect cropBounds = CGRectMake(tileImage.size.width * xCrop,
                                               tileImage.size.height * yCrop,
                                               tileImage.size.width * 0.5,
                                               tileImage.size.height * 0.5);
                
                CGImageRef imageRef = CGImageCreateWithImageInRect([tileImage CGImage], cropBounds);
                tileImage = [UIImage imageWithCGImage:imageRef];
                CGImageRelease(imageRef);
            }
            
            if (_mapView.debugTiles)
            {
                UIGraphicsBeginImageContext(tileImage.size);
                
                CGContextRef debugContext = UIGraphicsGetCurrentContext();
                
                CGRect debugRect = CGRectMake(0, 0, tileImage.size.width, tileImage.size.height);
                
                [tileImage drawInRect:debugRect];
                
                UIFont *font = [UIFont systemFontOfSize:32.0];
                
                CGContextSetStrokeColorWithColor(debugContext, [UIColor whiteColor].CGColor);
                CGContextSetLineWidth(debugContext, 2.0);
                CGContextSetShadowWithColor(debugContext, CGSizeMake(0.0, 0.0), 5.0, [UIColor blackColor].CGColor);
                
                CGContextStrokeRect(debugContext, debugRect);
                
                CGContextSetFillColorWithColor(debugContext, [UIColor whiteColor].CGColor);
                
                NSString *debugString = [NSString stringWithFormat:@"Zoom %d", zoom];
                CGSize debugSize1 = [debugString sizeWithFont:font];
                [debugString drawInRect:CGRectMake(5.0, 5.0, debugSize1.width, debugSize1.height) withFont:font];
                
                debugString = [NSString stringWithFormat:@"(%d, %d)", x, y];
                CGSize debugSize2 = [debugString sizeWithFont:font];
                [debugString drawInRect:CGRectMake(5.0, 5.0 + debugSize1.height + 5.0, debugSize2.width, debugSize2.height) withFont:font];
                
                tileImage = UIGraphicsGetImageFromCurrentImageContext();
                
                UIGraphicsEndImageContext();
            }
            CGContextSaveGState(context);
            CGContextTranslateCTM(context, 0.0, rect.size.height);
            CGContextScaleCTM(context, 1.0, -1.0);
            //we need to update the rect after the translate/scale
            rect = CGContextGetClipBoundingBox(context);
            CGContextDrawImage(context, rect, tileImage.CGImage);
            CGContextRestoreGState(context);
        }
        
    }
    
}

- (UIImage*) imageForRect:(CGRect)rect tile:(RMTile)tile{
    if (tile.zoom >= _tileSource.minZoom && tile.zoom <= _tileSource.maxZoom)
    {
        //        NSString *tileName = [NSString stringWithFormat:@"%d_%d_%d.png", tile.zoom, tile.x, tile.y];
        
        UIImage *cachedImage = nil;
        
        RMDatabaseCache *databaseCache = nil;
        
        for (RMTileCache *componentCache in _mapView.tileCache.tileCaches)
            if ([componentCache isKindOfClass:[RMDatabaseCache class]])
                databaseCache = (RMDatabaseCache *)componentCache;
        
        if ( ! [_tileSource isKindOfClass:[RMAbstractWebMapSource class]] || ! databaseCache || ! databaseCache.capacity)
        {
            return [_tileSource imageForTile:tile inCache:[_mapView tileCache]];
        }
        else
        {
            if (_tileSource.isCacheable) {
                //                NSLog(@"testing cache for tile %@", tileName);
                UIImage* image = [[_mapView tileCache] cachedImage:tile withCacheKey:[_tileSource uniqueTilecacheKey]];
                if (IS_VALID_TILE_IMAGE(image)) {
                    //                    NSLog(@"got cache for tile %@", tileName);
                    return image;
                }
            }
            
            RMTileCacheDownloadOperation *operation = [[RMTileCacheDownloadOperation alloc] initWithTile:tile
                                                                                           forTileSource:_tileSource
                                                                                              usingCache:[_mapView tileCache]];
            
            __block RMTileCacheDownloadOperation *internalOperation = operation;
            //            __block NSString* internalTileName = tileName;
            __block CGRect internalRect = rect;
            
            [operation setCompletionBlock:^(void)
             {
                 if ( ! [internalOperation isCancelled])
                 {
                     dispatch_sync(dispatch_get_main_queue(), ^(void)
                                   {
                                       //                                       NSLog(@"refreshing for tile %@, %@", internalTileName, NSStringFromCGRect(internalRect));
                                       [[self tiledLayer] setNeedsDisplayInRect:internalRect];
                                   });
                 }
                 internalOperation = nil;
                 //                 internalTileName = nil;
             }];
            
            [_backgroundFetchQueue addOperation:operation];
        }
        if (_mapView.missingTilesDepth == 0)
        {
            return [RMTileImage errorTile];
        }
        else if (_tileSource.isCacheable)
        {
            NSUInteger currentTileDepth = 1, currentZoom = tile.zoom - currentTileDepth;
            // tries to return lower zoom level tiles if a tile cannot be found
            while ( !cachedImage && currentZoom >= _tileSource.minZoom && currentTileDepth <= _mapView.missingTilesDepth)
            {
                float nextX = tile.x / powf(2.0, (float)currentTileDepth),
                nextY = tile.y / powf(2.0, (float)currentTileDepth);
                float nextTileX = floor(nextX),
                nextTileY = floor(nextY);
                
                UIImage* cachedImage = [[_mapView tileCache] cachedImage:RMTileMake((int)nextTileX, (int)nextTileY, currentZoom) withCacheKey:[_tileSource uniqueTilecacheKey]];
                
                if (IS_VALID_TILE_IMAGE(cachedImage))
                {
                    return cachedImage;
                }
                
                currentTileDepth++;
                currentZoom = tile.zoom - currentTileDepth;
            }
        }
    }
    
    return nil;
}

- (void)cancelBackgroundOperations
{
    
    if (_backgroundFetchQueue)
    {
        [_backgroundFetchQueue cancelAllOperations];
    }
}

@end
