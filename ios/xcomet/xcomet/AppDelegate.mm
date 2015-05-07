//
//  AppDelegate.m
//  xcomet
//
//  Created by kimziv on 15/5/4.
//  Copyright (c) 2015年 kimziv. All rights reserved.
//

#import "AppDelegate.h"

#include <stdio.h>
#include <functional>
#include <iostream>
#include <string>
//#include <netinet/tcp.h>
//#include <netinet/in.h>
#include "socketclient.h"
#import "XClient.h"
using namespace std;
using namespace xcomet;
static  SocketClient *client;
void test() {
    const char* host = "182.92.113.188";
    const int port = 9000;
    const char* user= "user527";
    const char* password = "pwd520";
    SimpleLogger::SetLogVerboseLevel(7);
    ClientOption option;
    option.host = host;
    option.port = port;
    option.username= user;
    option.password = password;
    
//    SocketClient *client=new  SocketClient(option);
//    client->SetConnectCallback([]() {
//        cout << "connected" << endl;
//    });
//    client->SetDisconnectCallback([]() {
//        cout << "disconnected" << endl;
//    });
//    client->SetMessageCallback([](const std::string& msg) {
//        cout << "receive message: " << msg << endl;
//    });
//    client->SetErrorCallback([](const std::string& error) {
//        cout << "error: " << error << endl;
//    });
//    cout << "print any key to close ..." << endl;
//    client->SetKeepaliveInterval(30);
//    client->Connect();
    //SocketClient client(option);
    client=new SocketClient(option);
    client->SetConnectCallback([]() {
        cout << "connected" << endl;
    });
    client->SetDisconnectCallback([]() {
        cout << "disconnected" << endl;
    });
    client->SetMessageCallback([](const std::string& msg) {
        cout << "receive message: " << msg << endl;
    });
    client->SetErrorCallback([](const std::string& error) {
        cout << "error: " << error << endl;
    });
    cout << "print any key to close ..." << endl;
    client->SetKeepaliveInterval(30);
    client->Connect();

//    getchar();
//   // client.Close();
//    cout << "print any key to exit ..." << endl;
//    getchar();
}
//@interface AppDelegate ()
//{
//    XClient *_xclient;
//}
//@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
//    // Override point for customization after application launch.
////    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
////        test();
////        //[self performSelector:@selector(scheduleInCurrentThread) onThread:[[self class] networkThread] withObject:nil waitUntilDone:YES];
////    });
//    [self setupXClient];
//    [self connect];
    return YES;
}


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//#pragma mark Private
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//- (void)setupXClient
//{
//    NSAssert(_xclient == nil, @"Method setupStream invoked multiple times");
//    
//    // Setup xmpp stream
//    //
//    // The XMPPStream is the base class for all activity.
//    // Everything else plugs into the xmppStream, such as modules/extensions and delegates.
//    const char* host = "182.92.113.188";
//    const int port = 9000;
//    const char* user= "user527";
//    const char* password = "pwd520";
//    ClientOption option;
//    option.host = host;
//    option.port = port;
//    option.username= user;
//    option.password = password;
//    _xclient = [[XClient alloc] initWithOption:option];
//    _xclient.enableBackgroundingOnSocket = YES;
////#endif
//    
//}
//
//- (BOOL)connect
//{
//    if (![_xclient isDisconnected]) {
//        return YES;
//    }
//    
//   // NSString *myJID = [[NSUserDefaults standardUserDefaults] stringForKey:kXMPPmyJID];
//    //NSString *myPassword = [[NSUserDefaults standardUserDefaults] stringForKey:kXMPPmyPassword];
//    
//    //
//    // If you don't want to use the Settings view to set the JID,
//    // uncomment the section below to hard code a JID and password.
//    //
//    // myJID = @"user@gmail.com/xmppframework";
//    // myPassword = @"";
//    
//   // if (myJID == nil || myPassword == nil) {
//    //    return NO;
//    //}
//    [_xclient setHostName:@"182.92.113.188"];
//    [_xclient setHostPort:9000];
//    
//    NSError *error = nil;
//    if (![_xclient connectWithTimeout:XClientTimeoutNone error:&error])
//    {
//        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error connecting"
//                                                            message:@"See console for error details."
//                                                           delegate:nil
//                                                  cancelButtonTitle:@"Ok"
//                                                  otherButtonTitles:nil];
//        [alertView show];
//        
//        NSLog(@"Error connecting: %@", error);
//        
//        return NO;
//    }
//    
//    return YES;
//}


+ (NSThread *)networkThread {
    static NSThread *networkThread = nil;
    static dispatch_once_t oncePredicate;
    
    dispatch_once(&oncePredicate, ^{
        networkThread =
        [[NSThread alloc] initWithTarget:self
                                selector:@selector(networkThreadMain:)
                                  object:nil];
        [networkThread start];
    });
    
    return networkThread;
}

+ (void)networkThreadMain:(id)unused {
    do {
        @autoreleasepool {
            [[NSRunLoop currentRunLoop] run];
        }
    } while (YES);
}

- (void)scheduleInCurrentThread
{
    test();
    //[inputstream scheduleInRunLoop:[NSRunLoop currentRunLoop]
    //                       forMode:NSRunLoopCommonModes];
}
- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
