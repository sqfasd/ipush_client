//
//  XClient.m
//  xcomet
//
//  Created by kimziv on 15/5/6.
//  Copyright (c) 2015年 kimziv. All rights reserved.
//

#import "XClient.h"
#import "XCLogging.h"
#import "XCInternal.h"
#import "XCMessage.h"
#import "XCModule.h"
#import "XCAutoPing.h"
#import "XCAutoReconnect.h"
#import "XClient+Internal.h"
#import "GCDAsyncSocket.h"
// Log levels: off, error, warn, info, verbose
#if DEBUG
static  int XCLogLevel = XC_LOG_LEVEL_INFO | XC_LOG_FLAG_SEND_RECV | XC_LOG_FLAG_TRACE;
#else
static const int XCLogLevel = XC_LOG_LEVEL_WARN;
#endif

#define  DEFAULT_HOST  @"182.92.113.188"
#define  DEFAULT_PORT 9000


#define  STATUS_200 @"HTTP/1.1 200"
#define  STATUS_303 @"HTTP/1.1 303"
#define  STATUS_400 @"HTTP/1.1 400"

typedef NS_ENUM(NSInteger, HTTPStatus) {
    HTTPStatusNone=-1,
    HTTPStatus200=200,
    HTTPStatus303=303,
    HTTPStatus400=400,
    HTTPStatus500=500
};

// Define the timeouts (in seconds) for retreiving various parts of the XML stream
#define TIMEOUT_XC_WRITE         -1
#define TIMEOUT_XC_READ_START    10
#define TIMEOUT_XC_READ_STREAM   -1

// Define the tags we'll use to differentiate what it is we're currently reading or writing
#define TAG_XC_READ_START         100
#define TAG_XC_READ_STREAM        101
#define TAG_XC_WRITE_START        200
#define TAG_XC_WRITE_STOP         201
#define TAG_XC_WRITE_STREAM       202
#define TAG_XC_WRITE_RECEIPT      203

// Define the timeouts (in seconds) for SRV
#define TIMEOUT_SRV_RESOLUTION 30.0

#define return_from_block  return

NSString *const XClientErrorDomain = @"XCStreamErrorDomain";
NSString *const XCStreamDidChangeMyJIDNotification = @"XCStreamDidChangeMyJID";



const NSTimeInterval XClientTimeoutNone = -1;

//enum XCStreamFlags
//{
//    kP2PInitiator                 = 1 << 0,  // If set, we are the P2P initializer
//    kIsSecure                     = 1 << 1,  // If set, connection has been secured via SSL/TLS
//    kIsAuthenticated              = 1 << 2,  // If set, authentication has succeeded
//    kDidStartNegotiation          = 1 << 3,  // If set, negotiation has started at least once
//};

enum XCStreamConfig
{
    kP2PMode                      = 1 << 0,  // If set, the XCStream was initialized in P2P mode
    kResetByteCountPerConnection  = 1 << 1,  // If set, byte count should be reset per connection
    kEnableBackgroundingOnSocket  = 1 << 2,  // If set, the VoIP flag should be set on the socket
};


@interface XClient ()<GCDAsyncSocketDelegate>
{
    dispatch_queue_t xcQueue;
    void *xcQueueTag;
    
    dispatch_queue_t receiveMessageQueue;
    
    GCDAsyncSocket *asyncSocket;
    uint64_t numberOfBytesSent;
    uint64_t numberOfBytesReceived;
    
    Byte flags;
    Byte config;
    
    NSString *hostName;
    UInt16 hostPort;
    NSString *username;
    NSString *password;
    
    dispatch_source_t connectTimer;
    XClientState state;
    UInt32 lastSeq_;
    
    NSMutableArray *registeredModules;
    NSMutableDictionary *autoDelegateDict;
    
    GCDMulticastDelegate <XClientDelegate> *multicastDelegate;
    
    XCAutoPing *autoPing;
    XCAutoReconnect *autoReconnect;
    UIBackgroundTaskIdentifier bgTask;
    NSInteger httpStatus;
    NSString *statusDes;
}
@end

@implementation XClient


/**
 * Shared initialization between the various init methods.
 **/
- (void)commonInit
{
    xcQueueTag = &xcQueueTag;
    xcQueue = dispatch_queue_create("xclient.push", DISPATCH_QUEUE_SERIAL);
    dispatch_queue_set_specific(xcQueue, xcQueueTag, xcQueueTag, NULL);
    
    receiveMessageQueue=dispatch_queue_create("xclient.push.receive", DISPATCH_QUEUE_SERIAL);
    //
    //    didReceiveIqQueue = dispatch_queue_create("xmpp.didReceiveIq", DISPATCH_QUEUE_SERIAL);
    //
    multicastDelegate = (GCDMulticastDelegate <XClientDelegate> *)[[GCDMulticastDelegate alloc] init];
    
    state = STATE_XC_DISCONNECTED;
    httpStatus=HTTPStatusNone;
    
    flags = 0;
    config = 0;
    
    numberOfBytesSent = 0;
    numberOfBytesReceived = 0;
    
    hostName=DEFAULT_HOST;
    hostPort = DEFAULT_PORT;
    //    keepAliveInterval = DEFAULT_KEEPALIVE_INTERVAL;
    //    keepAliveData = [@" " dataUsingEncoding:NSUTF8StringEncoding];
    
    registeredModules = [[NSMutableArray alloc] init];
    autoDelegateDict = [[NSMutableDictionary alloc] init];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(ntfDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(ntfBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(ntfWillTerminate:) name:UIApplicationWillTerminateNotification object:nil];
    [self performSelector:@selector(startMonitorReconnect) withObject:nil afterDelay:3];
}

-(void)ntfDidEnterBackground:(NSNotification *)noti
{
    
    UIApplication *app = [UIApplication sharedApplication];
    
    //create new uiBackgroundTask
    bgTask = [app beginBackgroundTaskWithExpirationHandler:^{
        XCLog(@"beginBackgroundTaskWithExpirationHandler");
//        [self disconnect];
//        state=STATE_XC_DISCONNECTED;
//        [app endBackgroundTask:bgTask];
//        bgTask = UIBackgroundTaskInvalid;
    }];
    [self startPing];
}

-(void)ntfBecomeActive:(NSNotification *)noti
{
    [self startPing];
}

-(void)ntfWillTerminate:(NSNotification *)noti
{
    [self disconnect];
    state=STATE_XC_DISCONNECTED;
}

-(instancetype)init
{
    self=[super init];
    if (self) {
        [self commonInit];
        // Initialize socket
        asyncSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:xcQueue];
    }
    return self;
}


/**
 * Standard deallocation method.
 * Every object variable declared in the header file should be released here.
 **/
- (void)dealloc
{
#if !OS_OBJECT_USE_OBJC
    dispatch_release(xcQueue);
#endif
    
    [asyncSocket setDelegate:nil delegateQueue:NULL];
    [asyncSocket disconnect];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    asyncSocket=nil;
    xcQueue=nil;
    receiveMessageQueue=nil;
    autoPing=nil;
    autoReconnect=nil;
}


#pragma -- varbles

- (XClientState)state
{
    __block XClientState result = STATE_XC_DISCONNECTED;
    
    dispatch_block_t block = ^{
        result = state;
    };
    
    if (dispatch_get_specific(xcQueueTag))
        block();
    else
        dispatch_sync(xcQueue, block);
    
    return result;
}

- (NSString *)hostName
{
    if (dispatch_get_specific(xcQueueTag))
    {
        return hostName;
    }
    else
    {
        __block NSString *result;
        
        dispatch_sync(xcQueue, ^{
            result = hostName;
        });
        
        return result;
    }
}



- (void)setHostName:(NSString *)newHostName
{
    if (dispatch_get_specific(xcQueueTag))
    {
        if (hostName != newHostName)
        {
            hostName = [newHostName copy];
        }
    }
    else
    {
        NSString *newHostNameCopy = [newHostName copy];
        
        dispatch_async(xcQueue, ^{
            hostName = newHostNameCopy;
        });
        
    }
}

- (UInt16)hostPort
{
    if (dispatch_get_specific(xcQueueTag))
    {
        return hostPort;
    }
    else
    {
        __block UInt16 result;
        
        dispatch_sync(xcQueue, ^{
            result = hostPort;
        });
        
        return result;
    }
}

- (void)setHostPort:(UInt16)newHostPort
{
    dispatch_block_t block = ^{
        hostPort = newHostPort;
    };
    
    if (dispatch_get_specific(xcQueueTag))
        block();
    else
        dispatch_async(xcQueue, block);
}

-(NSString *)username
{
    if (dispatch_get_specific(xcQueueTag)) {
        return username;
    }else{
        __block NSString *result;
        dispatch_sync(xcQueue, ^{
            result=username;
        });
        return result;
    }
}

-(void)setUsername:(NSString *)newUsername
{
    dispatch_block_t block=^{
        username=newUsername;
    };
    if (dispatch_get_specific(xcQueueTag)) {
        block();
    }else{
        dispatch_async(xcQueue, block);
    }
}

-(NSString *)password
{
    if (dispatch_get_specific(xcQueueTag)) {
        return password;
    }else{
        __block NSString *result;
        dispatch_sync(xcQueue, ^{
            result=password;
        });
        return result;
    }
}

-(void)setPassword:(NSString *)newPassword
{
    dispatch_block_t block=^{
        password=newPassword;
    };
    if (dispatch_get_specific(xcQueueTag)) {
        block();
    }else{
        dispatch_async(xcQueue, block);
    }
}

#if TARGET_OS_IPHONE

- (BOOL)enableBackgroundingOnSocket
{
    __block BOOL result = NO;
    
    dispatch_block_t block = ^{
        result = (config & kEnableBackgroundingOnSocket) ? YES : NO;
    };
    
    if (dispatch_get_specific(xcQueueTag))
        block();
    else
        dispatch_sync(xcQueue, block);
    
    return result;
}

- (void)setEnableBackgroundingOnSocket:(BOOL)flag
{
    dispatch_block_t block = ^{
        if (flag)
            config |= kEnableBackgroundingOnSocket;
        else
            config &= ~kEnableBackgroundingOnSocket;
    };
    
    if (dispatch_get_specific(xcQueueTag))
        block();
    else
        dispatch_async(xcQueue, block);
}

#endif

- (uint64_t)numberOfBytesSent
{
    __block uint64_t result = 0;
    
    dispatch_block_t block = ^{
        result = numberOfBytesSent;
    };
    
    if (dispatch_get_specific(xcQueueTag))
        block();
    else
        dispatch_sync(xcQueue, block);
    
    return result;
}

- (uint64_t)numberOfBytesReceived
{
    __block uint64_t result = 0;
    
    dispatch_block_t block = ^{
        result = numberOfBytesReceived;
    };
    
    if (dispatch_get_specific(xcQueueTag))
        block();
    else
        dispatch_sync(xcQueue, block);
    
    return result;
}

- (void)getNumberOfBytesSent:(uint64_t *)bytesSentPtr numberOfBytesReceived:(uint64_t *)bytesReceivedPtr
{
    __block uint64_t bytesSent = 0;
    __block uint64_t bytesReceived = 0;
    
    dispatch_block_t block = ^{
        bytesSent = numberOfBytesSent;
        bytesReceived = numberOfBytesReceived;
    };
    
    if (dispatch_get_specific(xcQueueTag))
        block();
    else
        dispatch_sync(xcQueue, block);
    
    if (bytesSentPtr) *bytesSentPtr = bytesSent;
    if (bytesReceivedPtr) *bytesReceivedPtr = bytesReceived;
}

- (BOOL)resetByteCountPerConnection
{
    __block BOOL result = NO;
    
    dispatch_block_t block = ^{
        result = (config & kResetByteCountPerConnection) ? YES : NO;
    };
    
    if (dispatch_get_specific(xcQueueTag))
        block();
    else
        dispatch_sync(xcQueue, block);
    
    return result;
}

- (void)setResetByteCountPerConnection:(BOOL)flag
{
    dispatch_block_t block = ^{
        if (flag)
            config |= kResetByteCountPerConnection;
        else
            config &= ~kResetByteCountPerConnection;
    };
    
    if (dispatch_get_specific(xcQueueTag))
        block();
    else
        dispatch_async(xcQueue, block);
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Authentication
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * This method applies to standard password authentication schemes only.
 * This is NOT the primary authentication method.
 *
 * @see authenticate:error:
 *
 * This method exists for backwards compatibility, and may disappear in future versions.
 **/
- (BOOL)authenticateWithUserID:(NSString *)userId password:(NSString *)pwd error:(NSError **)errPtr
{
    //XMPPLogTrace();
    
    // The given password parameter could be mutable
    //NSString *password = [inPassword copy];
    
    
    __block BOOL result = YES;
    __block NSError *err = nil;
    
    dispatch_block_t block = ^{ @autoreleasepool {
        
        if (state != STATE_XC_CONNECTED)
        {
            NSString *errMsg = @"Please wait until the stream is connected.";
            NSDictionary *info = @{NSLocalizedDescriptionKey : errMsg};
            
            err = [NSError errorWithDomain:XClientErrorDomain code:XClientInvalidState userInfo:info];
            
            result = NO;
            return_from_block;
        }
        
        if (userId == nil)
        {
            NSString *errMsg = @"You must set myJID before calling authenticate:error:.";
            NSDictionary *info = @{NSLocalizedDescriptionKey : errMsg};
            
            err = [NSError errorWithDomain:XClientErrorDomain code:XClientInvalidProperty userInfo:info];
            
            result = NO;
            return_from_block;
        }
        //        char buffer[1024] = {0};
        //        int size = ::snprintf(
        //                              buffer,
        //                              sizeof(buffer),
        //                              "GET /connect?uid=%s&password=%s HTTP/1.1\r\n"
        //                              "User-Agent: mobile_socket_client/0.1.0\r\n"
        //                              "Accept: */*\r\n"
        //                              "\r\n",
        //                              userId.UTF8String,
        //                              password.UTF8String);
        NSString *authString=[NSString stringWithFormat: @"GET /connect?uid=%@&password=%@ HTTP/1.1\r\n"
                              "User-Agent: mobile_socket_client/0.1.0\r\n"
                              "Accept: */*\r\n"
                              "\r\n",userId, pwd];
        NSData *outData= [authString dataUsingEncoding:NSUTF8StringEncoding];//[NSData dataWithBytes:buffer length:size];
        [self sendData:outData];
    }};
    
    
    if (dispatch_get_specific(xcQueueTag))
        block();
    else
        dispatch_sync(xcQueue, block);
    
    if (errPtr)
        *errPtr = err;
    
    return result;
}

- (BOOL)authenticate:(NSError **)errPtr
{
    //XMPPLogTrace();
    
    // The given password parameter could be mutable
    //NSString *password = [inPassword copy];
    
    
    __block BOOL result = YES;
    __block NSError *err = nil;
    
    dispatch_block_t block = ^{ @autoreleasepool {
        
        if (state != STATE_XC_CONNECTED)
        {
            NSString *errMsg = @"Please wait until the stream is connected.";
            NSDictionary *info = @{NSLocalizedDescriptionKey : errMsg};
            
            err = [NSError errorWithDomain:XClientErrorDomain code:XClientInvalidState userInfo:info];
            
            result = NO;
            return_from_block;
        }
        
        NSString *authString=[NSString stringWithFormat: @"GET /connect?uid=%@&password=%@ HTTP/1.1\r\n"
                              "User-Agent: mobile_socket_client/0.1.0\r\n"
                              "Accept: */*\r\n"
                              "\r\n",username,password];
        NSData *outData= [authString dataUsingEncoding:NSUTF8StringEncoding];
        [self sendData:outData];
    }};
    
    
    if (dispatch_get_specific(xcQueueTag))
        block();
    else
        dispatch_sync(xcQueue, block);
    
    if (errPtr)
        *errPtr = err;
    
    return result;
}
#pragma mark Send

/**
 * This method is for use by xmpp authentication mechanism classes.
 * They should send elements using this method instead of the public sendElement methods,
 * as those methods don't send the elements while authentication is in progress.
 *
 * @see XMPPSASLAuthentication
 **/
- (void)sendData:(NSData *)data
{
    dispatch_block_t block = ^{ @autoreleasepool {
        numberOfBytesSent += [data  length];
        [asyncSocket writeData:data
                   withTimeout:TIMEOUT_XC_WRITE
                           tag:TAG_XC_WRITE_STREAM];
    }};
    
    if (dispatch_get_specific(xcQueueTag))
        block();
    else
        dispatch_async(xcQueue, block);
}

-(void)sendMessage:(NSString *)content to:(NSString *)to {
    XCLog(@"SEND: %@", content);
    XCMessage *msg=[XCMessage new];
    msg.from=username;
    msg.to=to;
    msg.type=T_MESSAGE;
    msg.body=content;
    [self sendData:[msg toPacketData]];
}

-(void)sendAck {
    XCMessage *msg=[XCMessage new];
    msg.seq=lastSeq_;
    msg.type=T_ACK;
    [self sendData:[msg toPacketData]];
}

-(void)sendHeartbeat{
    //LOG(INFO) << "SendHeartbeat";
    XCMessage *msg=[XCMessage new];
    msg.type=T_HEARTBEAT;
    [self sendData:msg.toPacketData];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Connection State
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * Returns YES if the connection is closed, and thus no stream is open.
 * If the stream is neither disconnected, nor connected, then a connection is currently being established.
 **/
- (BOOL)isDisconnected
{
    __block BOOL result = NO;
    
    dispatch_block_t block = ^{
        result = (state == STATE_XC_DISCONNECTED);
    };
    
    if (dispatch_get_specific(xcQueueTag))
        block();
    else
        dispatch_sync(xcQueue, block);
    
    return result;
}

/**
 * Returns YES is the connection is currently connecting
 **/

- (BOOL)isConnecting
{
    // XMPPLogTrace();
    
    __block BOOL result = NO;
    
    dispatch_block_t block = ^{ @autoreleasepool {
        result = (state == STATE_XC_CONNECTING);
    }};
    
    if (dispatch_get_specific(xcQueueTag))
        block();
    else
        dispatch_sync(xcQueue, block);
    
    return result;
}
/**
 * Returns YES if the connection is open, and the stream has been properly established.
 * If the stream is neither disconnected, nor connected, then a connection is currently being established.
 **/
- (BOOL)isConnected
{
    __block BOOL result = NO;
    
    dispatch_block_t block = ^{
        result = (state == STATE_XC_CONNECTED);
    };
    
    if (dispatch_get_specific(xcQueueTag))
        block();
    else
        dispatch_sync(xcQueue, block);
    
    return result;
}


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Connect Timeout
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * Start Connect Timeout
 **/
- (void)startConnectTimeout:(NSTimeInterval)timeout
{
    XCLogTrace();
    
    if (timeout >= 0.0 && !connectTimer)
    {
        connectTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, xcQueue);
        
        dispatch_source_set_event_handler(connectTimer, ^{ @autoreleasepool {
            
            [self doConnectTimeout];
        }});
        dispatch_time_t tt = dispatch_time(DISPATCH_TIME_NOW, (timeout * NSEC_PER_SEC));
        dispatch_source_set_timer(connectTimer, tt, DISPATCH_TIME_FOREVER, 0);
        
        dispatch_resume(connectTimer);
    }
}

/**
 * End Connect Timeout
 **/
- (void)endConnectTimeout
{
    //XCLogTrace();
    
    if (connectTimer)
    {
        dispatch_source_cancel(connectTimer);
        connectTimer = NULL;
    }
}

/**
 * Connect has timed out, so inform the delegates and close the connection
 **/
- (void)doConnectTimeout
{
    XCLogTrace();
    [self endConnectTimeout];
    
    if (state != STATE_XC_DISCONNECTED)
    {
        [asyncSocket disconnect];
    }
    
}



////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark C2S Connection
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (BOOL)connectToHost:(NSString *)host onPort:(UInt16)port withTimeout:(NSTimeInterval)timeout error:(NSError **)errPtr
{
    NSAssert(dispatch_get_specific(xcQueueTag), @"Invoked on incorrect queue");
    
    //XCLogTrace();
    
    BOOL result = [asyncSocket connectToHost:host onPort:port error:errPtr];
    
    if (result && [self resetByteCountPerConnection])
    {
        numberOfBytesSent = 0;
        numberOfBytesReceived = 0;
    }
    
    if(result)
    {
        [self startConnectTimeout:timeout];
    }
    return result;
}

-(void)connect
{
    NSError *error=nil;
    [self connectWithTimeout:XClientTimeoutNone error:&error];
}

- (BOOL)connectWithTimeout:(NSTimeInterval)timeout error:(NSError **)errPtr
{
    //XCLogTrace();
    
    __block BOOL result = NO;
    __block NSError *err = nil;
    
    dispatch_block_t block = ^{ @autoreleasepool {
        if (!username || username.length==0 || !password || password.length==0) {
            XCLog(@"username and password must not be empty before connect");
            result = NO;
            return_from_block;
        }
        
        if (state != STATE_XC_DISCONNECTED)
        {
            NSString *errMsg = @"Attempting to connect while already connected or connecting.";
            NSDictionary *info = @{NSLocalizedDescriptionKey : errMsg};
            
            err = [NSError errorWithDomain:XClientErrorDomain code:XClientInvalidState userInfo:info];
            
            result = NO;
            return_from_block;
        }
        
        // Open TCP connection to the configured hostName.
        
        state = STATE_XC_CONNECTING;
        
        NSError *connectErr = nil;
        result = [self connectToHost:hostName onPort:hostPort withTimeout:XClientTimeoutNone error:&connectErr];
        
        if (!result)
        {
            err = connectErr;
            state = STATE_XC_DISCONNECTED;
        }
        
        if(result)
        {
            [self startConnectTimeout:timeout];
        }
    }};
    
    if (dispatch_get_specific(xcQueueTag))
        block();
    else
        dispatch_sync(xcQueue, block);
    
    if (errPtr)
        *errPtr = err;
    
    return result;
}

/**
 * Closes the connection to the remote host.
 **/
- (void)disconnect
{
    //XMPPLogTrace();
    
    dispatch_block_t block = ^{ @autoreleasepool {
        
        if (state != STATE_XC_DISCONNECTED)
        {
            //           // [multicastDelegate XClientWasToldToDisconnect:self];
            //
            //            if (state == STATE_XC_RESOLVING_SRV)
            //            {
            //                //[srvResolver stop];
            //               // srvResolver = nil;
            //
            //                state = STATE_XC_DISCONNECTED;
            //
            //                //[multicastDelegate XClientDidDisconnect:self withError:nil];
            //            }
            //            else
            //            {
            [asyncSocket disconnect];
            
            //                // Everthing will be handled in socketDidDisconnect:withError:
            //            }
        }
    }};
    
    if (dispatch_get_specific(xcQueueTag))
        block();
    else
        dispatch_sync(xcQueue, block);
}


#pragma mark --Handle Read && Write
-(void)handleReadLine:(NSData *)data
{
    if (!data || data.length==0) {
        return;
    }
    @autoreleasepool {
        NSString *response= [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSRange speratorRange = [response rangeOfString:@"\r\n\r\n"];
        if (speratorRange.location!=NSNotFound) {
            NSString *header=[response substringToIndex:speratorRange.location];
            if ([header rangeOfString:STATUS_200].location!=NSNotFound) {
                httpStatus=HTTPStatus200;
                [multicastDelegate xclientDidConnect:self withError:nil];
            }else if ([header rangeOfString:STATUS_303].location!=NSNotFound) {
                httpStatus=HTTPStatus303;
                XCLog(@"status 303 redirect header:%@.",header);
                NSRange locRange = [header rangeOfString:@"http://"];
                
                if (locRange.location!=NSNotFound) {
                    NSString *locStr=[header substringFromIndex:locRange.location+locRange.length];
                    NSRange portRange=[locStr rangeOfString:@":"];
                    NSRange slashRange=[locStr rangeOfString:@"/"];
                    if (portRange.location!=NSNotFound) {
                        self.hostName=[locStr substringToIndex:portRange.location];
                        self.hostPort=[[locStr substringWithRange:NSMakeRange(portRange.location+1, speratorRange.location-portRange.location-1)] integerValue];
                        
                    }else if (slashRange.location!=NSNotFound) {
                        self.hostName=[locStr substringToIndex:slashRange.location];
                        self.hostPort=80;
                    }
                    [self disconnect];
                    [self connect];
                }
            }else if ([header rangeOfString:STATUS_400].location!=NSNotFound) {
                httpStatus=HTTPStatus400;
            }
            // XCLog(@"header:%@",header);
        }else{
            
            
            NSString *line=[response stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            //NSDictionary *dic=[NSJSONSerialization JSONObjectWithData:[line dataUsingEncoding:NSUTF8StringEncoding] options:kNilOptions error:nil];
            switch (httpStatus) {
                case HTTPStatus200:
                {
                    if ([line hasPrefix:@"{"] && [line hasSuffix:@"}"]) {
                        XCMessage *msg=[XCMessage fromJsonData:[line dataUsingEncoding:NSUTF8StringEncoding]];
                        lastSeq_=msg.seq;
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [multicastDelegate xclient:self didReceiveMessage:msg];
                        });
                        [self sendAck];
                    }else{
                        if ([@"0" isEqualToString:line]) {
                           //[self disconnect];
                        }else{
                            int len= hexstr2int(line);
                            if (len==0) {
                                NSString *errMsg = @"The packet is not json format, cannot be parsed.";
                                NSDictionary *info = @{NSLocalizedDescriptionKey : errMsg};
                                NSError *err = [NSError errorWithDomain:XClientErrorDomain code:XClientInvalidProperty userInfo:info];
                                [multicastDelegate xclient:self didReceiveError:err];
                            }else{
                                // len
                                XCLog(@"message len:%i",len);
                            }
                        }
                        //
                    }
                    
                }
                    break;
                case HTTPStatus303:
                {
                    //redirect
                    statusDes=line;
                }
                    break;
                case HTTPStatus400:
                {
                    statusDes=line;
                    NSDictionary *info = @{NSLocalizedDescriptionKey : statusDes?statusDes:@""};
                    NSError *err = [NSError errorWithDomain:XClientErrorDomain code:XClientUnsupportedAction userInfo:info];
                    [multicastDelegate xclientDidConnect:self withError:err];
                    [self disconnect];
                }
                    break;
                default:
                    break;
            }
            
        }
    }
}

-(void)handleWrite
{
    
}


#pragma mark -- AutoPing
-(void)startPing
{
    dispatch_block_t block=^{
        if (!autoPing) {
            autoPing=[[XCAutoPing alloc] init];
        }
        [autoPing startPingIntervalTimerWithHandler:^{
            if ([UIApplication sharedApplication].applicationState==UIApplicationStateBackground) {
                XCLog(@"backgroundTimeRemaining:%f",[UIApplication sharedApplication].backgroundTimeRemaining);
            }
            if (state == STATE_XC_CONNECTED) {
                [self sendHeartbeat];
            }else if(state == STATE_XC_DISCONNECTED){
                [self connect];
            }
            
            
        }];
    };
    if (dispatch_get_specific(xcQueueTag)) {
        block();
    }else{
        dispatch_async(xcQueue, block);
    }
}

-(void)stopPing
{
    dispatch_block_t block=^{
        if (autoPing) {
            [autoPing stopPingIntervalTimer];
            autoPing=nil;
        }};
    if (dispatch_get_specific(xcQueueTag)) {
        block();
    }else{
        dispatch_async(xcQueue, block);
    }
}

#pragma mark -- AutoReconnect
-(void)startMonitorReconnect
{
    dispatch_block_t block=^{
        if (!autoReconnect) {
            autoReconnect=[[XCAutoReconnect alloc] init];
        }
        [autoReconnect startMonitoringWithHostName:hostName withHandler:^(GCNetworkReachabilityStatus status) {
            XCLog(@"GCNetworkReachabilityStatus:%i",status);
            if (status==GCNetworkReachabilityStatusNotReachable) {
//                UIApplication *app=[UIApplication sharedApplication];
//                if (app.applicationState==UIApplicationStateBackground) {
//                    [app endBackgroundTask:bgTask];
//                    //[self disconnect];
//                }
                
            }else{
                [self connect];
            }
        }];
    };
    
    if (dispatch_get_specific(xcQueueTag))
        block();
    else
        dispatch_async(xcQueue, block);
    
}


#pragma mark -- GCDAsyncSocketDelegate
/**
 * Called when a socket connects and is ready for reading and writing.
 * The host parameter will be an IP address, not a DNS name.
 **/
- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port
{
    //XCLogTrace();
    XCLog(@"didConnectToHost:%@",host);
    [asyncSocket readDataToData:[GCDAsyncSocket DoubleCRLFData] withTimeout:TIMEOUT_XC_READ_STREAM tag:TAG_XC_READ_STREAM];
    //[asyncSocket readDataWithTimeout:TIMEOUT_XC_READ_STREAM tag:TAG_XC_READ_STREAM];
    //[asyncSocket readDataToLength:1024*4 withTimeout:-1 tag:TAG_XC_READ_STREAM];
    // This method is invoked on the xmppQueue.
    //
    // The TCP connection is now established.
    state=STATE_XC_CONNECTED;
    
    [self endConnectTimeout];
    
#if TARGET_OS_IPHONE
    {
        if (self.enableBackgroundingOnSocket)
        {
            __block BOOL result;
            
            [asyncSocket performBlock:^{
                result = [asyncSocket enableBackgroundingOnSocket];
            }];
            
            if (result)
                XCLog(@"%@: Enabled backgrounding on socket", @"");
            else
                XCLog(@"%@: Error enabling backgrounding on socket!", @"");
        }
    }
#endif
    NSError *error=nil;
    [self authenticate:&error];
    if (error) {
        XCLog(@"authenticate error:%@",error);
    }
    //ping
    [self startPing];
    //[multicastDelegate XClient:self socketDidConnect:sock];
    
    //srvResolver = nil;
    //srvResults = nil;
    
    // Are we using old-style SSL? (Not the upgrade to TLS technique specified in the XMPP RFC)
    //if ([self isSecure])
    //{
    // The connection must be secured immediately (just like with HTTPS)
    //   [self startTLS];
    //}
    // else
    //{
    // [self startNegotiation];
    // }
    
}


/**
 * Called when a socket has completed reading the requested data. Not called if there is an error.
 **/
- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    //XCLogTrace();
    //NSLog(@"didReadData:%@",data);
    XCLog(@"didReadDataToString:%@",[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
    dispatch_async(receiveMessageQueue, ^{
        //dispatch_async(xcQueue, ^{ @autoreleasepool {
         [self handleReadLine:data];
        //}});
    });
    //[self handleReadLine:data];
    //[asyncSocket readDataWithTimeout:TIMEOUT_XC_READ_STREAM tag:TAG_XC_READ_STREAM];
    [asyncSocket readDataToData:[GCDAsyncSocket CRLFData] withTimeout:TIMEOUT_XC_READ_STREAM tag:TAG_XC_READ_STREAM];
}

/**
 * Called after data with the given tag has been successfully sent.
 **/
- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag
{
    //XCLogTrace();
    XCLog(@"didWriteDataWithTag:%li",tag);
}

/**
 * Called when a socket disconnects with or without error.
 *
 **/
- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err
{
    XCLogInfo(@"socketDidDisconnect:%@",err);
    [self endConnectTimeout];
    // Update state
    state = STATE_XC_DISCONNECTED;
    [self stopPing];
//    if (httpStatus==HTTPStatus200) {
        [multicastDelegate xclientDidDisconnect:self withError:err];
//    }else{
//        NSDictionary *info = @{NSLocalizedDescriptionKey : statusDes?statusDes:@""};
//        NSError *err = [NSError errorWithDomain:XClientErrorDomain code:XClientUnsupportedAction userInfo:info];
//        [multicastDelegate xclientDidConnect:self withError:err];
//        
//    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Configuration
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)addDelegate:(id)delegate delegateQueue:(dispatch_queue_t)delegateQueue
{
    // Asynchronous operation (if outside xmppQueue)
    
    dispatch_block_t block = ^{
        [multicastDelegate addDelegate:delegate delegateQueue:delegateQueue];
    };
    
    if (dispatch_get_specific(xcQueueTag))
        block();
    else
        dispatch_async(xcQueue, block);
}

- (void)removeDelegate:(id)delegate delegateQueue:(dispatch_queue_t)delegateQueue
{
    // Synchronous operation
    
    dispatch_block_t block = ^{
        [multicastDelegate removeDelegate:delegate delegateQueue:delegateQueue];
    };
    
    if (dispatch_get_specific(xcQueueTag))
        block();
    else
        dispatch_sync(xcQueue, block);
}

- (void)removeDelegate:(id)delegate
{
    // Synchronous operation
    
    dispatch_block_t block = ^{
        [multicastDelegate removeDelegate:delegate];
    };
    
    if (dispatch_get_specific(xcQueueTag))
        block();
    else
        dispatch_sync(xcQueue, block);
}



////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Module Plug-In System
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)registerModule:(XCModule *)module
{
    if (module == nil) return;
    
    // Asynchronous operation
    
    dispatch_block_t block = ^{ @autoreleasepool {
        
        // Register module
        
        [registeredModules addObject:module];
        
        // Add auto delegates (if there are any)
        
        NSString *className = NSStringFromClass([module class]);
        GCDMulticastDelegate *autoDelegates = autoDelegateDict[className];
        
        GCDMulticastDelegateEnumerator *autoDelegatesEnumerator = [autoDelegates delegateEnumerator];
        id delegate;
        dispatch_queue_t delegateQueue;
        
        while ([autoDelegatesEnumerator getNextDelegate:&delegate delegateQueue:&delegateQueue])
        {
            [module addDelegate:delegate delegateQueue:delegateQueue];
        }
        
        // Notify our own delegate(s)
        
       // [multicastDelegate xclient:self didRegisterModule:module];
        
    }};
    
    // Asynchronous operation
    
    if (dispatch_get_specific(xcQueueTag))
        block();
    else
        dispatch_async(xcQueue, block);
}

- (void)unregisterModule:(XCModule *)module
{
    if (module == nil) return;
    
    // Synchronous operation
    
    dispatch_block_t block = ^{ @autoreleasepool {
        
        // Notify our own delegate(s)
        
        //[multicastDelegate xclient:self willUnregisterModule:module];
        
        // Remove auto delegates (if there are any)
        
        NSString *className = NSStringFromClass([module class]);
        GCDMulticastDelegate *autoDelegates = autoDelegateDict[className];
        
        GCDMulticastDelegateEnumerator *autoDelegatesEnumerator = [autoDelegates delegateEnumerator];
        id delegate;
        dispatch_queue_t delegateQueue;
        
        while ([autoDelegatesEnumerator getNextDelegate:&delegate delegateQueue:&delegateQueue])
        {
            // The module itself has dispatch_sync'd in order to invoke its deactivate method,
            // which has in turn invoked this method. If we call back into the module,
            // and have it dispatch_sync again, we're going to get a deadlock.
            // So we must remove the delegate(s) asynchronously.
            
            [module removeDelegate:delegate delegateQueue:delegateQueue synchronously:NO];
        }
        
        // Unregister modules
        
        [registeredModules removeObject:module];
        
    }};
    
    // Synchronous operation
    
    if (dispatch_get_specific(xcQueueTag))
        block();
    else
        dispatch_sync(xcQueue, block);
}

- (void)autoAddDelegate:(id)delegate delegateQueue:(dispatch_queue_t)delegateQueue toModulesOfClass:(Class)aClass
{
    if (delegate == nil) return;
    if (aClass == nil) return;
    
    // Asynchronous operation
    
    dispatch_block_t block = ^{ @autoreleasepool {
        
        NSString *className = NSStringFromClass(aClass);
        
        // Add the delegate to all currently registered modules of the given class.
        
        for (XCModule *module in registeredModules)
        {
            if ([module isKindOfClass:aClass])
            {
                [module addDelegate:delegate delegateQueue:delegateQueue];
            }
        }
        
        // Add the delegate to list of auto delegates for the given class.
        // It will be added as a delegate to future registered modules of the given class.
        
        id delegates = autoDelegateDict[className];
        if (delegates == nil)
        {
            delegates = [[GCDMulticastDelegate alloc] init];
            
            autoDelegateDict[className] = delegates;
        }
        
        [delegates addDelegate:delegate delegateQueue:delegateQueue];
        
    }};
    
    // Asynchronous operation
    
    if (dispatch_get_specific(xcQueueTag))
        block();
    else
        dispatch_async(xcQueue, block);
}

- (void)removeAutoDelegate:(id)delegate delegateQueue:(dispatch_queue_t)delegateQueue fromModulesOfClass:(Class)aClass
{
    if (delegate == nil) return;
    // delegateQueue may be NULL
    // aClass may be NULL
    
    // Synchronous operation
    
    dispatch_block_t block = ^{ @autoreleasepool {
        
        if (aClass == NULL)
        {
            // Remove the delegate from all currently registered modules of ANY class.
            
            for (XCModule *module in registeredModules)
            {
                [module removeDelegate:delegate delegateQueue:delegateQueue];
            }
            
            // Remove the delegate from list of auto delegates for all classes,
            // so that it will not be auto added as a delegate to future registered modules.
            
            for (GCDMulticastDelegate *delegates in [autoDelegateDict objectEnumerator])
            {
                [delegates removeDelegate:delegate delegateQueue:delegateQueue];
            }
        }
        else
        {
            NSString *className = NSStringFromClass(aClass);
            
            // Remove the delegate from all currently registered modules of the given class.
            
            for (XCModule *module in registeredModules)
            {
                if ([module isKindOfClass:aClass])
                {
                    [module removeDelegate:delegate delegateQueue:delegateQueue];
                }
            }
            
            // Remove the delegate from list of auto delegates for the given class,
            // so that it will not be added as a delegate to future registered modules of the given class.
            
            GCDMulticastDelegate *delegates = autoDelegateDict[className];
            [delegates removeDelegate:delegate delegateQueue:delegateQueue];
            
            if ([delegates count] == 0)
            {
                [autoDelegateDict removeObjectForKey:className];
            }
        }
        
    }};
    
    // Synchronous operation
    
    if (dispatch_get_specific(xcQueueTag))
        block();
    else
        dispatch_sync(xcQueue, block);
}

- (void)enumerateModulesWithBlock:(void (^)(XCModule *module, NSUInteger idx, BOOL *stop))enumBlock
{
    if (enumBlock == NULL) return;
    
    dispatch_block_t block = ^{ @autoreleasepool {
        
        NSUInteger i = 0;
        BOOL stop = NO;
        
        for (XCModule *module in registeredModules)
        {
            enumBlock(module, i, &stop);
            
            if (stop)
                break;
            else
                i++;
        }
    }};
    
    // Synchronous operation
    
    if (dispatch_get_specific(xcQueueTag))
        block();
    else
        dispatch_sync(xcQueue, block);
}

- (void)enumerateModulesOfClass:(Class)aClass withBlock:(void (^)(XCModule *module, NSUInteger idx, BOOL *stop))block
{
    [self enumerateModulesWithBlock:^(XCModule *module, NSUInteger idx, BOOL *stop)
     {
         if([module isKindOfClass:aClass])
         {
             block(module,idx,stop);
         }
     }];
}

@end

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//#pragma mark -
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//@protocol XClientDelegate
//@optional
//
///**
// * This method is called after the client has been connected
// * if error is nil, auzhorized successfull
// * if error is not nil, auzhorized failed.
// **/
//- (void)xclientDidConnect:(XClient *)sender withError:(NSError *)error;
///**
// * This method is called after the client has reveived a message.
// **/
//- (void)xclient:(XClient *)sender didReceiveMessage:(XCMessage *)message;
///**
// * This method is called after the client has reveived a message that be parsed or an err response.
// **/
//- (void)xclient:(XClient *)sender didReceiveError:(NSError *)error;
///**
// * This method is called after the client is closed.
// **/
//- (void)xclientDidDisconnect:(XClient *)sender withError:(NSError *)error;
//
///**
// * These methods are called as client modules are registered and unregistered with the client.
// * This generally corresponds to client modules being initailzed and deallocated.
// *
// * The methods may be useful, for example, if a more precise auto delegation mechanism is needed
// * than what is available with the autoAddDelegate:toModulesOfClass: method.
// **/
//- (void)xclient:(XClient *)sender didRegisterModule:(id)module;
//- (void)xclient:(XClient *)sender willUnregisterModule:(id)module;
//
//
//@end
