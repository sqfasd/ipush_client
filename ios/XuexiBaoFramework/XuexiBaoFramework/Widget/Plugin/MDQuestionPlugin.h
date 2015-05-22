//
//  MDQuestionPlugin.h
//  XuexiBaoFramework
//
//  Created by 王俊 on 15/5/22.
//  Copyright (c) 2015年 杭州皆冠科技有限公司. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cordova/CDV.h>
#import <Cordova/CDVCommandDelegateImpl.h>
#import "URBMediaFocusViewController.h"




@interface MDQuestionPlugin : CDVPlugin<URBMediaFocusViewControllerDelegate>
//@property(nonatomic, strong)NSDictionary *questionDic;
@property(nonatomic, strong)NSDictionary *queParams;
@property(nonatomic, strong)MDQuestionV2 *question;
@property (nonatomic, strong) URBMediaFocusViewController *mediaFocusController;

- (void)showQuestion:(CDVInvokedUrlCommand*)command;

- (void)showPhoto:(CDVInvokedUrlCommand*)command;

@end

@interface MDQuestionCommandDelegate : CDVCommandDelegateImpl

@end

@interface MDQuestionCommandQueue : CDVCommandQueue

@end
