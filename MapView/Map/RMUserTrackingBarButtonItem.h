//
//  RMUserTrackingBarButtonItem.h
//  MapView
//
//  Created by Justin Miller on 5/10/12.
//  Copyright (c) 2012 MapBox / Development Seed. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RMMapView;

/** An RMUserTrackingBarButtonItem object is a specialized bar button item that allows the user to toggle through the user tracking modes. For example, when the user taps the button, the map view toggles between tracking the user with and without heading. The button also reflects the current user tracking mode if set elsewhere. This bar button item is associated to a single map view. */
@interface RMUserTrackingBarButtonItem : UIBarButtonItem

/** @name Initializing */

/** Initializes a newly created bar button item with the specified map view.
*   @param mapView The map view used by this bar button item.
*   @return The initialized bar button item. */
- (id)initWithMapView:(RMMapView *)mapView;

/** @name Accessing Properties */

/** The map view associated with this bar button item. */
@property (nonatomic, retain) IBOutlet RMMapView *mapView;

@end
