//
//  RMCompositeSource.m
//  MapView
//
//  Created by Justin Miller on 4/19/12.
//  Copyright (c) 2012 MapBox / Development Seed. All rights reserved.
//

#import "RMCompositeSource.h"

#import "RMAbstractMercatorTileSource.h"

@implementation RMCompositeSource

@synthesize compositeSources;

- (id)initWithTileSource:(id <RMTileSource>)initialTileSource
{
    self = [super init];
    
    if (self)
        compositeSources = [[NSMutableArray arrayWithObject:initialTileSource] retain];
    
    return self;
}

- (void)dealloc
{
    [compositeSources release];
    
    [super dealloc];
}

- (UIImage *)imageForTile:(RMTile)tile inCache:(RMTileCache *)tileCache
{
    // FIXME: cache
    
    UIImage *image = nil;
    
    for (id <RMTileSource>tileSource in self.compositeSources)
    {
        float minZoom = [tileSource minZoom];
        float maxZoom = [tileSource maxZoom];
        if ( tile.zoom < minZoom || tile.zoom > maxZoom ) {
            continue;
        }
        
        UIImage *sourceImage = [tileSource imageForTile:tile inCache:tileCache];
        
        if (sourceImage)
        {
            if (image != nil)
            {
                UIGraphicsBeginImageContext(image.size);
                
                [image drawAtPoint:CGPointMake(0,0)];
                
                [sourceImage drawAtPoint:CGPointMake(0,0)];
                
                image = UIGraphicsGetImageFromCurrentImageContext();
                
                UIGraphicsEndImageContext();
            }
            else
            {
                image = sourceImage;
            }
            break;
        }
    }
    
    return image;
}

- (void)cancelAllDownloads
{
    NSLog(@"cancelAllDownloads");
}

- (RMFractalTileProjection *)mercatorToTileProjection
{
    if ( ! tileProjection)
    {
        tileProjection = [[RMFractalTileProjection alloc] initFromProjection:[self projection]
                                                              tileSideLength:[self tileSideLength]
                                                                     maxZoom:[self maxZoom]
                                                                     minZoom:[self minZoom]];
    }
    
	return tileProjection;
}

- (RMProjection *)projection
{
	return [RMProjection googleProjection];
}

- (float)minZoom
{
    return kDefaultMinTileZoom;
}

- (void)setMinZoom:(NSUInteger)aMinZoom
{
    NSLog(@"setMinZoom:");
}

- (float)maxZoom
{
    return kDefaultMaxTileZoom;
}

- (void)setMaxZoom:(NSUInteger)aMaxZoom
{
    NSLog(@"setMaxZoom:");
}

- (int)tileSideLength
{
    return kDefaultTileSize;
}

- (void)setTileSideLength:(NSUInteger)aTileSideLength
{
    NSLog(@"setTileSideLength:");
}

- (RMSphericalTrapezium)latitudeLongitudeBoundingBox
{
    return kDefaultLatLonBoundingBox;
}

- (NSString *)uniqueTilecacheKey
{
    return NSStringFromClass([self class]);
}

- (NSString *)shortName
{
    return @"shortName";
}

- (NSString *)longDescription
{
    return @"longDescription";
}

- (NSString *)shortAttribution
{
    return @"shortAttribution";
}

- (NSString *)longAttribution
{
    return @"longAttribution";
}

- (void)didReceiveMemoryWarning
{
    NSLog(@"didReceiveMemoryWarning");
}

@end
