/*
 *  MaplyQuadPagingLayer.h
 *  WhirlyGlobe-MaplyComponent
 *
 *  Created by Steve Gifford on 5/20/13.
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

#import "MaplyComponentObject.h"
#import "MaplyViewControllerLayer.h"
#import "MaplyCoordinateSystem.h"
#import "MaplyTileSource.h"
#import "MaplyBaseViewController.h"

@class MaplyQuadPagingLayer;

/** @brief The paging delegate is used by the paging layer to load tiles.
    @details The Maply Paging Delegate is used by the MaplyQuadPagingLayer to do feature (e.g. not image) paging.  You set up an object that implements this protocol and talks to the paging layer.  This is how you load things like vector tiles.
    @details It's up to you to do the actual loading of tiles and turn the data into Maply features.  Once you do that, the paging layer will handle the rest.
    @see MaplyQuadPagingLayer
  */
@protocol MaplyPagingDelegate

/** @brief Minimum zoom level (e.g. 0)
    @details The minimum zoom level you can provide.  If you've only got one level of data, just return minZoom and maxZoom with the same value.
  */
- (int)minZoom;

/** @brief Maximum zoom level (e.g. 17)
    @details The maximum zoom level you can provide.
  */
- (int)maxZoom;

/** @brief Start fetching data for the given tile.
    @details The paging layer calls this method to let you know you should start fetching data for a given tile. This will not be called on the main thread so be prepared for that.
    @details You should immediately do an async call to your own loading logic and then merge in your results. If you do your loading calls in line you'll slow down the loading thread. After you're done you MUST call tileDidLoad in the layer, even for failures.
    @details Once you've loaded your data, you need to create the corresponding Maply objects in the view controller and pass them back to the paging layer for tracking.
    @param tileID The tile the system wants you to start loading.
    @param layer The quad paging layer you'll hand the data over to when it's loaded.
  */
- (void)startFetchForTile:(MaplyTileID)tileID forLayer:(MaplyQuadPagingLayer *)layer;

@end

/** @brief The Quad Paging Layer is for loading things like vector tile sets.
    @details The Maply Quad Paging Layer implements a general purpose paging interface for quad tree based data sources.  This is different from the MaplyQuadImageTilesLayer in that it's meant for paging things like vector tiles, or really any other features that are not images.
    @details You set up an object that implements the MaplyPagingDelegate protocol, create the MaplyQuadPagingLayer and respond to the startFetchForTile:forLayer: method.
    @details Once you've fetched your data for a given tile, you'll need to call tileDidLoad: or tileFailedToLoad:.  Then you'll want to create the visual objects in the MaplyViewController or WhirlyGlobeViewController and pass them in to addData:forTile:
    @details This is how the paging layer keeps track of which objects you've created for a given tile and can then remove them when the time comes.
    @details Objects must be created with @"enable" set to @(NO) in the description dictionary.  Tiles are paged before they are needed for dipslay and so the paging layer must have control over when data is displayed. It uses the enable/disable options for the various Maply objects in the view controllers.
  */
@interface MaplyQuadPagingLayer : MaplyViewControllerLayer

/** @brief Number of fetches allowed at once.
    @details Change the number of fetches allowed at once.  This means you'll have at most numSimultaneousFetches dispatch queues going.
  */
@property (nonatomic,assign) int numSimultaneousFetches;

/** @brief The view controller this paging layer is associated with.
    @details This view controller is the one you should create visual objects in.
  */
@property (nonatomic,weak,readonly) MaplyBaseViewController *viewC;

/** @brief Initialize with coordinate system and delegate for paging.
    @details This initializer takes the coordinate system we're working in and the MaplyPagingDelegate object.  Fill out that to do the real work.
    @param coordSys The coordinate system we're working in.
    @param tileSource The tile source that will fetch data and create visible objects.
    @return Returns a MaplyViewControllerLayer that can be added to the MaplyBaseViewController.
  */
- (id)initWithCoordSystem:(MaplyCoordinateSystem *)coordSys delegate:(NSObject<MaplyPagingDelegate> *)tileSource;

/** @brief You call this from your MaplyPagingDelegate with an array of data you've created for a tile.
    @details This method is called by your MaplyPagingDelegate to add MaplyComponentObject's to the data for a given tile.  Please create them disabled by putting @"enable": @(NO) in the description dictionary.  The paging layer will then be responsible for cleaning them up when needed as well as turning them on and off as the user moves around.
    @details The call is thread safe.
    @param dataObjects An NSArray of MaplyComponentObject objects.
    @param tileID The tile ID for the data we're handing over.
  */
- (void)addData:(NSArray *)dataObjects forTile:(MaplyTileID)tileID;

/** @brief Called from your MaplyPagingDelegate when a tile fails to load.
    @details If you fail to load your tile data in your MaplyPagingDelegate, you need to let the paging layer know with this call.  Otherwise the paging layer assumes the tile is still loading.
  */
- (void)tileFailedToLoad:(MaplyTileID)tileID;

/** @brief Called from your MaplyPagingDelegate when a tile loads.
    @details When you've finished loading the data for a tile in your MaplyPagingDelegate, but before you've called addData:forTile: call this method to let the paging layer know you succeeded in loading the tile.
 */
- (void)tileDidLoad:(MaplyTileID)tileID;

/** @brief Calculate the bounding box for a single tile.
    @details This is a utility method for calculating the extents of a given tile in the local coordinate system (e.g. the one paging layer is using).
    @param tileID The ID for the tile we're interested in.
    @param ll The lower left corner of the tile in local coordinates.
    @param ur The upper right corner of the tile in local coordinates.
  */
- (void)geoBoundsforTile:(MaplyTileID)tileID ll:(MaplyCoordinate *)ll ur:(MaplyCoordinate *)ur ;

@end
