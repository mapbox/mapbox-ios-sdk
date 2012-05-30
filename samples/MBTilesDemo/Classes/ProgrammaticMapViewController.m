//
//  ProgrammaticMapViewController.m
//  ProgrammaticMap
//
//  Created by Hal Mueller on 3/25/09.
//  Copyright Route-Me Contributors 2009. All rights reserved.
//

#import "ProgrammaticMapViewController.h"

#import "RMMarker.h"
#import "RMProjection.h"
#import "RMAnnotation.h"
#import "RMQuadTree.h"

#import "RMMBTilesSource.h"
#import "RMMapBoxSource.h"

@implementation ProgrammaticMapViewController
{
    BOOL showsLocalTileSource;
	CLLocationCoordinate2D center;
}

@synthesize mapView;

- (void)addMarkers
{
#define kNumberRows 1
#define kNumberColumns 9
#define kSpacing 10.0

	CLLocationCoordinate2D markerPosition;

	UIImage *redMarkerImage = [UIImage imageNamed:@"marker-red.png"];
	UIImage *blueMarkerImage = [UIImage imageNamed:@"marker-blue.png"];
	UIImage *xMarkerImage = [UIImage imageNamed:@"marker-X.png"];

	markerPosition.latitude = center.latitude - ((kNumberRows - 1)/2.0 * kSpacing);
	int i, j;
	for (i = 0; i < kNumberRows; i++)
    {
		markerPosition.longitude = center.longitude - ((kNumberColumns - 1)/2.0 * kSpacing);

		for (j = 0; j < kNumberColumns; j++)
        {
			markerPosition.longitude += kSpacing;
			NSLog(@"Add marker @ {%f,%f}", markerPosition.longitude, markerPosition.latitude);

            RMAnnotation *annotation = [RMAnnotation annotationWithMapView:self.mapView coordinate:markerPosition andTitle:[NSString stringWithFormat:@"%4.1f", markerPosition.longitude]];

            if ((markerPosition.longitude < -180) ||(markerPosition.longitude > 0))
            {
                annotation.annotationIcon = redMarkerImage;
                annotation.anchorPoint = CGPointMake(0.5, 1.0);
            }
            else
            {
                annotation.annotationIcon = blueMarkerImage;
                annotation.anchorPoint = CGPointMake(0.5, 1.0);
            }

            [self.mapView addAnnotation:annotation];

            annotation = [RMAnnotation annotationWithMapView:self.mapView coordinate:markerPosition andTitle:nil];
            annotation.annotationIcon = xMarkerImage;
            annotation.anchorPoint = CGPointMake(0.5, 0.5);

            [self.mapView addAnnotation:annotation];
		}

		markerPosition.latitude += kSpacing;
	}
}

- (void)viewDidLoad
{
	NSLog(@"viewDidLoad");
    [super viewDidLoad];

    center.latitude = 47.5635;
	center.longitude = 10.20981;

    showsLocalTileSource = YES;

    NSURL *tilesURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"control-room-0.2.0" ofType:@"mbtiles"]];
    RMMBTilesSource *tileSource = [[[RMMBTilesSource alloc] initWithTileSetURL:tilesURL] autorelease];

	self.mapView = [[[RMMapView alloc] initWithFrame:CGRectMake(10, 20, 300, 340)
                                       andTilesource:tileSource
                                    centerCoordinate:center
                                           zoomLevel:1.5
                                        maxZoomLevel:[tileSource maxZoom]
                                        minZoomLevel:[tileSource minZoom]
                                     backgroundImage:nil] autorelease];

    self.mapView.backgroundColor = [UIColor blackColor];
    self.mapView.delegate = self;

	[self.view addSubview:mapView];
	[self.view sendSubviewToBack:mapView];

    [self performSelector:@selector(addMarkers) withObject:nil afterDelay:0.5];
}

- (void)dealloc
{
    [self.mapView removeFromSuperview];
	self.mapView = nil;
	[super dealloc];
}

- (IBAction)swtichTilesource:(id)sender
{
    id <RMTileSource> newTileSource = nil;

    if (showsLocalTileSource)
    {
        showsLocalTileSource = NO;

        NSDictionary *info = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"geography-class" ofType:@"plist"]];
        newTileSource = [[[RMMapBoxSource alloc] initWithInfo:info] autorelease];
    }
    else
    {
        showsLocalTileSource = YES;

        NSURL *tilesURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"control-room-0.2.0" ofType:@"mbtiles"]];
        newTileSource = [[[RMMBTilesSource alloc] initWithTileSetURL:tilesURL] autorelease];
    }

    self.mapView.tileSource = newTileSource;
}

#pragma mark -
#pragma mark Delegate methods

- (RMMapLayer *)mapView:(RMMapView *)mapView layerForAnnotation:(RMAnnotation *)annotation
{
    RMMarker *marker = nil;

    if ([annotation.annotationType isEqualToString:kRMClusterAnnotationTypeName])
    {
        marker = [[[RMMarker alloc] initWithUIImage:[UIImage imageNamed:@"marker-blue.png"] anchorPoint:annotation.anchorPoint] autorelease];

        if (annotation.title)
        {
            marker.textForegroundColor = [UIColor whiteColor];
            [marker changeLabelUsingText:annotation.title];
        }
    }
    else
    {
        marker = [[[RMMarker alloc] initWithUIImage:annotation.annotationIcon anchorPoint:annotation.anchorPoint] autorelease];

        if (annotation.title)
        {
            marker.textForegroundColor = [UIColor whiteColor];
            [marker changeLabelUsingText:annotation.title];
        }
    }

    return marker;
}

@end
