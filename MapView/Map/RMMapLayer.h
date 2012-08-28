//
//  RMMapLayer.h
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

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

#import "RMFoundation.h"

@class RMAnnotation;

/** RMMapLayer is a generic class for displaying scrollable vector layers on a map view. Generally, a more specialized subclass such as RMMarker will be used for a specific purpose, but RMMapLayer can also be used directly for special purposes. */
@interface RMMapLayer : CAScrollLayer
{
    RMAnnotation *__weak annotation;

    // expressed in projected meters. The anchorPoint of the image/path/etc. is plotted here.
    RMProjectedPoint projectedLocation;

    BOOL enableDragging;

    // provided for storage of arbitrary user data
    id userInfo;
}

/** @name Configuring Map Layer Properties */

/** The annotation associated with the layer. This can be useful to inspect the annotation's userInfo in order to customize the visual representation. */
@property (nonatomic, weak) RMAnnotation *annotation;

/** The current projected location of the layer on the map. */
@property (nonatomic, assign) RMProjectedPoint projectedLocation;

/** When set to YES, the layer can be dragged by the user. */
@property (nonatomic, assign) BOOL enableDragging;

/** Storage for arbitrary data. */
@property (nonatomic, strong) id userInfo;

/** Set the screen position of the layer.
*   @param position The desired screen position.
*   @param animated If set to YES, any position change is animated. */
- (void)setPosition:(CGPoint)position animated:(BOOL)animated;

@end
