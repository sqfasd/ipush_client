//
//  MDLogUtil.h
//  education
//
//  Created by Tim on 14-5-19.
//  Copyright (c) 2014年 mudi. All rights reserved.
//

#import <Foundation/Foundation.h>


void LogFile(NSString *strLog);


@interface MDLogUtil : NSObject

+ (id)sharedInstance;

- (void)writeLog:(NSString *)log;

@end




