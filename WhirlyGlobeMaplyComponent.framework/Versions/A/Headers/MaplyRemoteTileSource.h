/*
 *  MaplyRemoteTileSource.h
 *  WhirlyGlobe-MaplyComponent
 *
 *  Created by Steve Gifford on 9/4/13.
 *  Copyright 2011-2013 mousebird consulting
 *
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *  http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 *
 */

#import "MaplyTileSource.h"
#import "MaplyCoordinateSystem.h"

@class MaplyRemoteTileSource;

/** The remote tile source delegate provides feedback on which
    tiles loaded and which didn't.  You'll be called in all sorts of
    random threads here, so act accordingly.
  */
@protocol MaplyRemoteTileSourceDelegate <NSObject>

@optional

/** The tile successfully loaded.
    @param tileSource the remote tile source that loaded the tile.
    @param tileID The ID of the tile we loaded.
  */
- (void) remoteTileSource:(MaplyRemoteTileSource *)tileSource tileDidLoad:(MaplyTileID)tileID;

/** The tile failed to load.
    @param tileSource The remote tile source that tried to load the tile.
    @param tileID The tile ID of the tile that failed to load.
    @param error The NSError message, probably from the network routine.
  */
- (void) remoteTileSource:(MaplyRemoteTileSource *)tileSource tileDidNotLoad:(MaplyTileID)tileID error:(NSError *)error;

@end

/** @brief The remote tile source knows how to fetch remote image pyramids.
    @details This is the MaplyTileSource compliant object that communicates with remote servers and fetches individual tiles as needed by the MaplyQuadImageTileLayer.
    @details It can be initialized in a couple of different ways depending on the information you have available.  Either you explicitly provide the baseURL, min and max levels and such, or hand in an NSDictionary that's been parsed from a tile spec.
    @details The remote tile source also handles cacheing if it you give it a cacheDir to work in.  By default cacheing is off (so be careful).
    @see MaplyQuadImageTilesLayer
 */
@interface MaplyRemoteTileSource : NSObject<MaplyTileSource>

/** @brief Initialize with enough information to fetch remote tiles.
    @details This version of the init method takes all the explicit
     information needed to fetch remote tiles.  This includes the
     base URL, file extension (e.g. image type), and min and max zoom levels.
    @param baseURL The base URL for fetching TMS tiles.
    @param ext Extension for the images we'll be fetching, typically @"png" or @"jpg"
    @param minZoom The minimum zoom level to fetch.  This really should be 0.
    @param maxZoom The maximum zoom level to fetch.
    @return The MaplyRemoteTileSource object or nil on failure.
  */
- (id)initWithBaseURL:(NSString *)baseURL ext:(NSString *)ext minZoom:(int)minZoom maxZoom:(int)maxZoom;

/** @brief Initialize from a remote tile spec.
    @details This version of the initializer takes an NSDictionary parsed
    from a JSON tile spec.  Take a look at the tile spec itself
    here (https://github.com/mapbox/tilejson-spec).  Basically
    it defines the available URLs (there can be multiple), the
    min and max zoom levels, coordinate system (not really) and
    file extension.  In many cases the coordinate system extents can't
    be trusted.
    @param jsonSpec An NSDictionary parsed from the JSON tile spec.
  */
- (id)initWithTilespec:(NSDictionary *)jsonSpec;

/** @brief The base URL we're fetching from.
    @details This is typically the top of the pyramid and we'll
     tack on the level, row, and column to form a full URL.
  */
@property (nonatomic,readonly) NSString *baseURL;

/** @brief The maximum zoom level available.
    @details This is the highest level (e.g. largest) that we'll
     fetch for a given pyramid tile source.  The source can sparse,
     so you are not required to have these tiles available, but this
     is as high as the MaplyQuadImageTilesLayer will fetch.
  */
@property (nonatomic) int maxZoom;

/** @brief The image type and file extension for the tiles.
    @details This is the filename extension, which implies the
     image type.  It's typically @"png" or @"jpg", but it
     can be anything that UIImage will recognize.
  */
@property (nonatomic,readonly) NSString *ext;

/** @brief Number of pixels on a side for any given tile.
    @details This is the number of pixels on any side for a
     given tile and it's typically 128 or 256.  This is largely
     a hint for the screen space based pager.  In most cases you
     are not required to actually return an image of the size
     you specify here, but it's a good idea.
  */
@property (nonatomic,readonly) int pixelsPerSide;

/** @brief The coordinate system the image pyramid is in.
    @details This is typically going to be MaplySphericalMercator
     with the web mercator extents.  That's what you'll get from
     OpenStreetMap and, often, MapBox.  In other cases it might
     be MaplyPlateCarree, which covers the whole earth.  Sometimes
     it might even be something unique of your own.
  */
@property (nonatomic,strong) MaplyCoordinateSystem *coordSys;

/** @brief The cache directory for image tiles.
    @details In general, we want to cache.  The globe, in particular,
    is going to fetch the same times over and over, quite a lot.
    The cacheing behavior is a little dumb.  It will just write
    files to the given directory forever.  If you're interacting
    with a giant image pyramid, that could be problematic.
  */
@property (nonatomic) NSString *cacheDir;

/** @brief A delegate for tile loads and failures.
    @details If set, you'll get callbacks when the various tiles load (or don't). You get called in all sorts of threads.  Act accordingly.
  */
@property (nonatomic,weak) NSObject<MaplyRemoteTileSourceDelegate> *delegate;

@end
