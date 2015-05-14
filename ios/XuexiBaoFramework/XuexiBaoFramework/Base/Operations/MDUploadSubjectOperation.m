//
//  MDUploadSubjectOperation.m
//  education
//
//  Created by Tim on 14-10-17.
//  Copyright (c) 2014年 mudi. All rights reserved.
//

#import "MDUploadSubjectOperation.h"
#import "MDXuexiBaoOperationMgr.h"
#import "UIAlertView+Blocks.h"
#import "MDNetworking.h"
#import "MSWeakTimer.h"
#import "MDLogUtil.h"



#define QUE_NOTIFICATION_TIMEOUT 20
MSWeakTimer *_searchTimer = nil;


@interface MDUploadSubjectOperation ()

@property (nonatomic, strong) UIImage *image;
@property (nonatomic, strong) NSString *queGuid;
@property (nonatomic, strong) NSString *binPath;
@property (nonatomic, strong) NSManagedObjectID *objectID;
@property (nonatomic, strong) BlockResponseOK blockSuccess;
@property (nonatomic, strong) BlockResponseFailure blockFailure;

@end


@implementation MDUploadSubjectOperation

// image: 原图
// binPath: 二值化相对路径
// oriPath: 原图相对路径
// objectID: CoreData记录项ID
// success: 成功的Block
// failure: 失败的Block
+ (MDUploadSubjectOperation *)operationWithImage:(UIImage *)image binPath:(NSString *)binPath guid:(NSString *)queGuid managedObjectID:(NSManagedObjectID *)objectID success:(BlockResponseOK)success failure:(BlockResponseFailure)failure
{
    MDUploadSubjectOperation *newOp = [[MDUploadSubjectOperation alloc] init];
    
    newOp.image = image;
    newOp.queGuid = queGuid;
    newOp.binPath = binPath;
    newOp.objectID = objectID;
    newOp.blockSuccess = success;
    newOp.blockFailure = failure;
    
    return newOp;
}

// 通过原图路径初始化
+ (MDUploadSubjectOperation *)operationWithOriPath:(NSString *)oriPath binPath:(NSString *)binPath guid:(NSString *)queGuid managedObjectID:(NSManagedObjectID *)objectID success:(BlockResponseOK)success failure:(BlockResponseFailure)failure
{
    MDUploadSubjectOperation *newOp = [[MDUploadSubjectOperation alloc] init];
    
    if (oriPath || oriPath.length > 0) {
        newOp.image = [UIImage imageWithContentsOfFile:[MDFileUtil.documentFolder stringByAppendingPathComponent:oriPath]];
    }
    newOp.binPath = binPath;
    newOp.queGuid = queGuid;
    newOp.objectID = objectID;
    newOp.blockSuccess = success;
    newOp.blockFailure = failure;
    
    return newOp;
}

- (void)main
{
    if (!self.objectID || !self.queGuid) {
        return;
    }
    
    // 5. 开始实际上传
    NSString *url = [NSString stringWithFormat:@"%@", MD_DOMAIN_PIC];
    NSDictionary *input = nil;
    if (self.binPath) {
        NSError *error = nil;
        NSData *binData = [NSData dataWithContentsOfFile:self.binPath options:0 error:&error];
        if (!binData || binData.length <= 0) {
            MDLog(@"UpdSubOperation binPath empty: %@ dbid:%@", self.binPath, self.objectID);
            [SVProgressHUD showStatus:[NSString stringWithFormat:@"binPath empty: %@", error]];

            return;
        }
        
        input = [NSDictionary dictionaryWithObjectsAndKeys:binData, @"files[]", nil];
    }
    else {
        if (self.image) {
            NSData *imgData = UIImageJPEGRepresentation(self.image, 1.0);
            if (!imgData || imgData.length <= 0) {
                // tim.wangj.test
                [SVProgressHUD showStatus:[NSString stringWithFormat:@"Img empty: %@", NSStringFromCGSize(self.image.size)]];
                return;
            }

            input = [NSDictionary dictionaryWithObjectsAndKeys:imgData, @"files2[]", nil];
        }
        else {
            input = [NSDictionary dictionaryWithObjectsAndKeys:[[NSData alloc] init], @"files[]", nil];
        }
    }
    MDLog(@"UpdSubOperation post params dbid:%@", self.objectID);
    
    
    [[MDNetworking sharedInstance] POSTForFileContent:url withInput:input timeout:60 success:^(id responseObject) {
        LogFile([NSString stringWithFormat:@"POSTFile OK: %@", responseObject]);
        
        MDLog(@"UpdSubOperation postFile resp: %@ dbid:%@", responseObject, self.objectID);
        
        __block NSString *imgUuid=[responseObject nonNullObjectForKey:@"image_id"];

        LogFile([NSString stringWithFormat:@"processUploading OK move oriimg.jpg to %@", imgUuid]);

        // 上传的imageid无效
        if (!imgUuid || ![imgUuid isKindOfClass:[NSString class]] || imgUuid.length <= 0) {
            MDLog(@"UpdSubOperation imageID invalid dbid:%@", self.objectID);
            
            [[MDCoreDataUtil sharedInstance] queUploadImageFailed:self.objectID];
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:kNTF_QUE_NEW_UPDFAIL object:nil];
            });
            self.blockFailure(nil);
        }
        // 上传的imageid有效
        else {
            // 上传成功，更新状态之后
            if (imgUuid && [imgUuid isKindOfClass:[NSString class]] && imgUuid.length>0) {
                // (0) 将ImageID更新到CoreData中
                [[MDCoreDataUtil sharedInstance] queSetImageIDFor:self.objectID imageID:imgUuid];
                
                // (1) 删除原图
                NSString *fileUUID = [[MDCoreDataUtil sharedInstance] queLocalFileGuidFor:imgUuid];
                
                MDLog(@"UpdSubOperation after updimg gotImgID:%@ fileUUID:%@ dbid:%@", imgUuid, fileUUID, self.objectID);
                [MDFileUtil deleteFileAtPath:[MDFileUtil.documentFolder stringByAppendingPathComponent:[DIR_ORV2 stringByAppendingPathComponent:fileUUID]]];
                
                // (2) 将彩图更名为imageid
                NSString *folder = [MDFileUtil.documentFolder stringByAppendingPathComponent:DIR_DATA];
                [MDFileUtil renameFile:[folder stringByAppendingPathComponent:fileUUID] to:[folder stringByAppendingPathComponent:imgUuid]];
                
                // (3) 将图片标记为未读
                [MDStoreUtil QueAddUnreadImgID:imgUuid];
            }
            

            MDLog(@"UpdSubOperation triggerBgAutoRefreshForQuestions dbid:%@", self.objectID);
            // 触发“自动刷新”机制
            [[MDXuexiBaoOperationMgr sharedInstance] triggerBgAutoRefreshForQuestions];
            
//            NSNumber *hasDisableNoPushAlert = [[MDStoreUtil sharedInstance] getObjectForKey:kCACHE_NOPUSHREMIND_NOMORE];
//            if (!hasDisableNoPushAlert || hasDisableNoPushAlert.boolValue == NO) {
//                UIAlertView *alert = [UIAlertView alloc] initWithTitle:@"提示" message:<#(NSString *)#> delegate:<#(id)#> cancelButtonTitle:<#(NSString *)#> otherButtonTitles:<#(NSString *), ...#>, nil
//                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"alert_title", @"") message:NSLocalizedString(@"push_alert", @"") cancelButtonTitle:@"知道了" otherButtonTitle:@"不再提示"];
//                [alert actionWithBlocksCancelButtonHandler:^{
//                    
//                } otherButtonHandler:^{
//                    [[MDStoreUtil sharedInstance] setObject:[NSNumber numberWithBool:YES] forKey:kCACHE_NOPUSHREMIND_NOMORE];
//                }];
//            }
            
            // 2. 如果上传成功，调用数据库更新接口，更新Status
            [[MDCoreDataUtil sharedInstance] updateQueWhenBinImgUploaded:self.objectID data:responseObject completion:^(BOOL suc, NSError *error) {

                if (suc) {
                    MDLog(@"UpdSubOperation success: %@ dbid:%@", responseObject, self.objectID);
                    
                    //7. 调用success
                    self.blockSuccess();
                }else{
                    MDLog(@"UpdSubOperation fail: %@ dbid:%@", responseObject, self.objectID);
                    
                    LogFile(@"updateQueWhenBinImgUploaded fail!!!");

                    if (error!=nil) {//数据存储失败
                        error = [NSError errorWithDomain:ERROR_DOMAIN code:ERROR_COREDATA userInfo:@{@"updateQueWhenBinImgUploaded":@"fail"}];
                        self.blockFailure(error);
                    }
                }
            }];
        }
        
    } failure:^(NSError *error) {
        MDLog(@"UpdSubOperation post file fail: %@\nupdate dbiD:%@", error, self.objectID);
        
        [[MDCoreDataUtil sharedInstance] queUploadImageFailed:self.objectID];
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:kNTF_QUE_NEW_UPDFAIL object:nil];
        });

        LogFile([NSString stringWithFormat:@"POSTFIle Fail: %@", error]);

        self.blockFailure(error);
    }];
}

@end




