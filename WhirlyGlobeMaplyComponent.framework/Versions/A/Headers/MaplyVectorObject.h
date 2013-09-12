/*
 *  MaplyVectorObject.h
 *  WhirlyGlobeComponent
 *
 *  Created by Steve Gifford on 8/2/12.
 *  Copyright 2012 mousebird consulting
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

#import <Foundation/Foundation.h>
#import <MaplyCoordinate.h>

/// Data type for the vector.  Multi means it contains multiple types
typedef enum {MaplyVectorNoneType,MaplyVectorPointType,MaplyVectorLinearType,MaplyVectorArealType,MaplyVectorMultiType} MaplyVectorObjectType;

/** Maply Component Vector Object.
    This can represent one or more vector features parsed out of GeoJSON or
    coming from a Vector Database Source.  You can also just make these
    up yourself wit the init calls.
  */
@interface MaplyVectorObject : NSObject

/// For user data
@property (nonatomic,strong) NSObject *userObject;
/// Turn this off to make this vector invisible to selection.
/// On by default.
@property (nonatomic,assign) bool selectable;

/// Get the attributes.  If it's a multi-object this will just return the first
///  attribute dictionary.
@property (nonatomic,readonly) NSDictionary *attributes;

/// Parse vector data from geoJSON.  Returns one object to represent
///  the whole thing, which might include multiple different vectors.
/// We assume the geoJSON is all in decimal degrees in WGS84.
+ (MaplyVectorObject *)VectorObjectFromGeoJSON:(NSData *)geoJSON;

/// Parse vector data from geoJSON.  Returns one object to represent
///  the whole thing, which might include multiple different vectors.
/// We assume the geoJSON is all in decimal degrees in WGS84.
/// This version uses the Apple JSON parser.  Slow, since it creates a dictionary.
+ (MaplyVectorObject *)VectorObjectFromGeoJSONApple:(NSData *)geoJSON;

/// This version takes a dictionary
+ (MaplyVectorObject *)VectorObjectFromGeoJSONDictionary:(NSDictionary *)geoJSON;

/// This version can deal with non-compliant assemblies returned by the experimental
///  OSM server
+ (NSDictionary *)VectorObjectsFromGeoJSONAssembly:(NSData *)geoJSON;

/// Construct with a single point
- (id)initWithPoint:(MaplyCoordinate *)coord attributes:(NSDictionary *)attr;
/// Construct with a linear feature (e.g. line string)
- (id)initWithLineString:(MaplyCoordinate *)coords numCoords:(int)numCoords attributes:(NSDictionary *)attr;
/// Construct as an areal with an exterior
- (id)initWithAreal:(MaplyCoordinate *)coords numCoords:(int)numCoords attributes:(NSDictionary *)attr;

/// Make a deep copy.  That is, copy all the vectors rather than just referencing them
- (MaplyVectorObject *)deepCopy;

/// Dump the feature(s) out as text
- (NSString *)log;

/// Add a hole to an existing areal feature
- (void)addHole:(MaplyCoordinate *)coords numCoords:(int)numCoords;

/// Vector type.  Multi means it's more than one type
- (MaplyVectorObjectType)vectorType;

/// For areal features, check if the given point is inside
- (bool)pointInAreal:(MaplyCoordinate)coord;

/// Calculate and return the center of the whole object
- (MaplyCoordinate)center;

/// For a linear feature, calculate the point and rotation (in radians) in the middle
- (bool)linearMiddle:(MaplyCoordinate *)middle rot:(float *)rot;

/// Calculate the center and extents of the largest loop.
/// Returns false if there was no loop
- (bool)largestLoopCenter:(MaplyCoordinate *)center mbrLL:(MaplyCoordinate *)ll mbrUR:(MaplyCoordinate *)ur;

/// Bounding box for all the data in the vector
- (bool)boundingBoxLL:(MaplyCoordinate *)ll ur:(MaplyCoordinate *)ur;

/// Return an NSArray of NSArrays of CLLocation points.
/// One array per loop in the areal, so assumes this is an areal
- (NSArray *)asCLLocationArrays;

/// Vector objects can encapsulate multiple objects since they're read from GeoJSON.
/// This splits any multiples into single objects.
- (NSArray *)splitVectors;

/// This will break up long edges in a vector until they lie flat on a globe to a given
///  epsilon.  The epislon is in display coordinates (radius = 1.0).
/// This routine breaks this up along geographic boundaries.
- (void)subdivideToGlobe:(float)epsilon;

/// This will break up long edges in a vector until they lie flat on a globe to a given
///  epsilon using a great circle route.  The epislon is in display coordinates (radius = 1.0).
- (void)subdivideToGlobeGreatCircle:(float)epsilon;

/// Return the input areals tesselated into triangles without attribution.
/// Note: Doesn't handle holes correctly
- (MaplyVectorObject *) tesselate;

@end

typedef MaplyVectorObject WGVectorObject;


/** Maply Vector Database.  This object encapsulates a simple database of vector features,
    possibly a Shapefile.  The implications is that not all the features are in memory.
 */
@interface MaplyVectorDatabase : NSObject

/// Construct from a shapefile in the bundle
+ (MaplyVectorDatabase *) vectorDatabaseWithShape:(NSString *)shapeName;

/// Return vectors that match the given SQL query
- (MaplyVectorObject *)fetchMatchingVectors:(NSString *)sqlQuery;

/// Search for all the areals that surround the given point (in geographic)
- (MaplyVectorObject *)fetchArealsForPoint:(MaplyCoordinate)coord;

/// Fetch all the vectors in the database
- (MaplyVectorObject *)fetchAllVectors;

@end
