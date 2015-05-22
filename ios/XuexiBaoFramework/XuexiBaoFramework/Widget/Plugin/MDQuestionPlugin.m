//
//  MDQuestionPlugin.m
//  XuexiBaoFramework
//
//  Created by 王俊 on 15/5/22.
//  Copyright (c) 2015年 杭州皆冠科技有限公司. All rights reserved.
//

#import "MDQuestionPlugin.h"
#import "URBMediaFocusViewController.h"
#import "MDQeustionDetailViewController.h"




@implementation MDQuestionPlugin
@synthesize queParams=_queParams;
@synthesize question=_question;
@synthesize mediaFocusController=_mediaFocusController;

- (void)requestCourseFail:(CDVInvokedUrlCommand *)command {
    MDLog(@"requestCourseFail command: %@", command.arguments);
    
    NSNumber *httpStatus = command.arguments.firstObject;
    NSNumber *respStatus = [command.arguments objectAtIndex:1];
    if (([httpStatus isKindOfClass:[NSNumber class]] && httpStatus.integerValue == 401) ||
        ([respStatus isKindOfClass:[NSNumber class]] && respStatus.integerValue == -3)) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kNTF_REQ_401 object:nil];
    }
}

- (void)getUserInfo:(CDVInvokedUrlCommand *)command {
    [self.commandDelegate runInBackground:^{
        CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:@{@"user_agent":[MDStoreUtil userAgent], @"token":[MDUserUtil sharedInstance].token, @"cookie":[[MDStoreUtil sharedInstance] getObjectForKey:UD_NET_LASTUSED_COOKIE]}];
        
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
    }];
}

- (void)showLoading:(CDVInvokedUrlCommand*)command
{
    [self.commandDelegate runInBackground:^{
        MDQeustionDetailViewController  *controller =(MDQeustionDetailViewController *)self.viewController;
        id params=[controller getQueLoadingParams];
        if (params) {
            CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:params];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
            
        }else{
            [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_NO_RESULT] callbackId:command.callbackId];
        }
    }];
}

- (void)showQuestion:(CDVInvokedUrlCommand*)command
{
    [self.commandDelegate runInBackground:^{
        MDQeustionDetailViewController  *controller =(MDQeustionDetailViewController *)self.viewController;
        [controller getQueDetailWithCallBack:^(id sender) {
            _queParams=sender;
            CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:sender];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        }];
        
    }];
}

- (void)showPhoto:(CDVInvokedUrlCommand*)command
{
    //MDLog(@"showPhoto---");
    NSString *url=[self.queParams nonNullValueForKeyPath:@"question.image_path"];
    self.mediaFocusController = [[URBMediaFocusViewController alloc] init];
    self.mediaFocusController.delegate = self;
    if (url==nil || url.length==0) {
        return;
    }
    
    MDQeustionDetailViewController  *controller =(MDQeustionDetailViewController *)self.viewController;
    if (controller.localImgPath && controller.localImgPath.length>0) {
        [self.mediaFocusController showImage:[UIImage imageWithContentsOfFile:controller.localImgPath] fromRect:CGRectMake(20, 60, 300, 200)];
    }else{
        // [[SDWebImageManager sharedManager] download]
        [self.mediaFocusController showImageFromURL:[NSURL URLWithString:url] fromRect:CGRectMake(20, 100, 300, 200)withPlaceholder:[UIImage imageNamed:XXBRSRC_NAME(@"defaultImage_1")]];
    }
    
}

-(void)showNewAnswer:(CDVInvokedUrlCommand*)command
{
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

-(void)reTryLink:(CDVInvokedUrlCommand*)command
{
    //     MDLog(@"reTryLink");
    //    command.methodName=@"reTryLink";
    //    [self showQuestion:command];
}

-(void)reTakePhoto:(CDVInvokedUrlCommand*)command
{
    MDLog(@"reTakePhoto");
    MDQeustionDetailViewController  *controller =(MDQeustionDetailViewController *)self.viewController;
    [controller retakePhoto];
    
    
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    
}

-(void)changeTitle:(CDVInvokedUrlCommand*)command
{
    MDLog(@"changeTitle");
    
    MDQeustionDetailViewController  *controller =(MDQeustionDetailViewController *)self.viewController;
    [self.commandDelegate runInBackground:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            NSNumber *page=(command.arguments&&command.arguments.count>0)?command.arguments[0]:@(-1);
            [controller changeTitle:page];
            CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        });
    }];
    
    
}


-(void)cacheIndex:(CDVInvokedUrlCommand *)command
{
    MDQeustionDetailViewController  *controller =(MDQeustionDetailViewController *)self.viewController;
    NSString *imgId=controller.imageId;
    NSNumber *cacheIndex=command.arguments.firstObject;
    if (imgId && cacheIndex) {
        [self.commandDelegate runInBackground:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                [[MDStoreUtil sharedInstance] setObject:cacheIndex forKey:[NSString stringWithFormat:kCACHE_KEY_QUE_CACHE_INDEX_FORMAT,imgId]];
            });
            CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        }];
    }
}

-(void)cacheImg:(CDVInvokedUrlCommand *)command
{
    [self.commandDelegate runInBackground:^{
        MDQeustionDetailViewController  *controller =(MDQeustionDetailViewController *)self.viewController;
        NSData* imageData = [NSData dataFromBase64String:[command.arguments objectAtIndex:0]];
        if (imageData && imageData.length>0) {
            UIImage* image = [[UIImage alloc] initWithData:imageData];
            [controller cacheImg:image];
        }
        
    }];
}


@end




@implementation MDQuestionCommandDelegate

-(id)getCommandInstance:(NSString *)pluginName
{
    return [super getCommandInstance:pluginName];
}

/*
 NOTE: this will only inspect execute calls coming explicitly from native plugins,
 not the commandQueue (from JavaScript). To see execute calls from JavaScript, see
 MainCommandQueue below
 */
//- (BOOL)execute:(CDVInvokedUrlCommand*)command
//{
//
//    return [super execute:command];
//}

- (NSString*)pathForResource:(NSString*)resourcepath;
{
    return [super pathForResource:resourcepath];
}


@end

@implementation MDQuestionCommandQueue

/* To override, uncomment the line in the init function(s)
 in MainViewController.m
 */
- (BOOL)execute:(CDVInvokedUrlCommand*)command
{
    return [super execute:command];
}

@end




