//
//  XClient.h
//  xcomet
//
//  Created by kimziv on 15/5/6.
//  Copyright (c) 2015年 kimziv. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GCDAsyncSocket.h"

#import "XClientOption.h"

@class XCModule;
extern NSString *const XClientErrorDomain;

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

extern const NSTimeInterval XClientTimeoutNone;
@interface XClient : NSObject<GCDAsyncSocketDelegate>

-(instancetype)initWithOption:(XClientOption *)option;

#if TARGET_OS_IPHONE

/**
 * If set, the kCFStreamNetworkServiceTypeVoIP flags will be set on the underlying CFRead/Write streams.
 *
 * The default value is NO.
 **/
@property (readwrite, assign) BOOL enableBackgroundingOnSocket;

#endif

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark State
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * Returns YES if the connection is closed, and thus no stream is open.
 * If the stream is neither disconnected, nor connected, then a connection is currently being established.
 **/
- (BOOL)isDisconnected;

/**
 * Returns YES is the connection is currently connecting
 **/
- (BOOL)isConnecting;

/**
 * Returns YES if the connection is open, and the stream has been properly established.
 * If the stream is neither disconnected, nor connected, then a connection is currently being established.
 *
 * If this method returns YES, then it is ready for you to start sending and receiving elements.
 **/
- (BOOL)isConnected;

@property (readwrite, copy) NSString *hostName;

/**
 * The port the xmpp server is running on.
 * If you do not explicitly set the port, the default port will be used.
 * If you set the port to zero, the default port will be used.
 *
 * The default port is 9000.
 **/
@property (readwrite, assign) UInt16 hostPort;

/**
 * Connects to the configured hostName on the configured hostPort.
 * The timeout is optional. To not time out use XMPPStreamTimeoutNone.
 * If the hostName or myJID are not set, this method will return NO and set the error parameter.
 **/
- (BOOL)connectWithTimeout:(NSTimeInterval)timeout error:(NSError **)errPtr;

/**
 * THIS IS DEPRECATED BY THE XMPP SPECIFICATION.
 *
 * The xmpp specification outlines the proper use of SSL/TLS by negotiating
 * the startTLS upgrade within the stream negotiation.
 * This method exists for those ancient servers that still require the connection to be secured prematurely.
 * The timeout is optional. To not time out use XMPPStreamTimeoutNone.
 *
 * Note: Such servers generally use port 5223 for this, which you will need to set.
 **/
- (BOOL)oldSchoolSecureConnectWithTimeout:(NSTimeInterval)timeout error:(NSError **)errPtr;

- (void)disconnect;

- (BOOL)authenticateWithUserID:(NSString *)userId password:(NSString *)password error:(NSError **)errPtr;
-(void)sendMessage:(NSString *)content to:(NSString *)to ;

-(void)sendAck;
-(void)sendHeartbeat;

/**
 * XMPPStream uses a multicast delegate.
 * This allows one to add multiple delegates to a single XMPPStream instance,
 * which makes it easier to separate various components and extensions.
 *
 * For example, if you were implementing two different custom extensions on top of XMPP,
 * you could put them in separate classes, and simply add each as a delegate.
 **/
- (void)addDelegate:(id)delegate delegateQueue:(dispatch_queue_t)delegateQueue;
- (void)removeDelegate:(id)delegate delegateQueue:(dispatch_queue_t)delegateQueue;
- (void)removeDelegate:(id)delegate;

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Module Plug-In System
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * The XMPPModule class automatically invokes these methods when it is activated/deactivated.
 *
 * The registerModule method registers the module with the xmppStream.
 * If there are any other modules that have requested to be automatically added as delegates to modules of this type,
 * then those modules are automatically added as delegates during the asynchronous execution of this method.
 *
 * The registerModule method is asynchronous.
 *
 * The unregisterModule method unregisters the module with the xmppStream,
 * and automatically removes it as a delegate of any other module.
 *
 * The unregisterModule method is fully synchronous.
 * That is, after this method returns, the module will not be scheduled in any more delegate calls from other modules.
 * However, if the module was already scheduled in an existing asynchronous delegate call from another module,
 * the scheduled delegate invocation remains queued and will fire in the near future.
 * Since the delegate invocation is already queued,
 * the module's retainCount has been incremented,
 * and the module will not be deallocated until after the delegate invocation has fired.
 **/
- (void)registerModule:(XCModule *)module;
- (void)unregisterModule:(XCModule *)module;

/**
 * Automatically registers the given delegate with all current and future registered modules of the given class.
 *
 * That is, the given delegate will be added to the delegate list ([module addDelegate:delegate delegateQueue:dq]) to
 * all current and future registered modules that respond YES to [module isKindOfClass:aClass].
 *
 * This method is used by modules to automatically integrate with other modules.
 * For example, a module may auto-add itself as a delegate to XMPPCapabilities
 * so that it can broadcast its implemented features.
 *
 * This may also be useful to clients, for example, to add a delegate to instances of something like XMPPChatRoom,
 * where there may be multiple instances of the module that get created during the course of an xmpp session.
 *
 * If you auto register on multiple queues, you can remove all registrations with a single
 * call to removeAutoDelegate::: by passing NULL as the 'dq' parameter.
 *
 * If you auto register for multiple classes, you can remove all registrations with a single
 * call to removeAutoDelegate::: by passing nil as the 'aClass' parameter.
 **/
- (void)autoAddDelegate:(id)delegate delegateQueue:(dispatch_queue_t)delegateQueue toModulesOfClass:(Class)aClass;
- (void)removeAutoDelegate:(id)delegate delegateQueue:(dispatch_queue_t)delegateQueue fromModulesOfClass:(Class)aClass;

/**
 * Allows for enumeration of the currently registered modules.
 *
 * This may be useful if the stream needs to be queried for modules of a particular type.
 **/
- (void)enumerateModulesWithBlock:(void (^)(XCModule *module, NSUInteger idx, BOOL *stop))block;

/**
 * Allows for enumeration of the currently registered modules that are a kind of Class.
 * idx is in relation to all modules not just those of the given class.
 **/
- (void)enumerateModulesOfClass:(Class)aClass withBlock:(void (^)(XCModule *module, NSUInteger idx, BOOL *stop))block;

@end


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@protocol XClientDelegate
@optional

/**
 * This method is called before the stream begins the connection process.
 *
 * If developing an iOS app that runs in the background, this may be a good place to indicate
 * that this is a task that needs to continue running in the background.
 **/
- (void)xmppStreamWillConnect:(XClient *)sender;

/**
 * This method is called after the tcp socket has connected to the remote host.
 * It may be used as a hook for various things, such as updating the UI or extracting the server's IP address.
 *
 * If developing an iOS app that runs in the background,
 * please use XMPPStream's enableBackgroundingOnSocket property as opposed to doing it directly on the socket here.
 **/
- (void)xmppStream:(XClient *)sender socketDidConnect:(GCDAsyncSocket *)socket;

///**
// * This method is called after a TCP connection has been established with the server,
// * and the opening XML stream negotiation has started.
// **/
//- (void)xmppStreamDidStartNegotiation:(XClient *)sender;
//
///**
// * This method is called immediately prior to the stream being secured via TLS/SSL.
// * Note that this delegate may be called even if you do not explicitly invoke the startTLS method.
// * Servers have the option of requiring connections to be secured during the opening process.
// * If this is the case, the XMPPStream will automatically attempt to properly secure the connection.
// *
// * The dictionary of settings is what will be passed to the startTLS method of the underlying GCDAsyncSocket.
// * The GCDAsyncSocket header file contains a discussion of the available key/value pairs,
// * as well as the security consequences of various options.
// * It is recommended reading if you are planning on implementing this method.
// *
// * The dictionary of settings that are initially passed will be an empty dictionary.
// * If you choose not to implement this method, or simply do not edit the dictionary,
// * then the default settings will be used.
// * That is, the kCFStreamSSLPeerName will be set to the configured host name,
// * and the default security validation checks will be performed.
// *
// * This means that authentication will fail if the name on the X509 certificate of
// * the server does not match the value of the hostname for the xmpp stream.
// * It will also fail if the certificate is self-signed, or if it is expired, etc.
// *
// * These settings are most likely the right fit for most production environments,
// * but may need to be tweaked for development or testing,
// * where the development server may be using a self-signed certificate.
// *
// * Note: If your development server is using a self-signed certificate,
// * you likely need to add GCDAsyncSocketManuallyEvaluateTrust=YES to the settings.
// * Then implement the xmppStream:didReceiveTrust:completionHandler: delegate method to perform custom validation.
// **/
//- (void)xmppStream:(XClient *)sender willSecureWithSettings:(NSMutableDictionary *)settings;
//
///**
// * Allows a delegate to hook into the TLS handshake and manually validate the peer it's connecting to.
// *
// * This is only called if the stream is secured with settings that include:
// * - GCDAsyncSocketManuallyEvaluateTrust == YES
// * That is, if a delegate implements xmppStream:willSecureWithSettings:, and plugs in that key/value pair.
// *
// * Thus this delegate method is forwarding the TLS evaluation callback from the underlying GCDAsyncSocket.
// *
// * Typically the delegate will use SecTrustEvaluate (and related functions) to properly validate the peer.
// *
// * Note from Apple's documentation:
// *   Because [SecTrustEvaluate] might look on the network for certificates in the certificate chain,
// *   [it] might block while attempting network access. You should never call it from your main thread;
// *   call it only from within a function running on a dispatch queue or on a separate thread.
// *
// * This is why this method uses a completionHandler block rather than a normal return value.
// * The idea is that you should be performing SecTrustEvaluate on a background thread.
// * The completionHandler block is thread-safe, and may be invoked from a background queue/thread.
// * It is safe to invoke the completionHandler block even if the socket has been closed.
// *
// * Keep in mind that you can do all kinds of cool stuff here.
// * For example:
// *
// * If your development server is using a self-signed certificate,
// * then you could embed info about the self-signed cert within your app, and use this callback to ensure that
// * you're actually connecting to the expected dev server.
// *
// * Also, you could present certificates that don't pass SecTrustEvaluate to the client.
// * That is, if SecTrustEvaluate comes back with problems, you could invoke the completionHandler with NO,
// * and then ask the client if the cert can be trusted. This is similar to how most browsers act.
// *
// * Generally, only one delegate should implement this method.
// * However, if multiple delegates implement this method, then the first to invoke the completionHandler "wins".
// * And subsequent invocations of the completionHandler are ignored.
// **/
//- (void)xmppStream:(XClient *)sender didReceiveTrust:(SecTrustRef)trust
// completionHandler:(void (^)(BOOL shouldTrustPeer))completionHandler;
//
///**
// * This method is called after the stream has been secured via SSL/TLS.
// * This method may be called if the server required a secure connection during the opening process,
// * or if the secureConnection: method was manually invoked.
// **/
//- (void)xmppStreamDidSecure:(XClient *)sender;
//
/**
 * This method is called after the XML stream has been fully opened.
 * More precisely, this method is called after an opening <xml/> and <stream:stream/> tag have been sent and received,
 * and after the stream features have been received, and any required features have been fullfilled.
 * At this point it's safe to begin communication with the server.
 **/
- (void)xmppStreamDidConnect:(XClient *)sender;

/**
 * This method is called after registration of a new user has successfully finished.
 * If registration fails for some reason, the xmppStream:didNotRegister: method will be called instead.
 **/
- (void)xmppStreamDidRegister:(XClient *)sender;
//
///**
// * This method is called if registration fails.
// **/
//- (void)xmppStream:(XClient *)sender didNotRegister:(NSXMLElement *)error;
//
///**
// * This method is called after authentication has successfully finished.
// * If authentication fails for some reason, the xmppStream:didNotAuthenticate: method will be called instead.
// **/
//- (void)xmppStreamDidAuthenticate:(XClient *)sender;
//
///**
// * This method is called if authentication fails.
// **/
//- (void)xmppStream:(XClient *)sender didNotAuthenticate:(NSXMLElement *)error;
//
///**
// * Binding a JID resource is a standard part of the authentication process,
// * and occurs after SASL authentication completes (which generally authenticates the JID username).
// *
// * This delegate method allows for a custom binding procedure to be used.
// * For example:
// * - a custom SASL authentication scheme might combine auth with binding
// * - stream management (xep-0198) replaces binding if it can resume a previous session
// *
// * Return nil (or don't implement this method) if you wish to use the standard binding procedure.
// **/
//- (id <XMPPCustomBinding>)xmppStreamWillBind:(XClient *)sender;
//
///**
// * This method is called if the XMPP server doesn't allow our resource of choice
// * because it conflicts with an existing resource.
// *
// * Return an alternative resource or return nil to let the server automatically pick a resource for us.
// **/
//- (NSString *)xmppStream:(XClient *)sender alternativeResourceForConflictingResource:(NSString *)conflictingResource;
//
///**
// * These methods are called before their respective XML elements are broadcast as received to the rest of the stack.
// * These methods can be used to modify elements on the fly.
// * (E.g. perform custom decryption so the rest of the stack sees readable text.)
// *
// * You may also filter incoming elements by returning nil.
// *
// * When implementing these methods to modify the element, you do not need to copy the given element.
// * You can simply edit the given element, and return it.
// * The reason these methods return an element, instead of void, is to allow filtering.
// *
// * Concerning thread-safety, delegates implementing the method are invoked one-at-a-time to
// * allow thread-safe modification of the given elements.
// *
// * You should NOT implement these methods unless you have good reason to do so.
// * For general processing and notification of received elements, please use xmppStream:didReceiveX: methods.
// *
// * @see xmppStream:didReceiveIQ:
// * @see xmppStream:didReceiveMessage:
// * @see xmppStream:didReceivePresence:
// **/
//- (XMPPIQ *)xmppStream:(XClient *)sender willReceiveIQ:(XMPPIQ *)iq;
//- (XMPPMessage *)xmppStream:(XClient *)sender willReceiveMessage:(XMPPMessage *)message;
//- (XMPPPresence *)xmppStream:(XClient *)sender willReceivePresence:(XMPPPresence *)presence;
//
///**
// * This method is called if any of the xmppStream:willReceiveX: methods filter the incoming stanza.
// *
// * It may be useful for some extensions to know that something was received,
// * even if it was filtered for some reason.
// **/
//- (void)xmppStreamDidFilterStanza:(XClient *)sender;
//
///**
// * These methods are called after their respective XML elements are received on the stream.
// *
// * In the case of an IQ, the delegate method should return YES if it has or will respond to the given IQ.
// * If the IQ is of type 'get' or 'set', and no delegates respond to the IQ,
// * then xmpp stream will automatically send an error response.
// *
// * Concerning thread-safety, delegates shouldn't modify the given elements.
// * As documented in NSXML / KissXML, elements are read-access thread-safe, but write-access thread-unsafe.
// * If you have need to modify an element for any reason,
// * you should copy the element first, and then modify and use the copy.
// **/
//- (BOOL)xmppStream:(XClient *)sender didReceiveIQ:(XMPPIQ *)iq;
//- (void)xmppStream:(XClient *)sender didReceiveMessage:(XMPPMessage *)message;
//- (void)xmppStream:(XClient *)sender didReceivePresence:(XMPPPresence *)presence;
//
///**
// * This method is called if an XMPP error is received.
// * In other words, a <stream:error/>.
// *
// * However, this method may also be called for any unrecognized xml stanzas.
// *
// * Note that standard errors (<iq type='error'/> for example) are delivered normally,
// * via the other didReceive...: methods.
// **/
- (void)xmppStream:(XClient *)sender didReceiveError:(NSError *)error;
//
///**
// * These methods are called before their respective XML elements are sent over the stream.
// * These methods can be used to modify outgoing elements on the fly.
// * (E.g. add standard information for custom protocols.)
// *
// * You may also filter outgoing elements by returning nil.
// *
// * When implementing these methods to modify the element, you do not need to copy the given element.
// * You can simply edit the given element, and return it.
// * The reason these methods return an element, instead of void, is to allow filtering.
// *
// * Concerning thread-safety, delegates implementing the method are invoked one-at-a-time to
// * allow thread-safe modification of the given elements.
// *
// * You should NOT implement these methods unless you have good reason to do so.
// * For general processing and notification of sent elements, please use xmppStream:didSendX: methods.
// *
// * @see xmppStream:didSendIQ:
// * @see xmppStream:didSendMessage:
// * @see xmppStream:didSendPresence:
// **/
//- (XMPPIQ *)xmppStream:(XClient *)sender willSendIQ:(XMPPIQ *)iq;
//- (XMPPMessage *)xmppStream:(XClient *)sender willSendMessage:(XMPPMessage *)message;
//- (XMPPPresence *)xmppStream:(XClient *)sender willSendPresence:(XMPPPresence *)presence;
//
///**
// * These methods are called after their respective XML elements are sent over the stream.
// * These methods may be used to listen for certain events (such as an unavailable presence having been sent),
// * or for general logging purposes. (E.g. a central history logging mechanism).
// **/
//- (void)xmppStream:(XClient *)sender didSendIQ:(XMPPIQ *)iq;
//- (void)xmppStream:(XClient *)sender didSendMessage:(XMPPMessage *)message;
//- (void)xmppStream:(XClient *)sender didSendPresence:(XMPPPresence *)presence;
//
///**
// * These methods are called after failing to send the respective XML elements over the stream.
// * This occurs when the stream gets disconnected before the element can get sent out.
// **/
//- (void)xmppStream:(XClient *)sender didFailToSendIQ:(XMPPIQ *)iq error:(NSError *)error;
//- (void)xmppStream:(XClient *)sender didFailToSendMessage:(XMPPMessage *)message error:(NSError *)error;
//- (void)xmppStream:(XClient *)sender didFailToSendPresence:(XMPPPresence *)presence error:(NSError *)error;
//
///**
// * This method is called if the XMPP Stream's jid changes.
// **/
//- (void)xmppStreamDidChangeMyJID:(XClient *)xmppStream;
//
///**
// * This method is called if the disconnect method is called.
// * It may be used to determine if a disconnection was purposeful, or due to an error.
// *
// * Note: A disconnect may be either "clean" or "dirty".
// * A "clean" disconnect is when the stream sends the closing </stream:stream> stanza before disconnecting.
// * A "dirty" disconnect is when the stream simply closes its TCP socket.
// * In most cases it makes no difference how the disconnect occurs,
// * but there are a few contexts in which the difference has various protocol implications.
// *
// * @see xmppStreamDidSendClosingStreamStanza
// **/
//- (void)xmppStreamWasToldToDisconnect:(XClient *)sender;
//
///**
// * This method is called after the stream has sent the closing </stream:stream> stanza.
// * This signifies a "clean" disconnect.
// *
// * Note: A disconnect may be either "clean" or "dirty".
// * A "clean" disconnect is when the stream sends the closing </stream:stream> stanza before disconnecting.
// * A "dirty" disconnect is when the stream simply closes its TCP socket.
// * In most cases it makes no difference how the disconnect occurs,
// * but there are a few contexts in which the difference has various protocol implications.
// **/
//- (void)xmppStreamDidSendClosingStreamStanza:(XClient *)sender;
//
///**
// * This methods is called if the XMPP stream's connect times out.
// **/
//- (void)xmppStreamConnectDidTimeout:(XClient *)sender;
//
/**
 * This method is called after the stream is closed.
 *
 * The given error parameter will be non-nil if the error was due to something outside the general xmpp realm.
 * Some examples:
 * - The TCP socket was unexpectedly disconnected.
 * - The SRV resolution of the domain failed.
 * - Error parsing xml sent from server.
 *
 * @see xmppStreamConnectDidTimeout:
 **/
- (void)xmppStreamDidDisconnect:(XClient *)sender withError:(NSError *)error;
//
///**
// * This method is only used in P2P mode when the connectTo:withAddress: method was used.
// *
// * It allows the delegate to read the <stream:features/> element if/when they arrive.
// * Recall that the XEP specifies that <stream:features/> SHOULD be sent.
// **/
//- (void)xmppStream:(XClient *)sender didReceiveP2PFeatures:(NSXMLElement *)streamFeatures;
//
///**
// * This method is only used in P2P mode when the connectTo:withSocket: method was used.
// *
// * It allows the delegate to customize the <stream:features/> element,
// * adding any specific featues the delegate might support.
// **/
//- (void)xmppStream:(XClient *)sender willSendP2PFeatures:(NSXMLElement *)streamFeatures;
//
/**
 * These methods are called as xmpp modules are registered and unregistered with the stream.
 * This generally corresponds to xmpp modules being initailzed and deallocated.
 *
 * The methods may be useful, for example, if a more precise auto delegation mechanism is needed
 * than what is available with the autoAddDelegate:toModulesOfClass: method.
 **/
- (void)xmppStream:(XClient *)sender didRegisterModule:(id)module;
- (void)xmppStream:(XClient *)sender willUnregisterModule:(id)module;
//
///**
// * Custom elements are Non-XMPP elements.
// * In other words, not <iq>, <message> or <presence> elements.
// *
// * Typically these kinds of elements are not allowed by the XMPP server.
// * But some custom implementations may use them.
// * The standard example is XEP-0198, which uses <r> & <a> elements.
// *
// * If you're using custom elements, you must register the custom element name(s).
// * Otherwise the xmppStream will treat non-XMPP elements as errors (xmppStream:didReceiveError:).
// *
// * @see registerCustomElementNames (in XMPPInternal.h)
// **/
//- (void)xmppStream:(XClient *)sender didSendCustomElement:(NSXMLElement *)element;
//- (void)xmppStream:(XClient *)sender didReceiveCustomElement:(NSXMLElement *)element;

@end