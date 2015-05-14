//
//  XCModule.h
//  xcomet
//
//  Created by kimziv on 15/5/7.
//  Copyright (c) 2015年 kimziv. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GCDMulticastDelegate.h"
@class XClient;
@interface XCModule : NSObject
{
    XClient *xmppStream;
    
    dispatch_queue_t moduleQueue;
    void *moduleQueueTag;
    
    id multicastDelegate;
}

@property (readonly) dispatch_queue_t moduleQueue;
@property (readonly) void *moduleQueueTag;

@property (strong, readonly) XClient *xmppStream;

- (id)init;
- (id)initWithDispatchQueue:(dispatch_queue_t)queue;

- (BOOL)activate:(XClient *)aXmppStream;
- (void)deactivate;

- (void)addDelegate:(id)delegate delegateQueue:(dispatch_queue_t)delegateQueue;
- (void)removeDelegate:(id)delegate delegateQueue:(dispatch_queue_t)delegateQueue;
- (void)removeDelegate:(id)delegate;

- (NSString *)moduleName;
@end
