//
//  XuexiBaoManager.m
//  XuexiBaoFramework
//
//  Created by 王俊 on 15/5/5.
//  Copyright (c) 2015年 杭州皆冠科技有限公司. All rights reserved.
//



#import "XuexiBaoManager.h"




@implementation XuexiBaoManager

+ (instancetype)sharedInstance {
    static XuexiBaoManager *mgr = nil;
    static dispatch_once_t predicate;
    
    dispatch_once(&predicate, ^{
        mgr = [[self alloc] init];
    });

    return mgr;
}


- (void)doInit {
    // 1. TalkingData统计
    [TalkingData sessionStarted:@"B3EC7279F87374F9F4856095ED0A2998" withChannelId:@"TalkingData"];
    [TalkingData setExceptionReportEnabled:NO];

}

@end




