//
//  MDCoreDataUtil.m
//  education
//
//  Created by kimziv on 14-5-7.
//  Copyright (c) 2014年 mudi. All rights reserved.
//

#import "MDCoreDataUtil.h"
#import "MDQuestionV2.h"



#define kRETRY_CNT_MAX 3
@implementation MDCoreDataUtil

+(id)sharedInstance
{
    static MDCoreDataUtil *_sharedCoreDataUtil =nil;
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        _sharedCoreDataUtil=[[self alloc] init];
    });
    return _sharedCoreDataUtil;
}

-(void)initCoreData
{
    [MagicalRecord setupAutoMigratingCoreDataStack];
}


#pragma mark Subject 题目接口
//-(NSManagedObjectContext *)managedObjectContext
//{
//    return [NSManagedObjectContext MR_defaultContext];
//}

-(NSManagedObjectID *)queAddQueWhenBinImgCreated:(NSString *)oriImgPath binImgPath:(NSString *)binImgPath
{
    if (oriImgPath && binImgPath && oriImgPath.length>0 && binImgPath.length>0)
    {
        MDQuestionV2 *question=[MDQuestionV2 MR_createEntity];
        question.ori_path=oriImgPath;
        question.bin_path=binImgPath;
        question.create_time=[NSDate date];
        question.update_time=question.create_time;
        question.status=[NSNumber numberWithInteger:QueStatusBinCreated];
        question.retry = [NSNumber numberWithInteger:0];
//        question.needBgPull=[NSNumber numberWithBool:[[MDStoreUtil sharedInstance] canReceivePush]];
//        question.lastRequestTime=question.create_time;
       // [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
        return question.objectID;
    }
    
    return nil;
}

-(void)queAddQueWhenBinImgCreated:(NSString *)guid oriImgPath:(NSString *)oriImgPath binImgPath:(NSString *)binImgPath completion:(QueAddCompletion)completion
{
    
    __block MDQuestionV2 *question=nil;
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        if (oriImgPath && binImgPath && oriImgPath.length>0)
        {
            question=[MDQuestionV2 MR_createInContext:localContext];
            question.ori_path=oriImgPath;
            question.bin_path=binImgPath;
            question.file_uuid = guid;
            question.create_time=[NSDate date];
            question.update_time=question.create_time;
            question.status=[NSNumber numberWithInteger:QueStatusBinCreated];
            question.retry = [NSNumber numberWithInteger:0];
//            question.needBgPull=[NSNumber numberWithBool:[[MDStoreUtil sharedInstance] canReceivePush]];
//            question.lastRequestTime=question.createTime;
           // [localContext MR_saveToPersistentStoreAndWait];
        }
    } completion:^(BOOL success, NSError *error) {
        if (completion) {
            completion(question.objectID);
        }
    }];
    
}

- (NSString *)queLocalFileGuidFor:(NSString *)imageID
{
    NSArray *localFileGuids = [MDQuestionV2 MR_findAllWithPredicate:[NSPredicate predicateWithFormat:@"%K == %@", MDQuestionV2Attributes.image_id, imageID]];

    if (!localFileGuids || localFileGuids.count <= 0)
        return @"";
    
    MDQuestionV2 *result = localFileGuids.firstObject;
    return result.file_uuid;
}

- (void)queRemoveQuesWithArrImgID:(NSArray *)arrImgIDs
{
    if (!arrImgIDs || arrImgIDs.count <= 0)
        return;
    
    for (NSString *imgID in arrImgIDs) {
        [self queRemoveQueWithImageID:imgID];
    }
}

- (void)queRemoveQueWithImageID:(NSString *)imageID
{
    if (!imageID)
        return;
    
    [MDQuestionV2 MR_deleteAllMatchingPredicate:[NSPredicate predicateWithFormat:@"%K == %@", MDQuestionV2Attributes.image_id, imageID]];
}

- (void)queRemoveQueWithFileUUID:(NSString *)fileUUID
{
    if (!fileUUID)
        return;
    
    [MDQuestionV2 MR_deleteAllMatchingPredicate:[NSPredicate predicateWithFormat:@"%K == %@", MDQuestionV2Attributes.file_uuid, fileUUID]];
}

- (void)queUploadImageFailed:(NSManagedObjectID *)objectID
{
    if (!objectID)
        return;

    [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *localContext) {
        MDQuestionV2 *question = (MDQuestionV2 *)[localContext objectWithID:objectID];
        question.status = [NSNumber numberWithInteger:QueStatusUploadedFail];
        question.update_time = [NSDate date];
        question.read_status = [NSNumber numberWithInteger:ReadStatusNo];
    }];
}

// 返回ImageID后，将Imageid添加到记录中
- (void)queSetImageIDFor:(NSManagedObjectID *)objectID imageID:(NSString *)imageID
{
    if (!objectID || !imageID || imageID.length <= 0)
        return;
    
    [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *localContext) {
        MDQuestionV2 *question = (MDQuestionV2 *)[localContext objectWithID:objectID];
        
        question.image_id = imageID;
    }];
}

// 将制定问题重置回上传状态
- (void)queResetQuesStatusForUpload:(NSArray *)questions
{
    if (!questions || questions.count <= 0)
        return;
    
    for (MDQuestionV2 *question in questions) {
        [self queResetQuestionStatusForUpload:question.objectID];
    }
}

- (void)queResetQuestionStatusForUpload:(NSManagedObjectID *)objectID
{
    if (!objectID)
        return;
    
    [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *localContext) {
        MDQuestionV2 *question = (MDQuestionV2 *)[localContext objectWithID:objectID];
        question.status = [NSNumber numberWithInteger:QueStatusBinCreated];
        question.retry = [NSNumber numberWithInteger:question.retry.integerValue + 1];
    }];
}

// 将超出重试次数的题目进行清除
- (void)queClearQuesOverRetry
{
    [MDQuestionV2 MR_deleteAllMatchingPredicate:[NSPredicate predicateWithFormat:@"%K > 10", MDQuestionV2Attributes.retry]];
}

- (NSInteger)queCountOfSubProcessing
{
    NSArray *result = [self queArrayOfSubProcessing];
    
    if (!result)
        return 0;
    
    for (MDQuestionV2 *que in result) {
        MDLog(@"queCountOfSubProcessing imgID:%@ fileUUID:%@",
              que.image_id,
              que.file_uuid);
    }
    
    return result.count;
}

- (NSArray *)queArrayOfSubProcessing
{
    NSArray *result = [MDQuestionV2 MR_findAllWithPredicate:[NSPredicate predicateWithFormat:@"(%K == %i) AND (%K <= 10)", MDQuestionV2Attributes.status, QueStatusBinCreated, MDQuestionV2Attributes.retry]];

    return result;
}

// “上传成功”的题目
- (NSInteger)queCountOfSubUpdSuccess
{
    NSArray *result = [self queArrayOfSubUpdSuccess];
    
    if (!result)
        return 0;
    
    return result.count;
}

- (NSArray *)queArrayOfSubUpdSuccess
{
    NSArray *result = [MDQuestionV2 MR_findAllWithPredicate:[NSPredicate predicateWithFormat:@"%K == %i", MDQuestionV2Attributes.status, QueStatusUploadedSuccess]];
    
    return result;
}

- (void)queAddRetryForSubUpdSuccess
{
    NSArray *arrayUpdSuccess = [self queArrayOfSubUpdSuccess];
    if (!arrayUpdSuccess || arrayUpdSuccess.count <= 0)
        return;
    
    for (MDQuestionV2 *question in arrayUpdSuccess) {
        [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *localContext) {
            question.retry = [NSNumber numberWithInteger:question.retry.integerValue + 1];
        }];
    }
}

- (NSInteger)queCountOfSubUpdFail
{
    NSArray *result = [self queArrayOfSubUpdFail];
    
    if (!result)
        return 0;
    
    return result.count;
}

- (NSArray *)queArrayOfSubUpdFail
{
    NSArray *result = [MDQuestionV2 MR_findAllWithPredicate:[NSPredicate predicateWithFormat:@"(%K == %i) AND (%K <= 10)", MDQuestionV2Attributes.status, QueStatusUploadedFail, MDQuestionV2Attributes.retry]];
    
    return result;
}

// 将所有上传错误的题目清除掉
- (void)queClearQuesUploadFailed
{
    [MDQuestionV2 MR_deleteAllMatchingPredicate:[NSPredicate predicateWithFormat:@"%K == %i", MDQuestionV2Attributes.status, QueStatusUploadedFail]];
}


-(void)updateQueWhenBinImgUploaded:(NSManagedObjectID *)objectId  data:(NSDictionary *)data completion:(MRSaveCompletionHandler)completion
{
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        if (data==nil || data.allKeys.count==0) {
            return ;
        }
        NSString *imgUuid=[data nonNullObjectForKey:@"image_id"];
        if (objectId) {
            MDQuestionV2 *question=(MDQuestionV2 *)[localContext objectWithID:objectId];
            if (imgUuid && [imgUuid isKindOfClass:[NSString class]] && imgUuid.length>0) {
                question.image_id=imgUuid;
                question.status=[NSNumber numberWithInteger:QueStatusUploadedSuccess];
            }else{//上传失败
                question.status=[NSNumber numberWithInteger:QueStatusUploadedFail];
            }
            question.update_time=[NSDate date];
            question.read_status=[NSNumber numberWithInteger:ReadStatusNo];
            [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
        }
    } completion:completion];
}

//-(void)updateQueWhenNotificationRecevied:(NSDictionary *)data completion:(MRSaveCompletionHandler)completion
//{
//    
//    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
//        NSNumber *type=[data nonNullValueForKeyPath:@"aps.type"];
//        if (type && (type.integerValue==kNOTIFICATION_TYPE_QUE || type.integerValue==kNOTIFICATION_TYPE_QUE_REPORT)) {
//            NSString *imgId=[data nonNullValueForKeyPath:@"aps.data.image_id"];
//            if (imgId && [imgId  hasPrefix:@"'"]) {
//                imgId=[imgId stringByReplacingOccurrencesOfString:@"'" withString:@""];
//            }
//            
//            if (imgId && imgId.length>0 ) {
//                MDQuestionV2 *question=[MDQuestionV2 MR_findFirstByAttribute:MDQuestionV2Attributes.image_id withValue:imgId inContext:localContext];
//                if (question) {
//                    question.status=[NSNumber numberWithInteger:QueStatusReceviedNotification];
//                    question.image_id=imgId;
////                    question.pushType=type;
//                    NSNumber *queStatus=[data nonNullValueForKeyPath:@"aps.data.status"];
//                    if (queStatus && queStatus.integerValue==400) {//成功;400图片识别失败;500，找不到问题答案
//                        question.status=[NSNumber numberWithInteger:QueStatusRecognitionImgFail];
//                    }else if (queStatus && queStatus.integerValue==500) {
//                        question.status=[NSNumber numberWithInteger:QueStatusAnswerNotFound];
//                    }
////                    question.readStatus=[NSNumber numberWithInteger:0];
//                }
//            }
//           // [localContext MR_saveToPersistentStoreAndWait];
//        }
//    } completion:completion];
//}

//查处问题数量
-(NSInteger)queryQuesCnt
{
      return  [MDQuestionV2 MR_countOfEntitiesWithPredicate:[NSPredicate predicateWithFormat:@"%K.length > 0",MDQuestionV2Attributes.image_id]];
}


-(void)updateQueReadStatus:(NSDictionary *)data completion:(MRSaveCompletionHandler)completion
{
    
}

// 获取已经上传成功，但没有通知识别结果的题目
- (NSArray *)queryQuesNoResponse
{
    return [MDQuestionV2 MR_findAllSortedBy:MDQuestionV2Attributes.update_time ascending:NO withPredicate:[NSPredicate predicateWithFormat:@"%K == %@", MDQuestionV2Attributes.status, QueStatusUploadedSuccess]];
}



-(NSInteger)queryQuesGotAndUnreadCnt
{
  return  [MDQuestionV2 MR_countOfEntitiesWithPredicate:[NSPredicate predicateWithFormat:@"(%K == %i) AND (%K == %i)",MDQuestionV2Attributes.status,QueStatusGetAnswerSuccess,MDQuestionV2Attributes.read_status,ReadStatusNo]];
    //return  [MDQuestion MR_findAllSortedBy:MDQuestionAttributes.lastRequestTime ascending:NO withPredicate:[NSPredicate predicateWithFormat:@"(%K == %@) AND (%K == YES)",MDQuestionAttributes.status,QueStatusGetAnswerSuccess,MDQuestionAttributes.readStatus]];
}

-(void)delQuestion:(MDQuestionV2 *)question inContext:(NSManagedObjectContext *)context completion:(void (^)(BOOL success, NSError *error))completion
{
    NSString *oriImgPath=question.ori_path;
    NSString *binImgPath=question.bin_path;
    [context deleteObject:question];
    [context MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
        if (completion) {
            completion(success,error);
        }
    }];
    [MDFileUtil deleteFileAtPath:oriImgPath];
    [MDFileUtil deleteFileAtPath:binImgPath];
}


-(MDQuestionV2 *)queryQueWhidImgId:(NSString *)imgId
{
    if (imgId==nil || imgId.length==0) {
        return nil;
    }
    return [MDQuestionV2 MR_findFirstByAttribute:MDQuestionV2Attributes.image_id withValue:imgId];
}

@end




