//
//  ViewController.m
//  xcomet
//
//  Created by kimziv on 15/5/4.
//  Copyright (c) 2015年 kimziv. All rights reserved.
//

#import "ViewController.h"
#import "XClient.h"
#import  "XCReconnect.h"
@interface ViewController ()
{
    XClient *_xclient;
}
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupXClient];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(IBAction)connectBtnClicked:(id)sender
{
    
        [self connect];
}

-(IBAction)sendBtnClicked:(id)sender
{
    [_xclient sendMessage:@"asdffaf asdfa sdf" to:@"test"];
}
-(IBAction)closeBtnClicked:(id)sender
{
    [_xclient disconnect];
}

- (void)setupXClient
{
    NSAssert(_xclient == nil, @"Method setupStream invoked multiple times");
    XClientOption *option=[XClientOption new];
    option.host = @"182.92.113.188";
    option.port = 9000;
    option.userName= @"user527";
    option.password = @"pwd520";
    _xclient = [[XClient alloc] initWithOption:option];
    _xclient.enableBackgroundingOnSocket = YES;
    XCReconnect *reconnect=[[XCReconnect alloc] init];
    [reconnect activate:_xclient];
    
}

- (BOOL)connect
{
//    if (![_xclient isDisconnected]) {
//        return YES;
//    }
    
    // NSString *myJID = [[NSUserDefaults standardUserDefaults] stringForKey:kXMPPmyJID];
    //NSString *myPassword = [[NSUserDefaults standardUserDefaults] stringForKey:kXMPPmyPassword];
    
    //
    // If you don't want to use the Settings view to set the JID,
    // uncomment the section below to hard code a JID and password.
    //
    // myJID = @"user@gmail.com/xmppframework";
    // myPassword = @"";
    
    // if (myJID == nil || myPassword == nil) {
    //    return NO;
    //}
    [_xclient setHostName:@"182.92.113.188"];
    [_xclient setHostPort:9000];
    
    NSError *error = nil;
    if (![_xclient connectWithTimeout:XClientTimeoutNone error:&error])
    {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error connecting"
                                                            message:@"See console for error details."
                                                           delegate:nil
                                                  cancelButtonTitle:@"Ok"
                                                  otherButtonTitles:nil];
        [alertView show];
        
        NSLog(@"Error connecting: %@", error);
        
        return NO;
    }
    
    return YES;
}
@end
