///
//  RMCircle.m
//
// Copyright (c) 2008-2012, Route-Me Contributors
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

#import "RMCircle.h"
#import "RMProjection.h"
#import "RMMapView.h"

#define kDefaultLineWidth 10.0
#define kDefaultLineColor [UIColor blackColor]
#define kDefaultFillColor [UIColor blueColor]

@interface RMCircle ()

- (void)updateCirclePathAnimated:(BOOL)animated;

@end

#pragma mark -

@implementation RMCircle

@synthesize shapeLayer;
@synthesize lineColor;
@synthesize fillColor;
@synthesize innerRadiusInMeters, radiusInMeters;
@synthesize arcStart, arcEnd;
@synthesize lineWidthInPixels;
@synthesize fullCircle;

- (id)initWithView:(RMMapView *)aMapView radiusInMeters:(CGFloat)_radiusInMeters
{
    return [self initWithView:aMapView innerRadiusInMeters:0 radiusInMeters:_radiusInMeters arcStart:0 arcEnd:2*M_PI fullCircle:TRUE];
}

- (id)initWithView:(RMMapView *)aMapView innerRadiusInMeters:(CGFloat)_innerRadiusInMeters radiusInMeters:(CGFloat)_radiusInMeters arcStart:(CGFloat) _arcStart arcEnd:(CGFloat)_arcEnd fullCircle:(BOOL)_fullCircle
{
    if (!(self = [super init]))
        return nil;

    shapeLayer = [[CAShapeLayer alloc] init];
    [self addSublayer:shapeLayer];

    mapView = aMapView;
    innerRadiusInMeters = _innerRadiusInMeters;
    radiusInMeters = _radiusInMeters;
    arcStart = _arcStart;
    arcEnd = _arcEnd;
    
    fullCircle = _fullCircle;

    lineWidthInPixels = kDefaultLineWidth;
    lineColor = kDefaultLineColor;
    fillColor = kDefaultFillColor;

    scaleLineWidth = NO;
    enableDragging = YES;

    circlePath = NULL;
    [self updateCirclePathAnimated:NO];

    return self;
}

- (void)dealloc
{
    mapView = nil;
    [shapeLayer release]; shapeLayer = nil;
    CGPathRelease(circlePath); circlePath = NULL;
    [lineColor release]; lineColor = nil;
    [fillColor release]; fillColor = nil;
    [super dealloc];
}

#pragma mark -

- (void)updateCirclePathAnimated:(BOOL)animated
{
    CGPathRelease(circlePath); circlePath = NULL;

    CGMutablePathRef newPath = CGPathCreateMutable();
    
    CGFloat latRadians = [[mapView projection] projectedPointToCoordinate:projectedLocation].latitude * M_PI / 180.0f;
    CGFloat pixelRadius = radiusInMeters / cos(latRadians) / [mapView metersPerPixel];
    //	DLog(@"Pixel Radius: %f", pixelRadius);

    CGRect rectangle = CGRectMake(self.position.x - pixelRadius,
                                  self.position.y - pixelRadius,
                                  (pixelRadius * 2),
                                  (pixelRadius * 2));

    CGFloat offset = floorf(-lineWidthInPixels / 2.0f) - 2;
    CGRect newBoundsRect = CGRectInset(rectangle, offset, offset);

    [self setBounds:newBoundsRect];

    //	DLog(@"Circle Rectangle: %f, %f, %f, %f", rectangle.origin.x, rectangle.origin.y, rectangle.size.width, rectangle.size.height);
    //	DLog(@"Bounds Rectangle: %f, %f, %f, %f", self.bounds.origin.x, self.bounds.origin.y, self.bounds.size.width, self.bounds.size.height);

    if(fullCircle)
    {
        arcStart = 0.0;
        arcEnd = 2.0*M_PI;
    }
    
    CGFloat outerRadius = radiusInMeters / [mapView metersPerPixel];
    CGFloat innerRadius = innerRadiusInMeters / [mapView metersPerPixel];
    
    CGPoint outerStart = CGPointMake(outerRadius*cos(arcStart)+self.position.x, outerRadius*sin(arcStart)+self.position.y);
    CGPoint innerEnd = CGPointMake(innerRadius*cos(arcEnd)+self.position.x, innerRadius*sin(arcEnd)+self.position.y);
        
    CGPathAddArc(newPath, NULL, self.position.x, self.position.y, outerRadius, arcStart, arcEnd, FALSE);
    
    if(fullCircle)
        CGPathMoveToPoint(newPath, NULL, innerEnd.x, innerEnd.y);
    else
        CGPathAddLineToPoint(newPath, NULL, innerEnd.x, innerEnd.y);
    
    CGPathAddArc(newPath, NULL, self.position.x, self.position.y, innerRadius, arcEnd, arcStart, TRUE);
    
    if(!fullCircle)
        CGPathAddLineToPoint(newPath, NULL, outerStart.x, outerStart.y);

    circlePath = newPath;

    // animate the path change if we're in an animation block
    //
    if (animated)
    {
        CABasicAnimation *pathAnimation = [CABasicAnimation animationWithKeyPath:@"path"];

        pathAnimation.duration  = [CATransaction animationDuration];
        pathAnimation.fromValue = [NSValue valueWithPointer:self.shapeLayer.path];
        pathAnimation.toValue   = [NSValue valueWithPointer:newPath];

        [self.shapeLayer addAnimation:pathAnimation forKey:@"animatePath"];
    }
    
    [self.shapeLayer setPath:newPath];
    [self.shapeLayer setFillColor:[fillColor CGColor]];
    [self.shapeLayer setStrokeColor:[lineColor CGColor]];
    [self.shapeLayer setLineWidth:lineWidthInPixels];
}

#pragma mark - Accessors

- (void)setLineColor:(UIColor *)newLineColor
{
    if (lineColor != newLineColor)
    {
        [lineColor release];
        lineColor = [newLineColor retain];
        [self updateCirclePathAnimated:NO];
    }
}

- (void)setFillColor:(UIColor *)newFillColor
{
    if (fillColor != newFillColor)
    {
        [fillColor release];
        fillColor = [newFillColor retain];
        [self updateCirclePathAnimated:NO];
    }
}

- (void)setRadiusInMeters:(CGFloat)newRadiusInMeters
{
    radiusInMeters = newRadiusInMeters;
    [self updateCirclePathAnimated:NO];
}

- (void)setLineWidthInPixels:(CGFloat)newLineWidthInPixels
{
    lineWidthInPixels = newLineWidthInPixels;
    [self updateCirclePathAnimated:NO];
}

- (void)setPosition:(CGPoint)position animated:(BOOL)animated
{
    [self setPosition:position];

    [self updateCirclePathAnimated:animated];
}

@end
