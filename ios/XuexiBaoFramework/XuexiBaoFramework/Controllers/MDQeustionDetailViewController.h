//
//  MDQeustionDetailViewController.h
//  education
//
//  Created by kimziv on 14-5-7.
//  Copyright (c) 2014年 mudi. All rights reserved.
//

#import <Cordova/CDV.h>
#import <Cordova/CDVCommandDelegateImpl.h>
#import "MDQuestionV2.h"
#import  "URBMediaFocusViewController.h"

typedef NS_ENUM(NSInteger, RequestAudioStatus) {
    RequestAudioStatusNotRequest=0,
    RequestAudioStatusAlreadyRequest,
    RequestAudioStatusNewAudio,
    RequestAudioStatusOldAudio
};


@interface MDQeustionDetailViewController : CDVViewController

@property (nonatomic, strong) NSDictionary *questionDic;
@property (nonatomic, strong) NSString *imageId;
@property (nonatomic, strong) NSNumber *updateTime;
@property (nonatomic, strong) NSString *audioNewQuestionID;

@end



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