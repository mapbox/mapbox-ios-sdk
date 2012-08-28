//
//  RMPath.h
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

#import <UIKit/UIKit.h>

#import "RMFoundation.h"
#import "RMMapLayer.h"

@class RMMapView;

@interface RMPath : RMMapLayer
{
    BOOL isFirstPoint;

    // The color of the line, or the outline if a polygon
    UIColor *lineColor;
    // The color of polygon's fill.
    UIColor *fillColor;

    CGMutablePathRef path;
    CGRect pathBoundingBox;
    BOOL ignorePathUpdates;
    CGRect previousBounds;

    // Width of the line, in pixels
    float lineWidth;

    /*! Drawing mode of the path; Choices are
     kCGPathFill,
     kCGPathEOFill,
     kCGPathStroke,
     kCGPathFillStroke,
     kCGPathEOFillStroke */
    CGPathDrawingMode drawingMode;

    // Line cap and join styles
    CGLineCap lineCap;
    CGLineJoin lineJoin;

    // Line dash style
    CGFloat *_lineDashLengths;
    CGFloat *_scaledLineDashLengths;
    size_t _lineDashCount;
    CGFloat lineDashPhase;

    // Line shadow
    CGFloat shadowBlur;
    CGSize shadowOffset;
    BOOL enableShadow;

    BOOL scaleLineWidth;
    BOOL scaleLineDash; // if YES line dashes will be scaled to keep a constant size if the layer is zoomed

    float renderedScale;
    RMMapView *mapView;
}

// DEPRECATED. Use RMShape instead.
- (id)initWithView:(RMMapView *)aMapView __attribute__ ((deprecated));;

@property (nonatomic, assign) CGPathDrawingMode drawingMode;
@property (nonatomic, assign) CGLineCap lineCap;
@property (nonatomic, assign) CGLineJoin lineJoin;
@property (nonatomic, weak) NSArray *lineDashLengths;
@property (nonatomic, assign) CGFloat lineDashPhase;
@property (nonatomic, assign) BOOL scaleLineDash;
@property (nonatomic, assign) float lineWidth;
@property (nonatomic, assign) BOOL	scaleLineWidth;
@property (nonatomic, assign) CGFloat shadowBlur;
@property (nonatomic, assign) CGSize shadowOffset;
@property (nonatomic, assign) BOOL enableShadow;
@property (nonatomic, strong) UIColor *lineColor;
@property (nonatomic, strong) UIColor *fillColor;
@property (nonatomic, readonly) CGRect pathBoundingBox;

- (void)moveToProjectedPoint:(RMProjectedPoint)projectedPoint;
- (void)moveToScreenPoint:(CGPoint)point;
- (void)moveToCoordinate:(CLLocationCoordinate2D)coordinate;

- (void)addLineToProjectedPoint:(RMProjectedPoint)projectedPoint;
- (void)addLineToScreenPoint:(CGPoint)point;
- (void)addLineToCoordinate:(CLLocationCoordinate2D)coordinate;

// Change the path without recalculating the geometry (performance!)
- (void)performBatchOperations:(void (^)(RMPath *aPath))block;

// This closes the path, connecting the last point to the first.
// After this action, no further points can be added to the path.
// There is no requirement that a path be closed.
- (void)closePath;

@end
