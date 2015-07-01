//
//  ViewController.m
//  demo
//
//  Created by kimziv on 15/5/11.
//  Copyright (c) 2015年 kimziv. All rights reserved.
//

#import "ViewController.h"
#import  <xcomet/xcomet.h>

@interface ViewController ()<XClientDelegate>
{
    XClient *_xclient;
    NSOperationQueue *_operationQueue;
    UILocalNotification *localNotification;
}
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _operationQueue=[[NSOperationQueue alloc] init];
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
    
    _xclient = [[XClient alloc] init];
    _xclient.enableBackgroundingOnSocket = YES;
    [_xclient addDelegate:self delegateQueue:dispatch_get_main_queue()];
}

- (BOOL)connect
{
    //    if (![_xclient isDisconnected]) {
    //        return YES;
    //    }
    _xclient.hostName=@"182.92.113.188";
    _xclient.hostPort=9000;
    _xclient.username= @"user527";
    _xclient.password = @"pwd520";

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

-(IBAction)sendTest:(id)sender
{
    NSMutableURLRequest *request=[NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"http://182.92.113.188:9001/pub?to=user527&from=test"]];
    request.HTTPMethod=@"POST";
    request.HTTPBody= [@"{\"type\":1040,\"ct\":\"湖北432\",\"td\":\"55266c351267419c34f168aa\",\"content\":\"4422\",\"url\":\"www.baidu.com\"}" dataUsingEncoding:NSUTF8StringEncoding];
    [NSURLConnection sendAsynchronousRequest:request queue:_operationQueue completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        NSLog(@"response:%@",[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
    }];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark XClient Delegate
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)xclientDidConnect:(XClient *)sender withError:(NSError *)error
{
    NSLog(@"xclientDidConnect withError:%@",error);
}

- (void)xclient:(XClient *)sender didReceiveMessage:(XCMessage *)message
{
    //DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    NSLog(@"didReceiveMessage:%@",message.body);
    // A simple example of inbound message handling.
    if (message.type==T_MESSAGE) {
        if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateActive)
        {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:message.from
                                                                message:message.body
                                                               delegate:nil
                                                      cancelButtonTitle:@"Ok"
                                                      otherButtonTitles:nil];
            [alertView show];
        }
        else
        {
            localNotification = [[UILocalNotification alloc] init];
            localNotification.alertAction = @"Ok";
            localNotification.alertBody =message.body;// [NSString stringWithFormat:@"From: %@\n\n%@",message.from,message.body];
            localNotification.soundName = UILocalNotificationDefaultSoundName;
            localNotification.applicationIconBadgeNumber=[UIApplication sharedApplication].applicationIconBadgeNumber+1;
            // [[UIApplication sharedApplication]  scheduleLocalNotification:localNotification];
            [[UIApplication sharedApplication] presentLocalNotificationNow:localNotification];
        }
        
    }
    
}

-(void)xclient:(XClient *)sender didReceiveError:(NSError *)error
{
    NSLog(@"didReceiveError:%@",error.description);
}

- (void)xclientDidDisconnect:(XClient *)sender withError:(NSError *)error
{
    NSLog(@"xclientDidDisconnect withError:%@",error);
}
@end
