//
//  RMOpenMapSurferSource.m
//  MapView
//
// Copyright (c) 2008-2013, Route-Me Contributors
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

#import "RMOpenMapSurferSource.h"

@implementation RMOpenMapSurferSource

- (id)init
{
	if (!(self = [super init]))
        return nil;
    
    self.minZoom = 1;
    self.maxZoom = 18;
    
	return self;
}

- (NSURL *)URLForTile:(RMTile)tile
{
	NSAssert4(((tile.zoom >= self.minZoom) && (tile.zoom <= self.maxZoom)),
			  @"%@ tried to retrieve tile with zoomLevel %d, outside source's defined range %f to %f",
			  self, tile.zoom, self.minZoom, self.maxZoom);
    
	NSURL *url =  [NSURL URLWithString:[NSString stringWithFormat:@"http://openmapsurfer.uni-hd.de/tiles/roads/x=%d&y=%d&z=%d", tile.x, tile.y, tile.zoom]];
    return url;
}

- (NSString *)uniqueTilecacheKey
{
	return @"OpenMapSurfer";
}

- (NSString *)shortName
{
	return @"OpenMapSurfer";
}

- (NSString *)longDescription
{
	return @"OpenMapSurfer http://www.openmapsurfer.uni-hd.de/. Commercial usage of the services provided by OpenMapSurfer does need approval!";
}

- (NSString *)shortAttribution
{
	return @"© OpenMapSurfer CC-BY-SA";
}

- (NSString *)longAttribution
{
	return @"Map data © OpenMapSurfer, licensed under Creative Commons Share Alike By Attribution.";
}

@end
