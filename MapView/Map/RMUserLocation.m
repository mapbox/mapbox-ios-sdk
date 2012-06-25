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

@synthesize updating;
@synthesize location;
@synthesize heading;

- (id)initWithMapView:(RMMapView *)aMapView coordinate:(CLLocationCoordinate2D)aCoordinate andTitle:(NSString *)aTitle
{
    if ( ! (self = [super initWithMapView:aMapView coordinate:aCoordinate andTitle:aTitle]))
        return nil;

    NSAssert([[NSBundle mainBundle] pathForResource:@"TrackingDot" ofType:@"png"], @"Unable to find necessary user location graphical assets (copy from MapView/Map/Resources)");
    
    layer = [[RMMarker alloc] initWithUIImage:[UIImage imageNamed:@"TrackingDot.png"]];

    annotationType = [kRMUserLocationAnnotationTypeName retain];
    
    clusteringEnabled = NO;

    return self;
}

- (void)dealloc
{
    [layer release]; layer = nil;
    [annotationType release]; annotationType = nil;
    [location release]; location = nil;
    [heading release]; heading = nil;
    [super dealloc];
}

- (BOOL)isUpdating
{
    return (self.mapView.userTrackingMode != RMUserTrackingModeNone);
}

- (void)setLocation:(CLLocation *)newLocation
{
    if ([newLocation distanceFromLocation:location] && newLocation.coordinate.latitude != 0 && newLocation.coordinate.longitude != 0)
    {
        [self willChangeValueForKey:@"location"];
        [location release];
        location = [newLocation retain];
        self.coordinate = location.coordinate;
        [self didChangeValueForKey:@"location"];
    }
}

- (void)setHeading:(CLHeading *)newHeading
{
    if (newHeading.trueHeading != heading.trueHeading)
    {
        [self willChangeValueForKey:@"heading"];
        [heading release];
        heading = [newHeading retain];
        [self didChangeValueForKey:@"heading"];
    }
}

- (BOOL)isUserLocationAnnotation
{
    return YES;
}

@end
