//
//  RMFileUtils.h
//  Pods
//
//  Created by Maciej Swic on 09/10/14.
//
//

#import <Foundation/Foundation.h>

@interface RMFileUtils : NSObject

//These methods are a lot faster than NSFileManager attributesAtPath and invoked often.

+ (unsigned long long int)folderSize:(NSString *)folderPath;
+ (long long)fileSizeAtPath:(NSString*)path;
+ (NSDate *)modificationDateForFileAtPath:(NSString*)path;

@end
