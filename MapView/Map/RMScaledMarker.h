//
//  RMScaledMarker.h
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
#import "RMMapLayer.h"
#import "RMFoundation.h"

/** An RMScaledMarker object is used for simple point annotations on a map view, represented as a single image. RMScaledMarker objects do  change in size when the map view zooms in or out */
@interface RMScaledMarker : RMMapLayer
{
    // Text label, visible by default if it has content, but not required.
    UIView  *label;
    UIColor *textForegroundColor;
    UIColor *textBackgroundColor;
    
    RMMapView *mapView;
    CGSize imageSize;
}

/** @name Setting Label Properties */

/** A custom label for the marker. The label is shown when first set. */
@property (nonatomic, retain) UIView  *label;

/** The marker object's label text foreground color. */
@property (nonatomic, retain) UIColor *textForegroundColor;

/** The marker object's label text background color. */
@property (nonatomic, retain) UIColor *textBackgroundColor;

/** scale in metersPerPixel of source image */
@property (readwrite) CGFloat metersPerPixel;

/** min/max scale for image */
@property (readwrite) CGFloat minScale;
@property (readwrite) CGFloat maxScale;

/** The font used for labels when another font is not explicitly requested. The default is the system font with size `15`. */
+ (UIFont *)defaultFont;

/** @name Creating Markers With Images */

/** Initializes and returns a newly allocated marker object using the specified image.
*   @param image An image to use for the marker. */
- (id)initWithUIImage:(UIImage *)image mapView:(RMMapView*)_mapView metersPerPixel:(CGFloat) _metersPerPixel;

/** Initializes and returns a newly allocated marker object using the specified image and anchor point.
*   @param image An image to use for the marker.
*   @param anchorPoint A point representing a range from `0` to `1` in each of the height and width coordinate space, normalized to the size of the image, at which to place the image.
*   @return An initialized marker object. */
- (id)initWithUIImage:(UIImage *)image anchorPoint:(CGPoint)_anchorPoint mapView:(RMMapView*)_mapView metersPerPixel:(CGFloat) _metersPerPixel;

/** @name Altering Labels */

/** Changes the label to a UILabel with the supplied text and default marker font and using the existing text foreground and background colors. 
*   @param text The text for the label. */
- (void)changeLabelUsingText:(NSString *)text;

// changes the labelView to a UILabel with supplied #text and default marker font, positioning the text some weird way i don't understand yet. Uses existing text color/background color.
- (void)changeLabelUsingText:(NSString *)text position:(CGPoint)position;

/** Changes the label to a UILabel with the supplied text and font and using the given text foreground and background colors.
*   @param text The text for the label. 
*   @param font A font to use for the label text. 
*   @param textColor The color for the label text. 
*   @param backgroundColor The color for the label background. */
- (void)changeLabelUsingText:(NSString *)text font:(UIFont *)font foregroundColor:(UIColor *)textColor backgroundColor:(UIColor *)backgroundColor;

// changes the labelView to a UILabel with supplied #text and default marker font, changing this marker's text foreground/background colors for this and future text strings; modifies position as in #changeLabelUsingText:position.
- (void)changeLabelUsingText:(NSString *)text position:(CGPoint)position font:(UIFont *)font foregroundColor:(UIColor *)textColor backgroundColor:(UIColor *)backgroundColor;

/** @name Showing and Hiding Labels */

/** Toggle the display of the marker's label, if any. If hidden, show and if shown, hide. */
- (void)toggleLabel;

/** Show the marker's label, if any. */
- (void)showLabel;

/** Hide the marker's label, if any. */
- (void)hideLabel;

/** @name Altering Images */

/** Replace the image for a marker. 
*   @param image An image to use for the marker. */
- (void)replaceUIImage:(UIImage *)image;

/** Replace the image for a marker using a custom anchor point.
*   @param image An image to use for the marker.
*   @param anchorPoint A point representing a range from `0` to `1` in each of the height and width coordinate space, normalized to the size of the image, at which to place the image. */
- (void)replaceUIImage:(UIImage *)image anchorPoint:(CGPoint)anchorPoint;



@end
