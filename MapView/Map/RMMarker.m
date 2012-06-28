//
//  RMMarker.m
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

#import "RMMarker.h"
#import "RMPixel.h"

@implementation RMMarker

#define defaultMarkerAnchorPoint CGPointMake(0.5, 0.5)

#define kCachesPath [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0]

// init
- (id)init
{
    if (!(self = [super init]))
        return nil;

    label = nil;
    textForegroundColor = [UIColor blackColor];
    textBackgroundColor = [UIColor clearColor];

    return self;
}

- (id)initWithUIImage:(UIImage *)image
{
    return [self initWithUIImage:image anchorPoint:defaultMarkerAnchorPoint];
}

- (id)initWithUIImage:(UIImage *)image anchorPoint:(CGPoint)_anchorPoint
{
    if (!(self = [self init]))
        return nil;

    self.contents = (id)[image CGImage];
    self.bounds = CGRectMake(0, 0, image.size.width, image.size.height);
    self.anchorPoint = _anchorPoint;

    self.masksToBounds = NO;
    self.label = nil;

    return self;
}

- (id)initWithMapBoxMarkerImage
{
    return [self initWithMapBoxMarkerImage:nil tintColor:nil size:RMMarkerMapBoxImageSizeMedium];
}

- (id)initWithMapBoxMarkerImage:(NSString *)symbolName
{
    return [self initWithMapBoxMarkerImage:symbolName tintColor:nil size:RMMarkerMapBoxImageSizeMedium];
}

- (id)initWithMapBoxMarkerImage:(NSString *)symbolName tintColor:(UIColor *)color
{
    return [self initWithMapBoxMarkerImage:symbolName tintColor:color size:RMMarkerMapBoxImageSizeMedium];
}

- (id)initWithMapBoxMarkerImage:(NSString *)symbolName tintColor:(UIColor *)color size:(RMMarkerMapBoxImageSize)size
{
    NSString *sizeString;
    
    switch (size)
    {
        case RMMarkerMapBoxImageSizeSmall:
            sizeString = @"small";
            break;
        
        case RMMarkerMapBoxImageSizeMedium:
        default:
            sizeString = @"medium";
            break;
        
        case RMMarkerMapBoxImageSizeLarge:
            sizeString = @"large";
            break;
    }
    
    NSString *colorHex;
    
    if (color)
    {
        CGFloat red, green, blue, alpha;

        if ([color getRed:&red green:&green blue:&blue alpha:&alpha])
            colorHex = [NSString stringWithFormat:@"%02x%02x%02x", ((NSUInteger)red * 255), ((NSUInteger)green * 255), ((NSUInteger)blue * 255)];
    }
    
    return [self initWithMapBoxMarkerImage:symbolName tintColorHex:colorHex sizeString:sizeString];
}

- (id)initWithMapBoxMarkerImage:(NSString *)symbolName tintColorHex:(NSString *)colorHex
{
    return [self initWithMapBoxMarkerImage:symbolName tintColorHex:colorHex sizeString:@"medium"];
}

- (id)initWithMapBoxMarkerImage:(NSString *)symbolName tintColorHex:(NSString *)colorHex sizeString:(NSString *)sizeString
{
    NSURL *imageURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://a.tiles.mapbox.com/v3/marker/pin-%@%@%@.png", 
                                               (sizeString ? [sizeString substringToIndex:1] : @"m"), 
                                               (symbolName ? [@"-" stringByAppendingString:symbolName] : nil), 
                                               (colorHex   ? [@"+" stringByAppendingString:[colorHex stringByReplacingOccurrencesOfString:@"#" withString:@""]] : nil)]];
    
    UIImage *image;
    
    NSString *cachePath = [NSString stringWithFormat:@"%@/%@", kCachesPath, [imageURL lastPathComponent]];
    
    if ((image = [UIImage imageWithContentsOfFile:cachePath]) && image)
        return [self initWithUIImage:image];
    
    [[NSFileManager defaultManager] createFileAtPath:cachePath contents:[NSData dataWithContentsOfURL:imageURL] attributes:nil];
    
    return [self initWithUIImage:[UIImage imageWithContentsOfFile:cachePath]];
}

- (void)dealloc
{
    self.label = nil;
    self.textForegroundColor = nil;
    self.textBackgroundColor = nil;
    [super dealloc];
}

#pragma mark -

- (void)replaceUIImage:(UIImage *)image
{
    [self replaceUIImage:image anchorPoint:defaultMarkerAnchorPoint];
}

- (void)replaceUIImage:(UIImage *)image anchorPoint:(CGPoint)_anchorPoint
{
    self.contents = (id)[image CGImage];
    self.bounds = CGRectMake(0, 0, image.size.width, image.size.height);
    self.anchorPoint = _anchorPoint;

    self.masksToBounds = NO;
}

@end
