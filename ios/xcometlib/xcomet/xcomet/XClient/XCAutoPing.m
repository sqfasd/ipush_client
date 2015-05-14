//
//  XCAutoPing.m
//  xcomet
//
//  Created by kimziv on 15/5/7.
//  Copyright (c) 2015年 kimziv. All rights reserved.
//

#import "XCAutoPing.h"
#import "XCLogging.h"
// Log levels: off, error, warn, info, verbose
#if DEBUG
static  int XCLogLevel = XC_LOG_LEVEL_INFO | XC_LOG_FLAG_SEND_RECV | XC_LOG_FLAG_TRACE;
#else
static const int XCLogLevel = XC_LOG_LEVEL_WARN;
#endif

#define kDefaultPingInterval 60

@interface XCAutoPing ()
{
    dispatch_queue_t moduleQueue;
    void *moduleQueueTag;
}

@end

@implementation XCAutoPing

-(instancetype)init
{
    self=[super init];
    if (self) {
        [self commonInit];
    }
    return self;
}

-(void)dealloc
{
   // dispatch_source_cancel(pingIntervalTimer);
    if (pingIntervalTimer)
    {
        pingIntervalTimer = NULL;
    }

    moduleQueue=NULL;
}

-(void)commonInit
{
    pingInterval=kDefaultPingInterval;
    const char *moduleQueueName = "cn.xxb.push.ping";
    moduleQueue = dispatch_queue_create(moduleQueueName, NULL);
    moduleQueueTag = &moduleQueueTag;
    dispatch_queue_set_specific(moduleQueue, moduleQueueTag, moduleQueueTag, NULL);
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Properties
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (NSTimeInterval)pingInterval
{
    if (dispatch_get_specific(moduleQueueTag))
    {
        return pingInterval;
    }
    else
    {
        __block NSTimeInterval result;
        
        dispatch_sync(moduleQueue, ^{
            result = pingInterval;
        });
        return result;
    }
}

- (void)setPingInterval:(NSTimeInterval)interval
{
    dispatch_block_t block = ^{
        
        if (pingInterval != interval)
        {
            pingInterval = interval;
            
            // Update the pingTimer.
            //
            // Depending on new value and current state of the pingTimer,
            // this may mean starting, stoping, or simply updating the timer.
            
//            if (pingInterval > 0)
//            {
//                    [self startPingIntervalTimer];
//            }
//            else
//            {
//                [self stopPingIntervalTimer];
//            }
        }
    };
    
    if (dispatch_get_specific(moduleQueueTag))
        block();
    else
        dispatch_async(moduleQueue, block);
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Ping Interval
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


- (void)startPingIntervalTimerWithHandler:(void(^)())handler
{
    XCLogTrace();
    
    if (pingInterval <= 0)
    {
        // Pinger is disabled
        return;
    }
    
    if (pingIntervalTimer == NULL)
    {
        pingIntervalTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, moduleQueue);
        dispatch_source_set_timer(pingIntervalTimer, DISPATCH_TIME_NOW, pingInterval * NSEC_PER_SEC, 0.0 * NSEC_PER_SEC);
        dispatch_source_set_event_handler(pingIntervalTimer, ^{@autoreleasepool {
            //[self handlePingIntervalTimerFire];
            if (handler) {
                handler();
            }
        }});
        dispatch_resume(pingIntervalTimer);
    }
//    dispatch_source_set_event_handler(pingIntervalTimer, ^{@autoreleasepool {
//        //[self handlePingIntervalTimerFire];
//        if (handler) {
//            handler();
//        }
//    }});
}

- (void)stopPingIntervalTimer
{
    //XMPPLogTrace();
    dispatch_source_cancel(pingIntervalTimer);
    if (pingIntervalTimer)
    {
#if !OS_OBJECT_USE_OBJC
        dispatch_release(pingIntervalTimer);
#endif
        pingIntervalTimer = NULL;
    }
}
@end
