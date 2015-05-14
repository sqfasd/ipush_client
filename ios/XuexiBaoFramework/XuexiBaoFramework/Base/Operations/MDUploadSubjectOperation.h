//
//  MDUploadSubjectOperation.h
//  education
//
//  Created by Tim on 14-10-17.
//  Copyright (c) 2014年 mudi. All rights reserved.
//

#import <Foundation/Foundation.h>



@interface MDUploadSubjectOperation : NSOperation

// 通过原图内容初始化
+ (MDUploadSubjectOperation *)operationWithImage:(UIImage *)image binPath:(NSString *)binPath guid:(NSString *)queGuid managedObjectID:(NSManagedObjectID *)objectID success:(BlockResponseOK)success failure:(BlockResponseFailure)failure;

// 通过原图路径初始化
+ (MDUploadSubjectOperation *)operationWithOriPath:(NSString *)imgPath binPath:(NSString *)binPath guid:(NSString *)queGuid managedObjectID:(NSManagedObjectID *)objectID success:(BlockResponseOK)success failure:(BlockResponseFailure)failure;

@end




