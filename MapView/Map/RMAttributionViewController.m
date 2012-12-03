//
//  RMAttributionViewController.m
//  MapView
//
//  Created by Justin Miller on 6/19/12.
//  Copyright (c) 2012 MapBox / Development Seed. All rights reserved.
//

#import "RMAttributionViewController.h"

#import "RMMapView.h"
#import "RMTileSource.h"

@interface RMMapView (RMAttributionViewControllerPrivate)

@property (nonatomic, assign) UIViewController *viewControllerPresentingAttribution;

@end

#pragma mark -

@implementation RMAttributionViewController
{
    RMMapView *_mapView;
}

- (id)initWithMapView:(RMMapView *)mapView
{
    self = [super initWithNibName:nil bundle:nil];
    
    if (self)
    {
        _mapView = mapView;

        self.view.backgroundColor = [UIColor darkGrayColor];
        
        [self.view addGestureRecognizer:[[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissModalViewControllerAnimated:)] autorelease]];
        
        UIWebView *webView = [[[UIWebView alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height - 70, self.view.bounds.size.width, 60)] autorelease];
        
        webView.delegate = self;
        
        webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;

        webView.backgroundColor = [UIColor clearColor];
        webView.opaque = NO;
        
        
        if ([webView respondsToSelector:@selector(scrollView) ]) {
            /* >= iOS5 */
            webView.scrollView.bounces = NO;
        } else {
            /* < iOS5 */
            for (id subview in webView.subviews) {
                if ([[subview class] isSubclassOfClass:[UIScrollView class]])
                    ((UIScrollView *)subview).bounces = NO;
            }
        }

        NSMutableString *attribution = [NSMutableString string];

        for (id <RMTileSource>tileSource in mapView.tileSources)
        {
            if ([tileSource respondsToSelector:@selector(shortAttribution)])
            {
                if ([attribution length])
                    [attribution appendString:@" "];

                if ([tileSource shortAttribution])
                    [attribution appendString:[tileSource shortAttribution]];
            }
        }
        
        if ( ! [attribution length])
              [attribution setString:@"Map data © OpenStreetMap contributors <a href=\"http://mapbox.com/about/maps/\">(Details)</a>"];
        
        NSMutableString *contentString = [NSMutableString string];

        [contentString appendString:@"<style type='text/css'>"];
        [contentString appendString:@"a:link {  color: white; text-decoration: none; }"];
        [contentString appendString:@"body { color: lightgray; font-family: Helvetica, Arial, Verdana, sans-serif; text-align: center; }"];
        [contentString appendString:@"</style>"];
        [contentString appendString:attribution];
        
        [webView loadHTMLString:contentString baseURL:nil];
                
        [self.view addSubview:webView];
    }
    
    return self;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return [_mapView.viewControllerPresentingAttribution shouldAutorotateToInterfaceOrientation:interfaceOrientation];
}

#pragma mark -

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    if (navigationType == UIWebViewNavigationTypeLinkClicked)
    {
        [[UIApplication sharedApplication] openURL:request.URL];
        
        [self performSelector:@selector(dismissModalViewControllerAnimated:) withObject:[NSNumber numberWithBool:YES] afterDelay:0];
    }
    
    return [[request.URL scheme] isEqualToString:@"about"];
}

@end
