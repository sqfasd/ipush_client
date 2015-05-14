//
//  MDSubBgRetryUpdOperation.m
//  education
//
//  Created by Tim on 14-10-22.
//  Copyright (c) 2014年 mudi. All rights reserved.
//

#import "MDSubBgRetryUpdOperation.h"
#import "MDUploadSubjectOperation.h"
#import "MDXuexiBaoOperationMgr.h"
#import "MDQuestionV2.h"



// 在App Active时尝试启动operation
// 仅在没有上传任务的时候启动operation
@implementation MDSubBgRetryUpdOperation

- (void)main
{
    // 1. 读取本地“上传失败”的列表
    NSArray *updFailArray = [[MDCoreDataUtil sharedInstance] queArrayOfSubUpdFail];
    
    // 1.1. 如果列表为空，则结束operation
    if (!updFailArray || updFailArray.count <= 0)
        return;
    
    // 1.2. 重置题目状态，通知界面刷新
    [[MDCoreDataUtil sharedInstance] queResetQuesStatusForUpload:updFailArray];
    // 1.3. 将已经上传成功的题目增加一次重试
    [[MDCoreDataUtil sharedInstance] queAddRetryForSubUpdSuccess];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:kNTF_QUE_REUPLOAD object:nil];
    });
    
    
    // 2. 遍历上传
    [updFailArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        MDQuestionV2 *question = obj;
        
        NSString *fullBinPath = [MDFileUtil.documentFolder stringByAppendingPathComponent:question.bin_path];
        MDLog(@"bg autoupd fullbinpath: %@", fullBinPath);
        
        MDUploadSubjectOperation *updOperation = [MDUploadSubjectOperation operationWithOriPath:[DIR_ORV2 stringByAppendingPathComponent:question.file_uuid] binPath:fullBinPath guid:question.file_uuid managedObjectID:question.objectID success:^{
            
        } failure:^(NSError *error) {
            
        }];
        
        [[MDXuexiBaoOperationMgr sharedInstance].operationQueue addOperation:updOperation];
    }];
    
    // 将超出3次重试的题目进行删除
    [[MDCoreDataUtil sharedInstance] queClearQuesOverRetry];
}

@end




