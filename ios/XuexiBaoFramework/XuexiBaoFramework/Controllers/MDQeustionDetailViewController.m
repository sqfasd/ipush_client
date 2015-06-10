//
//  MDQeustionDetailViewController.m
//  education
//
//  Created by kimziv on 14-5-7.
//  Copyright (c) 2014年 mudi. All rights reserved.
//

#import "MDQeustionDetailViewController.h"
#import "SCNavigationController.h"
#import "MDEditPhotoViewController.h"
#import "MDQueListViewController.h"
#import "UIViewController+Extension.h"
#import "UIAlertView+Blocks.h"
#import "MSWeakTimer.h"
#import "EGOCache.h"
#import "SDImageCache.h"
#import "MDNetworking.h"
#import "MDStoreUtil.h"
#import "KxMenu.h"
#import "MDQuestionPlugin.h"



#define  SINA_WEIBO_MAX_LEN 140
#define  WAIT_TIME_SECONDS 20



typedef enum : NSUInteger {
    LOGINOK_OPERTYPE_REQAUDIO = 1,
    LOGINOK_OPERTYPE_BUYAUDIO = 2
} LOGINOK_OPERTYPE;


@interface MDQeustionDetailViewController ()<UIActionSheetDelegate>

{
    MDQuestionPlugin *_plugin;
    NSArray *_shareActivities;
    NSString *_audioUrl;
    NSArray *_notEmptyAnswers;
    NSInteger  _audioTopIndex;
    
    // 未登录时，请求音频的临时变量
    NSString *requestAudioQueID;
    NSNumber *requestAudioQueIndex;
    
    // 登录完成后，需要进行操作的处理类型
    NSInteger loginOKOperType;
    BOOL      _isMenuShown;
    
    NSInteger displayIndex;
    
    BOOL isWBFirstPlay;
    NSString *playingWBId;
}


@property   (assign, nonatomic)                 BOOL                            enableShowAlertView;
@property   (assign,nonatomic)                  BOOL                            isFetchingList;

@end



@implementation MDQeustionDetailViewController
//@synthesize question=_question;
@synthesize imageId=_imageId;
@synthesize questionDic=_questionDic;
@synthesize localImgPath=_localImgPath;
@synthesize updateTime=_updateTime;
//@synthesize menuItems=_menuItems;


+ (MDQeustionDetailViewController *)instance {
    UIStoryboard *storyBoard = [UIStoryboard storyboardWithName:@"LOTStoryboard" bundle:XXBFRAMEWORK_BUNDLE];
    MDQeustionDetailViewController *detailVC = [storyBoard instantiateViewControllerWithIdentifier:@"MDQeustionDetailViewController"];

    return  detailVC;
}


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:NO];

//    [XueXiBao trackPageBegin:NSStringFromClass([MDQeustionDetailViewController class])];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    if ([self.webView isLoading]) {
        [self.webView stopLoading];
    }
    [self.webView stringByEvaluatingJavaScriptFromString:@"stopAudio();"];

//    // 如果选择的题目变了，向服务端请求一次换一题接口
//    NSNumber *cacheIndex=[[MDStoreUtil sharedInstance]getObjectForKey:[NSString stringWithFormat:kCACHE_KEY_QUE_CACHE_INDEX_FORMAT,_imageId]];
//    if (cacheIndex && cacheIndex.integerValue != displayIndex) {
//        if (cacheIndex.integerValue < _notEmptyAnswers.count) {
//            NSDictionary *answer = [_notEmptyAnswers objectAtIndex:cacheIndex.integerValue];
//            NSString *queId = [answer nonNullObjectForKey:@"question_id"];
//            if (!queId)
//                queId = @"";
//
//            [[MDXuexiBaoAPI sharedInstance] postForAPI:MD_DOMAIN api:OP_QUE_CHOOSE post:@{@"image_id":_imageId, @"question_id":queId} success:^(id responseObject) {
//                
//            } failure:^(NSError *error) {
//                
//            }];
//        }
//    }
    
//    [XueXiBao trackPageEnd:NSStringFromClass([MDQeustionDetailViewController class])];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self initViews];
    
    _isMenuShown = NO;
    _plugin =  [self.commandDelegate getCommandInstance:@"MDQuestionPlugin"];
    _plugin.viewController = self;
    self.enableShowAlertView = YES;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // 将未读状态改为已读状态
    [MDStoreUtil QueRemoveUnreadImgID:self.imageId];
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:kNOTIFICATION_NAME_QuestionRead object:@{@"que_read_status":@1, @"image_id":self.imageId}];
    });
}

-(void)retryLink
{
    //[self showQuestion:@{@"status":[NSNumber numberWithInteger:0]}];
    //[self getQueDetail:_imageId];
}

-(NSDictionary *)getQueLoadingParams
{
    if (_imageId==nil || _imageId.length==0) {
        return nil;
    }
    if ([_imageId  hasPrefix:@"'"]) {
        _imageId=[_imageId stringByReplacingOccurrencesOfString:@"'" withString:@""];
    }
    NSString *localImgPath=  [MDFileUtil.documentFolder stringByAppendingPathComponent:[DIR_DATA stringByAppendingPathComponent:[NSString stringWithFormat:@"%@",_imageId]]];
    if (![[NSFileManager defaultManager] fileExistsAtPath:localImgPath]) {
        localImgPath=@"";
    }
    if (!localImgPath || localImgPath.length==0) {
        localImgPath=[[SDImageCache sharedImageCache] defaultCachePathForKey:self.imageId];
        if (![[NSFileManager defaultManager] fileExistsAtPath:localImgPath]) {
            localImgPath=@"";
        }
    }
    
    self.localImgPath=localImgPath;
    
    return @{@"status":@0,
             @"question":@{@"update_time":self.updateTime?self.updateTime:[NSNull null],
                           @"image_path":localImgPath?localImgPath:@""},
             @"machine_answers":@[],
             @"human_answer":[NSNull null],
             @"local_img_path":localImgPath};
}




-(NSArray *)fillterAnswers:(NSArray *)answers
{
    if (!answers || answers.count==0) {
        return nil;
    }
    NSMutableArray *results=[NSMutableArray array];
    NSMutableArray *notEmptyAnswers=[NSMutableArray array];
    
    
    
    [answers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSDictionary *answer=obj;
        //[notEmptyAnswers addObject:answer];
        if (!answer || answer.count==0) {
            return ;
        }
        NSString *questionId=[answer objectForKey:@"question_id"];
        NSString *questionAnswer=[answer nonNullObjectForKey:@"question_answer"];
        NSString *questionBody=[answer objectForKey:@"question_body_html"];
        NSString *answerAnalysis=[answer nonNullObjectForKey:@"answer_analysis"];
        NSString *questionTag=[answer objectForKey:@"question_tag"];
        NSString *subject=[answer objectForKey:@"subject"];
        questionAnswer= questionAnswer?[questionAnswer stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]:@"";
        answerAnalysis=answerAnalysis?[answerAnalysis stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]:@"";
        if ((!questionAnswer || questionAnswer.length==0) && (!answerAnalysis || answerAnalysis.length==0)) {
            MDLog(@"questionAnswer is empty.");
            return;
        }
        [notEmptyAnswers addObject:answer];
        NSMutableDictionary *fillteredAnswer = @{@"questionId":questionId,
                                                 @"answer":questionAnswer,
                                                 @"image_id":self.imageId,
                                                 @"body":questionBody,
                                                 @"analysis":answerAnalysis,
                                                 @"tags":questionTag,
                                                 @"subject":subject}.mutableCopy;
        NSDictionary *audio=[answer nonNullObjectForKey:@"audio"];
        NSInteger audioStatus=RequestAudioStatusNotRequest;
        if (audio && audio.count>0) {
            NSString *audioId=[audio objectForKey:@"id"];
            NSNumber *duration=[audio objectForKey:@"duration"];
            NSNumber *gold=[audio objectForKey:@"gold"];
            NSNumber *isPay=[audio objectForKey:@"is_pay"];
            NSString *url=[audio objectForKey:@"url"];
            NSNumber *hasNewAudio=[audio objectForKey:@"hasNewAudio"];
            NSNumber *hasCommentAudio = [audio objectForKey:@"hasCommentAudio"] ? [audio objectForKey:@"hasCommentAudio"] : [NSNumber numberWithBool:NO];
            
            if (hasNewAudio && hasNewAudio.boolValue) {
                audioStatus=RequestAudioStatusNewAudio;
            }else{
                audioStatus=RequestAudioStatusOldAudio;
            }
            
            
            if ([MDUserUtil sharedInstance].isLogin) {
//                NSNumber *hasRemarked = [[MDStoreUtil sharedInstance] getObjectForKey:[NSString stringWithFormat:kCACHE_FORMAT_AUDIO_HASREMARK, [MDUserUtil sharedInstance].userID, audioId]];
//                if (hasRemarked && [hasRemarked isKindOfClass:[NSNumber class]]) {
//                    hasCommentAudio = hasRemarked;
//                }
//                
//                NSNumber *isPaid=[[MDStoreUtil sharedInstance] getObjectForKey:[NSString stringWithFormat:kCACHE_KEY_AUDIO_PAY_FORMAT,[MDUserUtil sharedInstance].userID,audioId]];
//                NSString *relativeAudioPath=[[MDStoreUtil sharedInstance] getObjectForKey:[NSString stringWithFormat:kCACHE_KEY_AUDIO_PATH_FORMAT,audioId]];
//                NSString *fullPath=[[MDFileUtil cachesFolder] stringByAppendingPathComponent:relativeAudioPath];
//                if (relativeAudioPath && relativeAudioPath.length>0 && [[NSFileManager defaultManager] fileExistsAtPath:([fullPath isKindOfClass:[NSString class]])?fullPath:@""]) {
//                    isPay=@(isPaid && isPaid.boolValue);
//                    url=fullPath;
//                }else{
//                    // isPay=@(isPaid && isPaid.boolValue);
//                    //url=@"";
//                }
                
                //获取置顶index
                if ( self.audioNewQuestionID && [self.audioNewQuestionID isEqualToString:questionId]) {
                    _audioTopIndex=idx;
                }
            }else{
                isPay=@(NO);
               // url=@"";
            }
            /*
             audio =                 {
             duration = 170;
             gold = 20;
             hasNewAudio = 0;
             id = "96ea7d40-f7d2-456a-a18f-6ccaa3709147";
             isPay = true;
             "is_pay" = 1;
             name = "103332_\U5b59\U96ea\U98de_15546392203.mp3";
             "order_id" = 100;
             "question_id" = 103332;
             url = "http://192.168.2.3:8080/4,1aee193f8873";
             };
             */
            //url=@"http://192.168.2.3:8081/3,015c4873f1";
            [fillteredAnswer addEntriesFromDictionary:@{@"audioId":audioId,
                                                        @"audioDuration":duration,
                                                        @"audioGold":gold,
                                                        @"audioHasPay":isPay,
                                                        @"audioUrl":url,
                                                        @"hasCommentAudio":hasCommentAudio,
                                                        @"audioStatus":@(audioStatus)}];
        }else{
//            NSNumber *isRequest=[[MDStoreUtil sharedInstance] getObjectForKey:[NSString stringWithFormat:kCACHE_KEY_AUDIO_IS_REQUESTED_FORMAT,self.imageId,questionId]];
//            if (isRequest&& isRequest.boolValue) {
//                audioStatus=RequestAudioStatusAlreadyRequest;
//            }else{
//                audioStatus=RequestAudioStatusNotRequest;
//            }

            [fillteredAnswer addEntriesFromDictionary:@{@"audioStatus":@(audioStatus)}];
            
        }
        [results addObject:fillteredAnswer];
    }];
    _notEmptyAnswers=notEmptyAnswers;
    
    return results;
}




-(NSDictionary *)fillterQuestion:(NSDictionary *)question
{
    if (!question || question.count==0) {
        return nil;
    }
    NSString *createTime=[question objectForKey:@"create_time"];
    NSString *updateTime=[question objectForKey:@"update_time"];
    NSString *imageId=[question objectForKey:@"image_id"];
    NSString *imagePath=[question objectForKey:@"image_path"];
    
    if ([imageId  hasPrefix:@"'"]) {
        imageId=[imageId stringByReplacingOccurrencesOfString:@"'" withString:@""];
    }
    NSString *localImgPath=  [MDFileUtil.documentFolder stringByAppendingPathComponent:[DIR_DATA stringByAppendingPathComponent:[NSString stringWithFormat:@"%@",imageId]]];
    
    if (localImgPath && localImgPath.length>0) {
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:localImgPath]) {
            imagePath=localImgPath;
        }else{
            localImgPath=[[SDImageCache sharedImageCache] defaultCachePathForKey:self.imageId];
            if ([[NSFileManager defaultManager] fileExistsAtPath:localImgPath]) {
                imagePath=localImgPath;
            }
        }
    }
    else{
        localImgPath=[[SDImageCache sharedImageCache] defaultCachePathForKey:self.imageId];
        if ([[NSFileManager defaultManager] fileExistsAtPath:localImgPath]) {
            imagePath=localImgPath;
        }
    }
    
    
    
    NSMutableDictionary *fillteredQuestion = @{@"create_time":createTime,
                                               @"update_time":updateTime,
                                               @"image_id":imageId,
                                               @"image_path":imagePath}.mutableCopy;
    return fillteredQuestion;
}

//-(NSInteger)getAudioIndex
//{
//
//}

-(void)getQueDetailWithCallBack:(void(^)(id sender))callBack
{
    if (_imageId==nil || _imageId.length==0) {
        return;
    }
    
    if ([_imageId  hasPrefix:@"'"]) {
        _imageId=[_imageId stringByReplacingOccurrencesOfString:@"'" withString:@""];
    }
    
    if (self.audioNewQuestionID && self.audioNewQuestionID.length!=0) {
        [[EGOCache globalCache]removeCacheForKey:[NSString stringWithFormat:kCACHE_KEY_QUE_DETAIL_FORMAT,self.imageId]];//清除缓存
    }
    
    [[MDXuexiBaoAPI sharedInstance] getQuestionAnswers:@{@"image_id":_imageId} success:^(id responseObject, BOOL cached) {
        NSNumber *cacheIndex=[[MDStoreUtil sharedInstance]getObjectForKey:[NSString stringWithFormat:kCACHE_KEY_QUE_CACHE_INDEX_FORMAT,_imageId]];
        if (cacheIndex) {
            displayIndex = cacheIndex.integerValue;
        }

        if (IsResponseOK(responseObject)) {
            _questionDic=[responseObject nonNullObjectForKey:@"result"];
            if (self.questionDic!=nil) {
                
                NSArray *answers=[self.questionDic nonNullValueForKeyPath:@"answers"];
                answers=[self fillterAnswers:answers];
                // NSDictionary *bestAnswer=[self.questionDic nonNullValueForKeyPath:@"best_reply"];
                NSDictionary *quesion=[self.questionDic nonNullValueForKeyPath:@"question"];
                quesion=[self fillterQuestion:quesion];
                
                NSNumber *isAsk=[self.questionDic nonNullValueForKeyPath:@"is_ask"];
                if (isAsk && !isAsk.boolValue) {
                    isAsk=[[MDStoreUtil sharedInstance] getObjectForKey:[NSString stringWithFormat:kCACHE_KEY_QUE_CACHE_IS_ASKED_FORMAT,self.imageId]];
                }else if (isAsk && isAsk.boolValue){
                    isAsk=@(YES);
                }
                if ( (answers && answers.count>0)  && quesion) {
                    
                    if (callBack) {
                        if (cached) {
                            
                            if(cacheIndex && cacheIndex.integerValue<answers.count){
                                callBack(@{@"status":@2,
                                           @"question":quesion?quesion:[NSNull null],
                                           @"machine_answers":answers?answers:@[],
                                           @"cache_index":cacheIndex,
                                           @"is_ask":isAsk?isAsk:@(NO),
                                           @"audio_top_index":@(_audioTopIndex)}
                                         );
                            }else{
                                callBack(@{@"status":@1,
                                           @"question":quesion?quesion:[NSNull null],
                                           @"machine_answers":answers?answers:@[],
                                           @"is_ask":isAsk?isAsk:@(NO),
                                           @"audio_top_index":@(_audioTopIndex)});
                            }
                        }else{
                            if(cacheIndex && cacheIndex.integerValue<answers.count){
                                callBack(@{@"status":@2,
                                           @"question":quesion?quesion:[NSNull null],
                                           @"machine_answers":answers?answers:@[],
                                           @"cache_index":cacheIndex,
                                           @"is_ask":isAsk?isAsk:@(NO),
                                           @"audio_top_index":@(_audioTopIndex)});
                            }else{
                                callBack(@{@"status":@1,
                                           @"question":quesion?quesion:[NSNull null],
                                           @"machine_answers":answers?answers:@[],
                                           @"is_ask":isAsk?isAsk:@(NO),
                                           @"audio_top_index":@(_audioTopIndex)});
                                
                            }
                            if (self.audioNewQuestionID && self.audioNewQuestionID.length!=0) {
//                                [[NSNotificationCenter defaultCenter]postNotificationName:kNTF_QUE_NEWAUDIO_HASREAD object:nil  userInfo:@{@"image_id":_imageId}];
                            }
                        }
                    }
                    
                }else if ( (answers==nil || answers.count==0)  && quesion) {
                    if (callBack) {
                        callBack(@{@"status":[NSNumber numberWithInteger:-1],
                                   @"question":quesion?quesion:[NSNull null],
                                   @"machine_answers":@[],
                                   @"is_ask":isAsk?isAsk:@(NO)});
                    }
                    [self changeTitle:@0];
                }else {
                    if (callBack) {
                        callBack(@{@"status":[NSNumber numberWithInteger:-2]});
                    }
                }
                dispatch_async(dispatch_get_main_queue(), ^{
                    //[self updateViews];
                });
                
            } else{
                if (callBack) {
                    callBack(@{@"status":[NSNumber numberWithInteger:-2]});
                }
            }
        }
        
    } failure:^(NSError *error) {
        if (callBack) {
            callBack(@{@"status":[NSNumber numberWithInteger:-2]});
        }
    }];
}

-(void)updateAudioRequestStatus:(NSDictionary *)audio index:(NSNumber *)index status:(RequestAudioStatus)status questionID:(NSString *)queID
{
    // NSNumber *index=@1;
    if (!status) {
        MDLog(@"updateAudioRequestStatus:status is empty");
        return;
    }
    
    NSDictionary *params=nil;
    if (status==RequestAudioStatusAlreadyRequest) {
        params=@{@"index":index,
                 @"audioStatus":@(status),
                 @"hasQuest":[NSNumber numberWithBool:YES]};
        
//        NSNumber *cacheIndex=[[MDStoreUtil sharedInstance]getObjectForKey:[NSString stringWithFormat:kCACHE_KEY_QUE_CACHE_INDEX_FORMAT,_imageId]];
//        MDLog(@"cacheIndex:%@", cacheIndex.description);
        
        [[EGOCache globalCache]setObject:@{} forKey:[NSString stringWithFormat:kCACHE_KEY_QUE_DETAIL_FORMAT,self.imageId]];//清除缓存

    }else if(status==RequestAudioStatusNewAudio){
        if(!audio || audio.count==0){
            MDLog(@"updateAudioRequestStatus:audio is empty");
            return;
        }
        NSNumber *audioDuration=[audio objectForKey:@"duration"];
        NSNumber *audioGold=[audio objectForKey:@"gold"];
        NSNumber *audioUrl=[audio objectForKey:@"url"];
        params=@{@"index":index,
                 @"audioStatus":@(status),
                 @"audioDuration":audioDuration?audioDuration:@0,
                 @"audioGold":audioGold?audioGold:@0,
                 @"image_id":self.imageId,
                 @"questionId":queID,
                 @"audioUrl":audioUrl?audioUrl:@""
                 };
        //        [[EGOCache globalCache]setObject:@{} forKey:[NSString stringWithFormat:kCACHE_KEY_QUE_DETAIL_FORMAT,self.imageId]];//清除缓存
        //         [[EGOCache globalCache]removeCacheForKey:[NSString stringWithFormat:kCACHE_KEY_QUE_DETAIL_FORMAT,self.imageId]];//清除缓存
    }else{
        MDLog(@"updateAudioRequestStatus:status is not right");
        return;
    }
    NSError *error=nil;
    NSData *data=[NSJSONSerialization dataWithJSONObject:params options:0 error:&error];
    NSString *jsStr=[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    [self.webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"requestCourseSucc(%@);",jsStr]];
}


-(void)dealloc
{
    [self.webView setDelegate:nil];
    self.webView=nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)initViews
{
    //self.title=@"题目详情";
    _audioTopIndex=-1;
    
    self.view.backgroundColor = COLOR_BG_COMMON;
    self.webView.backgroundColor = COLOR_BG_COMMON;
}

-(void)initRightNavBtn
{
    //     NSNumber *cacheIndex=[[MDStoreUtil sharedInstance]getObjectForKey:[NSString stringWithFormat:kCACHE_KEY_QUE_CACHE_INDEX_FORMAT,self.imageId]];
    //    if (cacheIndex && cacheIndex.integerValue !=-1) {
    //        NavBarItemInfo info={.type=NavBarItemTypeMore};
    //      self.navigationItem.rightBarButtonItem=[self makeNavBtn:info location:NavBarLocationRight];
    //    }else{
    //        NavBarItemInfo info={.type=NavBarItemTypeNone, .title=@"删除"};
    //        self.navigationItem.rightBarButtonItem=[self makeNavBtn:info location:NavBarLocationRight];
    //    }
    
    //[self updateViews];
}

-(BOOL)hasMachineAnswer{
    NSArray *answers=_notEmptyAnswers;//[self.questionDic nonNullValueForKeyPath:@"answers"];
    // NSDictionary *bestAnswer=[self.questionDic nonNullValueForKeyPath:@"best_reply"];
    NSDictionary *quesion=[self.questionDic nonNullValueForKeyPath:@"question"];
    //    return ( ((answers && answers.count>0) || (bestAnswer && bestAnswer.count>0))  && quesion);
    return ((answers && answers.count>0) && quesion);
}

- (void)leftNavBtnAction:(id)sender
{
    [super leftNavBtnAction:sender];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)rightNavBtnAction:(id)sender
{
    // [self doRequestAduioAction];
    
    NSNumber *cacheIndex=[[MDStoreUtil sharedInstance]getObjectForKey:[NSString stringWithFormat:kCACHE_KEY_QUE_CACHE_INDEX_FORMAT,self.imageId]];
    if (cacheIndex && cacheIndex.integerValue !=-1) {
        [self showMenu:sender];
    }else{
        [self deleteMenuItemClicked:sender];
    }
}

-(void)showMenu:(UIView *)sender
{
    
    [KxMenu setTintColor:[UIColor whiteColor]];
    NSArray *menuItems =
    @[
      [KxMenuItem menuItem:@"删除"
                     image:[UIImage imageNamed:XXBRSRC_NAME(@"btn_delete_h")]
                    target:self
                    action:@selector(deleteMenuItemClicked:)],
      ];
    

    if(!_isMenuShown){
        _isMenuShown = YES;
        [KxMenu showMenuInView:self.navigationController.view fromRect:CGRectMake(self.view.width-60, 15, 60, 40) menuItems:menuItems];
    }else{
        _isMenuShown = NO;
        [KxMenu dismissMenu];
    }
}




- (void) deleteMenuItemClicked:(id)sender
{
    // [self doRequestAduioAction];
    __weak MDQeustionDetailViewController * weakSelf = self;
    
    UIAlertView *alert=[[UIAlertView alloc] initWithTitle:nil message:NSLocalizedString(@"是否删除该题目?", @"") delegate:nil cancelButtonTitle:NSLocalizedString(@"取消", @"") otherButtonTitles:NSLocalizedString(@"delete", @"delete"), nil];
    [alert showWithHandler:^(UIAlertView *alertView, NSInteger buttonIndex) {
        if (buttonIndex==1) {
            [self deleteQuestion:weakSelf.imageId callBack:^(id response) {
                [[NSNotificationCenter defaultCenter] postNotificationName:kNOTIFICATION_NAME_DelQuestion object:nil userInfo:@{@"image_id":weakSelf.imageId}];
                [weakSelf.navigationController popViewControllerAnimated:YES];
            }];
        }
    }];
}

-(void)updateViews
{
    
    if ([self hasMachineAnswer]) {
        NSNumber *cacheIndex=[[MDStoreUtil sharedInstance]getObjectForKey:[NSString stringWithFormat:kCACHE_KEY_QUE_CACHE_INDEX_FORMAT,self.imageId]];
        if (cacheIndex && cacheIndex.integerValue !=-1) {
            NavBarItemInfo info={.type=NavBarItemTypeMore};
            //self.navigationItem.rightBarButtonItem=[self makeNavBtn:info location:NavBarLocationRight];
            [self setRightNavButton:[self makeNavBtn:info location:NavBarLocationRight]];
            
        }else{
            NavBarItemInfo info={.type=NavBarItemTypeCancel};
            //self.navigationItem.rightBarButtonItem=[self makeNavBtn:info location:NavBarLocationRight];
            [self setRightNavButton:[self makeNavBtn:info location:NavBarLocationRight]];
        }
        
    }else{
        self.navigationItem.rightBarButtonItem=nil;
    }
    // self.navigationItem.rightBarButtonItem.customView.hidden=![self hasMachineAnswer];
}

- (void) setRightNavButton:(UIBarButtonItem*)buttonItem
{
    UIBarButtonItem * negativeSpacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    negativeSpacer.width = -16;
    self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:negativeSpacer,buttonItem, nil];
}




#pragma mark -- Notifications

-(void)deleteQuestion:(NSString *)imageId callBack:(void(^)(id response))callBack
{
    if (imageId==nil || imageId.length==0) {
        MDLog(@"imageid is nil");
        return;
    }
    
    [SVProgressHUD showMDBusying];
    
    [[MDXuexiBaoAPI sharedInstance] postForAPI:MD_DOMAIN api:OP_QUE_DELETE post:@{@"image_ids":imageId} success:^(id responseObject) {
        if (IsResponseOK(responseObject)) {
            if (callBack) {
                callBack(responseObject);
            }
            
            [SVProgressHUD showStatus:@"成功删除提问"];
        }
    } failure:^(NSError *error) {
        
    }];
    
}

#pragma mark -



-(void)retakePhoto
{
    [[MDQueListViewController sharedInstance] showCameraController];
}

-(void)changeTitle:(NSNumber *)page
{
    if (page) {
        
        if (page.integerValue==0) {
            self.title=NSLocalizedString(@"题目详情", @"");
            NavBarItemInfo info={.type=NavBarItemTypeDelete};
            [self setRightNavButton:[self makeNavBtn:info location:NavBarLocationRight]];
            
            UIButton *button=(UIButton *)[self makeNavBtn:info location:NavBarLocationRight].customView;
            [button removeTarget:self action:@selector(rightNavBtnAction:) forControlEvents:UIControlEventTouchUpInside];
            [button addTarget:self action:@selector(deleteMenuItemClicked:) forControlEvents:UIControlEventTouchUpInside];
            
            
        }else if(page.integerValue==1){
            self.title=NSLocalizedString(@"题目详情", @"");
            NavBarItemInfo info={.type=NavBarItemTypeMore};
            [self setRightNavButton:[self makeNavBtn:info location:NavBarLocationRight]];
            
            UIButton *button=(UIButton *)[self makeNavBtn:info location:NavBarLocationRight].customView;
            
            [button removeTarget:self action:@selector(rightNavBtnAction:) forControlEvents:UIControlEventTouchUpInside];
            [button removeTarget:self action:@selector(deleteMenuItemClicked:) forControlEvents:UIControlEventTouchUpInside];
            [button addTarget:self action:@selector(showMenu:) forControlEvents:UIControlEventTouchUpInside];
            
        }
    }
    
}



- (NSString *)secs2Str:(NSInteger)totalSeconds
{
    if (totalSeconds<0) {
        return @"";
    }
    int seconds = totalSeconds % 60;
    int minutes = (totalSeconds / 60) % 60;
    int hours = (int)totalSeconds / 3600;
    
    return [NSString stringWithFormat:@"%02d:%02d:%02d",hours, minutes, seconds];
}



-(void)cacheImg:(UIImage *)image
{
    
    [[SDImageCache sharedImageCache] storeImage:image forKey:self.imageId];//
    
}


- (void) webViewDidStartLoad:(UIWebView*)theWebView
{
    return [super webViewDidStartLoad:theWebView];
}

- (void) webView:(UIWebView*)theWebView didFailLoadWithError:(NSError*)error
{
    return [super webView:theWebView didFailLoadWithError:error];
}

- (BOOL) webView:(UIWebView*)theWebView shouldStartLoadWithRequest:(NSURLRequest*)request navigationType:(UIWebViewNavigationType)navigationType
{
    return [super webView:theWebView shouldStartLoadWithRequest:request navigationType:navigationType];
}

- (void)webViewDidFinishLoad:(UIWebView*)theWebView
{
    [super webViewDidFinishLoad:theWebView];
    
    //    // 将未读状态改为已读状态
    //    [MDStoreUtil QueRemoveUnreadImgID:self.imageId];
    //    dispatch_async(dispatch_get_main_queue(), ^{
    //        [[NSNotificationCenter defaultCenter] postNotificationName:kNOTIFICATION_NAME_QuestionRead object:@{@"que_read_status":@1}];
    //    });
}

//-(void)showSeekHelpPage
//{
//    [self.webView stringByEvaluatingJavaScriptFromString:@"myPlugin.showQuestion();"];
//}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
 {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

//- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
//{
//    MDLog(@"buttonIndex %i clicked.",buttonIndex);
//    switch (buttonIndex) {
//        case 0:
//            [self reportError:REPORT_ERROR_RECOGNIZATION];
//            break;
//        case 1:
//            // [self reportError:REPORT_ERROR_ANSWER];
//            break;
//        default:
//            break;
//    }
//}

#pragma mark - HTTP API


@end
