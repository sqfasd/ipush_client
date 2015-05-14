//
//  XClient+Internal.h
//  xcomet
//
//  Created by kimziv on 15/5/11.
//  Copyright (c) 2015年 kimziv. All rights reserved.
//

#import "GCDAsyncSocket.h"

#import "XClientOption.h"

@class XCModule;
@class XCMessage;

typedef NS_ENUM(NSUInteger, XClientErrorCode) {
    XClientInvalidType,       // Attempting to access P2P methods in a non-P2P stream, or vice-versa
    XClientInvalidState,      // Invalid state for requested action, such as connect when already connected
    XClientInvalidProperty,   // Missing a required property, such as myJID
    XClientInvalidParameter,  // Invalid parameter, such as a nil JID
    XClientUnsupportedAction, // The server doesn't support the requested action
};

typedef NS_ENUM(NSUInteger, XClientStartTLSPolicy) {
    XClientStartTLSPolicyAllowed,   // TLS will be used if the server requires it
    XClientStartTLSPolicyPreferred, // TLS will be used if the server offers it
    XClientStartTLSPolicyRequired   // TLS will be used if the server offers it, else the stream won't connect
};


@interface XClient ()

/**
 * Connects to the configured hostName on the configured hostPort.
 **/
//- (BOOL)connectWithTimeout:(NSTimeInterval)timeout error:(NSError **)errPtr;
//- (void)disconnect;
//- (BOOL)authenticateWithUserID:(NSString *)userId password:(NSString *)password error:(NSError **)errPtr;
//-(void)sendMessage:(NSString *)content to:(NSString *)to ;

-(void)sendAck;
-(void)sendHeartbeat;



////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Module Plug-In System
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * The XMPPModule class automatically invokes these methods when it is activated/deactivated.
 **/
- (void)registerModule:(XCModule *)module;
- (void)unregisterModule:(XCModule *)module;

/**
 * Automatically registers the given delegate with all current and future registered modules of the given class.
 *
 **/
- (void)autoAddDelegate:(id)delegate delegateQueue:(dispatch_queue_t)delegateQueue toModulesOfClass:(Class)aClass;
- (void)removeAutoDelegate:(id)delegate delegateQueue:(dispatch_queue_t)delegateQueue fromModulesOfClass:(Class)aClass;

/**
 * Allows for enumeration of the currently registered modules.
 *
 * This may be useful if the client needs to be queried for modules of a particular type.
 **/
- (void)enumerateModulesWithBlock:(void (^)(XCModule *module, NSUInteger idx, BOOL *stop))block;

/**
 * Allows for enumeration of the currently registered modules that are a kind of Class.
 * idx is in relation to all modules not just those of the given class.
 **/
- (void)enumerateModulesOfClass:(Class)aClass withBlock:(void (^)(XCModule *module, NSUInteger idx, BOOL *stop))block;
@end

