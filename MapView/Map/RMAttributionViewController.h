//
//  RMAttributionViewController.h
//  MapView
//
//  Created by Justin Miller on 6/19/12.
//  Copyright (c) 2012 MapBox / Development Seed. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RMMapView;

@interface RMAttributionViewController : UIViewController <UIWebViewDelegate>

- (id)initWithMapView:(RMMapView *)mapView;
- (id)initWithMapView:(RMMapView *)mapView customAttributionString:(NSString *)attributionString;

@end
