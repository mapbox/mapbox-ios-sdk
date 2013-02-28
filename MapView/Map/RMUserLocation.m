//
//  RMUserLocation.m
//  MapView
//
// Copyright (c) 2008-2013, Route-Me Contributors
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

#import "RMUserLocation.h"
#import "RMMarker.h"
#import "RMMapView.h"

#define kRMUserLocationAnnotationTypeName @"RMUserLocationAnnotation"

@interface RMUserLocation ()

@property (nonatomic, assign) BOOL hasCustomLayer;

@end

#pragma mark -

@implementation RMUserLocation

@synthesize updating = _updating;
@synthesize location = _location;
@synthesize heading = _heading;
@synthesize hasCustomLayer = _hasCustomLayer;

- (id)initWithMapView:(RMMapView *)aMapView coordinate:(CLLocationCoordinate2D)aCoordinate andTitle:(NSString *)aTitle
{
    if ( ! (self = [super initWithMapView:aMapView coordinate:aCoordinate andTitle:aTitle]))
        return nil;

    self.annotationType = kRMUserLocationAnnotationTypeName;

    self.clusteringEnabled = NO;

    return self;
}

- (void)dealloc
{
    [layer release]; layer = nil;
    [annotationType release]; annotationType = nil;
    [_location release]; _location = nil;
    [_heading release]; _heading = nil;
    [super dealloc];
}

- (RMMapLayer *)layer
{
    if ( ! super.layer)
    {
        if ([self.mapView.delegate respondsToSelector:@selector(mapView:layerForAnnotation:)])
            super.layer = [self.mapView.delegate mapView:self.mapView layerForAnnotation:self];

        if (super.layer)
            self.hasCustomLayer = YES;

        if ( ! super.layer)
            super.layer = [[[RMMarker alloc] initWithUIImage:[RMMapView resourceImageNamed:@"TrackingDot.png"]] autorelease];

        super.layer.zPosition = -MAXFLOAT + 2;
    }

    return super.layer;
}

- (BOOL)isUpdating
{
    return (self.mapView.userTrackingMode != RMUserTrackingModeNone);
}

- (void)setLocation:(CLLocation *)newLocation
{
    if ([newLocation distanceFromLocation:_location] && newLocation.coordinate.latitude != 0 && newLocation.coordinate.longitude != 0)
    {
        [self willChangeValueForKey:@"location"];
        [_location release];
        _location = [newLocation retain];
        self.coordinate = _location.coordinate;
        [self didChangeValueForKey:@"location"];
    }
}

- (void)setHeading:(CLHeading *)newHeading
{
    if (newHeading.trueHeading != _heading.trueHeading)
    {
        [self willChangeValueForKey:@"heading"];
        [_heading release];
        _heading = [newHeading retain];
        [self didChangeValueForKey:@"heading"];
    }
}

- (BOOL)isUserLocationAnnotation
{
    return YES;
}

@end
