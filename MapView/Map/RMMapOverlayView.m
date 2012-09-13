//
//  RMMapOverlayView.m
//  MapView
//
//  Created by Thomas Rasch on 25.08.11.
//  Copyright (c) 2011 Alpstein. All rights reserved.
//

#import "RMMapOverlayView.h"
#import "RMMarker.h"
#import "RMAnnotation.h"
#import "RMPixel.h"
#import "RMMapView.h"

@implementation RMMapOverlayView

+ (Class)layerClass
{
    return [CAScrollLayer class];
}

- (id)initWithFrame:(CGRect)frame
{
    if (!(self = [super initWithFrame:frame]))
        return nil;

    self.layer.masksToBounds = NO;

    return self;
}

- (unsigned)sublayersCount
{
    return [self.layer.sublayers count];
}

- (void)addSublayer:(CALayer *)aLayer
{
    [self.layer addSublayer:aLayer];
}

- (void)insertSublayer:(CALayer *)aLayer atIndex:(unsigned)index
{
    [self.layer insertSublayer:aLayer atIndex:index];
}

- (void)insertSublayer:(CALayer *)aLayer below:(CALayer *)sublayer
{
    [self.layer insertSublayer:aLayer below:sublayer];
}

- (void)insertSublayer:(CALayer *)aLayer above:(CALayer *)sublayer
{
    [self.layer insertSublayer:aLayer above:sublayer];
}

- (void)moveLayersBy:(CGPoint)delta
{
    [self.layer scrollPoint:CGPointMake(-delta.x, -delta.y)];
}

- (CALayer *)overlayHitTest:(CGPoint)point
{
    RMMapView *mapView = ((RMMapView *)self.superview);

    // here we hide the accuracy circle & tracking halo to exclude from hit
    // testing, as well as be sure to show the user location (even if in
    // heading mode) to ensure hits on it
    //
    RMAnnotation *userLocationAnnotation = (RMAnnotation *)mapView.userLocation;
    RMAnnotation *accuracyCircleAnnotation = nil;
    RMAnnotation *trackingHaloAnnotation   = nil;

    NSArray *matches = nil;

    matches = [mapView.annotations filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"annotationType = %@", kRMAccuracyCircleAnnotationTypeName]];

    if ([matches count])
        accuracyCircleAnnotation = [matches lastObject];

    matches = [mapView.annotations filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"annotationType = %@", kRMTrackingHaloAnnotationTypeName]];

    if ([matches count])
        trackingHaloAnnotation = [matches lastObject];

    BOOL userLocationFlag;
    BOOL accuracyCircleFlag;
    BOOL trackingHaloFlag;

    if (userLocationAnnotation)
    {
        userLocationFlag = userLocationAnnotation.layer.isHidden;
        userLocationAnnotation.layer.hidden = NO;
    }

    if (accuracyCircleAnnotation)
    {
        accuracyCircleFlag = accuracyCircleAnnotation.layer.isHidden;
        accuracyCircleAnnotation.layer.hidden = YES;
    }

    if (trackingHaloAnnotation)
    {
        trackingHaloFlag = trackingHaloAnnotation.layer.isHidden;
        trackingHaloAnnotation.layer.hidden = YES;
    }
    
    NSMutableArray *hiddenAnnotationArray = [NSMutableArray array];
    
    for (RMAnnotation *annotation in mapView.annotations)
    {
        if(annotation.tapEnabled == FALSE)
        {
            [hiddenAnnotationArray addObject:annotation];
            annotation.layer.hidden = YES;
        }
    }

    CALayer *hit = [self.layer hitTest:point];

    if (userLocationAnnotation)
        userLocationAnnotation.layer.hidden = userLocationFlag;

    if (accuracyCircleAnnotation)
        accuracyCircleAnnotation.layer.hidden = accuracyCircleFlag;

    if (trackingHaloAnnotation)
        trackingHaloAnnotation.layer.hidden = trackingHaloFlag;
    
    for (RMAnnotation *annotation in hiddenAnnotationArray)
    {
        annotation.layer.hidden = NO;
    }

    return hit;
}

@end
