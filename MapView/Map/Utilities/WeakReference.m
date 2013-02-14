//
//  WeakReference.m
//  MapView
//
//  Created by teejay on 2/13/13.
//
//

#import "WeakReference.h"

@implementation WeakReference

- (id) initWithObject:(id) object {
    if (self = [super init]) {
        nonretainedObjectValue = originalObjectValue = object;
    }
    return self;
}

+ (WeakReference *) weakReferenceWithObject:(id) object {
    return [[self alloc] initWithObject:object];
}

- (id) nonretainedObjectValue { return nonretainedObjectValue; }
- (void *) originalObjectValue { return (__bridge void *) originalObjectValue; }

// To work appropriately with NSSet
- (BOOL) isEqual:(WeakReference *) object {
    if (![object isKindOfClass:[WeakReference class]]) return NO;
    return object.originalObjectValue == self.originalObjectValue;
}

@end
