//
//  RMUserLocation.h
//  MapView
//
//  Created by Justin Miller on 5/8/12.
//  Copyright (c) 2012 MapBox / Development Seed. All rights reserved.
//

#import "RMAnnotation.h"

/** The RMUserLocation class defines a specific type of annotation that identifies the user’s current location. You do not create instances of this class directly. Instead, you retrieve an existing RMUserLocation object from the userLocation property of the map view displayed in your application. */
@interface RMUserLocation : RMAnnotation

/** @name Determining the User’s Position */

/** A Boolean value indicating whether the user’s location is currently being updated. (read-only) */
@property (nonatomic, readonly, getter=isUpdating) BOOL updating;

/** The current location of the device. (read-only)
*
*   This property contains `nil` if the map view is not currently showing the user location or if the user’s location has not yet been determined. */
@property (weak, nonatomic, readonly) CLLocation *location;

/** The heading of the user location. (read-only)
*
* This property is `nil` if the user location tracking mode is not RMUserTrackingModeFollowWithHeading`. */
@property (weak, nonatomic, readonly) CLHeading *heading;

@end
