//
//  MDCoreDataUtil.h
//  education
//
//  Created by kimziv on 14-5-7.
//  Copyright (c) 2014年 mudi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MagicalRecord/NSManagedObjectContext+MagicalSaves.h>


//typedef void (^MRSaveCompletionHandler)(BOOL success, NSError *error);
@class MDQuestionV2;
@class MDCacheBulletin;
@class MDTopicData;
@class MDCirUnreadMsgData;



typedef void (^CDAddCompletion)(NSManagedObjectID *objectId);
typedef void (^QueAddCompletion)(NSManagedObjectID *objectId);


typedef enum : NSUInteger {
    TOPIC_STATUS_INIT = 0,
    TOPIC_STATUS_IMGUPD = 1,
    TOPIC_STATUS_OK = 2
} TOpicStatus;


@interface MDCoreDataUtil : NSObject

+(id)sharedInstance;

-(void)initCoreData;



#pragma mark Subject 题目接口
// 以下为拍题接口：
//Sync Method
//-(NSManagedObjectID *)addQueWhenBinImgCreated:(NSString *)oriImgPath binImgPath:(NSString *)binImgPath;
//Async Method
-(void)queAddQueWhenBinImgCreated:(NSString *)guid oriImgPath:(NSString *)oriImgPath binImgPath:(NSString *)binImgPath completion:(QueAddCompletion)completion;

// 返回ImageID后，将Imageid添加到记录中
- (void)queSetImageIDFor:(NSManagedObjectID *)objectID imageID:(NSString *)imageID;

// 根据imageID查询本地uuid
- (NSString *)queLocalFileGuidFor:(NSString *)imageID;

// 根据ImageID 删除问题
- (void)queRemoveQuesWithArrImgID:(NSArray *)arrImgIDs;
- (void)queRemoveQueWithImageID:(NSString *)imageID;
// 根据本地uuid删除问题
- (void)queRemoveQueWithFileUUID:(NSString *)fileUUID;

// 某个问题上传失败，更新该题状态
- (void)queUploadImageFailed:(NSManagedObjectID *)objectID;

// 将制定问题重置回上传状态
- (void)queResetQuesStatusForUpload:(NSArray *)questions;
- (void)queResetQuestionStatusForUpload:(NSManagedObjectID *)objectID;
// 将超出重试次数的题目进行清除
- (void)queClearQuesOverRetry;
// 将所有上传错误的题目清除掉
- (void)queClearQuesUploadFailed;

// “识别中”的题目（未上传、已上传）
- (NSInteger)queCountOfSubProcessing;
- (NSArray *)queArrayOfSubProcessing;

// “上传失败”的题目
- (NSInteger)queCountOfSubUpdFail;
- (NSArray *)queArrayOfSubUpdFail;

// “上传成功”的题目
- (NSInteger)queCountOfSubUpdSuccess;
- (NSArray *)queArrayOfSubUpdSuccess;
- (void)queAddRetryForSubUpdSuccess;

/*
 {
 files =     (
 {
 deleteType = DELETE;
 deleteUrl = "http://searchapi.taofangfei.com:3001/data/upload/public/files/1400065079210.bin";
 name = "1400065079210.bin";
 size = 1175;
 type = "image/jpeg";
 url = "http://searchapi.taofangfei.com:3001/data/upload/public/files/1400065079210.bin";
 }
 );
 "image_id" = "9c97a0a0-db56-11e3-a0a7-ef00485964b0";
 }
 */

-(void)updateQueWhenBinImgUploaded:(NSManagedObjectID *)objectId  data:(NSDictionary *)data completion:(MRSaveCompletionHandler)completion;
/*
 {
 aps =     {
 alert = "\U7b54\U6848\U6765\U4e86\Uff01";
 badge = 9;
 data =         {
 "image_id" = "'9c97a0a0-db56-11e3-a0a7-ef00485964b0'";
 msg = "no result";
 status = "-1";
 };
 sound = "bingbong.aiff";
 type = 10;
 };
 }
 */
-(void)updateQueWhenNotificationRecevied:(NSDictionary *)data completion:(MRSaveCompletionHandler)completion;
/*
 {
 "status" : 0,
 "result" : [
 {
 "question_body" : "已知关于x，y的方程组 \\begin{cases}3x-y=5\\\\4ax+5by=-22\\end{cases}和 \\begin{cases}2x+3y=-4\\\\ax-by=8\\end{cases}有相同解，求（-a） b值．",
 "question_answer" : "",
 "score" : 2.9345448,
 "question_tag" : "同解方程组",
 "_version_" : 1464467750640418800,
 "question_id" : "80171",
 "answer_analysis" : "xxx",
 "question_body_html" : "xxx"
 }
 ],
 "image_id" : "'d08ac7f0-bfec-11e3-88e6-b726f4807fbe'",
 "msg" : "ok",
 "numFound" : 618516,
 "raw_text" : "22.(8分)若方程组\\begin{cases}4x-y=5,\\\\ax+by=-1\\end{cases}与\\begin{cases}3x+y=9,\\3ax-4by=18\\end{cases}有公共,求a、b的值.\n "
 }
 */
//-(void)updateQueWhenQeustionGot:(NSDictionary *)data isPull:(BOOL)isPull completion:(MRSaveCompletionHandler)completion;

-(void)updateQueReadStatus:(NSDictionary *)data completion:(MRSaveCompletionHandler)completion;


//查处问题数量
-(NSInteger)queryQuesCnt;

////查询需要后台上传的问题
//-(NSArray *)queryQuesNeedBgPull;
////retry次数++
//-(void)increaseRetryCnt:(NSManagedObjectID*)objId

// ******* V2.0 Begin
// 获取已经上传成功，但没有通知识别结果的题目
- (NSArray *)queryQuesNoResponse;
// ******* V2.0 End

//根据状态和retry次数查询结果
//-(NSArray *)queryQuesAtStatus:(QueStatus)status limitRetries:(NSInteger)retryCnt;

////查询没有上传的任务
//-(NSArray *)queryQuesNotUpload;

//查询未读数量
-(NSInteger)queryQuesGotAndUnreadCnt;

////查询没有获取答案的任务
//-(NSArray *)queryQuesNotGet;


//-(void)delQuestion:(MDQuestion *)question inContext:(NSManagedObjectContext *)context;
-(void)delQuestion:(MDQuestionV2 *)question inContext:(NSManagedObjectContext *)context completion:(void (^)(BOOL success, NSError *error))completion;

-(MDQuestionV2 *)queryQueWhidImgId:(NSString *)imgId;

//-(void)delQuestionWithImgId:(NSString *)imgId completion:(MRSaveCompletionHandler)completion;
//
//-(void)delQuestion:(MDQuestion *)question completion:(MRSaveCompletionHandler)completion;

@end




