//
//  RMMapView.m
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

#import "RMMapView.h"
#import "RMMapViewDelegate.h"
#import "RMPixel.h"

#import "RMFoundation.h"
#import "RMProjection.h"
#import "RMMarker.h"
#import "RMPath.h"
#import "RMCircle.h"
#import "RMShape.h"
#import "RMAnnotation.h"
#import "RMQuadTree.h"

#import "RMFractalTileProjection.h"
#import "RMOpenStreetMapSource.h"

#import "RMTileCache.h"
#import "RMTileSource.h"

#import "RMMapTiledLayerView.h"
#import "RMMapOverlayView.h"
#import "RMLoadingTileView.h"

#import "RMUserLocation.h"

#import "RMAttributionViewController.h"

#pragma mark --- begin constants ----

#define kZoomRectPixelBuffer 150.0

#define kDefaultInitialLatitude  38.913175
#define kDefaultInitialLongitude -77.032458

#define kDefaultMinimumZoomLevel 0.0
#define kDefaultMaximumZoomLevel 25.0
#define kDefaultInitialZoomLevel 11.0

#define kDefaultAnnotationMarker [[[RMMarker alloc] initWithMapBoxMarkerImage:@"star" tintColor:[UIColor redColor]] autorelease]

#pragma mark --- end constants ----

@interface RMMapView (PrivateMethods) <UIScrollViewDelegate, UIGestureRecognizerDelegate, RMMapScrollViewDelegate, CLLocationManagerDelegate>

@property (nonatomic, assign) UIViewController *viewControllerPresentingAttribution;
@property (nonatomic, retain) RMUserLocation *userLocation;

- (void)createMapView;

- (void)registerMoveEventByUser:(BOOL)wasUserEvent;
- (void)registerZoomEventByUser:(BOOL)wasUserEvent;

- (void)correctPositionOfAllAnnotations;
- (void)correctPositionOfAllAnnotationsIncludingInvisibles:(BOOL)correctAllLayers animated:(BOOL)animated;

- (void)correctMinZoomScaleForBoundingMask;

- (void)updateHeadingForDeviceOrientation;

@end

#pragma mark -

@interface RMUserLocation (PrivateMethods)

@property (nonatomic, getter=isUpdating) BOOL updating;
@property (nonatomic, retain) CLLocation *location;
@property (nonatomic, retain) CLHeading *heading;

@end

#pragma mark -

@interface RMAnnotation (PrivateMethods)

@property (nonatomic, assign) BOOL isUserLocationAnnotation;

@end

#pragma mark -

@implementation RMMapView
{
    id <RMMapViewDelegate> _delegate;

    BOOL _delegateHasBeforeMapMove;
    BOOL _delegateHasAfterMapMove;
    BOOL _delegateHasBeforeMapZoom;
    BOOL _delegateHasAfterMapZoom;
    BOOL _delegateHasMapViewRegionDidChange;
    BOOL _delegateHasDoubleTapOnMap;
    BOOL _delegateHasSingleTapOnMap;
    BOOL _delegateHasSingleTapTwoFingersOnMap;
    BOOL _delegateHasLongSingleTapOnMap;
    BOOL _delegateHasTapOnAnnotation;
    BOOL _delegateHasDoubleTapOnAnnotation;
    BOOL _delegateHasTapOnLabelForAnnotation;
    BOOL _delegateHasDoubleTapOnLabelForAnnotation;
    BOOL _delegateHasShouldDragMarker;
    BOOL _delegateHasDidDragMarker;
    BOOL _delegateHasDidEndDragMarker;
    BOOL _delegateHasLayerForAnnotation;
    BOOL _delegateHasWillHideLayerForAnnotation;
    BOOL _delegateHasDidHideLayerForAnnotation;
    BOOL _delegateHasWillStartLocatingUser;
    BOOL _delegateHasDidStopLocatingUser;
    BOOL _delegateHasDidUpdateUserLocation;
    BOOL _delegateHasDidFailToLocateUserWithError;
    BOOL _delegateHasDidChangeUserTrackingMode;

    UIView *_backgroundView;
    RMMapScrollView *_mapScrollView;
    RMMapOverlayView *_overlayView;
    UIView *_tiledLayersSuperview;
    RMLoadingTileView *_loadingTileView;

    RMProjection *_projection;
    RMFractalTileProjection *_mercatorToTileProjection;
    RMTileSourcesContainer *_tileSourcesContainer;

    NSMutableSet *_annotations;
    NSMutableSet *_visibleAnnotations;

    BOOL _constrainMovement;
    RMProjectedRect _constrainingProjectedBounds;

    double _metersPerPixel;
    float _zoom, _lastZoom;
    CGPoint _lastContentOffset, _accumulatedDelta;
    CGSize _lastContentSize;
    BOOL _mapScrollViewIsZooming;

    BOOL _enableDragging, _enableBouncing;

    CGPoint _lastDraggingTranslation;
    RMAnnotation *_draggedAnnotation;

    CLLocationManager *_locationManager;

    RMAnnotation *_accuracyCircleAnnotation;
    RMAnnotation *_trackingHaloAnnotation;

    UIImageView *_userLocationTrackingView;
    UIImageView *_userHeadingTrackingView;
    UIImageView *_userHaloTrackingView;

    UIViewController *_viewControllerPresentingAttribution;
    UIButton *_attributionButton;

    CGAffineTransform _mapTransform;
    CATransform3D _annotationTransform;

    NSOperationQueue *_moveDelegateQueue;
    NSOperationQueue *_zoomDelegateQueue;

    UIImageView *_logoBug;
}

@synthesize decelerationMode = _decelerationMode;

@synthesize boundingMask = _boundingMask;
@synthesize zoomingInPivotsAroundCenter = _zoomingInPivotsAroundCenter;
@synthesize minZoom = _minZoom, maxZoom = _maxZoom;
@synthesize screenScale = _screenScale;
@synthesize tileCache = _tileCache;
@synthesize quadTree = _quadTree;
@synthesize enableClustering = _enableClustering;
@synthesize positionClusterMarkersAtTheGravityCenter = _positionClusterMarkersAtTheGravityCenter;
@synthesize orderClusterMarkersAboveOthers = _orderClusterMarkersAboveOthers;
@synthesize clusterMarkerSize = _clusterMarkerSize, clusterAreaSize = _clusterAreaSize;
@synthesize adjustTilesForRetinaDisplay = _adjustTilesForRetinaDisplay;
@synthesize userLocation = _userLocation;
@synthesize showsUserLocation = _showsUserLocation;
@synthesize userTrackingMode = _userTrackingMode;
@synthesize displayHeadingCalibration = _displayHeadingCalibration;
@synthesize missingTilesDepth = _missingTilesDepth;
@synthesize debugTiles = _debugTiles;
@synthesize hideAttribution = _hideAttribution;
@synthesize showLogoBug = _showLogoBug;

#pragma mark -
#pragma mark Initialization

- (void)performInitializationWithTilesource:(id <RMTileSource>)newTilesource
                           centerCoordinate:(CLLocationCoordinate2D)initialCenterCoordinate
                                  zoomLevel:(float)initialTileSourceZoomLevel
                               maxZoomLevel:(float)initialTileSourceMaxZoomLevel
                               minZoomLevel:(float)initialTileSourceMinZoomLevel
                            backgroundImage:(UIImage *)backgroundImage
{
    _constrainMovement = _enableBouncing = _zoomingInPivotsAroundCenter = NO;
    _enableDragging = YES;

    _lastDraggingTranslation = CGPointZero;
    _draggedAnnotation = nil;

    self.backgroundColor = [UIColor grayColor];

    self.clipsToBounds = YES;
    
    _tileSourcesContainer = [RMTileSourcesContainer new];
    _tiledLayersSuperview = nil;

    _projection = nil;
    _mercatorToTileProjection = nil;
    _mapScrollView = nil;
    _overlayView = nil;

    _screenScale = [UIScreen mainScreen].scale;

    _boundingMask = RMMapMinWidthBound;
    _adjustTilesForRetinaDisplay = NO;
    _missingTilesDepth = 1;
    _debugTiles = NO;

    _annotations = [NSMutableSet new];
    _visibleAnnotations = [NSMutableSet new];
    [self setQuadTree:[[[RMQuadTree alloc] initWithMapView:self] autorelease]];
    _enableClustering = _positionClusterMarkersAtTheGravityCenter = NO;
    _clusterMarkerSize = CGSizeMake(100.0, 100.0);
    _clusterAreaSize = CGSizeMake(150.0, 150.0);

    _moveDelegateQueue = [[NSOperationQueue alloc] init];
    [_moveDelegateQueue setMaxConcurrentOperationCount:1];

    _zoomDelegateQueue = [[NSOperationQueue alloc] init];
    [_zoomDelegateQueue setMaxConcurrentOperationCount:1];

    [self setTileCache:[[[RMTileCache alloc] init] autorelease]];

    if (backgroundImage)
    {
        [self setBackgroundView:[[[UIView alloc] initWithFrame:[self bounds]] autorelease]];
        self.backgroundView.layer.contents = (id)backgroundImage.CGImage;
    }
    else
    {
        _loadingTileView = [[[RMLoadingTileView alloc] initWithFrame:self.bounds] autorelease];
        [self setBackgroundView:_loadingTileView];
    }

    if (initialTileSourceMinZoomLevel < newTilesource.minZoom) initialTileSourceMinZoomLevel = newTilesource.minZoom;
    if (initialTileSourceMaxZoomLevel > newTilesource.maxZoom) initialTileSourceMaxZoomLevel = newTilesource.maxZoom;
    [self setTileSourcesMinZoom:initialTileSourceMinZoomLevel];
    [self setTileSourcesMaxZoom:initialTileSourceMaxZoomLevel];
    [self setTileSourcesZoom:initialTileSourceZoomLevel];

    [self setTileSource:newTilesource];
    [self setCenterCoordinate:initialCenterCoordinate animated:NO];

    [self setDecelerationMode:RMMapDecelerationFast];
    [self setBoundingMask:RMMapMinHeightBound];

    self.showLogoBug = YES;

    self.displayHeadingCalibration = YES;

    _mapTransform = CGAffineTransformIdentity;
    _annotationTransform = CATransform3DIdentity;

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleMemoryWarningNotification:)
                                                 name:UIApplicationDidReceiveMemoryWarningNotification
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleWillChangeOrientationNotification:)
                                                 name:UIApplicationWillChangeStatusBarOrientationNotification
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleDidChangeOrientationNotification:)
                                                 name:UIApplicationDidChangeStatusBarOrientationNotification
                                               object:nil];

    RMLog(@"Map initialised. tileSource:%@, minZoom:%f, maxZoom:%f, zoom:%f at {%f,%f}", newTilesource, self.minZoom, self.maxZoom, self.zoom, initialCenterCoordinate.longitude, initialCenterCoordinate.latitude);
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    LogMethod();

    if (!(self = [super initWithCoder:aDecoder]))
        return nil;

	CLLocationCoordinate2D coordinate;
	coordinate.latitude = kDefaultInitialLatitude;
	coordinate.longitude = kDefaultInitialLongitude;

    [self performInitializationWithTilesource:[[RMOpenStreetMapSource new] autorelease]
                             centerCoordinate:coordinate
                                    zoomLevel:kDefaultInitialZoomLevel
                                 maxZoomLevel:kDefaultMaximumZoomLevel
                                 minZoomLevel:kDefaultMinimumZoomLevel
                              backgroundImage:nil];

    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    LogMethod();

    return [self initWithFrame:frame andTilesource:[[RMOpenStreetMapSource new] autorelease]];
}

- (id)initWithFrame:(CGRect)frame andTilesource:(id <RMTileSource>)newTilesource
{
	LogMethod();

	CLLocationCoordinate2D coordinate;
	coordinate.latitude = kDefaultInitialLatitude;
	coordinate.longitude = kDefaultInitialLongitude;

	return [self initWithFrame:frame
                 andTilesource:newTilesource
              centerCoordinate:coordinate
                     zoomLevel:kDefaultInitialZoomLevel
                  maxZoomLevel:kDefaultMaximumZoomLevel
                  minZoomLevel:kDefaultMinimumZoomLevel
               backgroundImage:nil];
}

- (id)initWithFrame:(CGRect)frame
      andTilesource:(id <RMTileSource>)newTilesource
   centerCoordinate:(CLLocationCoordinate2D)initialCenterCoordinate
          zoomLevel:(float)initialZoomLevel
       maxZoomLevel:(float)maxZoomLevel
       minZoomLevel:(float)minZoomLevel
    backgroundImage:(UIImage *)backgroundImage
{
    LogMethod();

    if (!(self = [super initWithFrame:frame]))
        return nil;

    [self performInitializationWithTilesource:newTilesource
                             centerCoordinate:initialCenterCoordinate
                                    zoomLevel:initialZoomLevel
                                 maxZoomLevel:maxZoomLevel
                                 minZoomLevel:minZoomLevel
                              backgroundImage:backgroundImage];

    return self;
}

- (void)setFrame:(CGRect)frame
{
    CGRect r = self.frame;
    [super setFrame:frame];

    // only change if the frame changes and not during initialization
    if ( ! CGRectEqualToRect(r, frame))
    {
        RMProjectedPoint centerPoint = self.centerProjectedPoint;

        CGRect bounds = CGRectMake(0, 0, frame.size.width, frame.size.height);
        _backgroundView.frame = bounds;
        _mapScrollView.frame = bounds;
        _overlayView.frame = bounds;

        [self setCenterProjectedPoint:centerPoint animated:NO];

        [self correctPositionOfAllAnnotations];
        [self correctMinZoomScaleForBoundingMask];
    }
}

- (void)dealloc
{
    LogMethod();

    [self setDelegate:nil];
    [self setBackgroundView:nil];
    [self setQuadTree:nil];
    [_moveDelegateQueue cancelAllOperations];
    [_moveDelegateQueue release]; _moveDelegateQueue = nil;
    [_zoomDelegateQueue cancelAllOperations];
    [_zoomDelegateQueue release]; _zoomDelegateQueue = nil;
    [_draggedAnnotation release]; _draggedAnnotation = nil;
    [_annotations release]; _annotations = nil;
    [_visibleAnnotations release]; _visibleAnnotations = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_mapScrollView removeObserver:self forKeyPath:@"contentOffset"];
    [_tiledLayersSuperview release]; _tiledLayersSuperview = nil;
    [_mapScrollView release]; _mapScrollView = nil;
    [_overlayView release]; _overlayView = nil;
    [_tileSourcesContainer cancelAllDownloads]; [_tileSourcesContainer release]; _tileSourcesContainer = nil;
    [_projection release]; _projection = nil;
    [_mercatorToTileProjection release]; _mercatorToTileProjection = nil;
    [self setTileCache:nil];
    _locationManager.delegate = nil;
    [_locationManager stopUpdatingLocation];
    [_locationManager stopUpdatingHeading];
    [_locationManager release]; _locationManager = nil;
    [_userLocation release]; _userLocation = nil;
    [_accuracyCircleAnnotation release]; _accuracyCircleAnnotation = nil;
    [_trackingHaloAnnotation release]; _trackingHaloAnnotation = nil;
    [_userLocationTrackingView release]; _userLocationTrackingView = nil;
    [_userHeadingTrackingView release]; _userHeadingTrackingView = nil;
    [_userHaloTrackingView release]; _userHaloTrackingView = nil;
    [_attributionButton release]; _attributionButton = nil;
    [_logoBug release]; _logoBug = nil;
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    LogMethod();

    [self.tileCache didReceiveMemoryWarning];
    [self.tileSourcesContainer didReceiveMemoryWarning];
}

- (void)handleMemoryWarningNotification:(NSNotification *)notification
{
	[self didReceiveMemoryWarning];
}

- (void)handleWillChangeOrientationNotification:(NSNotification *)notification
{
    // send a dummy heading update to force re-rotation
    //
    if (self.userTrackingMode == RMUserTrackingModeFollowWithHeading)
        [self locationManager:_locationManager didUpdateHeading:_locationManager.heading];
}

- (void)handleDidChangeOrientationNotification:(NSNotification *)notification
{
    [self updateHeadingForDeviceOrientation];
}

- (void)layoutSubviews
{
    if ( ! self.viewControllerPresentingAttribution && ! _hideAttribution)
    {
        UIViewController *candidateViewController = self.window.rootViewController;

        while ([self isDescendantOfView:candidateViewController.view])
        {
            for (UIViewController *childViewController in candidateViewController.childViewControllers)
                if ([self isDescendantOfView:childViewController.view])
                    candidateViewController = childViewController;

            if ( ! [candidateViewController.childViewControllers count] || [candidateViewController isEqual:self.window.rootViewController])
                break;
        }

        self.viewControllerPresentingAttribution = candidateViewController;
    }
    else if (self.viewControllerPresentingAttribution && _hideAttribution)
    {
        self.viewControllerPresentingAttribution = nil;
    }

    [super layoutSubviews];
}

- (void)removeFromSuperview
{
    self.viewControllerPresentingAttribution = nil;

    [super removeFromSuperview];
}

- (NSString *)description
{
	CGRect bounds = self.bounds;

	return [NSString stringWithFormat:@"MapView at {%.0f,%.0f}-{%.0fx%.0f}", bounds.origin.x, bounds.origin.y, bounds.size.width, bounds.size.height];
}

#pragma mark -
#pragma mark Delegate

- (id <RMMapViewDelegate>)delegate
{
	return _delegate;
}

- (void)setDelegate:(id <RMMapViewDelegate>)aDelegate
{
    if (_delegate == aDelegate)
        return;

    _delegate = aDelegate;

    _delegateHasBeforeMapMove = [_delegate respondsToSelector:@selector(beforeMapMove:byUser:)];
    _delegateHasAfterMapMove  = [_delegate respondsToSelector:@selector(afterMapMove:byUser:)];

    _delegateHasBeforeMapZoom = [_delegate respondsToSelector:@selector(beforeMapZoom:byUser:)];
    _delegateHasAfterMapZoom  = [_delegate respondsToSelector:@selector(afterMapZoom:byUser:)];

    _delegateHasMapViewRegionDidChange = [_delegate respondsToSelector:@selector(mapViewRegionDidChange:)];

    _delegateHasDoubleTapOnMap = [_delegate respondsToSelector:@selector(doubleTapOnMap:at:)];
    _delegateHasSingleTapOnMap = [_delegate respondsToSelector:@selector(singleTapOnMap:at:)];
    _delegateHasSingleTapTwoFingersOnMap = [_delegate respondsToSelector:@selector(singleTapTwoFingersOnMap:at:)];
    _delegateHasLongSingleTapOnMap = [_delegate respondsToSelector:@selector(longSingleTapOnMap:at:)];

    _delegateHasTapOnAnnotation = [_delegate respondsToSelector:@selector(tapOnAnnotation:onMap:)];
    _delegateHasDoubleTapOnAnnotation = [_delegate respondsToSelector:@selector(doubleTapOnAnnotation:onMap:)];
    _delegateHasTapOnLabelForAnnotation = [_delegate respondsToSelector:@selector(tapOnLabelForAnnotation:onMap:)];
    _delegateHasDoubleTapOnLabelForAnnotation = [_delegate respondsToSelector:@selector(doubleTapOnLabelForAnnotation:onMap:)];

    _delegateHasShouldDragMarker = [_delegate respondsToSelector:@selector(mapView:shouldDragAnnotation:)];
    _delegateHasDidDragMarker = [_delegate respondsToSelector:@selector(mapView:didDragAnnotation:withDelta:)];
    _delegateHasDidEndDragMarker = [_delegate respondsToSelector:@selector(mapView:didEndDragAnnotation:)];

    _delegateHasLayerForAnnotation = [_delegate respondsToSelector:@selector(mapView:layerForAnnotation:)];
    _delegateHasWillHideLayerForAnnotation = [_delegate respondsToSelector:@selector(mapView:willHideLayerForAnnotation:)];
    _delegateHasDidHideLayerForAnnotation = [_delegate respondsToSelector:@selector(mapView:didHideLayerForAnnotation:)];

    _delegateHasWillStartLocatingUser = [_delegate respondsToSelector:@selector(mapViewWillStartLocatingUser:)];
    _delegateHasDidStopLocatingUser = [_delegate respondsToSelector:@selector(mapViewDidStopLocatingUser:)];
    _delegateHasDidUpdateUserLocation = [_delegate respondsToSelector:@selector(mapView:didUpdateUserLocation:)];
    _delegateHasDidFailToLocateUserWithError = [_delegate respondsToSelector:@selector(mapView:didFailToLocateUserWithError:)];
    _delegateHasDidChangeUserTrackingMode = [_delegate respondsToSelector:@selector(mapView:didChangeUserTrackingMode:animated:)];
}

- (void)registerMoveEventByUser:(BOOL)wasUserEvent
{
    @synchronized (_moveDelegateQueue)
    {
        BOOL flag = wasUserEvent;

        if ([_moveDelegateQueue operationCount] == 0)
        {
            dispatch_async(dispatch_get_main_queue(), ^(void)
            {
                if (_delegateHasBeforeMapMove)
                    [_delegate beforeMapMove:self byUser:flag];
            });
        }

        [_moveDelegateQueue setSuspended:YES];

        if ([_moveDelegateQueue operationCount] == 0)
        {
            [_moveDelegateQueue addOperationWithBlock:^(void)
            {
                dispatch_async(dispatch_get_main_queue(), ^(void)
                {
                    if (_delegateHasAfterMapMove)
                        [_delegate afterMapMove:self byUser:flag];
                });
            }];
        }
    }
}

- (void)registerZoomEventByUser:(BOOL)wasUserEvent
{
    @synchronized (_zoomDelegateQueue)
    {
        BOOL flag = wasUserEvent;

        if ([_zoomDelegateQueue operationCount] == 0)
        {
            dispatch_async(dispatch_get_main_queue(), ^(void)
            {
                if (_delegateHasBeforeMapZoom)
                    [_delegate beforeMapZoom:self byUser:flag];
            });
        }

        [_zoomDelegateQueue setSuspended:YES];

        if ([_zoomDelegateQueue operationCount] == 0)
        {
            [_zoomDelegateQueue addOperationWithBlock:^(void)
            {
                dispatch_async(dispatch_get_main_queue(), ^(void)
                {
                    if (_delegateHasAfterMapZoom)
                        [_delegate afterMapZoom:self byUser:flag];
                });
            }];
        }
    }
}

#pragma mark -
#pragma mark Bounds

- (RMProjectedRect)fitProjectedRect:(RMProjectedRect)rect1 intoRect:(RMProjectedRect)rect2
{
    if (rect1.size.width > rect2.size.width || rect1.size.height > rect2.size.height)
        return rect2;

    RMProjectedRect fittedRect = RMProjectedRectMake(0.0, 0.0, rect1.size.width, rect1.size.height);

    if (rect1.origin.x < rect2.origin.x)
        fittedRect.origin.x = rect2.origin.x;
    else if (rect1.origin.x + rect1.size.width > rect2.origin.x + rect2.size.width)
        fittedRect.origin.x = (rect2.origin.x + rect2.size.width) - rect1.size.width;
    else
        fittedRect.origin.x = rect1.origin.x;

    if (rect1.origin.y < rect2.origin.y)
        fittedRect.origin.y = rect2.origin.y;
    else if (rect1.origin.y + rect1.size.height > rect2.origin.y + rect2.size.height)
        fittedRect.origin.y = (rect2.origin.y + rect2.size.height) - rect1.size.height;
    else
        fittedRect.origin.y = rect1.origin.y;

    return fittedRect;
}

- (RMProjectedRect)projectedRectFromLatitudeLongitudeBounds:(RMSphericalTrapezium)bounds
{
    CLLocationCoordinate2D southWest = bounds.southWest;
    CLLocationCoordinate2D northEast = bounds.northEast;
    CLLocationCoordinate2D midpoint = {
        .latitude = (northEast.latitude + southWest.latitude) / 2,
        .longitude = (northEast.longitude + southWest.longitude) / 2
    };

    RMProjectedPoint myOrigin = [_projection coordinateToProjectedPoint:midpoint];
    RMProjectedPoint southWestPoint = [_projection coordinateToProjectedPoint:southWest];
    RMProjectedPoint northEastPoint = [_projection coordinateToProjectedPoint:northEast];
    RMProjectedPoint myPoint = {
        .x = northEastPoint.x - southWestPoint.x,
        .y = northEastPoint.y - southWestPoint.y
    };

    // Create the new zoom layout
    RMProjectedRect zoomRect;

    // Default is with scale = 2.0 * mercators/pixel
    zoomRect.size.width = self.bounds.size.width * 2.0;
    zoomRect.size.height = self.bounds.size.height * 2.0;

    if ((myPoint.x / self.bounds.size.width) < (myPoint.y / self.bounds.size.height))
    {
        if ((myPoint.y / self.bounds.size.height) > 1)
        {
            zoomRect.size.width = self.bounds.size.width * (myPoint.y / self.bounds.size.height);
            zoomRect.size.height = self.bounds.size.height * (myPoint.y / self.bounds.size.height);
        }
    }
    else
    {
        if ((myPoint.x / self.bounds.size.width) > 1)
        {
            zoomRect.size.width = self.bounds.size.width * (myPoint.x / self.bounds.size.width);
            zoomRect.size.height = self.bounds.size.height * (myPoint.x / self.bounds.size.width);
        }
    }

    myOrigin.x = myOrigin.x - (zoomRect.size.width / 2);
    myOrigin.y = myOrigin.y - (zoomRect.size.height / 2);

    RMLog(@"Origin is calculated at: %f, %f", [_projection projectedPointToCoordinate:myOrigin].longitude, [_projection projectedPointToCoordinate:myOrigin].latitude);

    zoomRect.origin = myOrigin;

//    RMLog(@"Origin: x=%f, y=%f, w=%f, h=%f", zoomRect.origin.easting, zoomRect.origin.northing, zoomRect.size.width, zoomRect.size.height);

    return zoomRect;
}

- (BOOL)tileSourceBoundsContainProjectedPoint:(RMProjectedPoint)point
{
    RMSphericalTrapezium bounds = [self.tileSourcesContainer latitudeLongitudeBoundingBox];

    if (bounds.northEast.latitude == 90.0 && bounds.northEast.longitude == 180.0 &&
        bounds.southWest.latitude == -90.0 && bounds.southWest.longitude == -180.0)
    {
        return YES;
    }

    return RMProjectedRectContainsProjectedPoint(_constrainingProjectedBounds, point);
}

- (BOOL)tileSourceBoundsContainScreenPoint:(CGPoint)pixelCoordinate
{
    RMProjectedPoint projectedPoint = [self pixelToProjectedPoint:pixelCoordinate];

    return [self tileSourceBoundsContainProjectedPoint:projectedPoint];
}

// ===

- (void)setConstraintsSouthWest:(CLLocationCoordinate2D)southWest northEast:(CLLocationCoordinate2D)northEast
{
    RMProjectedPoint projectedSouthWest = [_projection coordinateToProjectedPoint:southWest];
    RMProjectedPoint projectedNorthEast = [_projection coordinateToProjectedPoint:northEast];

    [self setProjectedConstraintsSouthWest:projectedSouthWest northEast:projectedNorthEast];
}

- (void)setProjectedConstraintsSouthWest:(RMProjectedPoint)southWest northEast:(RMProjectedPoint)northEast
{
    _constrainMovement = YES;
    _constrainingProjectedBounds = RMProjectedRectMake(southWest.x, southWest.y, northEast.x - southWest.x, northEast.y - southWest.y);
}

#pragma mark -
#pragma mark Movement

- (CLLocationCoordinate2D)centerCoordinate
{
    return [_projection projectedPointToCoordinate:[self centerProjectedPoint]];
}

- (void)setCenterCoordinate:(CLLocationCoordinate2D)centerCoordinate
{
    [self setCenterProjectedPoint:[_projection coordinateToProjectedPoint:centerCoordinate]];
}

- (void)setCenterCoordinate:(CLLocationCoordinate2D)centerCoordinate animated:(BOOL)animated
{
    [self setCenterProjectedPoint:[_projection coordinateToProjectedPoint:centerCoordinate] animated:animated];
}

// ===

- (RMProjectedPoint)centerProjectedPoint
{
    CGPoint center = CGPointMake(_mapScrollView.contentOffset.x + _mapScrollView.bounds.size.width/2.0, _mapScrollView.contentSize.height - (_mapScrollView.contentOffset.y + _mapScrollView.bounds.size.height/2.0));

    RMProjectedRect planetBounds = _projection.planetBounds;
    RMProjectedPoint normalizedProjectedPoint;
    normalizedProjectedPoint.x = (center.x * _metersPerPixel) - fabs(planetBounds.origin.x);
    normalizedProjectedPoint.y = (center.y * _metersPerPixel) - fabs(planetBounds.origin.y);

//    RMLog(@"centerProjectedPoint: {%f,%f}", normalizedProjectedPoint.x, normalizedProjectedPoint.y);

    return normalizedProjectedPoint;
}

- (void)setCenterProjectedPoint:(RMProjectedPoint)centerProjectedPoint
{
    [self setCenterProjectedPoint:centerProjectedPoint animated:YES];
}

- (void)setCenterProjectedPoint:(RMProjectedPoint)centerProjectedPoint animated:(BOOL)animated
{
    [self registerMoveEventByUser:NO];

//    RMLog(@"Current contentSize: {%.0f,%.0f}, zoom: %f", mapScrollView.contentSize.width, mapScrollView.contentSize.height, self.zoom);

    RMProjectedRect planetBounds = _projection.planetBounds;
	RMProjectedPoint normalizedProjectedPoint;
	normalizedProjectedPoint.x = centerProjectedPoint.x + fabs(planetBounds.origin.x);
	normalizedProjectedPoint.y = centerProjectedPoint.y + fabs(planetBounds.origin.y);

    [_mapScrollView setContentOffset:CGPointMake(normalizedProjectedPoint.x / _metersPerPixel - _mapScrollView.bounds.size.width/2.0,
                                                _mapScrollView.contentSize.height - ((normalizedProjectedPoint.y / _metersPerPixel) + _mapScrollView.bounds.size.height/2.0))
                           animated:animated];

//    RMLog(@"setMapCenterProjectedPoint: {%f,%f} -> {%.0f,%.0f}", centerProjectedPoint.x, centerProjectedPoint.y, mapScrollView.contentOffset.x, mapScrollView.contentOffset.y);

    if ( ! animated)
        [_moveDelegateQueue setSuspended:NO];

    [self correctPositionOfAllAnnotations];
}

// ===

- (void)moveBy:(CGSize)delta
{
    [self registerMoveEventByUser:NO];

    CGPoint contentOffset = _mapScrollView.contentOffset;
    contentOffset.x += delta.width;
    contentOffset.y += delta.height;
    _mapScrollView.contentOffset = contentOffset;

    [_moveDelegateQueue setSuspended:NO];
}

#pragma mark -
#pragma mark Zoom

- (void)setBoundingMask:(NSUInteger)mask
{
    _boundingMask = mask;

    [self correctMinZoomScaleForBoundingMask];
}

- (void)correctMinZoomScaleForBoundingMask
{
    if (self.boundingMask != RMMapNoMinBound)
    {
        if ([_tiledLayersSuperview.subviews count] == 0)
            return;

        CGFloat newMinZoomScale = (self.boundingMask == RMMapMinWidthBound ? self.bounds.size.width : self.bounds.size.height) / ((CATiledLayer *)((RMMapTiledLayerView *)[_tiledLayersSuperview.subviews objectAtIndex:0]).layer).tileSize.width;

        if (_mapScrollView.minimumZoomScale > 0 && newMinZoomScale > _mapScrollView.minimumZoomScale)
        {
            RMLog(@"clamping min zoom of %f to %f due to %@", log2f(_mapScrollView.minimumZoomScale), log2f(newMinZoomScale), (self.boundingMask == RMMapMinWidthBound ? @"RMMapMinWidthBound" : @"RMMapMinHeightBound"));

            _mapScrollView.minimumZoomScale = newMinZoomScale;
        }
    }
}

- (RMProjectedRect)projectedBounds
{
    CGPoint bottomLeft = CGPointMake(_mapScrollView.contentOffset.x, _mapScrollView.contentSize.height - (_mapScrollView.contentOffset.y + _mapScrollView.bounds.size.height));

    RMProjectedRect planetBounds = _projection.planetBounds;
    RMProjectedRect normalizedProjectedRect;
    normalizedProjectedRect.origin.x = (bottomLeft.x * _metersPerPixel) - fabs(planetBounds.origin.x);
    normalizedProjectedRect.origin.y = (bottomLeft.y * _metersPerPixel) - fabs(planetBounds.origin.y);
    normalizedProjectedRect.size.width = _mapScrollView.bounds.size.width * _metersPerPixel;
    normalizedProjectedRect.size.height = _mapScrollView.bounds.size.height * _metersPerPixel;

    return normalizedProjectedRect;
}

- (void)setProjectedBounds:(RMProjectedRect)boundsRect
{
    [self setProjectedBounds:boundsRect animated:YES];
}

- (void)setProjectedBounds:(RMProjectedRect)boundsRect animated:(BOOL)animated
{
    if (_constrainMovement)
        boundsRect = [self fitProjectedRect:boundsRect intoRect:_constrainingProjectedBounds];

    RMProjectedRect planetBounds = _projection.planetBounds;
	RMProjectedPoint normalizedProjectedPoint;
	normalizedProjectedPoint.x = boundsRect.origin.x + fabs(planetBounds.origin.x);
	normalizedProjectedPoint.y = boundsRect.origin.y + fabs(planetBounds.origin.y);

    float zoomScale = _mapScrollView.zoomScale;
    CGRect zoomRect = CGRectMake((normalizedProjectedPoint.x / _metersPerPixel) / zoomScale,
                                 ((planetBounds.size.height - normalizedProjectedPoint.y - boundsRect.size.height) / _metersPerPixel) / zoomScale,
                                 (boundsRect.size.width / _metersPerPixel) / zoomScale,
                                 (boundsRect.size.height / _metersPerPixel) / zoomScale);
    [_mapScrollView zoomToRect:zoomRect animated:animated];
}

- (float)adjustedZoomForCurrentBoundingMask:(float)zoomFactor
{
    if (_boundingMask == RMMapNoMinBound)
        return zoomFactor;

    double newMetersPerPixel = _metersPerPixel / zoomFactor;

    RMProjectedRect mercatorBounds = [_projection planetBounds];

    // Check for MinWidthBound
    if (_boundingMask & RMMapMinWidthBound)
    {
        double newMapContentsWidth = mercatorBounds.size.width / newMetersPerPixel;
        double screenBoundsWidth = [self bounds].size.width;
        double mapContentWidth;

        if (newMapContentsWidth < screenBoundsWidth)
        {
            // Calculate new zoom facter so that it does not shrink the map any further.
            mapContentWidth = mercatorBounds.size.width / _metersPerPixel;
            zoomFactor = screenBoundsWidth / mapContentWidth;
        }
    }

    // Check for MinHeightBound
    if (_boundingMask & RMMapMinHeightBound)
    {
        double newMapContentsHeight = mercatorBounds.size.height / newMetersPerPixel;
        double screenBoundsHeight = [self bounds].size.height;
        double mapContentHeight;

        if (newMapContentsHeight < screenBoundsHeight)
        {
            // Calculate new zoom facter so that it does not shrink the map any further.
            mapContentHeight = mercatorBounds.size.height / _metersPerPixel;
            zoomFactor = screenBoundsHeight / mapContentHeight;
        }
    }

    return zoomFactor;
}

- (BOOL)shouldZoomToTargetZoom:(float)targetZoom withZoomFactor:(float)zoomFactor
{
    // bools for syntactical sugar to understand the logic in the if statement below
    BOOL zoomAtMax = ([self zoom] == [self maxZoom]);
    BOOL zoomAtMin = ([self zoom] == [self minZoom]);
    BOOL zoomGreaterMin = ([self zoom] > [self minZoom]);
    BOOL zoomLessMax = ([self zoom] < [self maxZoom]);

    //zooming in zoomFactor > 1
    //zooming out zoomFactor < 1
    if ((zoomGreaterMin && zoomLessMax) || (zoomAtMax && zoomFactor<1) || (zoomAtMin && zoomFactor>1))
        return YES;
    else
        return NO;
}

- (void)zoomByFactor:(float)zoomFactor near:(CGPoint)pivot animated:(BOOL)animated
{
    if (![self tileSourceBoundsContainScreenPoint:pivot])
        return;

    zoomFactor = [self adjustedZoomForCurrentBoundingMask:zoomFactor];
    float zoomDelta = log2f(zoomFactor);
    float targetZoom = zoomDelta + [self zoom];

    if (targetZoom == [self zoom])
        return;

    // clamp zoom to remain below or equal to maxZoom after zoomAfter will be applied
    // Set targetZoom to maxZoom so the map zooms to its maximum
    if (targetZoom > [self maxZoom])
    {
        zoomFactor = exp2f([self maxZoom] - [self zoom]);
        targetZoom = [self maxZoom];
    }

    // clamp zoom to remain above or equal to minZoom after zoomAfter will be applied
    // Set targetZoom to minZoom so the map zooms to its maximum
    if (targetZoom < [self minZoom])
    {
        zoomFactor = 1/exp2f([self zoom] - [self minZoom]);
        targetZoom = [self minZoom];
    }

    if ([self shouldZoomToTargetZoom:targetZoom withZoomFactor:zoomFactor])
    {
        float zoomScale = _mapScrollView.zoomScale;
        CGSize newZoomSize = CGSizeMake(_mapScrollView.bounds.size.width / zoomFactor,
                                        _mapScrollView.bounds.size.height / zoomFactor);
        CGFloat factorX = pivot.x / _mapScrollView.bounds.size.width,
                factorY = pivot.y / _mapScrollView.bounds.size.height;
        CGRect zoomRect = CGRectMake(((_mapScrollView.contentOffset.x + pivot.x) - (newZoomSize.width * factorX)) / zoomScale,
                                     ((_mapScrollView.contentOffset.y + pivot.y) - (newZoomSize.height * factorY)) / zoomScale,
                                     newZoomSize.width / zoomScale,
                                     newZoomSize.height / zoomScale);
        [_mapScrollView zoomToRect:zoomRect animated:animated];
    }
    else
    {
        if ([self zoom] > [self maxZoom])
            [self setZoom:[self maxZoom]];
        if ([self zoom] < [self minZoom])
            [self setZoom:[self minZoom]];
    }
}

- (float)nextNativeZoomFactor
{
    float newZoom = fminf(floorf([self zoom] + 1.0), [self maxZoom]);

    return exp2f(newZoom - [self zoom]);
}

- (float)previousNativeZoomFactor
{
    float newZoom = fmaxf(floorf([self zoom] - 1.0), [self minZoom]);

    return exp2f(newZoom - [self zoom]);
}

- (void)zoomInToNextNativeZoomAt:(CGPoint)pivot
{
    [self zoomInToNextNativeZoomAt:pivot animated:NO];
}

- (void)zoomInToNextNativeZoomAt:(CGPoint)pivot animated:(BOOL)animated
{
    if (self.userTrackingMode != RMUserTrackingModeNone && ! CGPointEqualToPoint(pivot, [self coordinateToPixel:self.userLocation.location.coordinate]))
        self.userTrackingMode = RMUserTrackingModeNone;
    
    // Calculate rounded zoom
    float newZoom = fmin(ceilf([self zoom]) + 1.0, [self maxZoom]);

    float factor = exp2f(newZoom - [self zoom]);

    if (factor > 2.25)
    {
        newZoom = fmin(ceilf([self zoom]), [self maxZoom]);
        factor = exp2f(newZoom - [self zoom]);
    }

//    RMLog(@"zoom in from:%f to:%f by factor:%f around {%f,%f}", [self zoom], newZoom, factor, pivot.x, pivot.y);
    [self zoomByFactor:factor near:pivot animated:animated];
}

- (void)zoomOutToNextNativeZoomAt:(CGPoint)pivot
{
    [self zoomOutToNextNativeZoomAt:pivot animated:NO];
}

- (void)zoomOutToNextNativeZoomAt:(CGPoint)pivot animated:(BOOL) animated
{
    // Calculate rounded zoom
    float newZoom = fmax(floorf([self zoom]), [self minZoom]);

    float factor = exp2f(newZoom - [self zoom]);

    if (factor > 0.75)
    {
        newZoom = fmax(floorf([self zoom]) - 1.0, [self minZoom]);
        factor = exp2f(newZoom - [self zoom]);
    }

//    RMLog(@"zoom out from:%f to:%f by factor:%f around {%f,%f}", [self zoom], newZoom, factor, pivot.x, pivot.y);
    [self zoomByFactor:factor near:pivot animated:animated];
}

#pragma mark -
#pragma mark Zoom With Bounds

- (void)zoomWithLatitudeLongitudeBoundsSouthWest:(CLLocationCoordinate2D)southWest northEast:(CLLocationCoordinate2D)northEast animated:(BOOL)animated
{
    if (northEast.latitude == southWest.latitude && northEast.longitude == southWest.longitude) // There are no bounds, probably only one marker.
    {
        RMProjectedRect zoomRect;
        RMProjectedPoint myOrigin = [_projection coordinateToProjectedPoint:southWest];

        // Default is with scale = 2.0 * mercators/pixel
        zoomRect.size.width = [self bounds].size.width * 2.0;
        zoomRect.size.height = [self bounds].size.height * 2.0;
        myOrigin.x = myOrigin.x - (zoomRect.size.width / 2.0);
        myOrigin.y = myOrigin.y - (zoomRect.size.height / 2.0);
        zoomRect.origin = myOrigin;

        [self setProjectedBounds:zoomRect animated:animated];
    }
    else
    {
        // Convert northEast/southWest into RMMercatorRect and call zoomWithBounds
        CLLocationCoordinate2D midpoint = {
            .latitude = (northEast.latitude + southWest.latitude) / 2,
            .longitude = (northEast.longitude + southWest.longitude) / 2
        };

        RMProjectedPoint myOrigin = [_projection coordinateToProjectedPoint:midpoint];
        RMProjectedPoint southWestPoint = [_projection coordinateToProjectedPoint:southWest];
        RMProjectedPoint northEastPoint = [_projection coordinateToProjectedPoint:northEast];
        RMProjectedPoint myPoint = {
            .x = northEastPoint.x - southWestPoint.x,
            .y = northEastPoint.y - southWestPoint.y
        };

		// Create the new zoom layout
        RMProjectedRect zoomRect;

        // Default is with scale = 2.0 * mercators/pixel
        zoomRect.size.width = self.bounds.size.width * 2.0;
        zoomRect.size.height = self.bounds.size.height * 2.0;

        if ((myPoint.x / self.bounds.size.width) < (myPoint.y / self.bounds.size.height))
        {
            if ((myPoint.y / self.bounds.size.height) > 1)
            {
                zoomRect.size.width = self.bounds.size.width * (myPoint.y / self.bounds.size.height);
                zoomRect.size.height = self.bounds.size.height * (myPoint.y / self.bounds.size.height);
            }
        }
        else
        {
            if ((myPoint.x / self.bounds.size.width) > 1)
            {
                zoomRect.size.width = self.bounds.size.width * (myPoint.x / self.bounds.size.width);
                zoomRect.size.height = self.bounds.size.height * (myPoint.x / self.bounds.size.width);
            }
        }

        myOrigin.x = myOrigin.x - (zoomRect.size.width / 2);
        myOrigin.y = myOrigin.y - (zoomRect.size.height / 2);
        zoomRect.origin = myOrigin;

        [self setProjectedBounds:zoomRect animated:animated];
    }
}

#pragma mark -
#pragma mark Cache

- (void)removeAllCachedImages
{
    [self.tileCache removeAllCachedImages];
}

#pragma mark -
#pragma mark MapView (ScrollView)

- (void)createMapView
{
    [_tileSourcesContainer cancelAllDownloads];

    [_overlayView removeFromSuperview]; [_overlayView release]; _overlayView = nil;

    for (RMMapTiledLayerView *tiledLayerView in _tiledLayersSuperview.subviews)
    {
        tiledLayerView.layer.contents = nil;
        [tiledLayerView removeFromSuperview]; [tiledLayerView release]; tiledLayerView = nil;
    }

    [_tiledLayersSuperview removeFromSuperview]; [_tiledLayersSuperview release]; _tiledLayersSuperview = nil;

    [_mapScrollView removeObserver:self forKeyPath:@"contentOffset"];
    [_mapScrollView removeFromSuperview]; [_mapScrollView release]; _mapScrollView = nil;

    _mapScrollViewIsZooming = NO;

    int tileSideLength = [_tileSourcesContainer tileSideLength];
    CGSize contentSize = CGSizeMake(tileSideLength, tileSideLength); // zoom level 1

    _mapScrollView = [[RMMapScrollView alloc] initWithFrame:[self bounds]];
    _mapScrollView.delegate = self;
    _mapScrollView.opaque = NO;
    _mapScrollView.backgroundColor = [UIColor clearColor];
    _mapScrollView.showsVerticalScrollIndicator = NO;
    _mapScrollView.showsHorizontalScrollIndicator = NO;
    _mapScrollView.scrollsToTop = NO;
    _mapScrollView.scrollEnabled = _enableDragging;
    _mapScrollView.bounces = _enableBouncing;
    _mapScrollView.bouncesZoom = _enableBouncing;
    _mapScrollView.contentSize = contentSize;
    _mapScrollView.minimumZoomScale = exp2f([self minZoom]);
    _mapScrollView.maximumZoomScale = exp2f([self maxZoom]);
    _mapScrollView.contentOffset = CGPointMake(0.0, 0.0);
    _mapScrollView.clipsToBounds = NO;

    _tiledLayersSuperview = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, contentSize.width, contentSize.height)];
    _tiledLayersSuperview.userInteractionEnabled = NO;

    for (id <RMTileSource> tileSource in _tileSourcesContainer.tileSources)
    {
        RMMapTiledLayerView *tiledLayerView = [[RMMapTiledLayerView alloc] initWithFrame:CGRectMake(0.0, 0.0, contentSize.width, contentSize.height) mapView:self forTileSource:tileSource];

        ((CATiledLayer *)tiledLayerView.layer).tileSize = CGSizeMake(tileSideLength, tileSideLength);

        [_tiledLayersSuperview addSubview:tiledLayerView];
    }

    [_mapScrollView addSubview:_tiledLayersSuperview];

    _lastZoom = [self zoom];
    _lastContentOffset = _mapScrollView.contentOffset;
    _accumulatedDelta = CGPointMake(0.0, 0.0);
    _lastContentSize = _mapScrollView.contentSize;

    [_mapScrollView addObserver:self forKeyPath:@"contentOffset" options:(NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld) context:NULL];
    _mapScrollView.mapScrollViewDelegate = self;

    _mapScrollView.zoomScale = exp2f([self zoom]);
    [self setDecelerationMode:_decelerationMode];

    if (_backgroundView)
        [self insertSubview:_mapScrollView aboveSubview:_backgroundView];
    else
        [self insertSubview:_mapScrollView atIndex:0];

    _overlayView = [[RMMapOverlayView alloc] initWithFrame:[self bounds]];
    _overlayView.userInteractionEnabled = NO;

    [self insertSubview:_overlayView aboveSubview:_mapScrollView];

    // add gesture recognizers

    // one finger taps
    UITapGestureRecognizer *doubleTapRecognizer = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)] autorelease];
    doubleTapRecognizer.numberOfTouchesRequired = 1;
    doubleTapRecognizer.numberOfTapsRequired = 2;
    doubleTapRecognizer.delegate = self;

    UITapGestureRecognizer *singleTapRecognizer = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)] autorelease];
    singleTapRecognizer.numberOfTouchesRequired = 1;
    [singleTapRecognizer requireGestureRecognizerToFail:doubleTapRecognizer];
    singleTapRecognizer.delegate = self;

    UILongPressGestureRecognizer *longPressRecognizer = [[[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)] autorelease];
    longPressRecognizer.delegate = self;

    [self addGestureRecognizer:singleTapRecognizer];
    [self addGestureRecognizer:doubleTapRecognizer];
    [self addGestureRecognizer:longPressRecognizer];

    // two finger taps
    UITapGestureRecognizer *twoFingerSingleTapRecognizer = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTwoFingerSingleTap:)] autorelease];
    twoFingerSingleTapRecognizer.numberOfTouchesRequired = 2;
    twoFingerSingleTapRecognizer.delegate = self;

    [self addGestureRecognizer:twoFingerSingleTapRecognizer];

    // pan
    UIPanGestureRecognizer *panGestureRecognizer = [[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGesture:)] autorelease];
    panGestureRecognizer.minimumNumberOfTouches = 1;
    panGestureRecognizer.maximumNumberOfTouches = 1;

    // the delegate is used to decide whether a pan should be handled by this
    // recognizer or by the pan gesture recognizer of the scrollview
    panGestureRecognizer.delegate = self;

    // the pan recognizer is added to the scrollview as it competes with the
    // pan recognizer of the scrollview
    [_mapScrollView addGestureRecognizer:panGestureRecognizer];

    [_visibleAnnotations removeAllObjects];
    [self correctPositionOfAllAnnotations];
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return _tiledLayersSuperview;
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [self registerMoveEventByUser:YES];

    if (self.userTrackingMode != RMUserTrackingModeNone)
        self.userTrackingMode = RMUserTrackingModeNone;
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if ( ! decelerate)
        [_moveDelegateQueue setSuspended:NO];
}

- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView
{
    if (_decelerationMode == RMMapDecelerationOff)
        [scrollView setContentOffset:scrollView.contentOffset animated:NO];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [_moveDelegateQueue setSuspended:NO];
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
    [_moveDelegateQueue setSuspended:NO];
}

- (void)scrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(UIView *)view
{
    [self registerZoomEventByUser:(scrollView.pinchGestureRecognizer.state == UIGestureRecognizerStateBegan)];

    _mapScrollViewIsZooming = YES;

    if (_loadingTileView)
        _loadingTileView.mapZooming = YES;
}

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(float)scale
{
    [_moveDelegateQueue setSuspended:NO];
    [_zoomDelegateQueue setSuspended:NO];

    _mapScrollViewIsZooming = NO;

    [self correctPositionOfAllAnnotations];

    if (_loadingTileView)
        _loadingTileView.mapZooming = NO;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (_loadingTileView)
    {
        CGSize delta = CGSizeMake(scrollView.contentOffset.x - _lastContentOffset.x, scrollView.contentOffset.y - _lastContentOffset.y);
        CGPoint newOffset = CGPointMake(_loadingTileView.contentOffset.x + delta.width, _loadingTileView.contentOffset.y + delta.height);
        _loadingTileView.contentOffset = newOffset;
    }
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView
{
    BOOL wasUserAction = (scrollView.pinchGestureRecognizer.state == UIGestureRecognizerStateChanged);

    [self registerZoomEventByUser:wasUserAction];

    if (self.userTrackingMode != RMUserTrackingModeNone && wasUserAction)
        self.userTrackingMode = RMUserTrackingModeNone;
    
    [self correctPositionOfAllAnnotations];

    if (_zoom < 3 && self.userTrackingMode == RMUserTrackingModeFollowWithHeading)
        self.userTrackingMode = RMUserTrackingModeFollow;
}

// Detect dragging/zooming

- (void)scrollView:(RMMapScrollView *)aScrollView correctedContentOffset:(inout CGPoint *)aContentOffset
{
    if ( ! _constrainMovement)
        return;

    if (CGPointEqualToPoint(_lastContentOffset, *aContentOffset))
        return;

    // The first offset during zooming out (animated) is always garbage
    if (_mapScrollViewIsZooming == YES &&
        _mapScrollView.zooming == NO &&
        _lastContentSize.width > _mapScrollView.contentSize.width &&
        ((*aContentOffset).y - _lastContentOffset.y) == 0.0)
    {
        return;
    }

    RMProjectedRect planetBounds = _projection.planetBounds;
    double currentMetersPerPixel = planetBounds.size.width / aScrollView.contentSize.width;

    CGPoint bottomLeft = CGPointMake((*aContentOffset).x,
                                     aScrollView.contentSize.height - ((*aContentOffset).y + aScrollView.bounds.size.height));

    RMProjectedRect normalizedProjectedRect;
    normalizedProjectedRect.origin.x = (bottomLeft.x * currentMetersPerPixel) - fabs(planetBounds.origin.x);
    normalizedProjectedRect.origin.y = (bottomLeft.y * currentMetersPerPixel) - fabs(planetBounds.origin.y);
    normalizedProjectedRect.size.width = aScrollView.bounds.size.width * currentMetersPerPixel;
    normalizedProjectedRect.size.height = aScrollView.bounds.size.height * currentMetersPerPixel;

    if (RMProjectedRectContainsProjectedRect(_constrainingProjectedBounds, normalizedProjectedRect))
        return;

    RMProjectedRect fittedProjectedRect = [self fitProjectedRect:normalizedProjectedRect intoRect:_constrainingProjectedBounds];

    RMProjectedPoint normalizedProjectedPoint;
	normalizedProjectedPoint.x = fittedProjectedRect.origin.x + fabs(planetBounds.origin.x);
	normalizedProjectedPoint.y = fittedProjectedRect.origin.y + fabs(planetBounds.origin.y);

    CGPoint correctedContentOffset = CGPointMake(normalizedProjectedPoint.x / currentMetersPerPixel,
                                                 aScrollView.contentSize.height - ((normalizedProjectedPoint.y / currentMetersPerPixel) + aScrollView.bounds.size.height));
    *aContentOffset = correctedContentOffset;
}

- (void)scrollView:(RMMapScrollView *)aScrollView correctedContentSize:(inout CGSize *)aContentSize
{
    if ( ! _constrainMovement)
        return;

    RMProjectedRect planetBounds = _projection.planetBounds;
    double currentMetersPerPixel = planetBounds.size.width / (*aContentSize).width;

    RMProjectedSize projectedSize;
    projectedSize.width = aScrollView.bounds.size.width * currentMetersPerPixel;
    projectedSize.height = aScrollView.bounds.size.height * currentMetersPerPixel;

    if (RMProjectedSizeContainsProjectedSize(_constrainingProjectedBounds.size, projectedSize))
        return;

    CGFloat factor = 1.0;
    if (projectedSize.width > _constrainingProjectedBounds.size.width)
        factor = (projectedSize.width / _constrainingProjectedBounds.size.width);
    else
        factor = (projectedSize.height / _constrainingProjectedBounds.size.height);

    *aContentSize = CGSizeMake((*aContentSize).width * factor, (*aContentSize).height * factor);
}

- (void)observeValueForKeyPath:(NSString *)aKeyPath ofObject:(id)anObject change:(NSDictionary *)change context:(void *)context
{
    NSValue *oldValue = [change objectForKey:NSKeyValueChangeOldKey],
            *newValue = [change objectForKey:NSKeyValueChangeNewKey];

    CGPoint oldContentOffset = [oldValue CGPointValue],
            newContentOffset = [newValue CGPointValue];

    if (CGPointEqualToPoint(oldContentOffset, newContentOffset))
        return;

    // The first offset during zooming out (animated) is always garbage
    if (_mapScrollViewIsZooming == YES &&
        _mapScrollView.zooming == NO &&
        _lastContentSize.width > _mapScrollView.contentSize.width &&
        (newContentOffset.y - oldContentOffset.y) == 0.0)
    {
        _lastContentOffset = _mapScrollView.contentOffset;
        _lastContentSize = _mapScrollView.contentSize;

        return;
    }

//    RMLog(@"contentOffset: {%.0f,%.0f} -> {%.1f,%.1f} (%.0f,%.0f)", oldContentOffset.x, oldContentOffset.y, newContentOffset.x, newContentOffset.y, newContentOffset.x - oldContentOffset.x, newContentOffset.y - oldContentOffset.y);
//    RMLog(@"contentSize: {%.0f,%.0f} -> {%.0f,%.0f}", _lastContentSize.width, _lastContentSize.height, mapScrollView.contentSize.width, mapScrollView.contentSize.height);
//    RMLog(@"isZooming: %d, scrollview.zooming: %d", _mapScrollViewIsZooming, mapScrollView.zooming);

    RMProjectedRect planetBounds = _projection.planetBounds;
    _metersPerPixel = planetBounds.size.width / _mapScrollView.contentSize.width;

    _zoom = log2f(_mapScrollView.zoomScale);
    _zoom = (_zoom > _maxZoom) ? _maxZoom : _zoom;
    _zoom = (_zoom < _minZoom) ? _minZoom : _zoom;

    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(correctPositionOfAllAnnotations) object:nil];

    if (_zoom == _lastZoom)
    {
        CGPoint contentOffset = _mapScrollView.contentOffset;
        CGPoint delta = CGPointMake(_lastContentOffset.x - contentOffset.x, _lastContentOffset.y - contentOffset.y);
        _accumulatedDelta.x += delta.x;
        _accumulatedDelta.y += delta.y;

        if (fabsf(_accumulatedDelta.x) < kZoomRectPixelBuffer && fabsf(_accumulatedDelta.y) < kZoomRectPixelBuffer)
        {
            [_overlayView moveLayersBy:_accumulatedDelta];
            [self performSelector:@selector(correctPositionOfAllAnnotations) withObject:nil afterDelay:0.1];
        }
        else
        {
            if (_mapScrollViewIsZooming)
                [self correctPositionOfAllAnnotationsIncludingInvisibles:NO animated:YES];
            else
                [self correctPositionOfAllAnnotations];
        }
    }
    else
    {
        [self correctPositionOfAllAnnotationsIncludingInvisibles:NO animated:(_mapScrollViewIsZooming && !_mapScrollView.zooming)];
        _lastZoom = _zoom;
    }

    _lastContentOffset = _mapScrollView.contentOffset;
    _lastContentSize = _mapScrollView.contentSize;

    if (_delegateHasMapViewRegionDidChange)
        [_delegate mapViewRegionDidChange:self];
}

#pragma mark - Gesture Recognizers and event handling

- (RMAnnotation *)findAnnotationInLayer:(CALayer *)layer
{
    if ([layer respondsToSelector:@selector(annotation)])
        return [((RMMarker *)layer) annotation];

    CALayer *superlayer = [layer superlayer];

    if (superlayer != nil && [superlayer respondsToSelector:@selector(annotation)])
        return [((RMMarker *)superlayer) annotation];
    else if ([superlayer superlayer] != nil && [[superlayer superlayer] respondsToSelector:@selector(annotation)])
        return [((RMMarker *)[superlayer superlayer]) annotation];

    return nil;
}

- (void)singleTapAtPoint:(CGPoint)aPoint
{
    if (_delegateHasSingleTapOnMap)
        [_delegate singleTapOnMap:self at:aPoint];
}

- (void)handleSingleTap:(UIGestureRecognizer *)recognizer
{
    CALayer *hit = [_overlayView overlayHitTest:[recognizer locationInView:self]];

    if ( ! hit)
    {
        [self singleTapAtPoint:[recognizer locationInView:self]];
        return;
    }

    CALayer *superlayer = [hit superlayer];

    // See if tap was on an annotation layer or marker label and send delegate protocol method
    if ([hit isKindOfClass:[RMMapLayer class]])
    {
        [self tapOnAnnotation:[((RMMapLayer *)hit) annotation] atPoint:[recognizer locationInView:self]];
    }
    else if (superlayer != nil && [superlayer isKindOfClass:[RMMarker class]])
    {
        [self tapOnLabelForAnnotation:[((RMMarker *)superlayer) annotation] atPoint:[recognizer locationInView:self]];
    }
    else if ([superlayer superlayer] != nil && [[superlayer superlayer] isKindOfClass:[RMMarker class]])
    {
        [self tapOnLabelForAnnotation:[((RMMarker *)[superlayer superlayer]) annotation] atPoint:[recognizer locationInView:self]];
    }
    else
    {
        [self singleTapAtPoint:[recognizer locationInView:self]];
    }
}

- (void)doubleTapAtPoint:(CGPoint)aPoint
{
    [self registerZoomEventByUser:YES];

    if (self.zoomingInPivotsAroundCenter)
    {
        [self zoomInToNextNativeZoomAt:[self convertPoint:self.center fromView:self.superview] animated:YES];
    }
    else if (self.userTrackingMode != RMUserTrackingModeNone && fabsf(aPoint.x - [self coordinateToPixel:self.userLocation.location.coordinate].x) < 75 && fabsf(aPoint.y - [self coordinateToPixel:self.userLocation.location.coordinate].y) < 75)
    {
        [self zoomInToNextNativeZoomAt:[self coordinateToPixel:self.userLocation.location.coordinate] animated:YES];
    }
    else
    {
        [self registerMoveEventByUser:YES];

        [self zoomInToNextNativeZoomAt:aPoint animated:YES];
    }

    if (_delegateHasDoubleTapOnMap)
        [_delegate doubleTapOnMap:self at:aPoint];
}

- (void)handleDoubleTap:(UIGestureRecognizer *)recognizer
{
    CALayer *hit = [_overlayView overlayHitTest:[recognizer locationInView:self]];

    if ( ! hit)
    {
        [self doubleTapAtPoint:[recognizer locationInView:self]];
        return;
    }

    CALayer *superlayer = [hit superlayer];

    // See if tap was on a marker or marker label and send delegate protocol method
    if ([hit isKindOfClass:[RMMarker class]])
    {
        [self doubleTapOnAnnotation:[((RMMarker *)hit) annotation] atPoint:[recognizer locationInView:self]];
    }
    else if (superlayer != nil && [superlayer isKindOfClass:[RMMarker class]])
    {
        [self doubleTapOnLabelForAnnotation:[((RMMarker *)superlayer) annotation] atPoint:[recognizer locationInView:self]];
    }
    else if ([superlayer superlayer] != nil && [[superlayer superlayer] isKindOfClass:[RMMarker class]])
    {
        [self doubleTapOnLabelForAnnotation:[((RMMarker *)[superlayer superlayer]) annotation] atPoint:[recognizer locationInView:self]];
    }
    else
    {
        [self doubleTapAtPoint:[recognizer locationInView:self]];
    }
}

- (void)handleTwoFingerSingleTap:(UIGestureRecognizer *)recognizer
{
    [self registerZoomEventByUser:YES];

    CGPoint centerPoint = [self convertPoint:self.center fromView:self.superview];

    if (self.userTrackingMode != RMUserTrackingModeNone)
        centerPoint = [self coordinateToPixel:self.userLocation.location.coordinate];

    [self zoomOutToNextNativeZoomAt:centerPoint animated:YES];

    if (_delegateHasSingleTapTwoFingersOnMap)
        [_delegate singleTapTwoFingersOnMap:self at:[recognizer locationInView:self]];
}

- (void)handleLongPress:(UILongPressGestureRecognizer *)recognizer
{
    if (recognizer.state != UIGestureRecognizerStateBegan)
        return;

    if (_delegateHasLongSingleTapOnMap)
        [_delegate longSingleTapOnMap:self at:[recognizer locationInView:self]];
}

// defines when the additional pan gesture recognizer on the scroll should handle the gesture
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)recognizer
{
    if ([recognizer isKindOfClass:[UIPanGestureRecognizer class]])
    {
        // check whether our custom pan gesture recognizer should start recognizing the gesture
        CALayer *hit = [_overlayView overlayHitTest:[recognizer locationInView:_overlayView]];

        if ([hit isEqual:_overlayView.layer])
            return NO;
        
        if (!hit || ([hit respondsToSelector:@selector(enableDragging)] && ![(RMMarker *)hit enableDragging]))
            return NO;

        if ( ! [self shouldDragAnnotation:[self findAnnotationInLayer:hit]])
            return NO;
    }

    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    if ([touch.view isKindOfClass:[UIControl class]])
        return NO;

    return YES;
}

- (void)handlePanGesture:(UIPanGestureRecognizer *)recognizer
{
    if (recognizer.state == UIGestureRecognizerStateBegan)
    {
        CALayer *hit = [_overlayView.layer hitTest:[recognizer locationInView:self]];

        if ( ! hit)
            return;

        if ([hit respondsToSelector:@selector(enableDragging)] && ![(RMMarker *)hit enableDragging])
            return;

        _lastDraggingTranslation = CGPointZero;
        [_draggedAnnotation release];
        _draggedAnnotation = [[self findAnnotationInLayer:hit] retain];
    }

    if (recognizer.state == UIGestureRecognizerStateChanged)
    {
        CGPoint translation = [recognizer translationInView:_overlayView];
        CGPoint delta = CGPointMake(_lastDraggingTranslation.x - translation.x, _lastDraggingTranslation.y - translation.y);
        _lastDraggingTranslation = translation;

        [CATransaction begin];
        [CATransaction setAnimationDuration:0];
        [self didDragAnnotation:_draggedAnnotation withDelta:delta];
        [CATransaction commit];
    }
    else if (recognizer.state == UIGestureRecognizerStateEnded)
    {
        [self didEndDragAnnotation:_draggedAnnotation];
        [_draggedAnnotation release]; _draggedAnnotation = nil;
    }
}

// Overlay

- (void)tapOnAnnotation:(RMAnnotation *)anAnnotation atPoint:(CGPoint)aPoint
{
    if (_delegateHasTapOnAnnotation && anAnnotation)
    {
        [_delegate tapOnAnnotation:anAnnotation onMap:self];
    }
    else
    {
        if (_delegateHasSingleTapOnMap)
            [_delegate singleTapOnMap:self at:aPoint];
    }
}

- (void)doubleTapOnAnnotation:(RMAnnotation *)anAnnotation atPoint:(CGPoint)aPoint
{
    if (_delegateHasDoubleTapOnAnnotation && anAnnotation)
    {
        [_delegate doubleTapOnAnnotation:anAnnotation onMap:self];
    }
    else
    {
        [self doubleTapAtPoint:aPoint];
    }
}

- (void)tapOnLabelForAnnotation:(RMAnnotation *)anAnnotation atPoint:(CGPoint)aPoint
{
    if (_delegateHasTapOnLabelForAnnotation && anAnnotation)
    {
        [_delegate tapOnLabelForAnnotation:anAnnotation onMap:self];
    }
    else if (_delegateHasTapOnAnnotation && anAnnotation)
    {
        [_delegate tapOnAnnotation:anAnnotation onMap:self];
    }
    else
    {
        if (_delegateHasSingleTapOnMap)
            [_delegate singleTapOnMap:self at:aPoint];
    }
}

- (void)doubleTapOnLabelForAnnotation:(RMAnnotation *)anAnnotation atPoint:(CGPoint)aPoint
{
    if (_delegateHasDoubleTapOnLabelForAnnotation && anAnnotation)
    {
        [_delegate doubleTapOnLabelForAnnotation:anAnnotation onMap:self];
    }
    else if (_delegateHasDoubleTapOnAnnotation && anAnnotation)
    {
        [_delegate doubleTapOnAnnotation:anAnnotation onMap:self];
    }
    else
    {
        [self doubleTapAtPoint:aPoint];
    }
}

- (BOOL)shouldDragAnnotation:(RMAnnotation *)anAnnotation
{
    if (_delegateHasShouldDragMarker)
        return [_delegate mapView:self shouldDragAnnotation:anAnnotation];
    else
        return NO;
}

- (void)didDragAnnotation:(RMAnnotation *)anAnnotation withDelta:(CGPoint)delta
{
    if (_delegateHasDidDragMarker)
        [_delegate mapView:self didDragAnnotation:anAnnotation withDelta:delta];
}

- (void)didEndDragAnnotation:(RMAnnotation *)anAnnotation
{
    if (_delegateHasDidEndDragMarker)
        [_delegate mapView:self didEndDragAnnotation:anAnnotation];
}

#pragma mark -
#pragma mark Snapshots

- (UIImage *)takeSnapshotAndIncludeOverlay:(BOOL)includeOverlay
{
    _overlayView.hidden = !includeOverlay;

    UIGraphicsBeginImageContextWithOptions(self.bounds.size, self.opaque, [[UIScreen mainScreen] scale]);

    for (RMMapTiledLayerView *tiledLayerView in _tiledLayersSuperview.subviews)
        tiledLayerView.useSnapshotRenderer = YES;

    [self.layer renderInContext:UIGraphicsGetCurrentContext()];

    for (RMMapTiledLayerView *tiledLayerView in _tiledLayersSuperview.subviews)
        tiledLayerView.useSnapshotRenderer = NO;

    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();

    UIGraphicsEndImageContext();

    _overlayView.hidden = NO;

    return image;
}

- (UIImage *)takeSnapshot
{
    return [self takeSnapshotAndIncludeOverlay:YES];
}

#pragma mark - TileSources

- (RMTileSourcesContainer *)tileSourcesContainer
{
    return [[_tileSourcesContainer retain] autorelease];
}

- (id <RMTileSource>)tileSource
{
    NSArray *tileSources = [_tileSourcesContainer tileSources];

    if ([tileSources count] > 0)
        return [tileSources objectAtIndex:0];

    return nil;
}

- (NSArray *)tileSources
{
    return [_tileSourcesContainer tileSources];
}

- (void)setTileSource:(id <RMTileSource>)tileSource
{
    [_tileSourcesContainer removeAllTileSources];
    [self addTileSource:tileSource];
}

- (void)setTileSources:(NSArray *)tileSources
{
    if ( ! [_tileSourcesContainer setTileSources:tileSources])
        return;

    RMProjectedPoint centerPoint = [self centerProjectedPoint];

    [_projection release];
    _projection = [[_tileSourcesContainer projection] retain];

    [_mercatorToTileProjection release];
    _mercatorToTileProjection = [[_tileSourcesContainer mercatorToTileProjection] retain];

    RMSphericalTrapezium bounds = [_tileSourcesContainer latitudeLongitudeBoundingBox];

    _constrainMovement = !(bounds.northEast.latitude == 90.0 && bounds.northEast.longitude == 180.0 && bounds.southWest.latitude == -90.0 && bounds.southWest.longitude == -180.0);

    if (_constrainMovement)
        _constrainingProjectedBounds = (RMProjectedRect)[self projectedRectFromLatitudeLongitudeBounds:bounds];
    else
        _constrainingProjectedBounds = _projection.planetBounds;

    [self setTileSourcesMinZoom:_tileSourcesContainer.minZoom];
    [self setTileSourcesMaxZoom:_tileSourcesContainer.maxZoom];
    [self setZoom:[self zoom]]; // setZoom clamps zoom level to min/max limits

    // Recreate the map layer
    [self createMapView];

    [self setCenterProjectedPoint:centerPoint animated:NO];
}

- (void)addTileSource:(id <RMTileSource>)tileSource
{
    [self addTileSource:tileSource atIndex:-1];
}

- (void)addTileSource:(id<RMTileSource>)newTileSource atIndex:(NSUInteger)index
{
    if ([_tileSourcesContainer.tileSources containsObject:newTileSource])
        return;

    if ( ! [_tileSourcesContainer addTileSource:newTileSource atIndex:index])
        return;

    RMProjectedPoint centerPoint = [self centerProjectedPoint];

    [_projection release];
    _projection = [[_tileSourcesContainer projection] retain];

    [_mercatorToTileProjection release];
    _mercatorToTileProjection = [[_tileSourcesContainer mercatorToTileProjection] retain];

    RMSphericalTrapezium bounds = [_tileSourcesContainer latitudeLongitudeBoundingBox];

    _constrainMovement = !(bounds.northEast.latitude == 90.0 && bounds.northEast.longitude == 180.0 && bounds.southWest.latitude == -90.0 && bounds.southWest.longitude == -180.0);

    if (_constrainMovement)
        _constrainingProjectedBounds = (RMProjectedRect)[self projectedRectFromLatitudeLongitudeBounds:bounds];
    else
        _constrainingProjectedBounds = _projection.planetBounds;

    [self setTileSourcesMinZoom:_tileSourcesContainer.minZoom];
    [self setTileSourcesMaxZoom:_tileSourcesContainer.maxZoom];
    [self setZoom:[self zoom]]; // setZoom clamps zoom level to min/max limits

    // Recreate the map layer
    NSUInteger tileSourcesContainerSize = [[_tileSourcesContainer tileSources] count];

    if (tileSourcesContainerSize == 1)
    {
        [self createMapView];
    }
    else
    {
        int tileSideLength = [_tileSourcesContainer tileSideLength];
        CGSize contentSize = CGSizeMake(tileSideLength, tileSideLength); // zoom level 1

        RMMapTiledLayerView *tiledLayerView = [[RMMapTiledLayerView alloc] initWithFrame:CGRectMake(0.0, 0.0, contentSize.width, contentSize.height) mapView:self forTileSource:newTileSource];

        ((CATiledLayer *)tiledLayerView.layer).tileSize = CGSizeMake(tileSideLength, tileSideLength);

        if (index >= [[_tileSourcesContainer tileSources] count])
            [_tiledLayersSuperview addSubview:tiledLayerView];
        else
            [_tiledLayersSuperview insertSubview:tiledLayerView atIndex:index];
    }

    [self setCenterProjectedPoint:centerPoint animated:NO];
}

- (void)removeTileSource:(id <RMTileSource>)tileSource
{
    RMProjectedPoint centerPoint = [self centerProjectedPoint];

    [_tileSourcesContainer removeTileSource:tileSource];

    if ([_tileSourcesContainer.tileSources count] == 0)
    {
        [_projection release];
        [_mercatorToTileProjection release];
        _constrainMovement = NO;
    }

    // Remove the map layer
    RMMapTiledLayerView *tileSourceTiledLayerView = nil;

    for (RMMapTiledLayerView *tiledLayerView in _tiledLayersSuperview.subviews)
    {
        if (tiledLayerView.tileSource == tileSource)
        {
            tileSourceTiledLayerView = tiledLayerView;
            break;
        }
    }

    tileSourceTiledLayerView.layer.contents = nil;
    [tileSourceTiledLayerView removeFromSuperview]; [tileSourceTiledLayerView release]; tileSourceTiledLayerView = nil;

    [self setCenterProjectedPoint:centerPoint animated:NO];
}

- (void)removeTileSourceAtIndex:(NSUInteger)index
{
    RMProjectedPoint centerPoint = [self centerProjectedPoint];

    [_tileSourcesContainer removeTileSourceAtIndex:index];

    if ([_tileSourcesContainer.tileSources count] == 0)
    {
        [_projection release];
        [_mercatorToTileProjection release];
        _constrainMovement = NO;
    }

    // Remove the map layer
    RMMapTiledLayerView *tileSourceTiledLayerView = [_tiledLayersSuperview.subviews objectAtIndex:index];

    tileSourceTiledLayerView.layer.contents = nil;
    [tileSourceTiledLayerView removeFromSuperview]; [tileSourceTiledLayerView release]; tileSourceTiledLayerView = nil;

    [self setCenterProjectedPoint:centerPoint animated:NO];
}

- (void)moveTileSourceAtIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex
{
    if (fromIndex == toIndex)
        return;

    if (fromIndex >= [[_tileSourcesContainer tileSources] count])
        return;

    RMProjectedPoint centerPoint = [self centerProjectedPoint];

    [_tileSourcesContainer moveTileSourceAtIndex:fromIndex toIndex:toIndex];

    // Move the map layer
    [_tiledLayersSuperview exchangeSubviewAtIndex:fromIndex withSubviewAtIndex:toIndex];

    [self setCenterProjectedPoint:centerPoint animated:NO];
}

- (void)setHidden:(BOOL)isHidden forTileSource:(id <RMTileSource>)tileSource
{
    NSArray *tileSources = [self tileSources];

    [tileSources enumerateObjectsUsingBlock:^(id <RMTileSource> currentTileSource, NSUInteger index, BOOL *stop)
     {
        if (tileSource == currentTileSource)
        {
            [self setHidden:isHidden forTileSourceAtIndex:index];
            *stop = YES;
        }
     }];
}

- (void)setHidden:(BOOL)isHidden forTileSourceAtIndex:(NSUInteger)index
{
    if (index >= [_tiledLayersSuperview.subviews count])
        return;

    ((RMMapTiledLayerView *)[_tiledLayersSuperview.subviews objectAtIndex:index]).hidden = isHidden;
}

- (void)reloadTileSource:(id <RMTileSource>)tileSource
{
    // Reload the map layer
    for (RMMapTiledLayerView *tiledLayerView in _tiledLayersSuperview.subviews)
    {
        if (tiledLayerView.tileSource == tileSource)
        {
//            tiledLayerView.layer.contents = nil;
            [tiledLayerView setNeedsDisplay];
            break;
        }
    }
}

- (void)reloadTileSourceAtIndex:(NSUInteger)index
{
    if (index >= [_tiledLayersSuperview.subviews count])
        return;

    // Reload the map layer
    RMMapTiledLayerView *tiledLayerView = [_tiledLayersSuperview.subviews objectAtIndex:index];
//    tiledLayerView.layer.contents = nil;
    [tiledLayerView setNeedsDisplay];
}

#pragma mark - Properties

- (UIView *)backgroundView
{
    return [[_backgroundView retain] autorelease];
}

- (void)setBackgroundView:(UIView *)aView
{
    if (_backgroundView == aView)
        return;

    if (_backgroundView != nil)
    {
        [_backgroundView removeFromSuperview];
        [_backgroundView release];
    }

    _backgroundView = [aView retain];
    if (_backgroundView == nil)
        return;

    _backgroundView.frame = [self bounds];

    [self insertSubview:_backgroundView atIndex:0];
}

- (double)metersPerPixel
{
    return _metersPerPixel;
}

- (void)setMetersPerPixel:(double)newMetersPerPixel
{
    [self setMetersPerPixel:newMetersPerPixel animated:YES];
}

- (void)setMetersPerPixel:(double)newMetersPerPixel animated:(BOOL)animated
{
    double factor = self.metersPerPixel / newMetersPerPixel;

    [self zoomByFactor:factor near:CGPointMake(self.bounds.size.width/2.0, self.bounds.size.height/2.0) animated:animated];
}

- (double)scaledMetersPerPixel
{
    return _metersPerPixel / _screenScale;
}

// From http://stackoverflow.com/questions/610193/calculating-pixel-size-on-an-iphone
#define kiPhone3MillimeteresPerPixel 0.1558282
#define kiPhone4MillimetersPerPixel (0.0779 * 2.0)

#define iPad1MillimetersPerPixel 0.1924
#define iPad3MillimetersPerPixel (0.09621 * 2.0)

- (double)scaleDenominator
{
    double iphoneMillimetersPerPixel;

    BOOL deviceIsIPhone = ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone);
    BOOL deviceHasRetinaDisplay = (_screenScale > 1.0);

    if (deviceHasRetinaDisplay)
        iphoneMillimetersPerPixel = (deviceIsIPhone ? kiPhone4MillimetersPerPixel : iPad3MillimetersPerPixel);
    else
        iphoneMillimetersPerPixel = (deviceIsIPhone ? kiPhone3MillimeteresPerPixel : iPad1MillimetersPerPixel);

    return ((_metersPerPixel * 1000.0) / iphoneMillimetersPerPixel);
}

- (void)setMinZoom:(float)newMinZoom
{
    if (newMinZoom < 0.0)
        newMinZoom = 0.0;

    _minZoom = newMinZoom;

//    RMLog(@"New minZoom:%f", newMinZoom);

    _mapScrollView.minimumZoomScale = exp2f(newMinZoom);

    [self correctMinZoomScaleForBoundingMask];
}

- (float)tileSourcesMinZoom
{
    return self.tileSourcesContainer.minZoom;
}

- (void)setTileSourcesMinZoom:(float)tileSourcesMinZoom
{
    tileSourcesMinZoom = ceilf(tileSourcesMinZoom) - 0.99;

    if ( ! self.adjustTilesForRetinaDisplay && _screenScale > 1.0)
        tileSourcesMinZoom -= 1.0;

    [self setMinZoom:tileSourcesMinZoom];
}

- (void)setMaxZoom:(float)newMaxZoom
{
    if (newMaxZoom < 0.0)
        newMaxZoom = 0.0;

    _maxZoom = newMaxZoom;

//    RMLog(@"New maxZoom:%f", newMaxZoom);

    _mapScrollView.maximumZoomScale = exp2f(newMaxZoom);
}

- (float)tileSourcesMaxZoom
{
    return self.tileSourcesContainer.maxZoom;
}

- (void)setTileSourcesMaxZoom:(float)tileSourcesMaxZoom
{
    tileSourcesMaxZoom = floorf(tileSourcesMaxZoom);

    if ( ! self.adjustTilesForRetinaDisplay && _screenScale > 1.0)
        tileSourcesMaxZoom -= 1.0;

    [self setMaxZoom:tileSourcesMaxZoom];
}

- (float)zoom
{
    return _zoom;
}

// if #zoom is outside of range #minZoom to #maxZoom, zoom level is clamped to that range.
- (void)setZoom:(float)newZoom
{
    _zoom = (newZoom > _maxZoom) ? _maxZoom : newZoom;
    _zoom = (_zoom < _minZoom) ? _minZoom : _zoom;

//    RMLog(@"New zoom:%f", _zoom);

    _mapScrollView.zoomScale = exp2f(_zoom);
}

- (float)tileSourcesZoom
{
    float zoom = ceilf(_zoom);

    if ( ! self.adjustTilesForRetinaDisplay && _screenScale > 1.0)
        zoom += 1.0;

    return zoom;
}

- (void)setTileSourcesZoom:(float)tileSourcesZoom
{
    tileSourcesZoom = floorf(tileSourcesZoom);

    if ( ! self.adjustTilesForRetinaDisplay && _screenScale > 1.0)
        tileSourcesZoom -= 1.0;

    [self setZoom:tileSourcesZoom];
}

- (void)setEnableClustering:(BOOL)doEnableClustering
{
    _enableClustering = doEnableClustering;

    [self correctPositionOfAllAnnotations];
}

- (void)setDecelerationMode:(RMMapDecelerationMode)aDecelerationMode
{
    _decelerationMode = aDecelerationMode;

    float decelerationRate = 0.0;

    if (aDecelerationMode == RMMapDecelerationNormal)
        decelerationRate = UIScrollViewDecelerationRateNormal;
    else if (aDecelerationMode == RMMapDecelerationFast)
        decelerationRate = UIScrollViewDecelerationRateFast;

    [_mapScrollView setDecelerationRate:decelerationRate];
}

- (BOOL)enableDragging
{
    return _enableDragging;
}

- (void)setEnableDragging:(BOOL)enableDragging
{
    _enableDragging = enableDragging;
    _mapScrollView.scrollEnabled = enableDragging;
}

- (BOOL)enableBouncing
{
    return _enableBouncing;
}

- (void)setEnableBouncing:(BOOL)enableBouncing
{
    _enableBouncing = enableBouncing;
    _mapScrollView.bounces = enableBouncing;
    _mapScrollView.bouncesZoom = enableBouncing;
}

- (void)setAdjustTilesForRetinaDisplay:(BOOL)doAdjustTilesForRetinaDisplay
{
    if (_adjustTilesForRetinaDisplay == doAdjustTilesForRetinaDisplay)
        return;

    _adjustTilesForRetinaDisplay = doAdjustTilesForRetinaDisplay;

    RMProjectedPoint centerPoint = [self centerProjectedPoint];

    [self createMapView];

    [self setCenterProjectedPoint:centerPoint animated:NO];
}

- (float)adjustedZoomForRetinaDisplay
{
    if (!self.adjustTilesForRetinaDisplay && _screenScale > 1.0)
        return [self zoom] + 1.0;

    return [self zoom];
}

- (RMProjection *)projection
{
    return [[_projection retain] autorelease];
}

- (RMFractalTileProjection *)mercatorToTileProjection
{
    return [[_mercatorToTileProjection retain] autorelease];
}

- (void)setDebugTiles:(BOOL)shouldDebug;
{
    _debugTiles = shouldDebug;

    for (RMMapTiledLayerView *tiledLayerView in _tiledLayersSuperview.subviews)
    {
        tiledLayerView.layer.contents = nil;
        [tiledLayerView.layer setNeedsDisplay];
    }
}

- (void)setShowLogoBug:(BOOL)showLogoBug
{
    if (showLogoBug && ! _logoBug)
    {
        _logoBug = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"mapbox.png"]];

        _logoBug.frame = CGRectMake(8, self.bounds.size.height - _logoBug.bounds.size.height - 4, _logoBug.bounds.size.width, _logoBug.bounds.size.height);
        _logoBug.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin;

        [self addSubview:_logoBug];
    }
    else if ( ! showLogoBug && _logoBug)
    {
        [_logoBug removeFromSuperview];
        [_logoBug release]; _logoBug = nil;
    }

    _showLogoBug = showLogoBug;
}

#pragma mark -
#pragma mark LatLng/Pixel translation functions

- (CGPoint)projectedPointToPixel:(RMProjectedPoint)projectedPoint
{
    RMProjectedRect planetBounds = _projection.planetBounds;
    RMProjectedPoint normalizedProjectedPoint;
	normalizedProjectedPoint.x = projectedPoint.x + fabs(planetBounds.origin.x);
	normalizedProjectedPoint.y = projectedPoint.y + fabs(planetBounds.origin.y);

    // \bug: There is a rounding error here for high zoom levels
    CGPoint projectedPixel = CGPointMake((normalizedProjectedPoint.x / _metersPerPixel) - _mapScrollView.contentOffset.x, (_mapScrollView.contentSize.height - (normalizedProjectedPoint.y / _metersPerPixel)) - _mapScrollView.contentOffset.y);

//    RMLog(@"pointToPixel: {%f,%f} -> {%f,%f}", projectedPoint.x, projectedPoint.y, projectedPixel.x, projectedPixel.y);

    return projectedPixel;
}

- (CGPoint)coordinateToPixel:(CLLocationCoordinate2D)coordinate
{
    return [self projectedPointToPixel:[_projection coordinateToProjectedPoint:coordinate]];
}

- (RMProjectedPoint)pixelToProjectedPoint:(CGPoint)pixelCoordinate
{
    RMProjectedRect planetBounds = _projection.planetBounds;
    RMProjectedPoint normalizedProjectedPoint;
    normalizedProjectedPoint.x = ((pixelCoordinate.x + _mapScrollView.contentOffset.x) * _metersPerPixel) - fabs(planetBounds.origin.x);
    normalizedProjectedPoint.y = ((_mapScrollView.contentSize.height - _mapScrollView.contentOffset.y - pixelCoordinate.y) * _metersPerPixel) - fabs(planetBounds.origin.y);

//    RMLog(@"pixelToPoint: {%f,%f} -> {%f,%f}", pixelCoordinate.x, pixelCoordinate.y, normalizedProjectedPoint.x, normalizedProjectedPoint.y);

    return normalizedProjectedPoint;
}

- (CLLocationCoordinate2D)pixelToCoordinate:(CGPoint)pixelCoordinate
{
    return [_projection projectedPointToCoordinate:[self pixelToProjectedPoint:pixelCoordinate]];
}

- (RMProjectedPoint)coordinateToProjectedPoint:(CLLocationCoordinate2D)coordinate
{
    return [_projection coordinateToProjectedPoint:coordinate];
}

- (CLLocationCoordinate2D)projectedPointToCoordinate:(RMProjectedPoint)projectedPoint
{
    return [_projection projectedPointToCoordinate:projectedPoint];
}

- (RMProjectedSize)viewSizeToProjectedSize:(CGSize)screenSize
{
    return RMProjectedSizeMake(screenSize.width * _metersPerPixel, screenSize.height * _metersPerPixel);
}

- (CGSize)projectedSizeToViewSize:(RMProjectedSize)projectedSize
{
    return CGSizeMake(projectedSize.width / _metersPerPixel, projectedSize.height / _metersPerPixel);
}

- (RMProjectedPoint)projectedOrigin
{
    CGPoint origin = CGPointMake(_mapScrollView.contentOffset.x, _mapScrollView.contentSize.height - _mapScrollView.contentOffset.y);

    RMProjectedRect planetBounds = _projection.planetBounds;
    RMProjectedPoint normalizedProjectedPoint;
    normalizedProjectedPoint.x = (origin.x * _metersPerPixel) - fabs(planetBounds.origin.x);
    normalizedProjectedPoint.y = (origin.y * _metersPerPixel) - fabs(planetBounds.origin.y);

//    RMLog(@"projectedOrigin: {%f,%f}", normalizedProjectedPoint.x, normalizedProjectedPoint.y);

    return normalizedProjectedPoint;
}

- (RMProjectedSize)projectedViewSize
{
    return RMProjectedSizeMake(self.bounds.size.width * _metersPerPixel, self.bounds.size.height * _metersPerPixel);
}

- (CLLocationCoordinate2D)normalizeCoordinate:(CLLocationCoordinate2D)coordinate
{
	if (coordinate.longitude > 180.0)
        coordinate.longitude -= 360.0;

	coordinate.longitude /= 360.0;
	coordinate.longitude += 0.5;
	coordinate.latitude = 0.5 - ((log(tan((M_PI_4) + ((0.5 * M_PI * coordinate.latitude) / 180.0))) / M_PI) / 2.0);

	return coordinate;
}

- (RMTile)tileWithCoordinate:(CLLocationCoordinate2D)coordinate andZoom:(int)tileZoom
{
	int scale = (1<<tileZoom);
	CLLocationCoordinate2D normalizedCoordinate = [self normalizeCoordinate:coordinate];

	RMTile returnTile;
	returnTile.x = (int)(normalizedCoordinate.longitude * scale);
	returnTile.y = (int)(normalizedCoordinate.latitude * scale);
	returnTile.zoom = tileZoom;

	return returnTile;
}

- (RMSphericalTrapezium)latitudeLongitudeBoundingBoxForTile:(RMTile)aTile
{
    RMProjectedRect planetBounds = _projection.planetBounds;

    double scale = (1<<aTile.zoom);
    double tileSideLength = [_tileSourcesContainer tileSideLength];
    double tileMetersPerPixel = planetBounds.size.width / (tileSideLength * scale);

    CGPoint bottomLeft = CGPointMake(aTile.x * tileSideLength, (scale - aTile.y - 1) * tileSideLength);

    RMProjectedRect normalizedProjectedRect;
    normalizedProjectedRect.origin.x = (bottomLeft.x * tileMetersPerPixel) - fabs(planetBounds.origin.x);
    normalizedProjectedRect.origin.y = (bottomLeft.y * tileMetersPerPixel) - fabs(planetBounds.origin.y);
    normalizedProjectedRect.size.width = tileSideLength * tileMetersPerPixel;
    normalizedProjectedRect.size.height = tileSideLength * tileMetersPerPixel;

    RMSphericalTrapezium boundingBox;
    boundingBox.southWest = [self projectedPointToCoordinate:
                             RMProjectedPointMake(normalizedProjectedRect.origin.x,
                                                  normalizedProjectedRect.origin.y)];
    boundingBox.northEast = [self projectedPointToCoordinate:
                             RMProjectedPointMake(normalizedProjectedRect.origin.x + normalizedProjectedRect.size.width,
                                                  normalizedProjectedRect.origin.y + normalizedProjectedRect.size.height)];

//    RMLog(@"Bounding box for tile (%d,%d) at zoom %d: {%f,%f} {%f,%f)", aTile.x, aTile.y, aTile.zoom, boundingBox.southWest.longitude, boundingBox.southWest.latitude, boundingBox.northEast.longitude, boundingBox.northEast.latitude);

    return boundingBox;
}

#pragma mark -
#pragma mark Bounds

- (RMSphericalTrapezium)latitudeLongitudeBoundingBox
{
    return [self latitudeLongitudeBoundingBoxFor:[self bounds]];
}

- (RMSphericalTrapezium)latitudeLongitudeBoundingBoxFor:(CGRect)rect
{
    RMSphericalTrapezium boundingBox;
    CGPoint northwestScreen = rect.origin;

    CGPoint southeastScreen;
    southeastScreen.x = rect.origin.x + rect.size.width;
    southeastScreen.y = rect.origin.y + rect.size.height;

    CGPoint northeastScreen, southwestScreen;
    northeastScreen.x = southeastScreen.x;
    northeastScreen.y = northwestScreen.y;
    southwestScreen.x = northwestScreen.x;
    southwestScreen.y = southeastScreen.y;

    CLLocationCoordinate2D northeastLL, northwestLL, southeastLL, southwestLL;
    northeastLL = [self pixelToCoordinate:northeastScreen];
    northwestLL = [self pixelToCoordinate:northwestScreen];
    southeastLL = [self pixelToCoordinate:southeastScreen];
    southwestLL = [self pixelToCoordinate:southwestScreen];

    boundingBox.northEast.latitude = fmax(northeastLL.latitude, northwestLL.latitude);
    boundingBox.southWest.latitude = fmin(southeastLL.latitude, southwestLL.latitude);

    // westerly computations:
    // -179, -178 -> -179 (min)
    // -179, 179  -> 179 (max)
    if (fabs(northwestLL.longitude - southwestLL.longitude) <= kMaxLong)
        boundingBox.southWest.longitude = fmin(northwestLL.longitude, southwestLL.longitude);
    else
        boundingBox.southWest.longitude = fmax(northwestLL.longitude, southwestLL.longitude);

    if (fabs(northeastLL.longitude - southeastLL.longitude) <= kMaxLong)
        boundingBox.northEast.longitude = fmax(northeastLL.longitude, southeastLL.longitude);
    else
        boundingBox.northEast.longitude = fmin(northeastLL.longitude, southeastLL.longitude);

    return boundingBox;
}

#pragma mark -
#pragma mark Annotations

- (void)correctScreenPosition:(RMAnnotation *)annotation animated:(BOOL)animated
{
    RMProjectedRect planetBounds = _projection.planetBounds;
	RMProjectedPoint normalizedProjectedPoint;
	normalizedProjectedPoint.x = annotation.projectedLocation.x + fabs(planetBounds.origin.x);
	normalizedProjectedPoint.y = annotation.projectedLocation.y + fabs(planetBounds.origin.y);

    CGPoint newPosition = CGPointMake((normalizedProjectedPoint.x / _metersPerPixel) - _mapScrollView.contentOffset.x,
                                      _mapScrollView.contentSize.height - (normalizedProjectedPoint.y / _metersPerPixel) - _mapScrollView.contentOffset.y);

//    RMLog(@"Change annotation at {%f,%f} in mapView {%f,%f}", annotation.position.x, annotation.position.y, mapScrollView.contentSize.width, mapScrollView.contentSize.height);

    [annotation setPosition:newPosition animated:animated];
}

- (void)correctPositionOfAllAnnotationsIncludingInvisibles:(BOOL)correctAllAnnotations animated:(BOOL)animated
{
    // Prevent blurry movements
    [CATransaction begin];

    // Synchronize marker movement with the map scroll view
    if (animated && !_mapScrollView.isZooming)
    {
        [CATransaction setAnimationTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
        [CATransaction setAnimationDuration:0.30];
    }
    else
    {
        [CATransaction setDisableActions:YES];
    }

    _accumulatedDelta.x = 0.0;
    _accumulatedDelta.y = 0.0;
    [_overlayView moveLayersBy:_accumulatedDelta];

    if (self.quadTree)
    {
        if (!correctAllAnnotations || _mapScrollViewIsZooming)
        {
            for (RMAnnotation *annotation in _visibleAnnotations)
                [self correctScreenPosition:annotation animated:animated];

//            RMLog(@"%d annotations corrected", [visibleAnnotations count]);

            [CATransaction commit];

            return;
        }

        double boundingBoxBuffer = (kZoomRectPixelBuffer * _metersPerPixel);

        RMProjectedRect boundingBox = self.projectedBounds;
        boundingBox.origin.x -= boundingBoxBuffer;
        boundingBox.origin.y -= boundingBoxBuffer;
        boundingBox.size.width += (2.0 * boundingBoxBuffer);
        boundingBox.size.height += (2.0 * boundingBoxBuffer);

        NSArray *annotationsToCorrect = [self.quadTree annotationsInProjectedRect:boundingBox
                                                         createClusterAnnotations:self.enableClustering
                                                         withProjectedClusterSize:RMProjectedSizeMake(self.clusterAreaSize.width * _metersPerPixel, self.clusterAreaSize.height * _metersPerPixel)
                                                    andProjectedClusterMarkerSize:RMProjectedSizeMake(self.clusterMarkerSize.width * _metersPerPixel, self.clusterMarkerSize.height * _metersPerPixel)
                                                                findGravityCenter:self.positionClusterMarkersAtTheGravityCenter];
        NSMutableSet *previousVisibleAnnotations = [[NSMutableSet alloc] initWithSet:_visibleAnnotations];

        for (RMAnnotation *annotation in annotationsToCorrect)
        {
            if (annotation.layer == nil && _delegateHasLayerForAnnotation)
                annotation.layer = [_delegate mapView:self layerForAnnotation:annotation];
            if (annotation.layer == nil && [annotation.annotationType isEqualToString:kRMPointAnnotationTypeName])
                annotation.layer = kDefaultAnnotationMarker;
            if (annotation.layer == nil)
                continue;

            if ([annotation.layer isKindOfClass:[RMMarker class]] && ! annotation.isUserLocationAnnotation)
                annotation.layer.transform = _annotationTransform;

            // Use the zPosition property to order the layer hierarchy
            if ( ! [_visibleAnnotations containsObject:annotation])
            {
                [_overlayView addSublayer:annotation.layer];
                [_visibleAnnotations addObject:annotation];
            }

            [self correctScreenPosition:annotation animated:animated];

            [previousVisibleAnnotations removeObject:annotation];
        }

        for (RMAnnotation *annotation in previousVisibleAnnotations)
        {
            if ( ! annotation.isUserLocationAnnotation)
            {
                if (_delegateHasWillHideLayerForAnnotation)
                    [_delegate mapView:self willHideLayerForAnnotation:annotation];

                annotation.layer = nil;

                if (_delegateHasDidHideLayerForAnnotation)
                    [_delegate mapView:self didHideLayerForAnnotation:annotation];

                [_visibleAnnotations removeObject:annotation];
            }
        }

        [previousVisibleAnnotations release];

//        RMLog(@"%d annotations on screen, %d total", [overlayView sublayersCount], [annotations count]);
    }
    else
    {
        CALayer *lastLayer = nil;

        @synchronized (_annotations)
        {
            if (correctAllAnnotations)
            {
                for (RMAnnotation *annotation in _annotations)
                {
                    [self correctScreenPosition:annotation animated:animated];

                    if ([annotation isAnnotationWithinBounds:[self bounds]])
                    {
                        if (annotation.layer == nil && _delegateHasLayerForAnnotation)
                            annotation.layer = [_delegate mapView:self layerForAnnotation:annotation];
                        if (annotation.layer == nil && [annotation.annotationType isEqualToString:kRMPointAnnotationTypeName])
                            annotation.layer = kDefaultAnnotationMarker;
                        if (annotation.layer == nil)
                            continue;

                        if ([annotation.layer isKindOfClass:[RMMarker class]] && ! annotation.isUserLocationAnnotation)
                            annotation.layer.transform = _annotationTransform;

                        if (![_visibleAnnotations containsObject:annotation])
                        {
                            if (!lastLayer)
                                [_overlayView insertSublayer:annotation.layer atIndex:0];
                            else
                                [_overlayView insertSublayer:annotation.layer above:lastLayer];

                            [_visibleAnnotations addObject:annotation];
                        }

                        lastLayer = annotation.layer;
                    }
                    else
                    {
                        if ( ! annotation.isUserLocationAnnotation)
                        {
                            if (_delegateHasWillHideLayerForAnnotation)
                                [_delegate mapView:self willHideLayerForAnnotation:annotation];

                            annotation.layer = nil;
                            [_visibleAnnotations removeObject:annotation];

                            if (_delegateHasDidHideLayerForAnnotation)
                                [_delegate mapView:self didHideLayerForAnnotation:annotation];
                        }
                    }
                }
//                RMLog(@"%d annotations on screen, %d total", [overlayView sublayersCount], [annotations count]);
            }
            else
            {
                for (RMAnnotation *annotation in _visibleAnnotations)
                    [self correctScreenPosition:annotation animated:animated];

//                RMLog(@"%d annotations corrected", [visibleAnnotations count]);
            }
        }
    }

    NSMutableArray *sortedAnnotations = [NSMutableArray arrayWithArray:[_visibleAnnotations allObjects]];

    [sortedAnnotations filterUsingPredicate:[NSPredicate predicateWithFormat:@"isUserLocationAnnotation = NO"]];

    [sortedAnnotations sortUsingComparator:^(id obj1, id obj2)
    {
        RMAnnotation *annotation1 = (RMAnnotation *)obj1;
        RMAnnotation *annotation2 = (RMAnnotation *)obj2;

        if (   [annotation1.annotationType isEqualToString:kRMClusterAnnotationTypeName] && ! [annotation2.annotationType isEqualToString:kRMClusterAnnotationTypeName])
            return (_orderClusterMarkersAboveOthers ? NSOrderedDescending : NSOrderedAscending);

        if ( ! [annotation1.annotationType isEqualToString:kRMClusterAnnotationTypeName] &&   [annotation2.annotationType isEqualToString:kRMClusterAnnotationTypeName])
            return (_orderClusterMarkersAboveOthers ? NSOrderedAscending : NSOrderedDescending);

        CGPoint obj1Point = [self convertPoint:annotation1.position fromView:_overlayView];
        CGPoint obj2Point = [self convertPoint:annotation2.position fromView:_overlayView];

        if (obj1Point.y > obj2Point.y)
            return NSOrderedDescending;

        if (obj1Point.y < obj2Point.y)
            return NSOrderedAscending;

        return NSOrderedSame;
    }];

    for (CGFloat i = 0; i < [sortedAnnotations count]; i++)
        ((RMAnnotation *)[sortedAnnotations objectAtIndex:i]).layer.zPosition = (CGFloat)i;

    [CATransaction commit];
}

- (void)correctPositionOfAllAnnotations
{
    [self correctPositionOfAllAnnotationsIncludingInvisibles:YES animated:NO];
}

- (NSArray *)annotations
{
    return [_annotations allObjects];
}

- (NSArray *)visibleAnnotations
{
    return [_visibleAnnotations allObjects];
}

- (void)addAnnotation:(RMAnnotation *)annotation
{
    @synchronized (_annotations)
    {
        [_annotations addObject:annotation];
        [self.quadTree addAnnotation:annotation];
    }

    if (_enableClustering)
    {
        [self correctPositionOfAllAnnotations];
    }
    else
    {
        [self correctScreenPosition:annotation animated:NO];

        if (annotation.layer == nil && [annotation isAnnotationOnScreen] && _delegateHasLayerForAnnotation)
            annotation.layer = [_delegate mapView:self layerForAnnotation:annotation];

        if ( ! annotation.layer && [annotation.annotationType isEqualToString:kRMPointAnnotationTypeName])
            annotation.layer = kDefaultAnnotationMarker;

        if (annotation.layer)
        {
            [_overlayView addSublayer:annotation.layer];
            [_visibleAnnotations addObject:annotation];
        }
    }
}

- (void)addAnnotations:(NSArray *)newAnnotations
{
    @synchronized (_annotations)
    {
        [_annotations addObjectsFromArray:newAnnotations];
        [self.quadTree addAnnotations:newAnnotations];
    }

    [self correctPositionOfAllAnnotationsIncludingInvisibles:YES animated:NO];
}

- (void)removeAnnotation:(RMAnnotation *)annotation
{
    @synchronized (_annotations)
    {
        [_annotations removeObject:annotation];
        [_visibleAnnotations removeObject:annotation];
    }

    [self.quadTree removeAnnotation:annotation];

    // Remove the layer from the screen
    annotation.layer = nil;
}

- (void)removeAnnotations:(NSArray *)annotationsToRemove
{
    @synchronized (_annotations)
    {
        for (RMAnnotation *annotation in annotationsToRemove)
        {
            if ( ! annotation.isUserLocationAnnotation)
            {
                [_annotations removeObject:annotation];
                [_visibleAnnotations removeObject:annotation];
                [self.quadTree removeAnnotation:annotation];
                annotation.layer = nil;
            }
       }
    }

    [self correctPositionOfAllAnnotations];
}

- (void)removeAllAnnotations
{
    [self removeAnnotations:[_annotations allObjects]];
}

- (CGPoint)mapPositionForAnnotation:(RMAnnotation *)annotation
{
    [self correctScreenPosition:annotation animated:NO];
    return annotation.position;
}

#pragma mark -
#pragma mark User Location

- (void)setShowsUserLocation:(BOOL)newShowsUserLocation
{
    if (newShowsUserLocation == _showsUserLocation)
        return;

    _showsUserLocation = newShowsUserLocation;

    if (newShowsUserLocation)
    {
        RMRequireAsset(@"HeadingAngleSmall.png");
        RMRequireAsset(@"TrackingDot.png");
        RMRequireAsset(@"TrackingDotHalo.png");
        RMRequireAsset(@"TrackingHeading.png");
        RMRequireAsset(@"TrackingLocation.png");

        if (_delegateHasWillStartLocatingUser)
            [_delegate mapViewWillStartLocatingUser:self];

        self.userLocation = [RMUserLocation annotationWithMapView:self coordinate:CLLocationCoordinate2DMake(MAXFLOAT, MAXFLOAT) andTitle:nil];

        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.headingFilter = 5.0;
        _locationManager.delegate = self;
        [_locationManager startUpdatingLocation];
    }
    else
    {
        [_locationManager stopUpdatingLocation];
        [_locationManager stopUpdatingHeading];
        _locationManager.delegate = nil;
        [_locationManager release]; _locationManager = nil;

        if (_delegateHasDidStopLocatingUser)
            [_delegate mapViewDidStopLocatingUser:self];

        [self setUserTrackingMode:RMUserTrackingModeNone animated:YES];

        NSMutableArray *annotationsToRemove = [NSMutableArray array];

        for (RMAnnotation *annotation in _annotations)
        {
            if (annotation.isUserLocationAnnotation)
                [annotationsToRemove addObject:annotation];
        }

        for (RMAnnotation *annotationToRemove in annotationsToRemove)
        {
            [self removeAnnotation:annotationToRemove];
        }

        self.userLocation = nil;
    }    
}

- (void)setUserLocation:(RMUserLocation *)newUserLocation
{
    if ( ! [newUserLocation isEqual:_userLocation])
    {
        [_userLocation release];
        _userLocation = [newUserLocation retain];
    }
}

- (BOOL)isUserLocationVisible
{
    if (self.userLocation)
    {
        CGPoint locationPoint = [self mapPositionForAnnotation:self.userLocation];

        CGRect locationRect = CGRectMake(locationPoint.x - self.userLocation.location.horizontalAccuracy,
                                         locationPoint.y - self.userLocation.location.horizontalAccuracy,
                                         self.userLocation.location.horizontalAccuracy * 2,
                                         self.userLocation.location.horizontalAccuracy * 2);

        return CGRectIntersectsRect([self bounds], locationRect);
    }

    return NO;
}

- (void)setUserTrackingMode:(RMUserTrackingMode)mode
{
    [self setUserTrackingMode:mode animated:YES];
}

- (void)setUserTrackingMode:(RMUserTrackingMode)mode animated:(BOOL)animated
{
    if (mode == _userTrackingMode)
        return;

    if (mode == RMUserTrackingModeFollowWithHeading && ! CLLocationCoordinate2DIsValid(self.userLocation.coordinate))
        mode = RMUserTrackingModeNone;

    _userTrackingMode = mode;

    switch (_userTrackingMode)
    {
        case RMUserTrackingModeNone:
        default:
        {
            [_locationManager stopUpdatingHeading];

            [CATransaction setAnimationDuration:0.5];
            [CATransaction setAnimationTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];

            [UIView animateWithDuration:(animated ? 0.5 : 0.0)
                                  delay:0.0
                                options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationCurveEaseInOut
                             animations:^(void)
                             {
                                 _mapTransform = CGAffineTransformIdentity;
                                 _annotationTransform = CATransform3DIdentity;

                                 _mapScrollView.transform = _mapTransform;
                                 _overlayView.transform   = _mapTransform;

                                 for (RMAnnotation *annotation in _annotations)
                                     if ([annotation.layer isKindOfClass:[RMMarker class]] && ! annotation.isUserLocationAnnotation)
                                         annotation.layer.transform = _annotationTransform;
                             }
                             completion:nil];

            [CATransaction commit];

            if (_userLocationTrackingView || _userHeadingTrackingView || _userHaloTrackingView)
            {
                [_userLocationTrackingView removeFromSuperview]; _userLocationTrackingView = nil;
                [_userHeadingTrackingView removeFromSuperview]; _userHeadingTrackingView = nil;
                [_userHaloTrackingView removeFromSuperview]; _userHaloTrackingView = nil;
            }

            self.userLocation.layer.hidden = NO;

            break;
        }
        case RMUserTrackingModeFollow:
        {
            self.showsUserLocation = YES;

            [_locationManager stopUpdatingHeading];

            if (self.userLocation)
                [self locationManager:_locationManager didUpdateToLocation:self.userLocation.location fromLocation:self.userLocation.location];

            if (_userLocationTrackingView || _userHeadingTrackingView || _userHaloTrackingView)
            {
                [_userLocationTrackingView removeFromSuperview]; _userLocationTrackingView = nil;
                [_userHeadingTrackingView removeFromSuperview]; _userHeadingTrackingView = nil;
                [_userHaloTrackingView removeFromSuperview]; _userHaloTrackingView = nil;
            }

            [CATransaction setAnimationDuration:0.5];
            [CATransaction setAnimationTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];

            [UIView animateWithDuration:(animated ? 0.5 : 0.0)
                                  delay:0.0
                                options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationCurveEaseInOut
                             animations:^(void)
                             {
                                 _mapTransform = CGAffineTransformIdentity;
                                 _annotationTransform = CATransform3DIdentity;

                                 _mapScrollView.transform = _mapTransform;
                                 _overlayView.transform   = _mapTransform;

                                 for (RMAnnotation *annotation in _annotations)
                                     if ([annotation.layer isKindOfClass:[RMMarker class]] && ! annotation.isUserLocationAnnotation)
                                         annotation.layer.transform = _annotationTransform;
                             }
                             completion:nil];

            [CATransaction commit];

            self.userLocation.layer.hidden = NO;

            break;
        }
        case RMUserTrackingModeFollowWithHeading:
        {
            self.showsUserLocation = YES;

            self.userLocation.layer.hidden = YES;

            _userHaloTrackingView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"TrackingDotHalo"]];

            _userHaloTrackingView.center = CGPointMake(round([self bounds].size.width  / 2),
                                                      round([self bounds].size.height / 2));

            _userHaloTrackingView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin  |
                                                    UIViewAutoresizingFlexibleRightMargin |
                                                    UIViewAutoresizingFlexibleTopMargin   |
                                                    UIViewAutoresizingFlexibleBottomMargin;

            for (NSString *animationKey in _trackingHaloAnnotation.layer.animationKeys)
                [_userHaloTrackingView.layer addAnimation:[[[_trackingHaloAnnotation.layer animationForKey:animationKey] copy] autorelease] forKey:animationKey];

            [self insertSubview:_userHaloTrackingView belowSubview:_overlayView];

            _userHeadingTrackingView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"HeadingAngleSmall.png"]];

            _userHeadingTrackingView.frame = CGRectMake((self.bounds.size.width  / 2) - (_userHeadingTrackingView.bounds.size.width / 2),
                                                       (self.bounds.size.height / 2) - _userHeadingTrackingView.bounds.size.height,
                                                       _userHeadingTrackingView.bounds.size.width,
                                                       _userHeadingTrackingView.bounds.size.height * 2);

            _userHeadingTrackingView.contentMode = UIViewContentModeTop;

            _userHeadingTrackingView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin  |
                                                        UIViewAutoresizingFlexibleRightMargin |
                                                        UIViewAutoresizingFlexibleTopMargin   |
                                                        UIViewAutoresizingFlexibleBottomMargin;

            _userHeadingTrackingView.alpha = 0.0;

            [self insertSubview:_userHeadingTrackingView belowSubview:_overlayView];

            _userLocationTrackingView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"TrackingDot.png"]];

            _userLocationTrackingView.center = CGPointMake(round([self bounds].size.width  / 2), 
                                                          round([self bounds].size.height / 2));

            _userLocationTrackingView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin  |
                                                         UIViewAutoresizingFlexibleRightMargin |
                                                         UIViewAutoresizingFlexibleTopMargin   |
                                                         UIViewAutoresizingFlexibleBottomMargin;
            
            [self insertSubview:_userLocationTrackingView aboveSubview:_userHeadingTrackingView];

            if (self.zoom < 3)
                [self zoomByFactor:exp2f(3 - [self zoom]) near:self.center animated:YES];

            if (self.userLocation)
                [self locationManager:_locationManager didUpdateToLocation:self.userLocation.location fromLocation:self.userLocation.location];

            [self updateHeadingForDeviceOrientation];

            [_locationManager startUpdatingHeading];

            break;
        }
    }

    if (_delegateHasDidChangeUserTrackingMode)
        [_delegate mapView:self didChangeUserTrackingMode:_userTrackingMode animated:animated];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
    if ( ! _showsUserLocation || _mapScrollView.isDragging || ! newLocation || ! CLLocationCoordinate2DIsValid(newLocation.coordinate))
        return;

    if ([newLocation distanceFromLocation:oldLocation])
    {
        self.userLocation.location = newLocation;

        if (_delegateHasDidUpdateUserLocation)
            [_delegate mapView:self didUpdateUserLocation:self.userLocation];
    }

    if (self.userTrackingMode != RMUserTrackingModeNone)
    {
        // center on user location unless we're already centered there (or very close)
        //
        CGPoint mapCenterPoint    = [self convertPoint:self.center fromView:self.superview];
        CGPoint userLocationPoint = [self mapPositionForAnnotation:self.userLocation];

        if (fabsf(userLocationPoint.x - mapCenterPoint.x) > 1.0 || fabsf(userLocationPoint.y - mapCenterPoint.y) > 1.0)
        {
            if (round(_zoom) >= 10)
            {
                // at sufficient detail, just re-center the map; don't zoom
                //
                [self setCenterCoordinate:self.userLocation.location.coordinate animated:YES];
            }
            else
            {
                // otherwise re-center and zoom in to near accuracy confidence
                //
                float delta = (newLocation.horizontalAccuracy / 110000) * 1.2; // approx. meter per degree latitude, plus some margin

                CLLocationCoordinate2D desiredSouthWest = CLLocationCoordinate2DMake(newLocation.coordinate.latitude  - delta,
                                                                                     newLocation.coordinate.longitude - delta);

                CLLocationCoordinate2D desiredNorthEast = CLLocationCoordinate2DMake(newLocation.coordinate.latitude  + delta,
                                                                                     newLocation.coordinate.longitude + delta);

                CGFloat pixelRadius = fminf(self.bounds.size.width, self.bounds.size.height) / 2;

                CLLocationCoordinate2D actualSouthWest = [self pixelToCoordinate:CGPointMake(userLocationPoint.x - pixelRadius, userLocationPoint.y - pixelRadius)];
                CLLocationCoordinate2D actualNorthEast = [self pixelToCoordinate:CGPointMake(userLocationPoint.x + pixelRadius, userLocationPoint.y + pixelRadius)];

                if (desiredNorthEast.latitude  != actualNorthEast.latitude  ||
                    desiredNorthEast.longitude != actualNorthEast.longitude ||
                    desiredSouthWest.latitude  != actualSouthWest.latitude  ||
                    desiredSouthWest.longitude != actualSouthWest.longitude)
                {
                    [self zoomWithLatitudeLongitudeBoundsSouthWest:desiredSouthWest northEast:desiredNorthEast animated:YES];
                }
            }
        }
    }

    if ( ! _accuracyCircleAnnotation)
    {
        _accuracyCircleAnnotation = [[RMAnnotation annotationWithMapView:self coordinate:newLocation.coordinate andTitle:nil] retain];
        _accuracyCircleAnnotation.annotationType = kRMAccuracyCircleAnnotationTypeName;
        _accuracyCircleAnnotation.clusteringEnabled = NO;
        _accuracyCircleAnnotation.enabled = NO;
        _accuracyCircleAnnotation.layer = [[RMCircle alloc] initWithView:self radiusInMeters:newLocation.horizontalAccuracy];
        _accuracyCircleAnnotation.layer.zPosition = -MAXFLOAT;
        _accuracyCircleAnnotation.isUserLocationAnnotation = YES;

        ((RMCircle *)_accuracyCircleAnnotation.layer).lineColor = [UIColor colorWithRed:0.378 green:0.552 blue:0.827 alpha:0.7];
        ((RMCircle *)_accuracyCircleAnnotation.layer).fillColor = [UIColor colorWithRed:0.378 green:0.552 blue:0.827 alpha:0.15];

        ((RMCircle *)_accuracyCircleAnnotation.layer).lineWidthInPixels = 2.0;

        [self addAnnotation:_accuracyCircleAnnotation];
    }

    if ([newLocation distanceFromLocation:oldLocation])
        _accuracyCircleAnnotation.coordinate = newLocation.coordinate;

    if (newLocation.horizontalAccuracy != oldLocation.horizontalAccuracy)
        ((RMCircle *)_accuracyCircleAnnotation.layer).radiusInMeters = newLocation.horizontalAccuracy;

    if ( ! _trackingHaloAnnotation)
    {
        _trackingHaloAnnotation = [[RMAnnotation annotationWithMapView:self coordinate:newLocation.coordinate andTitle:nil] retain];
        _trackingHaloAnnotation.annotationType = kRMTrackingHaloAnnotationTypeName;
        _trackingHaloAnnotation.clusteringEnabled = NO;
        _trackingHaloAnnotation.enabled = NO;

        // create image marker
        //
        _trackingHaloAnnotation.layer = [[RMMarker alloc] initWithUIImage:[UIImage imageNamed:@"TrackingDotHalo.png"]];
        _trackingHaloAnnotation.layer.zPosition = -MAXFLOAT + 1;
        _trackingHaloAnnotation.isUserLocationAnnotation = YES;

        [CATransaction begin];
        [CATransaction setAnimationDuration:2.5];
        [CATransaction setAnimationTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];

        // scale out radially
        //
        CABasicAnimation *boundsAnimation = [CABasicAnimation animationWithKeyPath:@"transform"];
        boundsAnimation.repeatCount = MAXFLOAT;
        boundsAnimation.fromValue = [NSValue valueWithCATransform3D:CATransform3DMakeScale(0.1, 0.1, 1.0)];
        boundsAnimation.toValue   = [NSValue valueWithCATransform3D:CATransform3DMakeScale(2.0, 2.0, 1.0)];
        boundsAnimation.removedOnCompletion = NO;
        boundsAnimation.fillMode = kCAFillModeForwards;

        [_trackingHaloAnnotation.layer addAnimation:boundsAnimation forKey:@"animateScale"];

        // go transparent as scaled out
        //
        CABasicAnimation *opacityAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
        opacityAnimation.repeatCount = MAXFLOAT;
        opacityAnimation.fromValue = [NSNumber numberWithFloat:1.0];
        opacityAnimation.toValue   = [NSNumber numberWithFloat:-1.0];
        opacityAnimation.removedOnCompletion = NO;
        opacityAnimation.fillMode = kCAFillModeForwards;

        [_trackingHaloAnnotation.layer addAnimation:opacityAnimation forKey:@"animateOpacity"];

        [CATransaction commit];

        [self addAnnotation:_trackingHaloAnnotation];
    }

    if ([newLocation distanceFromLocation:oldLocation])
        _trackingHaloAnnotation.coordinate = newLocation.coordinate;

    self.userLocation.layer.hidden = ( ! CLLocationCoordinate2DIsValid(self.userLocation.coordinate) || self.userTrackingMode == RMUserTrackingModeFollowWithHeading);

    if (_userLocationTrackingView)
        _userLocationTrackingView.hidden = ! CLLocationCoordinate2DIsValid(self.userLocation.coordinate);

    _accuracyCircleAnnotation.layer.hidden = newLocation.horizontalAccuracy <= 10;

    _trackingHaloAnnotation.layer.hidden = ( ! CLLocationCoordinate2DIsValid(self.userLocation.coordinate) || newLocation.horizontalAccuracy > 10 || self.userTrackingMode == RMUserTrackingModeFollowWithHeading);

    if (_userHaloTrackingView)
        _userHaloTrackingView.hidden = ( ! CLLocationCoordinate2DIsValid(self.userLocation.coordinate) || newLocation.horizontalAccuracy > 10);

    if ( ! [_annotations containsObject:self.userLocation])
        [self addAnnotation:self.userLocation];
}

- (BOOL)locationManagerShouldDisplayHeadingCalibration:(CLLocationManager *)manager
{
    if (self.displayHeadingCalibration)
        [_locationManager performSelector:@selector(dismissHeadingCalibrationDisplay) withObject:nil afterDelay:10.0];

    return self.displayHeadingCalibration;
}

- (void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading
{
    if ( ! _showsUserLocation || _mapScrollView.isDragging || newHeading.headingAccuracy < 0)
        return;

    self.userLocation.heading = newHeading;

    if (_delegateHasDidUpdateUserLocation)
        [_delegate mapView:self didUpdateUserLocation:self.userLocation];

    if (newHeading.trueHeading != 0 && self.userTrackingMode == RMUserTrackingModeFollowWithHeading)
    {
        if (_userHeadingTrackingView.alpha < 1.0)
            [UIView animateWithDuration:0.5 animations:^(void) { _userHeadingTrackingView.alpha = 1.0; }];

        [CATransaction begin];
        [CATransaction setAnimationDuration:0.5];
        [CATransaction setAnimationTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];

        [UIView animateWithDuration:0.5
                              delay:0.0
                            options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationCurveEaseInOut
                         animations:^(void)
                         {
                             CGFloat angle = (M_PI / -180) * newHeading.trueHeading;

                             _mapTransform = CGAffineTransformMakeRotation(angle);
                             _annotationTransform = CATransform3DMakeAffineTransform(CGAffineTransformMakeRotation(-angle));

                             _mapScrollView.transform = _mapTransform;
                             _overlayView.transform   = _mapTransform;

                             for (RMAnnotation *annotation in _annotations)
                                 if ([annotation.layer isKindOfClass:[RMMarker class]] && ! annotation.isUserLocationAnnotation)
                                     annotation.layer.transform = _annotationTransform;

                             [self correctPositionOfAllAnnotations];
                         }
                         completion:nil];

        [CATransaction commit];
    }
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    if (status == kCLAuthorizationStatusDenied || status == kCLAuthorizationStatusRestricted)
    {
        self.userTrackingMode  = RMUserTrackingModeNone;
        self.showsUserLocation = NO;
    }
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    if ([error code] == kCLErrorDenied)
    {
        self.userTrackingMode  = RMUserTrackingModeNone;
        self.showsUserLocation = NO;

        if (_delegateHasDidFailToLocateUserWithError)
            [_delegate mapView:self didFailToLocateUserWithError:error];
    }
}

- (void)updateHeadingForDeviceOrientation
{
    if (_locationManager)
    {
        // note that right/left device and interface orientations are opposites (see UIApplication.h)
        //
        switch ([[UIApplication sharedApplication] statusBarOrientation])
        {
            case (UIInterfaceOrientationLandscapeLeft):
            {
                _locationManager.headingOrientation = CLDeviceOrientationLandscapeRight;
                break;
            }
            case (UIInterfaceOrientationLandscapeRight):
            {
                _locationManager.headingOrientation = CLDeviceOrientationLandscapeLeft;
                break;
            }
            case (UIInterfaceOrientationPortraitUpsideDown):
            {
                _locationManager.headingOrientation = CLDeviceOrientationPortraitUpsideDown;
                break;
            }
            case (UIInterfaceOrientationPortrait):
            default:
            {
                _locationManager.headingOrientation = CLDeviceOrientationPortrait;
                break;
            }
        }
    }
}

#pragma mark -
#pragma mark Attribution

- (void)setHideAttribution:(BOOL)flag
{
    if (_hideAttribution == flag)
        return;

    _hideAttribution = flag;

    [self layoutSubviews];
}

- (UIViewController *)viewControllerPresentingAttribution
{
    return _viewControllerPresentingAttribution;
}

- (void)setViewControllerPresentingAttribution:(UIViewController *)viewController
{
    _viewControllerPresentingAttribution = viewController;
    
    if (_viewControllerPresentingAttribution && ! _attributionButton)
    {
        _attributionButton = [[UIButton buttonWithType:UIButtonTypeInfoLight] retain];
        
        _attributionButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin;
        
        [_attributionButton addTarget:self action:@selector(showAttribution:) forControlEvents:UIControlEventTouchUpInside];
        
        _attributionButton.frame = CGRectMake(self.bounds.size.width  - 30,
                                              self.bounds.size.height - 30,
                                              _attributionButton.bounds.size.width,
                                              _attributionButton.bounds.size.height);

        [self addSubview:_attributionButton];
    }
    else if ( ! _viewControllerPresentingAttribution && _attributionButton)
    {
        [_attributionButton removeFromSuperview];
        [_attributionButton release]; _attributionButton = nil;
    }
}

- (void)showAttribution:(id)sender
{
    if (_viewControllerPresentingAttribution)
    {
        RMAttributionViewController *attributionViewController = [[[RMAttributionViewController alloc] initWithMapView:self] autorelease];
        
        attributionViewController.modalTransitionStyle = UIModalTransitionStylePartialCurl;
        
        [_viewControllerPresentingAttribution presentModalViewController:attributionViewController animated:YES];
    }
}

@end
