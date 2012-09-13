//
//  RMUserTrackingBarButtonItem.m
//  MapView
//
//  Created by Justin Miller on 5/10/12.
//  Copyright (c) 2012 MapBox / Development Seed. All rights reserved.
//

#import "RMUserTrackingBarButtonItem.h"

#import "RMMapView.h"
#import "RMUserLocation.h"

typedef enum {
    RMUserTrackingButtonStateActivity = 0,
    RMUserTrackingButtonStateLocation = 1,
    RMUserTrackingButtonStateHeading  = 2
} RMUserTrackingButtonState;

@interface RMUserTrackingBarButtonItem ()

@property (nonatomic, retain) UISegmentedControl *segmentedControl;
@property (nonatomic, retain) UIImageView *buttonImageView;
@property (nonatomic, retain) UIActivityIndicatorView *activityView;
@property (nonatomic, assign) RMUserTrackingButtonState state;

- (void)createBarButtonItem;
- (void)updateAppearance;
- (void)changeMode:(id)sender;

@end

#pragma mark -

@implementation RMUserTrackingBarButtonItem

@synthesize mapView = _mapView;
@synthesize segmentedControl = _segmentedControl;
@synthesize buttonImageView = _buttonImageView;
@synthesize activityView = _activityView;
@synthesize state = _state;

- (id)initWithMapView:(RMMapView *)mapView
{
    if ( ! (self = [super initWithCustomView:[[UIControl alloc] initWithFrame:CGRectMake(0, 0, 32, 32)]]))
        return nil;

    [self createBarButtonItem];
    [self setMapView:mapView];

    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if ( ! (self = [super initWithCoder:aDecoder]))
        return nil;

    [self setCustomView:[[UIControl alloc] initWithFrame:CGRectMake(0, 0, 32, 32)]];

    [self createBarButtonItem];

    return self;
}

- (void)createBarButtonItem
{
    _segmentedControl = [[[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObject:@""]] retain];
    _segmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;
    [_segmentedControl setWidth:32.0 forSegmentAtIndex:0];
    _segmentedControl.userInteractionEnabled = NO;
    _segmentedControl.tintColor = self.tintColor;
    _segmentedControl.center = self.customView.center;

    [self.customView addSubview:_segmentedControl];

    _buttonImageView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"TrackingLocation.png"]] retain];
    _buttonImageView.contentMode = UIViewContentModeCenter;
    _buttonImageView.frame = CGRectMake(0, 0, 32, 32);
    _buttonImageView.center = self.customView.center;
    _buttonImageView.userInteractionEnabled = NO;

    [self.customView addSubview:_buttonImageView];

    _activityView = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite] retain];
    _activityView.hidesWhenStopped = YES;
    _activityView.center = self.customView.center;
    _activityView.userInteractionEnabled = NO;

    [self.customView addSubview:_activityView];

    [((UIControl *)self.customView) addTarget:self action:@selector(changeMode:) forControlEvents:UIControlEventTouchUpInside];

    _state = RMUserTrackingButtonStateLocation;
}

- (void)dealloc
{
    [_segmentedControl release]; _segmentedControl = nil;
    [_buttonImageView release]; _buttonImageView = nil;
    [_activityView release]; _activityView = nil;
    [_mapView removeObserver:self forKeyPath:@"userTrackingMode"];
    [_mapView removeObserver:self forKeyPath:@"userLocation.location"];
    [_mapView release]; _mapView = nil;
    
    [super dealloc];
}

#pragma mark -

- (void)setMapView:(RMMapView *)newMapView
{
    if ( ! [newMapView isEqual:_mapView])
    {
        [_mapView removeObserver:self forKeyPath:@"userTrackingMode"];
        [_mapView removeObserver:self forKeyPath:@"userLocation.location"];
        [_mapView release];

        _mapView = [newMapView retain];
        [_mapView addObserver:self forKeyPath:@"userTrackingMode"      options:NSKeyValueObservingOptionNew context:nil];
        [_mapView addObserver:self forKeyPath:@"userLocation.location" options:NSKeyValueObservingOptionNew context:nil];

        [self updateAppearance];
    }
}

- (void)setTintColor:(UIColor *)newTintColor
{
    [super setTintColor:newTintColor];

    _segmentedControl.tintColor = newTintColor;
}

#pragma mark -

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    [self updateAppearance];
}

#pragma mark -

- (void)updateAppearance
{
    // "selection" state
    //
    _segmentedControl.selectedSegmentIndex = (_mapView.userTrackingMode == RMUserTrackingModeNone ? UISegmentedControlNoSegment : 0);

    // activity/image state
    //
    if (_mapView.userTrackingMode != RMUserTrackingModeNone && ( ! _mapView.userLocation || ! _mapView.userLocation.location || (_mapView.userLocation.location.coordinate.latitude == 0 && _mapView.userLocation.location.coordinate.longitude == 0)))
    {
        // if we should be tracking but don't yet have a location, show activity
        //
        [UIView animateWithDuration:0.25
                              delay:0.0
                            options:UIViewAnimationOptionBeginFromCurrentState
                         animations:^(void)
                         {
                             _buttonImageView.transform = CGAffineTransformMakeScale(0.01, 0.01);
                             _activityView.transform    = CGAffineTransformMakeScale(0.01, 0.01);
                         }
                         completion:^(BOOL finished)
                         {
                             _buttonImageView.hidden = YES;

                             [_activityView startAnimating];

                             [UIView animateWithDuration:0.25 animations:^(void)
                             {
                                 _buttonImageView.transform = CGAffineTransformIdentity;
                                 _activityView.transform    = CGAffineTransformIdentity;
                             }];
                         }];

        _state = RMUserTrackingButtonStateActivity;
    }
    else
    {
        if ((_mapView.userTrackingMode != RMUserTrackingModeFollowWithHeading && _state != RMUserTrackingButtonStateLocation) ||
            (_mapView.userTrackingMode == RMUserTrackingModeFollowWithHeading && _state != RMUserTrackingButtonStateHeading))
        {
            // if image state doesn't match mode, update it
            //
            [UIView animateWithDuration:0.25
                                  delay:0.0
                                options:UIViewAnimationOptionBeginFromCurrentState
                             animations:^(void)
                             {
                                 _buttonImageView.transform = CGAffineTransformMakeScale(0.01, 0.01);
                                 _activityView.transform    = CGAffineTransformMakeScale(0.01, 0.01);
                             }
                             completion:^(BOOL finished)
                             {
                                 _buttonImageView.image  = [UIImage imageNamed:(_mapView.userTrackingMode == RMUserTrackingModeFollowWithHeading ? @"TrackingHeading.png" : @"TrackingLocation.png")];
                                 _buttonImageView.hidden = NO;

                                 [_activityView stopAnimating];

                                 [UIView animateWithDuration:0.25 animations:^(void)
                                 {
                                     _buttonImageView.transform = CGAffineTransformIdentity;
                                     _activityView.transform    = CGAffineTransformIdentity;
                                 }];
                             }];

            _state = (_mapView.userTrackingMode == RMUserTrackingModeFollowWithHeading ? RMUserTrackingButtonStateHeading : RMUserTrackingButtonStateLocation);
        }
    }
}

- (void)changeMode:(id)sender
{
    if (_mapView)
    {
        switch (_mapView.userTrackingMode)
        {
            case RMUserTrackingModeNone:
            default:
            {
                _mapView.userTrackingMode = RMUserTrackingModeFollow;
                
                break;
            }
            case RMUserTrackingModeFollow:
            {
                if ([CLLocationManager headingAvailable])
                    _mapView.userTrackingMode = RMUserTrackingModeFollowWithHeading;
                else
                    _mapView.userTrackingMode = RMUserTrackingModeNone;

                break;
            }
            case RMUserTrackingModeFollowWithHeading:
            {
                _mapView.userTrackingMode = RMUserTrackingModeNone;

                break;
            }
        }
    }

    [self updateAppearance];
}

@end
