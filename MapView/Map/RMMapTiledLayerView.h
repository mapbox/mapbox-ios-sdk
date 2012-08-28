//
//  RMMapTiledLayerView.h
//  MapView
//
//  Created by Thomas Rasch on 17.08.11.
//  Copyright (c) 2011 Alpstein. All rights reserved.
//

#import "RMTileSource.h"

@class RMMapView;

@interface RMMapTiledLayerView : UIView

@property (nonatomic, assign) BOOL useSnapshotRenderer;

@property (weak, nonatomic, readonly) id <RMTileSource> tileSource;

- (id)initWithFrame:(CGRect)frame mapView:(RMMapView *)aMapView forTileSource:(id <RMTileSource>)aTileSource;

@end
