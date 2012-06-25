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

@implementation RMAttributionViewController

- (id)initWithMapView:(RMMapView *)mapView
{
    return [self initWithMapView:mapView customAttributionString:nil];
}

- (id)initWithMapView:(RMMapView *)mapView customAttributionString:(NSString *)attributionString
{
    self = [super initWithNibName:nil bundle:nil];
    
    if (self)
    {
        self.view.backgroundColor = [UIColor darkGrayColor];
        
        [self.view addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissModalViewControllerAnimated:)]];
        
        UIWebView *webView = [[UIWebView alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height - 70, self.view.bounds.size.width, 60)];
        
        webView.delegate = self;
        
        webView.backgroundColor = [UIColor clearColor];
        webView.opaque = NO;
        
        NSString *attribution = [mapView.tileSource shortAttribution];
        
        if ( ! attribution)
            attribution = (attributionString ? attributionString : @"Map data © OpenStreetMap contributors, CC BY-SA <a href=\"http://mapbox.com/about/maps/\">(Details)</a>");
        
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
