//
//  RMMapLayer.h
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

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

#import "RMFoundation.h"

@class RMAnnotation;

@interface RMMapLayer : CAScrollLayer
{
    RMAnnotation *annotation;

    /// expressed in projected meters. The anchorPoint of the image/path/etc. is plotted here.
    RMProjectedPoint projectedLocation;

    BOOL enableDragging;

    /// provided for storage of arbitrary user data
    id userInfo;
    
    /// Text label, visible by default if it has content, but not required.
    UIView  *label;
    UIColor *textForegroundColor;
    UIColor *textBackgroundColor;
}

@property (nonatomic, assign) RMAnnotation *annotation;
@property (nonatomic, assign) RMProjectedPoint projectedLocation;
@property (nonatomic, assign) BOOL enableDragging;
@property (nonatomic, retain) id userInfo;

@property (nonatomic, retain) UIView  *label;
@property (nonatomic, retain) UIColor *textForegroundColor;
@property (nonatomic, retain) UIColor *textBackgroundColor;

/// the font used for labels when another font is not explicitly requested; currently [UIFont systemFontOfSize:15]
+ (UIFont *)defaultFont;

/// changes the labelView to a UILabel with supplied #text and default marker font, using existing text foreground/background color.
- (void)changeLabelUsingText:(NSString *)text;

/// changes the labelView to a UILabel with supplied #text and default marker font, positioning the text some weird way i don't understand yet. Uses existing text color/background color.
- (void)changeLabelUsingText:(NSString *)text position:(CGPoint)position;

/// changes the labelView to a UILabel with supplied #text and default marker font, changing this marker's text foreground/background colors for this and future text strings.
- (void)changeLabelUsingText:(NSString *)text font:(UIFont *)font foregroundColor:(UIColor *)textColor backgroundColor:(UIColor *)backgroundColor;

/// changes the labelView to a UILabel with supplied #text and default marker font, changing this marker's text foreground/background colors for this and future text strings; modifies position as in #changeLabelUsingText:position.
- (void)changeLabelUsingText:(NSString *)text position:(CGPoint)position font:(UIFont *)font foregroundColor:(UIColor *)textColor backgroundColor:(UIColor *)backgroundColor;

- (void)toggleLabel;
- (void)showLabel;
- (void)hideLabel;

@end
