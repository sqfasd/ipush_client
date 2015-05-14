//
//  LOTLib.m
//  XuexiBaoFramework
//
//  Created by 王俊 on 15/5/12.
//  Copyright (c) 2015年 杭州皆冠科技有限公司. All rights reserved.
//



#import "LOTLib.h"
//#import <xcomet/xcomet.h>

#import "xcomet.h"


@interface LOTLib ()<XClientDelegate>

@property (nonatomic, strong) XClient *xClient;

@end



@implementation LOTLib

+ (instancetype)sharedInstance {
    static LOTLib *sharedlib = nil;
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        sharedlib = [[self alloc] init];
    });
    
    return sharedlib;
}

- (id)init {
    self = [super init];
    if (self) {
        
    }
    
    return self;
}

- (void)doInit {
    // 1. TalkingData统计
    [TalkingData sessionStarted:@"B3EC7279F87374F9F4856095ED0A2998" withChannelId:@"TalkingData"];
    [TalkingData setExceptionReportEnabled:NO];
    
    // 2. 初始化Push模块
    self.xClient.enableBackgroundingOnSocket = YES;
    [self.xClient addDelegate:self delegateQueue:dispatch_get_main_queue()];
}



#pragma mark --
#pragma mark -- Properties
- (XClient *)xClient {
    if (!_xClient) {
        _xClient = [[XClient alloc] init];
    }
    
    return _xClient;
}



#pragma mark --
#pragma mark -- XClientDelegate
/**
 * This method is called after the client has been connected
 * if error is nil, auzhorized successfull
 * if error is not nil, auzhorized failed.
 **/
- (void)xclientDidConnect:(XClient *)sender withError:(NSError *)error {
    
}

/**
 * This method is called after the client has reveived a message.
 **/
- (void)xclient:(XClient *)sender didReceiveMessage:(XCMessage *)message {
    
}

/**
 * This method is called after the client has reveived a message that be parsed or an err response.
 **/
- (void)xclient:(XClient *)sender didReceiveError:(NSError *)error {
    
}

/**
 * This method is called after the client is closed.
 **/
- (void)xclientDidDisconnect:(XClient *)sender withError:(NSError *)error {
    
}

@end




