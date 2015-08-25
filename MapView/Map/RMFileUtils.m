//
//  RMFileUtils.m
//  Pods
//
//  Created by Maciej Swic on 09/10/14.
//
//

#import "sys/stat.h"

#import "RMFileUtils.h"

@implementation RMFileUtils

+ (unsigned long long int)folderSize:(NSString *)folderPath
{
    NSArray *filesArray = [[NSFileManager defaultManager] subpathsOfDirectoryAtPath:folderPath error:nil];
    NSEnumerator *filesEnumerator = [filesArray objectEnumerator];
    NSString *fileName;
    unsigned long long int fileSize = 0;
    
    while (fileName = [filesEnumerator nextObject]) {
        fileSize += [self fileSizeAtPath:[folderPath stringByAppendingPathComponent:fileName]];
    }
    
    return fileSize;
}

+ (long long)fileSizeAtPath:(NSString*)path
{
    long long size;
    struct stat attrib;
    
    stat([path UTF8String], &attrib);
    
    size = attrib.st_size;
    
    return size;
}

+ (NSDate *)modificationDateForFileAtPath:(NSString*)path
{
    //Return code 0 means that the file exists, ref `man access`
    if (access(path.UTF8String, F_OK) == 0) {
        struct tm* date;
        struct stat attrib;
        
        stat(path.UTF8String, &attrib);
        
        date = gmtime(&(attrib.st_mtime));
        
        NSDateComponents *comps = [[NSDateComponents alloc] init];
        [comps setSecond: date->tm_sec];
        [comps setMinute: date->tm_min];
        [comps setHour: date->tm_hour];
        [comps setDay: date->tm_mday];
        [comps setMonth: date->tm_mon + 1];
        [comps setYear: date->tm_year + 1900];
        
        NSCalendar *cal = [NSCalendar currentCalendar];
        NSDate *modificationDate = [[cal dateFromComponents:comps] dateByAddingTimeInterval:[[NSTimeZone systemTimeZone] secondsFromGMT]];
        
        return modificationDate;
    } else {
        return nil;
    }
}

+ (NSTimeInterval)ageOfFileAtPath:(NSString *)path
{
    NSDate *modificationDate = [self modificationDateForFileAtPath:path];
    
    if (modificationDate) {
        return [NSDate.date timeIntervalSinceDate:modificationDate];
    } else {
        return 0;
    }
}

@end
