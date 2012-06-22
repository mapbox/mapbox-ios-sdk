//
//  RMMapLayer.m
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

#import "RMMapLayer.h"
#import "RMPixel.h"

@implementation RMMapLayer

@synthesize annotation;
@synthesize projectedLocation;
@synthesize enableDragging;
@synthesize userInfo;

@synthesize label;
@synthesize textForegroundColor;
@synthesize textBackgroundColor;

+ (UIFont *)defaultFont
{
    return [UIFont systemFontOfSize:15];
}

- (id)init
{
	if (!(self = [super init]))
		return nil;

    self.annotation = nil;
    self.enableDragging = NO;

	return self;
}

- (id)initWithLayer:(id)layer
{
    if (!(self = [super initWithLayer:layer]))
        return nil;

    self.annotation = nil;
    self.userInfo = nil;

    return self;
}

- (void)dealloc
{
    self.annotation = nil;
    self.userInfo = nil;
    [super dealloc];
}

/// return nil for certain animation keys to block core animation
//- (id <CAAction>)actionForKey:(NSString *)key
//{
//    if ([key isEqualToString:@"position"] || [key isEqualToString:@"bounds"])
//        return nil;
//    else
//        return [super actionForKey:key];
//}

- (void)setLabel:(UIView *)aView
{
    if (label == aView)
        return;
    
    if (label != nil)
    {
        [[label layer] removeFromSuperlayer];
        [label release]; label = nil;
    }
    
    if (aView != nil)
    {
        label = [aView retain];
        [self addSublayer:[label layer]];
    }
}

- (void)changeLabelUsingText:(NSString *)text
{
    CGPoint position = CGPointMake([self bounds].size.width / 2 - [text sizeWithFont:[RMMapLayer defaultFont]].width / 2, 4);
    [self changeLabelUsingText:text position:position font:[RMMapLayer defaultFont] foregroundColor:[self textForegroundColor] backgroundColor:[self textBackgroundColor]];
}

- (void)changeLabelUsingText:(NSString*)text position:(CGPoint)position
{
    [self changeLabelUsingText:text position:position font:[RMMapLayer defaultFont] foregroundColor:[self textForegroundColor] backgroundColor:[self textBackgroundColor]];
}

- (void)changeLabelUsingText:(NSString *)text font:(UIFont *)font foregroundColor:(UIColor *)textColor backgroundColor:(UIColor *)backgroundColor
{
    CGPoint position = CGPointMake([self bounds].size.width / 2 - [text sizeWithFont:font].width / 2, 4);
    [self setTextForegroundColor:textColor];
    [self setTextBackgroundColor:backgroundColor];
    [self changeLabelUsingText:text  position:position font:font foregroundColor:textColor backgroundColor:backgroundColor];
}

- (void)changeLabelUsingText:(NSString *)text position:(CGPoint)position font:(UIFont *)font foregroundColor:(UIColor *)textColor backgroundColor:(UIColor *)backgroundColor
{
    CGSize textSize = [text sizeWithFont:font];
    CGRect frame = CGRectMake(position.x, position.y, textSize.width+4, textSize.height+4);
    
    UILabel *aLabel = [[UILabel alloc] initWithFrame:frame];
    [self setTextForegroundColor:textColor];
    [self setTextBackgroundColor:backgroundColor];
    [aLabel setNumberOfLines:0];
    [aLabel setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
    [aLabel setBackgroundColor:backgroundColor];
    [aLabel setTextColor:textColor];
    [aLabel setFont:font];
    [aLabel setTextAlignment:UITextAlignmentCenter];
    [aLabel setText:text];
    
    [self setLabel:aLabel];
    [aLabel release];
}

- (void)toggleLabel
{
    if (self.label == nil)
        return;
    
    if ([self.label isHidden])
        [self showLabel];
    else
        [self hideLabel];
}

- (void)showLabel
{
    if ([self.label isHidden])
    {
        // Using addSublayer will animate showing the label, whereas setHidden is not animated
        [self addSublayer:[self.label layer]];
        [self.label setHidden:NO];
    }
}

- (void)hideLabel
{
    if (![self.label isHidden])
    {
        // Using removeFromSuperlayer will animate hiding the label, whereas setHidden is not animated
        [[self.label layer] removeFromSuperlayer];
        [self.label setHidden:YES];
    }
}

@end
