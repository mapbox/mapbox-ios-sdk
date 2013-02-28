//
//  RMUserTrackingBarButtonItem.m
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

    _buttonImageView = [[[UIImageView alloc] initWithImage:[RMMapView resourceImageNamed:@"TrackingLocation.png"]] retain];
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
                                 _buttonImageView.image  = [RMMapView resourceImageNamed:(_mapView.userTrackingMode == RMUserTrackingModeFollowWithHeading ? @"TrackingHeading.png" : @"TrackingLocation.png")];
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
