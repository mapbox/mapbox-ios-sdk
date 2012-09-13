//
//  RMUserLocation.m
//  MapView
//
//  Created by Justin Miller on 5/8/12.
//  Copyright (c) 2012 MapBox / Development Seed. All rights reserved.
//

#import "RMUserLocation.h"
#import "RMMarker.h"
#import "RMMapView.h"

@implementation RMUserLocation

@synthesize updating = _updating;
@synthesize location = _location;
@synthesize heading = _heading;

- (id)initWithMapView:(RMMapView *)aMapView coordinate:(CLLocationCoordinate2D)aCoordinate andTitle:(NSString *)aTitle
{
    if ( ! (self = [super initWithMapView:aMapView coordinate:aCoordinate andTitle:aTitle]))
        return nil;

    self.layer = [[[RMMarker alloc] initWithUIImage:[UIImage imageNamed:@"TrackingDot.png"]] autorelease];

    self.layer.zPosition = -MAXFLOAT + 2;

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
