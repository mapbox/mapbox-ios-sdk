///
//  RMShape.m
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

#import "RMShape.h"
#import "RMPixel.h"
#import "RMProjection.h"
#import "RMMapView.h"
#import "RMAnnotation.h"

@implementation RMShape
{
    BOOL isFirstPoint, ignorePathUpdates;
    float lastScale;

    CGRect nonClippedBounds;
    CGRect previousBounds;

    NSMutableArray *layers;
    CAShapeLayer *currentLayer;
    
    NSMutableArray *paths;
    UIBezierPath *currentPath;

    RMMapView *mapView;
}

@synthesize scaleLineWidth;
@synthesize lineDashLengths;
@synthesize scaleLineDash;
@synthesize shadowBlur;
@synthesize shadowOffset;
@synthesize enableShadow;
@synthesize pathBoundingBox;

#define kDefaultLineWidth 2.0

- (id)initWithView:(RMMapView *)aMapView
{
    if (!(self = [super init]))
        return nil;

    mapView = aMapView;
    
    paths = [[NSMutableArray alloc] init];
       
    lineWidth = kDefaultLineWidth;
    ignorePathUpdates = NO;
    
    layers = [[NSMutableArray alloc] init];
    
    [self newSegment];
    
    pathBoundingBox = CGRectZero;
    nonClippedBounds = CGRectZero;
    previousBounds = CGRectZero;
    lastScale = 0.0;

    self.masksToBounds = YES;

    scaleLineWidth = NO;
    scaleLineDash = NO;
    isFirstPoint = YES;

    [(id)self setValue:[[UIScreen mainScreen] valueForKey:@"scale"] forKey:@"contentsScale"];

    return self;
}

- (void) newSegment
{
    currentPath = [[UIBezierPath alloc] init];
    [paths addObject:currentPath];
    
    currentLayer = [[CAShapeLayer alloc] init];
    [layers addObject:currentLayer];
    
    currentLayer.rasterizationScale = [[UIScreen mainScreen] scale];
    currentLayer.lineWidth = lineWidth;
    currentLayer.lineCap = kCALineCapButt;
    currentLayer.lineJoin = kCALineJoinMiter;
    currentLayer.strokeColor = [UIColor blackColor].CGColor;
    currentLayer.fillColor = [UIColor clearColor].CGColor;
    currentLayer.shadowRadius = 0.0;
    currentLayer.shadowOpacity = 0.0;
    currentLayer.shadowOffset = CGSizeMake(0, 0);
    [self addSublayer:currentLayer];
}

- (void)dealloc
{
    mapView = nil;
    
    for(UIBezierPath *path in paths)
    {
        [path release];
    }
    [paths removeAllObjects]; [paths release]; paths = nil;
    
    currentPath = nil;
    
    for(CAShapeLayer *layer in layers)
    {
        [layer release];
    }
    [layers removeAllObjects]; [layers release]; layers = nil;
    
    currentLayer = nil;
    
    [super dealloc];
}

- (id <CAAction>)actionForKey:(NSString *)key
{
    return nil;
}

#pragma mark -

- (void)recalculateGeometryAnimated:(BOOL)animated
{
    if (ignorePathUpdates)
        return;
    
    NSUInteger index = 0;
    
    CGRect previousNonClippedBounds = CGRectZero;
    
    float scale = 1.0f / [mapView metersPerPixel];
    
    for(UIBezierPath *thisPath in paths)
    {
        CAShapeLayer *thisLayer = [layers objectAtIndex:index];
        index++;
        
        // we have to calculate the scaledLineWidth even if scalling did not change
        // as the lineWidth might have changed
        float scaledLineWidth;
        
        if (scaleLineWidth)
            scaledLineWidth = lineWidth * scale;
        else
            scaledLineWidth = lineWidth;
        
        thisLayer.lineWidth = scaledLineWidth;
        
        if (lineDashLengths)
        {
            if (scaleLineDash)
            {
                NSMutableArray *scaledLineDashLengths = [NSMutableArray array];
                
                for (NSNumber *lineDashLength in lineDashLengths)
                {
                    [scaledLineDashLengths addObject:[NSNumber numberWithFloat:lineDashLength.floatValue * scale]];
                }
                
                thisLayer.lineDashPattern = scaledLineDashLengths;
            }
            else
            {
                thisLayer.lineDashPattern = lineDashLengths;
            }
        }
        
        // we are about to overwrite nonClippedBounds, therefore we save the old value
        previousNonClippedBounds = nonClippedBounds;
        
        if (scale != lastScale)
        {
            CGAffineTransform scaling = CGAffineTransformMakeScale(scale, scale);
            UIBezierPath *scaledPath = [thisPath copy];
            [scaledPath applyTransform:scaling];
            
            if (animated)
            {
                CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"path"];
                animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
                animation.repeatCount = 0;
                animation.autoreverses = NO;
                animation.fromValue = (id) thisLayer.path;
                animation.toValue = (id) scaledPath.CGPath;
                [thisLayer addAnimation:animation forKey:@"animatePath"];
            }
            
            thisLayer.path = scaledPath.CGPath;
            
            // calculate the bounds of the scaled path
            CGRect boundsInMercators = scaledPath.bounds;
            CGRect bounds = CGRectInset(boundsInMercators, -scaledLineWidth - (2 * thisLayer.shadowRadius), -scaledLineWidth - (2 * thisLayer.shadowRadius));

            nonClippedBounds = CGRectUnion(nonClippedBounds, bounds);
            
            [scaledPath release];
        }
    }
    
    lastScale = scale;
    
    // if the path is not scaled, nonClippedBounds stay the same as in the previous invokation
    
    // Clip bound rect to screen bounds.
    // If bounds are not clipped, they won't display when you zoom in too much.
    
    CGRect screenBounds = [mapView frame];
    
    // we start with the non-clipped bounds and clip them
    CGRect clippedBounds = nonClippedBounds;
    
    float offset;
    const float outset = 150.0f; // provides a buffer off screen edges for when path is scaled or moved
    
    CGPoint newPosition = self.annotation.position;
    
    //    RMLog(@"x:%f y:%f screen bounds: %f %f %f %f", newPosition.x, newPosition.y,  screenBounds.origin.x, screenBounds.origin.y, screenBounds.size.width, screenBounds.size.height);
    
    // Clip top
    offset = newPosition.y + clippedBounds.origin.y - screenBounds.origin.y + outset;
    if (offset < 0.0f)
    {
        clippedBounds.origin.y -= offset;
        clippedBounds.size.height += offset;
    }
    
    // Clip left
    offset = newPosition.x + clippedBounds.origin.x - screenBounds.origin.x + outset;
    if (offset < 0.0f)
    {
        clippedBounds.origin.x -= offset;
        clippedBounds.size.width += offset;
    }
    
    // Clip bottom
    offset = newPosition.y + clippedBounds.origin.y + clippedBounds.size.height - screenBounds.origin.y - screenBounds.size.height - outset;
    if (offset > 0.0f)
    {
        clippedBounds.size.height -= offset;
    }
    
    // Clip right
    offset = newPosition.x + clippedBounds.origin.x + clippedBounds.size.width - screenBounds.origin.x - screenBounds.size.width - outset;
    if (offset > 0.0f)
    {
        clippedBounds.size.width -= offset;
    }
    
    if (animated)
    {
        CABasicAnimation *positionAnimation = [CABasicAnimation animationWithKeyPath:@"position"];
        positionAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        positionAnimation.repeatCount = 0;
        positionAnimation.autoreverses = NO;
        positionAnimation.fromValue = [NSValue valueWithCGPoint:self.position];
        positionAnimation.toValue = [NSValue valueWithCGPoint:newPosition];
        [self addAnimation:positionAnimation forKey:@"animatePosition"];
    }
    
    super.position = newPosition;
    
    // bounds are animated non-clipped but set with clipping
    
    CGPoint previousNonClippedAnchorPoint = CGPointMake(-previousNonClippedBounds.origin.x / previousNonClippedBounds.size.width,
                                                        -previousNonClippedBounds.origin.y / previousNonClippedBounds.size.height);
    CGPoint nonClippedAnchorPoint = CGPointMake(-nonClippedBounds.origin.x / nonClippedBounds.size.width,
                                                -nonClippedBounds.origin.y / nonClippedBounds.size.height);
    CGPoint clippedAnchorPoint = CGPointMake(-clippedBounds.origin.x / clippedBounds.size.width,
                                             -clippedBounds.origin.y / clippedBounds.size.height);
    
    if (animated)
    {
        CABasicAnimation *boundsAnimation = [CABasicAnimation animationWithKeyPath:@"bounds"];
        boundsAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        boundsAnimation.repeatCount = 0;
        boundsAnimation.autoreverses = NO;
        boundsAnimation.fromValue = [NSValue valueWithCGRect:previousNonClippedBounds];
        boundsAnimation.toValue = [NSValue valueWithCGRect:nonClippedBounds];
        [self addAnimation:boundsAnimation forKey:@"animateBounds"];
    }
    
    self.bounds = clippedBounds;
    previousBounds = clippedBounds;
    
    // anchorPoint is animated non-clipped but set with clipping
    if (animated)
    {
        CABasicAnimation *anchorPointAnimation = [CABasicAnimation animationWithKeyPath:@"anchorPoint"];
        anchorPointAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        anchorPointAnimation.repeatCount = 0;
        anchorPointAnimation.autoreverses = NO;
        anchorPointAnimation.fromValue = [NSValue valueWithCGPoint:previousNonClippedAnchorPoint];
        anchorPointAnimation.toValue = [NSValue valueWithCGPoint:nonClippedAnchorPoint];
        [self addAnimation:anchorPointAnimation forKey:@"animateAnchorPoint"];
    }
    
    self.anchorPoint = clippedAnchorPoint;
}

#pragma mark -

- (void)addPointToProjectedPoint:(RMProjectedPoint)point withDrawing:(BOOL)isDrawing
{
    if (isFirstPoint)
    {
        isFirstPoint = FALSE;
        projectedLocation = point;

        self.position = [mapView projectedPointToPixel:projectedLocation];

        [currentPath moveToPoint:CGPointMake(0.0f, 0.0f)];
    }
    else
    {
        point.x = point.x - projectedLocation.x;
        point.y = point.y - projectedLocation.y;

        if (isDrawing)
            [currentPath addLineToPoint:CGPointMake(point.x, -point.y)];
        else
            [currentPath moveToPoint:CGPointMake(point.x, -point.y)];

        lastScale = 0.0;
        [self recalculateGeometryAnimated:NO];
    }

    [self setNeedsDisplay];
}

- (void)moveToProjectedPoint:(RMProjectedPoint)projectedPoint
{
    [self addPointToProjectedPoint:projectedPoint withDrawing:NO];
}

- (void)moveToScreenPoint:(CGPoint)point
{
    RMProjectedPoint mercator = [mapView pixelToProjectedPoint:point];
    [self moveToProjectedPoint:mercator];
}

- (void)moveToCoordinate:(CLLocationCoordinate2D)coordinate
{
    RMProjectedPoint mercator = [[mapView projection] coordinateToProjectedPoint:coordinate];
    [self moveToProjectedPoint:mercator];
}

- (void)addLineToProjectedPoint:(RMProjectedPoint)projectedPoint
{
    [self addPointToProjectedPoint:projectedPoint withDrawing:YES];
}

- (void)addLineToScreenPoint:(CGPoint)point
{
    RMProjectedPoint mercator = [mapView pixelToProjectedPoint:point];
    [self addLineToProjectedPoint:mercator];
}

- (void)addLineToCoordinate:(CLLocationCoordinate2D)coordinate
{
    RMProjectedPoint mercator = [[mapView projection] coordinateToProjectedPoint:coordinate];
    [self addLineToProjectedPoint:mercator];
}

- (void)performBatchOperations:(void (^)(RMShape *aPath))block
{
    ignorePathUpdates = YES;
    block(self);
    ignorePathUpdates = NO;

    lastScale = 0.0;
    [self recalculateGeometryAnimated:NO];
}

#pragma mark - Accessors

- (void)closePath
{
    [currentPath closePath];
}

- (float)lineWidth
{
    return lineWidth;
}

- (void)setLineWidth:(float)newLineWidth
{
    lineWidth = newLineWidth;

    lastScale = 0.0;
    [self recalculateGeometryAnimated:NO];
}

- (NSString *)lineCap
{
    return currentLayer.lineCap;
}

- (void)setLineCap:(NSString *)newLineCap
{
    currentLayer.lineCap = newLineCap;
    [self setNeedsDisplay];
}

- (NSString *)lineJoin
{
    return currentLayer.lineJoin;
}

- (void)setLineJoin:(NSString *)newLineJoin
{
    currentLayer.lineJoin = newLineJoin;
    [self setNeedsDisplay];
}

- (UIColor *)lineColor
{
    return [UIColor colorWithCGColor:currentLayer.strokeColor];
}

- (void)setLineColor:(UIColor *)aLineColor
{
    if (currentLayer.strokeColor != aLineColor.CGColor)
    {
        currentLayer.strokeColor = aLineColor.CGColor;
        [self setNeedsDisplay];
    }
}

- (UIColor *)fillColor
{
    return [UIColor colorWithCGColor:currentLayer.fillColor];
}

- (void)setFillColor:(UIColor *)aFillColor
{
    if (currentLayer.fillColor != aFillColor.CGColor)
    {
        currentLayer.fillColor = aFillColor.CGColor;
        [self setNeedsDisplay];
    }
}

- (CGFloat)shadowBlur
{
    return currentLayer.shadowRadius;
}

- (void)setShadowBlur:(CGFloat)blur
{
    currentLayer.shadowRadius = blur;
    [self setNeedsDisplay];
}

- (CGSize)shadowOffset
{
    return currentLayer.shadowOffset;
}

- (void)setShadowOffset:(CGSize)offset
{
    currentLayer.shadowOffset = offset;
    [self setNeedsDisplay];
}

- (BOOL)enableShadow
{
    return (currentLayer.shadowOpacity > 0);
}

- (void)setEnableShadow:(BOOL)flag
{
    currentLayer.shadowOpacity   = (flag ? 1.0 : 0.0);
    currentLayer.shouldRasterize = ! flag;
    [self setNeedsDisplay];
}

- (NSString *)fillRule
{
    return currentLayer.fillRule;
}

- (void)setFillRule:(NSString *)fillRule
{
    currentLayer.fillRule = fillRule;
}

- (CGFloat)lineDashPhase
{
    return currentLayer.lineDashPhase;
}

- (void)setLineDashPhase:(CGFloat)dashPhase
{
    currentLayer.lineDashPhase = dashPhase;
}

- (void)setPosition:(CGPoint)newPosition animated:(BOOL)animated
{
    //if (CGPointEqualToPoint(newPosition, super.position) && CGRectEqualToRect(self.bounds, previousBounds))
        //return;

    [self recalculateGeometryAnimated:animated];
}

@end
