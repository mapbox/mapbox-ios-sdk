//
//  RMAnnotation.h
//  MapView
//
// Copyright (c) 2008-2009, Route-Me Contributors
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

#import "RMFoundation.h"

@class RMMapView, RMMapLayer, RMQuadTreeNode;

@interface RMAnnotation : NSObject
{
    CLLocationCoordinate2D coordinate;
    NSString *title;

    CGPoint position;
    RMProjectedPoint projectedLocation;
    RMProjectedRect  projectedBoundingBox;
    BOOL hasBoundingBox;
    BOOL enabled, clusteringEnabled;

    RMMapLayer *layer;
    RMQuadTreeNode *quadTreeNode;

    // provided for storage of arbitrary user data
    id userInfo;
    NSString *annotationType;
    UIImage  *annotationIcon, *badgeIcon;
    CGPoint   anchorPoint;
}

@property (nonatomic, assign) CLLocationCoordinate2D coordinate;
@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) id userInfo;
@property (nonatomic, retain) NSString *annotationType;
@property (nonatomic, retain) UIImage *annotationIcon;
@property (nonatomic, retain) UIImage *badgeIcon;
@property (nonatomic, assign) CGPoint anchorPoint;

// the location on screen. don't set this directly, use the coordinate property.
@property (nonatomic, assign) CGPoint position;
@property (nonatomic, assign) RMProjectedPoint projectedLocation; // in projected meters
@property (nonatomic, assign) RMProjectedRect  projectedBoundingBox;
@property (nonatomic, assign) BOOL hasBoundingBox;
@property (nonatomic, assign) BOOL enabled;
@property (nonatomic, assign) BOOL clusteringEnabled;

// RMMarker, RMPath, whatever you return in your delegate method mapView:layerForAnnotation:
@property (nonatomic, retain) RMMapLayer *layer;

// This is for the QuadTree. Don't mess this up.
@property (nonatomic, assign) RMQuadTreeNode *quadTreeNode;

// This is for filtering non-user annotations.
@property (nonatomic, assign) BOOL isUserLocationAnnotation;

+ (id)annotationWithMapView:(RMMapView *)aMapView coordinate:(CLLocationCoordinate2D)aCoordinate andTitle:(NSString *)aTitle;
- (id)initWithMapView:(RMMapView *)aMapView coordinate:(CLLocationCoordinate2D)aCoordinate andTitle:(NSString *)aTitle;

- (void)setBoundingBoxCoordinatesSouthWest:(CLLocationCoordinate2D)southWest northEast:(CLLocationCoordinate2D)northEast;
- (void)setBoundingBoxFromLocations:(NSArray *)locations;

- (BOOL)isAnnotationOnScreen;
- (BOOL)isAnnotationWithinBounds:(CGRect)bounds;

// Used internally
@property (nonatomic, retain) RMMapView *mapView;

@end
