//
//  MDAddNewQuestionOperation.h
//  education
//
//  Created by Tim on 14-10-17.
//  Copyright (c) 2014年 mudi. All rights reserved.
//

#import <Foundation/Foundation.h>



// 拍照之后创建新题目的任务
// 主要负责二值化+本地文件存储管理
// 上传部分由NSUploadSubjectOperation处理
@interface MDAddNewQuestionOperation : NSOperation

+ (MDAddNewQuestionOperation *)operationWithImage:(UIImage *)image success:(BlockResponseOK)success failure:(BlockResponseFailure)failure;

@property (nonatomic, strong) __block UIImage *cropImage;
@property (nonatomic, strong) BlockResponseOK blockSuccess;
@property (nonatomic, strong) BlockResponseFailure blockFailure;

@end




