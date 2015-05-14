//
//  MDLogUtil.m
//  education
//
//  Created by Tim on 14-5-19.
//  Copyright (c) 2014年 mudi. All rights reserved.
//

#import "MDLogUtil.h"



void LogFile(NSString *strLog)
{
    [[MDLogUtil sharedInstance] writeLog:strLog];
}



@interface MDLogUtil ()

{
    NSFileHandle *logHandle;
    NSString *logFilePath;
}

@end


@implementation MDLogUtil

+ (id)sharedInstance
{
    static MDLogUtil *sharedLogUtil = nil;
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        sharedLogUtil = [[self alloc] init];
    });
    
    return sharedLogUtil;
}

- (id)init
{
    self = [super init];
    if (self) {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        logFilePath = [MDFileUtil.documentFolder stringByAppendingPathComponent:[NSString stringWithFormat:@"/log.lg"]];
        
        logHandle = [NSFileHandle fileHandleForUpdatingAtPath:logFilePath];
        if (!logHandle) {
            [fileManager createFileAtPath:logFilePath contents:nil attributes:nil];
            logHandle = [NSFileHandle fileHandleForUpdatingAtPath:logFilePath];
        }
    }
    
    return self;
}

- (void)dealloc
{
    [logHandle closeFile];
}

- (void)writeLog:(NSString *)log
{
    if (!logHandle)
        return;

#ifdef DEBUG
    MDLog(@"%@", log);

//    NSString *finalLog = [NSString stringWithFormat:@"%@: %@\r\n", [NSDate date], log];
    NSString *finalLog = [NSString stringWithFormat:@"%@ %@\r\n", [NSDate date], log];
    
    [logHandle seekToEndOfFile];
    [logHandle writeData:[finalLog dataUsingEncoding:NSUTF8StringEncoding]];
#endif
}

@end




