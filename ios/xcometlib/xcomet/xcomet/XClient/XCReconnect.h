//
//  XCReconnect.h
//  xcomet
//
//  Created by kimziv on 15/5/7.
//  Copyright (c) 2015年 kimziv. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import "XCModule.h"

#define _XMPP_RECONNECT_H

#define DEFAULT_XMPP_RECONNECT_DELAY 2.0

#define DEFAULT_XMPP_RECONNECT_TIMER_INTERVAL 20.0


@protocol XCReconnectDelegate;
@interface XCReconnect : XCModule
{
    Byte flags;
    Byte config;
    NSTimeInterval reconnectDelay;
    
    dispatch_source_t reconnectTimer;
    NSTimeInterval reconnectTimerInterval;
    
    SCNetworkReachabilityRef reachability;
    
    int reconnectTicket;

    SCNetworkReachabilityFlags previousReachabilityFlags;
}

/**
 * Whether auto reconnect is enabled or disabled.
 *
 * The default value is YES (enabled).
 *
 * Note: Altering this property will only affect future accidental disconnections.
 * For example, if autoReconnect was true, and you disable this property after an accidental disconnection,
 * this will not stop the current reconnect process.
 * In order to stop a current reconnect process use the stop method.
 *
 * Similarly, if autoReconnect was false, and you enable this property after an accidental disconnection,
 * this will not start a reconnect process.
 * In order to start a reconnect process use the manualStart method.
 **/
@property (nonatomic, assign) BOOL autoReconnect;

/**
 * When the accidental disconnection first happens,
 * a short delay may be used before attempting the reconnection.
 *
 * The default value is DEFAULT_XMPP_RECONNECT_DELAY (defined at the top of this file).
 *
 * To disable this feature, set the value to zero.
 *
 * Note: NSTimeInterval is a double that specifies the time in seconds.
 **/
@property (nonatomic, assign) NSTimeInterval reconnectDelay;

/**
 * A reconnect timer may optionally be used to attempt a reconnect periodically.
 * The timer will be started after the initial reconnect delay.
 *
 * The default value is DEFAULT_XMPP_RECONNECT_TIMER_INTERVAL (defined at the top of this file).
 *
 * To disable this feature, set the value to zero.
 *
 * Note: NSTimeInterval is a double that specifies the time in seconds.
 **/
@property (nonatomic, assign) NSTimeInterval reconnectTimerInterval;

/**
 * Whether you want to reconnect using the legacy method -[XMPPStream oldSchoolSecureConnectWithTimeout:error:]
 * instead of the standard -[XMPPStream connect:].
 *
 * If you initially connect using -oldSchoolSecureConnectWithTimeout:error:, set this to YES to reconnect the same way.
 *
 * The default value is NO (disabled).
 */
@property (nonatomic, assign) BOOL usesOldSchoolSecureConnect;

/**
 * As opposed to using autoReconnect, this method may be used to manually start the reconnect process.
 * This may be useful, for example, if one needs network monitoring in order to setup the inital xmpp connection.
 * Or if one wants autoReconnect but only in very limited situations which they prefer to control manually.
 *
 * After invoking this method one can expect the class to act as if an accidental disconnect just occurred.
 * That is, a reconnect attempt will be tried after reconnectDelay seconds,
 * and the class will begin monitoring the network for changes in reachability to the xmpp host.
 *
 * A manual start of the reconnect process will effectively end once the xmpp stream has been opened.
 * That is, if you invoke manualStart and the xmpp stream is later opened,
 * then future disconnections will not result in an auto reconnect process (unless the autoReconnect property applies).
 *
 * This method does nothing if the xmpp stream is not disconnected.
 **/
- (void)manualStart;

/**
 * Stops the current reconnect process.
 *
 * This method will stop the current reconnect process regardless of whether the
 * reconnect process was started due to the autoReconnect property or due to a call to manualStart.
 *
 * Stopping the reconnect process does NOT prevent future auto reconnects if the property is enabled.
 * That is, if the autoReconnect property is still enabled, and the xmpp stream is later opened, authenticated and
 * accidentally disconnected, this class will still attempt an automatic reconnect.
 *
 * Stopping the reconnect process does NOT prevent future calls to manualStart from working.
 *
 * It only stops the CURRENT reconnect process.
 **/
- (void)stop;

@end

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@protocol XCReconnectDelegate
@optional

/**
 * This method may be used to fine tune when we
 * should and should not attempt an auto reconnect.
 *
 * For example, if on the iPhone, one may want to prevent auto reconnect when WiFi is not available.
 **/


- (void)xmppReconnect:(XCReconnect *)sender didDetectAccidentalDisconnect:(SCNetworkReachabilityFlags)connectionFlags;
- (BOOL)xmppReconnect:(XCReconnect *)sender shouldAttemptAutoReconnect:(SCNetworkReachabilityFlags)reachabilityFlags;

@end
