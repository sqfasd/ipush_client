//
//  XClient.h
//  xcomet
//
//  Created by kimziv on 15/5/6.
//  Copyright (c) 2015年 kimziv. All rights reserved.
//

#import <Foundation/Foundation.h>

@class XCMessage;

extern  NSString *const XClientErrorDomain;
extern const NSTimeInterval XClientTimeoutNone;

@interface XClient : NSObject

/**
 * If set, the kCFStreamNetworkServiceTypeVoIP flags will be set on the underlying CFRead/Write streams.
 *
 * The default value is NO.
 **/
@property (readwrite, assign) BOOL enableBackgroundingOnSocket;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark State
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * Returns YES if the connection is closed, and thus no tcp stream is open.
 * If the client is neither disconnected, nor connected, then a connection is currently being established.
 **/
- (BOOL)isDisconnected;

/**
 * Returns YES is the connection is currently connecting
 **/
- (BOOL)isConnecting;

/**
 * Returns YES if the connection is open, and the client has been properly established.
 **/
- (BOOL)isConnected;


/**
 * hostName is ip address or domain name, if empty use default hostname internally
 **/
@property (readwrite, copy) NSString *hostName;
/**
 * hostName is host prot, if empty use default hostname internally
 **/
@property (readwrite, assign) UInt16 hostPort;

/**
 * username and password is used for authorized the valid client, can not empthy.
 **/
@property(readwrite, copy)NSString *username;
@property(readwrite, copy)NSString *password;

/**
 * Connects to the server with timeout and error out .
 * The timeout is optional. To not time out use XClientTimeoutNone.
 * If the username or password are not set, this method will return NO and set the error parameter.
 **/
- (BOOL)connectWithTimeout:(NSTimeInterval)timeout error:(NSError **)errPtr;
/**
 *  close the connection manually.
 **/
- (void)disconnect;
/**
 *  send a text message to an user
 *  to is the user ID.
 **/
-(void)sendMessage:(NSString *)content to:(NSString *)to ;




/**
 * XClient uses a multicast delegate.
 * This allows one to add multiple delegates to a single XClient instance,
 * which makes it easier to separate various components and extensions.
 **/
- (void)addDelegate:(id)delegate delegateQueue:(dispatch_queue_t)delegateQueue;
- (void)removeDelegate:(id)delegate delegateQueue:(dispatch_queue_t)delegateQueue;
- (void)removeDelegate:(id)delegate;
@end


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@protocol XClientDelegate
@optional

/**
 * This method is called after the client has been connected  
 * if error is nil, auzhorized successfull
 * if error is not nil, auzhorized failed.
 **/
- (void)xclientDidConnect:(XClient *)sender withError:(NSError *)error;
/**
 * This method is called after the client has reveived a message.
 **/
- (void)xclient:(XClient *)sender didReceiveMessage:(XCMessage *)message;
/**
 * This method is called after the client has reveived a message that be parsed or an err response.
 **/
- (void)xclient:(XClient *)sender didReceiveError:(NSError *)error;
/**
 * This method is called after the client is closed.
 **/
- (void)xclientDidDisconnect:(XClient *)sender withError:(NSError *)error;

@end