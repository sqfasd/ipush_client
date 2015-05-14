//
//  MDFileUtil.h
//  education
//
//  Created by Tim on 14-5-14.
//  Copyright (c) 2014年 mudi. All rights reserved.
//


#import <Foundation/Foundation.h>



@interface MDFileUtil : NSObject

+ (MDFileUtil *)sharedInstance;
+ (NSString *)documentFolder;
+ (NSString *)cachesFolder;
+ (void)deleteFileAtPath:(NSString *)path;
+ (void)renameFile:(NSString *)oriPath to:(NSString *)newPath;

- (BOOL)saveFileContent:(id)content toPath:(NSString *)fullFolder withFileName:(NSString *)fileName;
- (BOOL)saveFileContent:(id)content toFolder:(NSString *)folder withFileName:(NSString *)fileName;

- (void)moveFileFrom:(NSString *)oriPath to:(NSString *)newPath;

- (void)initAccountFolder:(NSString *)userID;

@end
