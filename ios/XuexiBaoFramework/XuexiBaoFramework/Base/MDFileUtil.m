//
//  MDFileUtil.m
//  education
//
//  Created by Tim on 14-5-14.
//  Copyright (c) 2014年 mudi. All rights reserved.
//

#import "MDFileUtil.h"



@implementation MDFileUtil

+ (MDFileUtil *)sharedInstance
{
    static MDFileUtil *sharedFileUtil = nil;
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        sharedFileUtil = [[self alloc] init];
    });
    
    return sharedFileUtil;
}

+ (NSString *)documentFolder
{
    NSArray *documentDirectories = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    
    return [documentDirectories objectAtIndex:0];
}

+ (NSString *)cachesFolder
{
    NSArray *cacheDirectories = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    
    return [cacheDirectories objectAtIndex:0];
}


+(void)deleteFileAtPath:(NSString *)path
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        BOOL isDir=YES;
        if ([[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir] ) {
            if (!isDir) {
                NSError *error;
                [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
                if (error) {
                    MDLog(@"del file failure:%@",error.description);
                }
            }else{
                MDLog(@"del file failure:%@ %@", path, @"is dir, not a file");
            }
        }
    });
}

+ (void)renameFile:(NSString *)oriPath to:(NSString *)newPath
{
    if (!newPath || newPath.length <= 0) {
        MDLog(@"renameFile newPath invalid");
        return;
    }
    
    if (!oriPath || oriPath.length <= 0) {
        MDLog(@"renameFile oriPath invalid");
        return;
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSFileManager *fileMgr = [NSFileManager defaultManager];
        if (![fileMgr fileExistsAtPath:oriPath])
            return;
        
        NSError *error = nil;
        if (YES != [fileMgr moveItemAtPath:oriPath toPath:newPath error:&error]) {
            MDLog(@"renameFile rename failed");
        }
    });
}


- (id)init
{
    self = [super init];
    if (self) {
        
    }
    
    return self;
}

- (BOOL)saveFileContent:(id)content toPath:(NSString *)fullFolder withFileName:(NSString *)fileName
{
    if (!fileName || !fullFolder)
        return NO;
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL *isDir = nil;
    if (![fileManager fileExistsAtPath:fullFolder isDirectory:isDir]) {
        NSError *error;
        if (![fileManager createDirectoryAtPath:fullFolder withIntermediateDirectories:YES attributes:nil error:&error]) {
            MDLog(@"Create data dir fail:%@", fullFolder);
            return NO;
        }
    }
    
    NSString *fileFullPath = [fullFolder stringByAppendingPathComponent:fileName];
    if (![fileManager createFileAtPath:fileFullPath contents:content attributes:nil]) {
        NSLog(@"Create file fail: %@", fileFullPath);
        return NO;
    }
    
    return YES;
}

- (BOOL)saveFileContent:(id)content toFolder:(NSString *)folder withFileName:(NSString *)fileName
{
    if (!fileName)
        return NO;
    
    NSFileManager *fileManager = [NSFileManager defaultManager];

    NSString *dataFolder = nil;
    if (folder) {
        dataFolder = [MDFileUtil.documentFolder stringByAppendingPathComponent:folder];
    }
    else {
        dataFolder = MDFileUtil.documentFolder;
    }

    BOOL *isDir = nil;
    if (![fileManager fileExistsAtPath:dataFolder isDirectory:isDir]) {
        NSError *error;
        if (![fileManager createDirectoryAtPath:dataFolder withIntermediateDirectories:YES attributes:nil error:&error]) {
            MDLog(@"Create data dir fail:%@", dataFolder);
            return NO;
        }
    }

    NSString *fileFullPath = [dataFolder stringByAppendingPathComponent:fileName];
    if (![fileManager createFileAtPath:fileFullPath contents:content attributes:nil]) {
        NSLog(@"Create file fail: %@", fileFullPath);
        return NO;
    }

    return YES;
}

- (void)moveFileFrom:(NSString *)oriPath to:(NSString *)newPath
{
    if (!oriPath || oriPath.length <= 0 || !newPath || newPath.length <= 0)
        return;
    
    NSFileManager *fileManager = [NSFileManager defaultManager];

    if (![fileManager fileExistsAtPath:oriPath])
        return;
    
    NSError *error = nil;
    [fileManager moveItemAtPath:oriPath toPath:newPath error:&error];
}

- (void)initAccountFolder:(NSString *)userID
{
    if (!userID || [userID length] <= 0)
        return;
    
    BOOL *isDir = nil;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *dataFolder = [MDFileUtil.documentFolder stringByAppendingPathComponent:userID];

    // 创建用户文件夹
    if (![fileManager fileExistsAtPath:dataFolder isDirectory:isDir]) {
        NSError *error = nil;
        if (![fileManager createDirectoryAtPath:dataFolder withIntermediateDirectories:YES attributes:nil error:&error]) {
            MDLog(@"Create user dir fail: %@", dataFolder);
            return;
        }
    }
    
    // 后续与用户目录初始化的代码添加在此处
}

@end









