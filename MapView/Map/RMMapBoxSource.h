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
//  This source supports both tiles from MapBox Hosting as well as the open source,
//  self-hosted TileStream software.
//
//  When initializing an instance, pass in valid TileJSON[1] as returned by
//  the MapBox Hosting API[2] or TileStream software[3].
//
//  Also supports simplestyle[4] data for TileJSON 2.1.0+[5].
//
//  Example app at https://github.com/mapbox/mapbox-ios-example
//
//  [1] https://github.com/mapbox/tilejson-spec
//  [2] http://mapbox.com/hosting/api/
//  [3] https://github.com/mapbox/tilestream
//  [4] https://github.com/mapbox/simplestyle-spec
//  [5] https://github.com/mapbox/tilejson-spec/tree/v2.1.0/
//
//  This class also supports initialization via the deprecated info dictionary
//  for backwards compatibility and for iOS < 5.0 where JSON serialization isn't
//  built into the SDK. Its use is discouraged.

#import "RMAbstractWebMapSource.h"

#define kMapBoxDefaultTileSize 256
#define kMapBoxDefaultMinTileZoom 0
#define kMapBoxDefaultMaxTileZoom 18
#define kMapBoxDefaultLatLonBoundingBox ((RMSphericalTrapezium){ .northEast = { .latitude =  90, .longitude =  180 }, \
                                                                 .southWest = { .latitude = -90, .longitude = -180 } })

@class RMMapView;

@interface RMMapBoxSource : RMAbstractWebMapSource

// Designated initializer. Point to either a remote TileJSON spec or a local TileJSON or property list.
- (id)initWithReferenceURL:(NSURL *)referenceURL;

// Initialize source with TileJSON.
- (id)initWithTileJSON:(NSString *)tileJSON;

// For TileJSON 2.1.0+ layers, look for and auto-add annotations from simplestyle data.
- (id)initWithTileJSON:(NSString *)tileJSON enablingDataOnMapView:(RMMapView *)mapView;
- (id)initWithReferenceURL:(NSURL *)referenceURL enablingDataOnMapView:(RMMapView *)mapView;

// Initialize source with properly list (deprecated; use TileJSON).
- (id)initWithInfo:(NSDictionary *)info __attribute__ ((deprecated));

// HTML-formatted legend for this source, if any
- (NSString *)legend;

// Suggested starting center coordinate
- (CLLocationCoordinate2D)centerCoordinate;

// Suggested starting center zoom
- (float)centerZoom;

// Regional or global coverage?
- (BOOL)coversFullWorld;

@property (nonatomic, readonly, retain) NSDictionary *infoDictionary;

@end
