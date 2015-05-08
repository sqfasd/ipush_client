//
//  XCAutoReconnect.h
//  xcomet
//
//  Created by kimziv on 15/5/8.
//  Copyright (c) 2015年 kimziv. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GCNetworkReachability.h"

@interface XCAutoReconnect : NSObject

@property(assign,readonly)BOOL isReachable;
-(void)startMonitoringWithHostName:(NSString *)hostName withHandler:(void(^)(GCNetworkReachabilityStatus status))handler;
-(void)stopMonitoring;
@end
