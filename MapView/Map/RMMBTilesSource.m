//
//  RMMBTilesSource.m
//
//  Created by Justin R. Miller on 6/18/10.
//  Copyright 2012 MapBox.
//  All rights reserved.
//  
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions are met:
//  
//      * Redistributions of source code must retain the above copyright
//        notice, this list of conditions and the following disclaimer.
//  
//      * Redistributions in binary form must reproduce the above copyright
//        notice, this list of conditions and the following disclaimer in the
//        documentation and/or other materials provided with the distribution.
//  
//      * Neither the name of MapBox, nor the names of its contributors may be
//        used to endorse or promote products derived from this software
//        without specific prior written permission.
//  
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
//  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
//  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
//  DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
//  ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
//  (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
//  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
//  ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
//  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
//  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

#import "RMMBTilesSource.h"
#import "RMTileImage.h"
#import "RMProjection.h"
#import "RMFractalTileProjection.h"

#import "FMDatabase.h"
#import "FMDatabaseQueue.h"

@implementation RMMBTilesSource

- (id)initWithTileSetURL:(NSURL *)tileSetURL
{
	if ( ! [super init])
		return nil;

	tileProjection = [[RMFractalTileProjection alloc] initFromProjection:[self projection] 
                                                          tileSideLength:kMBTilesDefaultTileSize 
                                                                 maxZoom:kMBTilesDefaultMaxTileZoom 
                                                                 minZoom:kMBTilesDefaultMinTileZoom];

    queue = [[FMDatabaseQueue databaseQueueWithPath:[tileSetURL relativePath]] retain];

    if ( ! queue)
        return nil;

    [queue inDatabase:^(FMDatabase *db) {
        [db setShouldCacheStatements:YES];
    }];

	return self;
}

- (void)cancelAllDownloads
{
    // no-op
}

- (void)dealloc
{
	[tileProjection release]; tileProjection = nil;
    [queue release]; queue = nil;
	[super dealloc];
}

- (int)tileSideLength
{
	return tileProjection.tileSideLength;
}

- (void)setTileSideLength:(NSUInteger)aTileSideLength
{
	[tileProjection setTileSideLength:aTileSideLength];
}

- (UIImage *)imageForTile:(RMTile)tile inCache:(RMTileCache *)tileCache
{
    NSAssert4(((tile.zoom >= self.minZoom) && (tile.zoom <= self.maxZoom)),
			  @"%@ tried to retrieve tile with zoomLevel %d, outside source's defined range %f to %f", 
			  self, tile.zoom, self.minZoom, self.maxZoom);

    NSInteger zoom = tile.zoom;
    NSInteger x    = tile.x;
    NSInteger y    = pow(2, zoom) - tile.y - 1;

    dispatch_async(dispatch_get_main_queue(), ^(void)
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:RMTileRequested object:[NSNumber numberWithUnsignedLongLong:RMTileKey(tile)]];
    });
    
    __block UIImage *image;

    [queue inDatabase:^(FMDatabase *db)
    {
        FMResultSet *results = [db executeQuery:@"select tile_data from tiles where zoom_level = ? and tile_column = ? and tile_row = ?", 
                                   [NSNumber numberWithShort:zoom], 
                                   [NSNumber numberWithUnsignedInt:x], 
                                   [NSNumber numberWithUnsignedInt:y]];

        if ([db hadError])
            image = [RMTileImage errorTile];

        BOOL hasResults = [results next];

        NSData* data = nil;
        if ( hasResults ) {
            data = [results dataForColumn:@"tile_data"];
        }

        if ( ! data)
            image = [RMTileImage errorTile];
        else
            image = [UIImage imageWithData:data];

        [results close];
    }];

    dispatch_async(dispatch_get_main_queue(), ^(void)
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:RMTileRetrieved object:[NSNumber numberWithUnsignedLongLong:RMTileKey(tile)]];
    });

    return image;
}

- (NSString *)tileURL:(RMTile)tile
{
    return nil;
}

- (NSString *)tileFile:(RMTile)tile
{
    return nil;
}

- (NSString *)tilePath
{
    return nil;
}

- (RMFractalTileProjection *)mercatorToTileProjection
{
	return [[tileProjection retain] autorelease];
}

- (RMProjection *)projection
{
	return [RMProjection googleProjection];
}

- (float)minZoom
{
    static double oneTimeMinZoom = -1;
    if ( oneTimeMinZoom < 0 ) {
        __block double minZoom;
        
        [queue inDatabase:^(FMDatabase *db)
         {
             FMResultSet *results = [db executeQuery:@"select min(zoom_level) from tiles"];
             
             if ([db hadError])
                 minZoom = kMBTilesDefaultMinTileZoom;
             
             [results next];
             
             minZoom = [results doubleForColumnIndex:0];
             
             [results close];
         }];
        oneTimeMinZoom = minZoom;
    }

    return oneTimeMinZoom;
}

- (float)maxZoom
{
    static double oneTimeMaxZoom = -1;
    if ( oneTimeMaxZoom < 0 ) {
        __block double maxZoom;
        
        [queue inDatabase:^(FMDatabase *db)
         {
             FMResultSet *results = [db executeQuery:@"select max(zoom_level) from tiles"];
             
             if ([db hadError])
                 maxZoom = kMBTilesDefaultMaxTileZoom;
             
             [results next];
             
             maxZoom = [results doubleForColumnIndex:0];
             
             [results close];
         }];
        oneTimeMaxZoom = maxZoom;
    }

    return oneTimeMaxZoom;
}

- (void)setMinZoom:(NSUInteger)aMinZoom
{
    [tileProjection setMinZoom:aMinZoom];
}

- (void)setMaxZoom:(NSUInteger)aMaxZoom
{
    [tileProjection setMaxZoom:aMaxZoom];
}

- (RMSphericalTrapezium)latitudeLongitudeBoundingBox
{
    __block RMSphericalTrapezium bounds = kMBTilesDefaultLatLonBoundingBox;

    [queue inDatabase:^(FMDatabase *db)
    {
        FMResultSet *results = [db executeQuery:@"select value from metadata where name = 'bounds'"];

        [results next];

        NSString *boundsString = [results stringForColumnIndex:0];

        [results close];

        if (boundsString)
        {
            NSArray *parts = [boundsString componentsSeparatedByString:@","];

            if ([parts count] == 4)
            {
                bounds.southWest.longitude = [[parts objectAtIndex:0] doubleValue];
                bounds.southWest.latitude  = [[parts objectAtIndex:1] doubleValue];
                bounds.northEast.longitude = [[parts objectAtIndex:2] doubleValue];
                bounds.northEast.latitude  = [[parts objectAtIndex:3] doubleValue];
            }
        }
    }];

    return bounds;
}

- (BOOL)coversFullWorld
{
    RMSphericalTrapezium ownBounds     = [self latitudeLongitudeBoundingBox];
    RMSphericalTrapezium defaultBounds = kMBTilesDefaultLatLonBoundingBox;

    if (ownBounds.southWest.longitude <= defaultBounds.southWest.longitude + 10 && 
        ownBounds.northEast.longitude >= defaultBounds.northEast.longitude - 10)
        return YES;

    return NO;
}

- (NSString *)legend
{
    __block NSString *legend;

    [queue inDatabase:^(FMDatabase *db)
    {
        FMResultSet *results = [db executeQuery:@"select value from metadata where name = 'legend'"];

        if ([db hadError])
            legend = nil;

        [results next];

        legend = [results stringForColumn:@"value"];

        [results close];
    }];

    return legend;
}

- (void)didReceiveMemoryWarning
{
    NSLog(@"*** didReceiveMemoryWarning in %@", [self class]);
}

- (NSString *)uniqueTilecacheKey
{
    return [NSString stringWithFormat:@"MBTiles%@", [queue.path lastPathComponent]];
}

- (NSString *)shortName
{
    __block NSString *shortName;

    [queue inDatabase:^(FMDatabase *db)
    {
        FMResultSet *results = [db executeQuery:@"select value from metadata where name = 'name'"];

        if ([db hadError])
            shortName = nil;

        [results next];

        shortName = [results stringForColumnIndex:0];

        [results close];
    }];

    return shortName;
}

- (NSString *)longDescription
{
    __block NSString *description;

    [queue inDatabase:^(FMDatabase *db)
    {
        FMResultSet *results = [db executeQuery:@"select value from metadata where name = 'description'"];

        if ([db hadError])
            description = nil;

        [results next];

        description = [results stringForColumnIndex:0];

        [results close];
    }];

    return [NSString stringWithFormat:@"%@ - %@", [self shortName], description];
}

- (NSString *)shortAttribution
{
    __block NSString *attribution;

    [queue inDatabase:^(FMDatabase *db)
    {
        FMResultSet *results = [db executeQuery:@"select value from metadata where name = 'attribution'"];

        if ([db hadError])
            attribution = @"Unknown MBTiles attribution";

        [results next];

        attribution = [results stringForColumnIndex:0];

        [results close];
    }];

    return attribution;
}

- (NSString *)longAttribution
{
    return [NSString stringWithFormat:@"%@ - %@", [self shortName], [self shortAttribution]];
}

@end
