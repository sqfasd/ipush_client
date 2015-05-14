//
//  MDUploadMgr.m
//  education
//
//  Created by Tim on 14-10-17.
//  Copyright (c) 2014年 mudi. All rights reserved.
//

#import "MDXuexiBaoOperationMgr.h"
#import "MDSubBgRetryUpdOperation.h"
#import "MDBgAutoRefreshQuestions.h"



@interface MDXuexiBaoOperationMgr ()

{
    MDBgAutoRefreshQuestions *refreshQueOperation;
}

@end



@implementation MDXuexiBaoOperationMgr

#pragma mark Initialization
+ (MDXuexiBaoOperationMgr *)sharedInstance
{
    static MDXuexiBaoOperationMgr *sharedMgr = nil;
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        sharedMgr = [[self alloc] init];
    });
    
    return sharedMgr;
}

- (id)init
{
    self = [super init];
    if (self) {

    }
    
    return self;
}


#pragma mark Properties
- (NSOperationQueue *)operationQueue
{
    if (!_operationQueue) {
        _operationQueue = [[NSOperationQueue alloc] init];
        _operationQueue.maxConcurrentOperationCount = 3;
    }
    
    return _operationQueue;
}


- (void)checkAndSyncUpdFailSubjects:(BOOL)force
{
    // 如果有正在处理的任务，就不添加后台任务
    // 为了确保不重复添加此任务
    if (!force) {
        if (self.operationQueue.operationCount > 0)
            return;
    }
    
    // 添加后台任务
    MDSubBgRetryUpdOperation *bgOperation = [[MDSubBgRetryUpdOperation alloc] init];
    [self.operationQueue addOperation:bgOperation];
}

// 触发自动衰减式刷新的Task
- (void)triggerBgAutoRefreshForQuestions
{
    // 1. 如果任务正在执行，则重置刷新条件
    if (refreshQueOperation && !refreshQueOperation.isFinished) {
        MDLog(@"triggerBgAutoRefreshForQuestions operation not FIN");
        [refreshQueOperation reset];
        return;
    }
    
    MDLog(@"triggerBgAutoRefreshForQuestions new operation %@", refreshQueOperation);

    MDLog(@"OPQ size: %lu\noperations:%@", (unsigned long)self.operationQueue.operations.count, self.operationQueue.operations);
    
    // 2. 如果任务为空，或者已经执行完，创建一个新任务执行
    refreshQueOperation = [[MDBgAutoRefreshQuestions alloc] init];
    MDLog(@"OPQ after create MDBgAutoRefreshQuestions");

    [self.operationQueue addOperation:refreshQueOperation];
}

// 触发自动刷新任务“尝试结束”
- (void)triggerBgAutoRefreshForSignal
{
    if (!refreshQueOperation || refreshQueOperation.isFinished) {
        MDLog(@"triggerBgAutoRefreshForSignal operation invalid");
        return;
    }
    
    MDLog(@"triggerBgAutoRefreshForSignal signal");
    [refreshQueOperation signal];
}

@end




