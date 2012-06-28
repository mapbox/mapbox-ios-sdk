//
//  RMMarker.h
//
// Copyright (c) 2008-2009, Route-Me Contributors
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
#import "RMMapLayer.h"
#import "RMFoundation.h"

@class RMMarkerStyle;

typedef enum {
    RMMarkerMapBoxImageSizeSmall,
    RMMarkerMapBoxImageSizeMedium,
    RMMarkerMapBoxImageSizeLarge
} RMMarkerMapBoxImageSize;

/// one marker drawn on the map. Note that RMMarker ultimately descends from CALayer, and has an image contents.
/// RMMarker inherits "position" and "anchorPoint" from CALayer.
@interface RMMarker : RMMapLayer
{

}

/// returns RMMarker initialized with #image, and the default anchor point (0.5, 0.5)
- (id)initWithUIImage:(UIImage *)image;

/// \brief returns RMMarker initialized with provided image and anchorPoint. 
/// #anchorPoint x and y range from 0 to 1, normalized to the width and height of image, 
/// referenced to upper left corner, y increasing top to bottom. To put the image's upper right corner on the marker's 
/// #projectedLocation, use an anchor point of (1.0, 0.0);
- (id)initWithUIImage:(UIImage *)image anchorPoint:(CGPoint)anchorPoint;

/// fetches, caches, and uses remote MapBox marker images (default is a medium, empty, gray pin)
- (id)initWithMapBoxMarkerImage;
- (id)initWithMapBoxMarkerImage:(NSString *)symbolName;
- (id)initWithMapBoxMarkerImage:(NSString *)symbolName tintColor:(UIColor *)color;
- (id)initWithMapBoxMarkerImage:(NSString *)symbolName tintColor:(UIColor *)color size:(RMMarkerMapBoxImageSize)size;
- (id)initWithMapBoxMarkerImage:(NSString *)symbolName tintColorHex:(NSString *)colorHex;
- (id)initWithMapBoxMarkerImage:(NSString *)symbolName tintColorHex:(NSString *)colorHex sizeString:(NSString *)sizeString;

@end
