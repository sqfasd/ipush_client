//
//  XCAutoReconnect.m
//  xcomet
//
//  Created by kimziv on 15/5/8.
//  Copyright (c) 2015年 kimziv. All rights reserved.
//

#import "XCAutoReconnect.h"


@interface XCAutoReconnect ()
{
    GCNetworkReachability *_reachability;
}

@end
@implementation XCAutoReconnect
@synthesize isReachable=_isReachable;

-(void)dealloc
{
    _reachability=nil;
}

-(BOOL)isReachable
{
    return _reachability.isReachable;
}

-(void)startMonitoringWithHostName:(NSString *)hostName withHandler:(void(^)(GCNetworkReachabilityStatus status))handler
{
//    if (!hostName || hostName.length==0) {
//        return;
//    }
    if (!_reachability) {
        _reachability=[GCNetworkReachability reachabilityForInternetConnection];
    }
    //[_reachability startMonitoringNetworkReachabilityWithNotification];
    [_reachability startMonitoringNetworkReachabilityWithHandler:^(GCNetworkReachabilityStatus status) {
        if (handler) {
            handler(status);
        }
    }];
}


-(void)stopMonitoring
{
    if (_reachability) {
        [_reachability stopMonitoringNetworkReachability];
    }
}


@end
