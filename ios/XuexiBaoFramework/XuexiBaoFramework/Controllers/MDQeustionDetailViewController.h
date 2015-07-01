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

+ (MDQeustionDetailViewController *)instance;

@property (nonatomic, strong) NSDictionary *questionDic;
@property (nonatomic, strong) NSString *imageId;
@property (nonatomic, strong) NSNumber *updateTime;
@property (nonatomic, strong) NSString *audioNewQuestionID;

@property(nonatomic, strong)NSString *localImgPath;

-(NSDictionary *)getQueLoadingParams;
-(void)getQueDetailWithCallBack:(void(^)(id sender))callBack;
-(void)retakePhoto;
-(void)changeTitle:(NSNumber *)page;
-(void)cacheImg:(UIImage *)image;

@end


