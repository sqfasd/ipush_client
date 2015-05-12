//
//  XCAutoPing.h
//  xcomet
//
//  Created by kimziv on 15/5/7.
//  Copyright (c) 2015年 kimziv. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface XCAutoPing : NSObject
{
@private
NSTimeInterval pingInterval;
dispatch_source_t pingIntervalTimer;
}

/**
 * How often to send a ping.
 *
 * The internal timer fires every (pingInterval / 4) seconds.
 * Upon firing it checks when data was last received from the target,
 * and sends a ping if the elapsed time has exceeded the pingInterval.
 * Thus the effective resolution of the timer is based on the configured interval.
 *
 * To temporarily disable auto-ping, set the interval to zero.
 *
 * The default pingInterval is 60 seconds.
 **/
@property (readwrite) NSTimeInterval pingInterval;

- (void)startPingIntervalTimerWithHandler:(void(^)())handler;
- (void)stopPingIntervalTimer;
@end
