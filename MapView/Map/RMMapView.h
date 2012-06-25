//
//  RMMapView.h
//
// Copyright (c) 2008-2012, Route-Me Contributors
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

#import <UIKit/UIKit.h>
#import <CoreGraphics/CGGeometry.h>

#import "RMGlobalConstants.h"
#import "RMFoundation.h"
#import "RMMapViewDelegate.h"
#import "RMTile.h"
#import "RMProjection.h"
#import "RMMapOverlayView.h"
#import "RMMapTiledLayerView.h"

// constants for boundingMask
enum {
    RMMapNoMinBound		= 0, // Map can be zoomed out past view limits
    RMMapMinHeightBound	= 1, // Minimum map height when zooming out restricted to view height
    RMMapMinWidthBound	= 2  // Minimum map width when zooming out restricted to view width (default)
};

typedef enum {
    RMMapDecelerationNormal,
    RMMapDecelerationFast,
    RMMapDecelerationOff
} RMMapDecelerationMode;

#define kRMUserLocationAnnotationTypeName   @"RMUserLocationAnnotation"
#define kRMTrackingHaloAnnotationTypeName   @"RMTrackingHaloAnnotation"
#define kRMAccuracyCircleAnnotationTypeName @"RMAccuracyCircleAnnotation"

@class RMProjection;
@class RMFractalTileProjection;
@class RMTileCache;
@class RMMapLayer;
@class RMMapTiledLayerView;
@class RMMarker;
@class RMAnnotation;
@class RMQuadTree;
@class RMUserLocation;

@protocol RMMercatorToTileProjection;
@protocol RMTileSource;
@protocol RMMapTiledLayerViewDelegate;

@interface RMMapView : UIView <UIScrollViewDelegate, RMMapOverlayViewDelegate, RMMapTiledLayerViewDelegate, CLLocationManagerDelegate>
{
    id <RMMapViewDelegate> delegate;

    /// projection objects to convert from latitude/longitude to meters,
    /// from projected meters to tile coordinates
    RMProjection *projection;
    RMFractalTileProjection *mercatorToTileProjection;

    /// subview for the background image displayed while tiles are loading. Set its contents by providing your own "loading.png".
    UIView *backgroundView;
    UIScrollView *mapScrollView;
    RMMapTiledLayerView *tiledLayerView;
    RMMapOverlayView *overlayView;

    double metersPerPixel;
    BOOL adjustTilesForRetinaDisplay;

    NSMutableSet   *annotations;
    NSMutableSet   *visibleAnnotations;
    RMQuadTree     *quadTree;
    BOOL            enableClustering, positionClusterMarkersAtTheGravityCenter;
    CGSize          clusterMarkerSize, clusterAreaSize;

    id <RMTileSource> tileSource;
    RMTileCache *tileCache; // Generic tile cache

    /// minimum and maximum zoom number allowed for the view. #minZoom and #maxZoom must be within the limits of #tileSource but can be stricter; they are clamped to tilesource limits if needed.
    float minZoom, maxZoom, zoom;
    float screenScale;

    NSUInteger boundingMask;
    
    CLLocationManager *locationManager;
    RMUserLocation *userLocation;
    BOOL showsUserLocation;
    RMUserTrackingMode userTrackingMode;
    
    UIImageView *userLocationTrackingView;
    UIImageView *userHeadingTrackingView;
    
    UIViewController *viewControllerPresentingAttribution;
    UIButton *attributionButton;
}

@property (nonatomic, assign) id <RMMapViewDelegate> delegate;

// View properties
@property (nonatomic, assign) BOOL enableDragging;
@property (nonatomic, assign) RMMapDecelerationMode decelerationMode;

@property (nonatomic, assign) CLLocationCoordinate2D centerCoordinate;
@property (nonatomic, assign) RMProjectedPoint centerProjectedPoint;
@property (nonatomic, assign) RMProjectedRect projectedBounds;

@property (nonatomic, readonly) RMProjectedPoint projectedOrigin;
@property (nonatomic, readonly) RMProjectedSize projectedViewSize;

@property (nonatomic, assign)   double metersPerPixel;
@property (nonatomic, readonly) double scaledMetersPerPixel;
@property (nonatomic, readonly) double scaleDenominator; /// The denominator in a cartographic scale like 1/24000, 1/50000, 1/2000000.
@property (nonatomic, readonly) float screenScale;
@property (nonatomic, assign)   NSUInteger boundingMask;

@property (nonatomic, assign)   BOOL adjustTilesForRetinaDisplay;
@property (nonatomic, readonly) float adjustedZoomForRetinaDisplay; // takes adjustTilesForRetinaDisplay and screen scale into account

@property (nonatomic, assign) float zoom; /// zoom level is clamped to range (minZoom, maxZoom)
@property (nonatomic, assign) float minZoom;
@property (nonatomic, assign) float maxZoom;

@property (nonatomic, retain) RMQuadTree *quadTree;
@property (nonatomic, assign) BOOL enableClustering;
@property (nonatomic, assign) BOOL positionClusterMarkersAtTheGravityCenter;
@property (nonatomic, assign) CGSize clusterMarkerSize;
@property (nonatomic, assign) CGSize clusterAreaSize;

@property (nonatomic, readonly) RMProjection *projection;
@property (nonatomic, readonly) id <RMMercatorToTileProjection> mercatorToTileProjection;

@property (nonatomic, retain) id <RMTileSource> tileSource;
@property (nonatomic, retain) RMTileCache *tileCache;

@property (nonatomic, retain) UIView *backgroundView;

@property (nonatomic) BOOL showsUserLocation;
@property (nonatomic, readonly, retain) RMUserLocation *userLocation;
@property (nonatomic, readonly, getter=isUserLocationVisible) BOOL userLocationVisible;
@property (nonatomic) RMUserTrackingMode userTrackingMode;

@property (weak) UIViewController *viewControllerPresentingAttribution;

#pragma mark -
#pragma mark Initializers

- (id)initWithFrame:(CGRect)frame andTilesource:(id <RMTileSource>)newTilesource;

/// designated initializer
- (id)initWithFrame:(CGRect)frame
      andTilesource:(id <RMTileSource>)newTilesource
   centerCoordinate:(CLLocationCoordinate2D)initialCenterCoordinate
          zoomLevel:(float)initialZoomLevel
       maxZoomLevel:(float)maxZoomLevel
       minZoomLevel:(float)minZoomLevel
    backgroundImage:(UIImage *)backgroundImage;

- (void)setFrame:(CGRect)frame;

#pragma mark -
#pragma mark Movement

/// recenter the map on #coordinate, expressed as CLLocationCoordinate2D (latitude/longitude)
- (void)setCenterCoordinate:(CLLocationCoordinate2D)coordinate animated:(BOOL)animated;

/// recenter the map on #aPoint, expressed in projected meters
- (void)setCenterProjectedPoint:(RMProjectedPoint)aPoint animated:(BOOL)animated;

- (void)moveBy:(CGSize)delta;

#pragma mark -
#pragma mark Zoom

/// recenter the map on #boundsRect, expressed in projected meters
- (void)setProjectedBounds:(RMProjectedRect)boundsRect animated:(BOOL)animated;

- (void)zoomByFactor:(float)zoomFactor near:(CGPoint)center animated:(BOOL)animated;

- (void)zoomInToNextNativeZoomAt:(CGPoint)pivot animated:(BOOL)animated;
- (void)zoomOutToNextNativeZoomAt:(CGPoint)pivot animated:(BOOL)animated;

- (void)zoomWithLatitudeLongitudeBoundsSouthWest:(CLLocationCoordinate2D)southWest northEast:(CLLocationCoordinate2D)northEast animated:(BOOL)animated;

- (float)nextNativeZoomFactor;
- (float)previousNativeZoomFactor;

- (void)setMetersPerPixel:(double)newMetersPerPixel animated:(BOOL)animated;

#pragma mark -
#pragma mark Conversions

- (CGPoint)projectedPointToPixel:(RMProjectedPoint)projectedPoint;
- (CGPoint)coordinateToPixel:(CLLocationCoordinate2D)coordinate;

- (RMProjectedPoint)pixelToProjectedPoint:(CGPoint)pixelCoordinate;
- (CLLocationCoordinate2D)pixelToCoordinate:(CGPoint)pixelCoordinate;

- (RMProjectedPoint)coordinateToProjectedPoint:(CLLocationCoordinate2D)coordinate;
- (CLLocationCoordinate2D)projectedPointToCoordinate:(RMProjectedPoint)projectedPoint;

- (RMProjectedSize)viewSizeToProjectedSize:(CGSize)screenSize;
- (CGSize)projectedSizeToViewSize:(RMProjectedSize)projectedSize;

- (CLLocationCoordinate2D)normalizeCoordinate:(CLLocationCoordinate2D)coordinate;
- (RMTile)tileWithCoordinate:(CLLocationCoordinate2D)coordinate andZoom:(int)zoom;

/// returns the smallest bounding box containing the entire view
- (RMSphericalTrapezium)latitudeLongitudeBoundingBox;
/// returns the smallest bounding box containing a rectangular region of the view
- (RMSphericalTrapezium)latitudeLongitudeBoundingBoxFor:(CGRect) rect;

#pragma mark -
#pragma mark Bounds

- (BOOL)projectedBounds:(RMProjectedRect)bounds containsPoint:(RMProjectedPoint)point;
- (BOOL)tileSourceBoundsContainProjectedPoint:(RMProjectedPoint)point;

- (void)setConstraintsSouthWest:(CLLocationCoordinate2D)southWest northEast:(CLLocationCoordinate2D)northEast;
- (void)setProjectedConstraintsSouthWest:(RMProjectedPoint)southWest northEast:(RMProjectedPoint)northEast;

#pragma mark -
#pragma mark Annotations

- (NSArray *)annotations;

- (void)addAnnotation:(RMAnnotation *)annotation;
- (void)addAnnotations:(NSArray *)annotations;

- (void)removeAnnotation:(RMAnnotation *)annotation;
- (void)removeAnnotations:(NSArray *)annotations;
- (void)removeAllAnnotations;

- (CGPoint)mapPositionForAnnotation:(RMAnnotation *)annotation;

#pragma mark -
#pragma mark Cache

///  Clear all images from the #tileSource's caching system.
-(void)removeAllCachedImages;

#pragma mark -
#pragma mark Snapshots

- (UIImage *)takeSnapshot;
- (UIImage *)takeSnapshotAndIncludeOverlay:(BOOL)includeOverlay;

#pragma mark -
#pragma mark User Location

- (void)setUserTrackingMode:(RMUserTrackingMode)mode animated:(BOOL)animated;

@end
