//
//  RMTileCacheDownloadOperation.m
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

#import "RMTileCacheDownloadOperation.h"
#import "RMAbstractWebMapSource.h"
#import "RMConfiguration.h"

@interface RMTileCacheDownloadOperation ()

@property (readwrite, getter=isExecuting) BOOL executing;
@property (readwrite, getter=isFinished) BOOL finished;
@property (readwrite, getter=isCancelled) BOOL cancelled;

@end

@implementation RMTileCacheDownloadOperation {
    __weak id <RMTileSource>_source;
    __weak RMTileCache *_cache;
    void(^_completion)(NSError *);
    __weak NSURLSessionDataTask *_task;
    NSURLSession *_session;
    NSURLRequest *_request;
    NSUInteger _attempt;
}

@synthesize executing = _executing, finished = _finished, cancelled = _cancelled;

+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key
{
    NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
    
    if ([key isEqualToString:@"isExecuting"]) {
        keyPaths = [keyPaths setByAddingObject:@"executing"];
    } else if ([key isEqualToString:@"isFinished"]) {
        keyPaths = [keyPaths setByAddingObject:@"finished"];
    } else if ([key isEqualToString:@"isCancelled"]) {
        keyPaths = [keyPaths setByAddingObject:@"cancelled"];
    }
    
    return keyPaths;
}

- (instancetype)initWithTile:(RMTile)tile
               forTileSource:(id <RMTileSource>)source
                  usingCache:(RMTileCache *)cache
{
    return [self initWithTile:tile
                forTileSource:source
                   usingCache:cache
                   completion:nil];
}

- (instancetype)initWithTile:(RMTile)tile
               forTileSource:(id<RMTileSource>)source
                  usingCache:(RMTileCache *)cache
                  completion:(void (^)(NSError *))completion
{
    NSAssert([source isKindOfClass:[RMAbstractWebMapSource class]], @"only web-based tile sources are supported for downloading");
    
    if (self = [super init]) {
        _tile = tile;
        _source = source;
        _cache = cache;
        _completion = [completion copy];
        
        _session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
        _request = [self createURLRequestForURL:[(RMAbstractWebMapSource *)_source URLForTile:_tile]];
    }
    return self;
}

- (BOOL)isAsynchronous
{
    return YES;
}

- (void)start
{
    if (!_source || !_cache || [self isCancelled]) {
        self.finished = YES;
        return;
    }
    
    _attempt = 0;
    _task = [self createDataTaskForRequest:_request];
    [_task resume];
    
    self.executing = YES;
}

- (void)cancel
{
    if ([self isCancelled]) {
        return;
    }
    
    [_task cancel];
    self.cancelled = YES;
}

- (void)completeOperation
{
    self.executing = NO;
    self.finished = YES;
}

- (NSURLRequest *)createURLRequestForURL:(NSURL *)URL
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
    request.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
    request.timeoutInterval = [(RMAbstractWebMapSource *)_source requestTimeoutSeconds];
    [request setValue:[[RMConfiguration sharedInstance] userAgent] forHTTPHeaderField:@"User-Agent"];
    return request;
}

- (NSURLSessionDataTask *)createDataTaskForRequest:(NSURLRequest *)request
{
    NSUInteger retryCount = [(RMAbstractWebMapSource *)_source retryCount];
    NSURLSessionDataTask *task = [_session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error.code == NSURLErrorCancelled) {
            [self completeOperation];
        } else {
            NSError *outError = nil;
            NSInteger statusCode = [(NSHTTPURLResponse *)response statusCode];
            
            if (statusCode != 200) {
                outError = [NSError errorWithDomain:@"com.mapbox.error.http" code:statusCode userInfo:nil];
            } else if (error) {
                outError = error;
            } else if (!data) {
                outError = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorUnknown userInfo:nil];
            }
            
            if (outError && _attempt < retryCount) {
                _attempt++;
                _task = [self createDataTaskForRequest:request];
                [_task resume];
            } else {
                if (!outError) {
                     [_cache addDiskCachedImageData:data forTile:_tile withCacheKey:[_source uniqueTilecacheKey]];
                }
                
                if (_completion) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        _completion(outError);
                    });
                }
                [self completeOperation];
            }
        }
    }];
    return task;
}

@end
