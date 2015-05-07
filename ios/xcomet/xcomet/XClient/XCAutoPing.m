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

#define kDefaultPingInterval 30

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

- (void)handlePingIntervalTimerFire
{
//    if (awaitingPingResponse) return;
//    
//    BOOL sendPing = NO;
//    
//    if (lastReceiveTime == 0)
//    {
//        sendPing = YES;
//    }
//    else
//    {
//        NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
//        NSTimeInterval elapsed = (now - lastReceiveTime);
//        
//        XMPPLogTrace2(@"%@: %@ - elapsed(%f)", [self class], THIS_METHOD, elapsed);
//        
//        sendPing = ((elapsed < 0) || (elapsed >= pingInterval));
//    }
//    
//    if (sendPing)
//    {
//        awaitingPingResponse = YES;
//        
//        if (targetJID)
//            [xmppPing sendPingToJID:targetJID withTimeout:pingTimeout];
//        else
//            [xmppPing sendPingToServerWithTimeout:pingTimeout];
//        
//        [multicastDelegate xmppAutoPingDidSendPing:self];
//    }
}

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
    
    if (pingIntervalTimer)
    {
#if !OS_OBJECT_USE_OBJC
        dispatch_release(pingIntervalTimer);
#endif
        pingIntervalTimer = NULL;
    }
}
@end
