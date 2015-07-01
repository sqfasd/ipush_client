//
//  MDUploadMgr.h
//  education
//
//  Created by Tim on 14-10-17.
//  Copyright (c) 2014年 mudi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MDUploadSubjectOperation.h"



#define DISTATCH_MAIN_ASYNC(x) dispatch_async(dispatch_get_main_queue(), ^{x});

@interface MDXuexiBaoOperationMgr : NSObject

+ (MDXuexiBaoOperationMgr *)sharedInstance;

@property (nonatomic, strong) NSOperationQueue *operationQueue;

- (void)checkAndSyncUpdFailSubjects:(BOOL)force;

// 触发自动衰减式刷新的Task
- (void)triggerBgAutoRefreshForQuestions;
// 触发自动刷新任务“尝试结束”
- (void)triggerBgAutoRefreshForSignal;

@end
