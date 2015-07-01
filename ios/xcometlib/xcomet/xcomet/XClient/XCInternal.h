//
//  XCInternal.h
//  xcomet
//
//  Created by kimziv on 15/5/6.
//  Copyright (c) 2015年 kimziv. All rights reserved.
//

#ifndef xcomet_XCInternal_h
#define xcomet_XCInternal_h
#import "XCModule.h"
typedef NS_ENUM(NSInteger, XClientState) {
    STATE_XC_DISCONNECTED,
    //STATE_XC_RESOLVING_SRV,
    STATE_XC_CONNECTING,
    STATE_XC_AUTH,
    STATE_XC_CONNECTED,
};


@interface XCModule (/* Internal */)

/**
 * Used internally by methods like XMPPStream's unregisterModule:.
 * Normally removing a delegate is a synchronous operation, but due to multiple dispatch_sync operations,
 * it must occasionally be done asynchronously to avoid deadlock.
 **/
- (void)removeDelegate:(id)delegate delegateQueue:(dispatch_queue_t)delegateQueue synchronously:(BOOL)synchronously;

@end
#endif
