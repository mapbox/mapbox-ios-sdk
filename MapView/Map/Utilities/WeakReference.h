//
//  WeakReference.h
//  MapView
//
//  Created by teejay on 2/13/13.
//
//

#import <Foundation/Foundation.h>

@interface WeakReference : NSObject
{
    __weak id nonretainedObjectValue;
    __unsafe_unretained id originalObjectValue;
}

+ (WeakReference *) weakReferenceWithObject:(id) object;

- (id) nonretainedObjectValue;
- (void *) originalObjectValue;
@end
