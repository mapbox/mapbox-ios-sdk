//
//  RMMapBoxSource.h
//
//  Created by Justin R. Miller on 5/17/11.
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

#import "RMAbstractWebMapSource.h"

#define kMapBoxDefaultTileSize 256
#define kMapBoxDefaultMinTileZoom 0
#define kMapBoxDefaultMaxTileZoom 18
#define kMapBoxDefaultLatLonBoundingBox ((RMSphericalTrapezium){ .northEast = { .latitude =  90, .longitude =  180 }, \
                                                                 .southWest = { .latitude = -90, .longitude = -180 } })

@class RMMapView;


/** An RMMapBoxSource is used to display map tiles from a network-based map hosted on [MapBox](http://mapbox.com/plans) or the open source [TileStream](https://github.com/mapbox/tilestream) software. Maps are reference by their [TileJSON](http://mapbox.com/developers/tilejson/) endpoint or file. */
@interface RMMapBoxSource : RMAbstractWebMapSource

/** @name Creating Tile Sources */

/** Designated initializer. Point to either a remote or local TileJSON structure.
*   @param referenceURL A remote or local URL pointing to a TileJSON structure. 
*   @return An initialized MapBox tile source. */
- (id)initWithReferenceURL:(NSURL *)referenceURL;

/** Initialize a tile source with TileJSON.
*   @param tileJSON A string containing TileJSON. 
*   @return An initialized MapBox tile source. */
- (id)initWithTileJSON:(NSString *)tileJSON;

/** For TileJSON 2.1.0+ layers, automatically find and add annotations from [simplestyle](http://mapbox.com/developers/simplestyle/) data.
*   @param tileJSON A string containing TileJSON. 
*   @param mapView A map view on which to display the annotations. 
*   @return An initialized MapBox tile source. */
- (id)initWithTileJSON:(NSString *)tileJSON enablingDataOnMapView:(RMMapView *)mapView;

/** For TileJSON 2.1.0+ layers, automatically find and add annotations from [simplestyle](http://mapbox.com/developers/simplestyle/) data.
 *   @param referenceURL A remote or local URL pointing to a TileJSON structure.
 *   @param mapView A map view on which to display the annotations.
 *   @return An initialized MapBox tile source. */
- (id)initWithReferenceURL:(NSURL *)referenceURL enablingDataOnMapView:(RMMapView *)mapView;

/** @name Querying Tile Source Information */

/** Any available HTML-formatted map legend data for the tile source, suitable for display in a UIWebView. */
- (NSString *)legend;

/** A suggested starting center coordinate for the map layer. */
- (CLLocationCoordinate2D)centerCoordinate;

/** A suggested starting center zoom level for the map layer. */
- (float)centerZoom;

/** Returns YES if the tile source provides full-world coverage; otherwise, returns NO. */
- (BOOL)coversFullWorld;

/** Info about the TileJSON in a Cocoa-native format. */
@property (nonatomic, readonly, strong) NSDictionary *infoDictionary;

@end
