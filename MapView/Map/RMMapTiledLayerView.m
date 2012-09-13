//
//  RMMapTiledLayerView.m
//  MapView
//
//  Created by Thomas Rasch on 17.08.11.
//  Copyright (c) 2011 Alpstein. All rights reserved.
//

#import "RMMapTiledLayerView.h"

#import "RMMapView.h"
#import "RMTileSource.h"
#import "RMTileImage.h"
#import "RMTileCache.h"
#import "RMMBTilesSource.h"
#import "RMDBMapSource.h"

@implementation RMMapTiledLayerView
{
    RMMapView *_mapView;
    id <RMTileSource> _tileSource;
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

    _mapView = [aMapView retain];
    _tileSource = [aTileSource retain];

    self.useSnapshotRenderer = NO;

    CATiledLayer *tiledLayer = [self tiledLayer];
    size_t levelsOf2xMagnification = _mapView.tileSourcesContainer.maxZoom;
    if (_mapView.adjustTilesForRetinaDisplay) levelsOf2xMagnification += 1;
    tiledLayer.levelsOfDetail = levelsOf2xMagnification;
    tiledLayer.levelsOfDetailBias = levelsOf2xMagnification;

    return self;
}

- (void)dealloc
{
    [_tileSource cancelAllDownloads];
    self.layer.contents = nil;
    [_tileSource release]; _tileSource = nil;
    [_mapView release]; _mapView = nil;
    [super dealloc];
}

- (void)didMoveToWindow
{
    self.contentScaleFactor = 1.0f;
}

- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)context
{
    CGRect rect   = CGContextGetClipBoundingBox(context);
    CGRect bounds = self.bounds;
    short zoom    = log2(bounds.size.width / rect.size.width);

//    NSLog(@"drawLayer: {{%f,%f},{%f,%f}}", rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);

    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

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
                    [tileImage drawInRect:CGRectMake(x * rectSize, y * rectSize, rectSize, rectSize)];
                }
            }

            UIGraphicsPopContext();
        }
    }
    else
    {
        int x = floor(rect.origin.x / rect.size.width),
            y = floor(fabs(rect.origin.y / rect.size.height));

//        NSLog(@"Tile @ x:%d, y:%d, zoom:%d", x, y, zoom);

        UIGraphicsPushContext(context);

        UIImage *tileImage = nil;

        if (zoom >= _tileSource.minZoom && zoom <= _tileSource.maxZoom)
        {
            if ([_tileSource isKindOfClass:[RMMBTilesSource class]] || [_tileSource isKindOfClass:[RMDBMapSource class]])
            {
                // for local tiles, query the source directly since trivial blocking
                //
                tileImage = [_tileSource imageForTile:RMTileMake(x, y, zoom) inCache:[_mapView tileCache]];
            }
            else
            {
                // for non-local tiles, consult cache directly first, else fetch asynchronously
                //
                tileImage = [[_mapView tileCache] cachedImage:RMTileMake(x, y, zoom) withCacheKey:[_tileSource uniqueTilecacheKey]];

                if ( ! tileImage)
                {
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void)
                    {
                        if ([_tileSource imageForTile:RMTileMake(x, y, zoom) inCache:[_mapView tileCache]])
                        {
                            dispatch_async(dispatch_get_main_queue(), ^(void)
                            {
                                [self.layer setNeedsDisplay];
                            });
                        }
                    });
                }
            }
        }

        if ( ! tileImage)
        {
            if (_mapView.missingTilesDepth == 0)
            {
                tileImage = [RMTileImage errorTile];
            }
            else
            {
                NSUInteger currentTileDepth = 1, currentZoom = zoom - currentTileDepth;

                // tries to return lower zoom level tiles if a tile cannot be found
                while ( !tileImage && currentZoom >= _tileSource.minZoom && currentTileDepth <= _mapView.missingTilesDepth)
                {
                    float nextX = x / powf(2.0, (float)currentTileDepth),
                          nextY = y / powf(2.0, (float)currentTileDepth);
                    float nextTileX = floor(nextX),
                          nextTileY = floor(nextY);

                    tileImage = [_tileSource imageForTile:RMTileMake((int)nextTileX, (int)nextTileY, currentZoom) inCache:[_mapView tileCache]];

                    if (tileImage)
                    {
                        // crop
                        float cropSize = 1.0 / powf(2.0, (float)currentTileDepth);

                        CGRect cropBounds = CGRectMake(tileImage.size.width * (nextX - nextTileX),
                                                       tileImage.size.height * (nextY - nextTileY),
                                                       tileImage.size.width * cropSize,
                                                       tileImage.size.height * cropSize);

                        CGImageRef imageRef = CGImageCreateWithImageInRect([tileImage CGImage], cropBounds);
                        tileImage = [UIImage imageWithCGImage:imageRef];
                        CGImageRelease(imageRef);

                        break;
                    }

                    currentTileDepth++;
                    currentZoom = zoom - currentTileDepth;
                }
            }
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

        [tileImage drawInRect:rect];

        UIGraphicsPopContext();
    }

    [pool release]; pool = nil;
}

@end
