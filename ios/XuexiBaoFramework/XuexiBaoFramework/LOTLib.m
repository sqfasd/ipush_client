//
//  LOTLib.m
//  XuexiBaoFramework
//
//  Created by 王俊 on 15/5/12.
//  Copyright (c) 2015年 杭州皆冠科技有限公司. All rights reserved.
//



#import "LOTLib.h"
//#import <xcomet/xcomet.h>

//#import "xcomet.h"
#import "UIActionSheet+Blocks.h"
#import "MDXuexiBaoOperationMgr.h"
#import "MDQuestionV2.h"



@interface LOTLib ()

@end



@implementation LOTLib

+ (instancetype)sharedInstance {
    static LOTLib *sharedlib = nil;
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        sharedlib = [[self alloc] init];
    });
    
    return sharedlib;
}

- (id)init {
    self = [super init];
    if (self) {
        
    }
    
    return self;
}

- (void)startWithAppKey:(NSString *)appKey secret:(NSString *)secret {
    // 0. 设置appkey 与 appsecret
    [[MDStoreUtil sharedInstance] setObject:appKey forKey:PARAM_SDK_APPKEY];
    [[MDStoreUtil sharedInstance] setObject:secret forKey:PARAM_SDK_APPSECRET];
    
    // 1. binddevice
    [[MDXuexiBaoAPI sharedInstance] bindDeviceSuccess:^(id responseObject) {
        if (IsResponseOK(responseObject)) {
            [[MDUserUtil sharedInstance] setToken:[responseObject nonNullValueForKeyPath:@"result.token"]];
            // [[MDUserUtil sharedInstance] setMobileBind:[[responseObject nonNullValueForKeyPath:@"result.ismobilebind"]boolValue]];
            [[MDUserUtil sharedInstance] setUserID:[responseObject nonNullValueForKeyPath:@"result.userid"]];
            [[MDUserUtil sharedInstance] setLogin:[[responseObject nonNullValueForKeyPath:@"result.is_login"] boolValue]];
//            [MDUserUtil sharedInstance].pushToken=JsonValue([responseObject nonNullValueForKeyPath:@"result.pushtoken"],CLASS_NSSTRING);
            
            [[NSNotificationCenter defaultCenter] postNotificationName:kNOTIFICATION_NAME_BIND_DEV_FINISHED object:nil];
        }
        else {
            MDLog(@"bindDevice resp invalid: %@", responseObject);
        }
        
    } failure:^(NSError *error) {
        MDLog(@"bindDevice fail: %@", error);
    }];
    
    
    // 2. TalkingData统计
    // 学习宝教师版：8D338D321EE8E7807CAF938ED5C6D514
    // 学习宝：B3EC7279F87374F9F4856095ED0A2998
    [TalkingData sessionStarted:@"8D338D321EE8E7807CAF938ED5C6D514" withChannelId:@"TalkingData"];
    [TalkingData setExceptionReportEnabled:NO];
    
    
//    // 3. 初始化Push模块
//    self.xClient.enableBackgroundingOnSocket = YES;
//    [self.xClient addDelegate:self delegateQueue:dispatch_get_main_queue()];
    
    
    // 4. 初始化CoreData
    [[MDCoreDataUtil sharedInstance] initCoreData];
}




#pragma mark --
#pragma mark -- 题目接口
/*!
 *  @method queCountOfSubUpdFailed
 *
 *  @abstract
 *  获取上传失败的题目数量
 *
 *  @return
 *  返回数量
 *
 *  @discussion
 *  UI界面根据需要查询上传出错的题目数量
 */
- (NSInteger)queCountOfSubUpdFailed {
    return [[MDCoreDataUtil sharedInstance] queCountOfSubUpdFail];
}

/*!
 *  @method queReuploadSubUpdFailed
 *
 *  @abstract
 *  触发重新上传失败的题目
 *
 *  @discussion
 *  UI界面根据需要调用
 */
- (void)queReuploadSubUpdFailed {
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:[NSString stringWithFormat:@"%li道题目上传失败：", (long)[[MDCoreDataUtil sharedInstance] queCountOfSubUpdFail]] delegate:nil cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
    
    [actionSheet addButtonWithTitle:@"全部上传"];
    [actionSheet addButtonWithTitle:@"全部删除"];
    
    actionSheet.cancelButtonIndex = [actionSheet addButtonWithTitle:NSLocalizedString(@"取消", @"")];
    
    [actionSheet showInView:[UIApplication sharedApplication].keyWindow handler:^(UIActionSheet *actionSheet, NSInteger buttonIndex) {
        // 全部上传
        if (buttonIndex == 0) {
            [[MDXuexiBaoOperationMgr sharedInstance] checkAndSyncUpdFailSubjects:YES];
        }
        // 全部删除
        else if (buttonIndex == 1) {
            [[MDCoreDataUtil sharedInstance] queClearQuesUploadFailed];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:kNTF_REFRESH_QUESTIONLIST object:nil];
        });
    }];

}

/*!
 *  @method queCountOfSubProcessing
 *
 *  @abstract
 *  获取上传中的题目数量
 *
 *  @discussion
 *  UI界面根据需要调用
 */
- (NSInteger)queCountOfSubProcessing {
    return [[MDCoreDataUtil sharedInstance] queCountOfSubProcessing];
}

/*!
 *  @method queCheckAnySubGetAnswer
 *
 *  @abstract
 *  调用以确认是否有任何题目完成了上传，获得了答案
 *
 *  @discussion
 *  UI界面根据需要调用
 */
- (void)queCheckAnySubGetAnswer:(NSArray *)questions {
    if (!questions || questions.count <= 0)
        return;
    
    NSArray *processingList = [[MDCoreDataUtil sharedInstance] queArrayOfSubProcessing];
    if (!processingList || processingList.count <= 0)
        return;
    
    BOOL hasMatchData = NO;
    NSMutableArray *removeImgIDs = [[NSMutableArray alloc] init];
    
    for (NSString *imgId in questions) {
        for (MDQuestionV2 *dbQue in processingList) {
            MDLog(@"dbQue imgID:%@", dbQue.image_id);
            
            if ([dbQue.image_id isEqualToString:imgId]) {
                MDLog(@"found equal");
                [removeImgIDs addObject:dbQue.image_id];
                hasMatchData = YES;
            }
        }
    }
    
    if (hasMatchData) {
        [[MDCoreDataUtil sharedInstance] queRemoveQuesWithArrImgID:removeImgIDs.copy];

        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:kNTF_REFRESH_QUESTIONLIST object:nil];
        });
    }

}

@end




