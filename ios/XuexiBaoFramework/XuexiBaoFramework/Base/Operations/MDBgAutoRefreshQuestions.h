//
//  MDBgAutoRefreshQuestions.h
//  education
//
//  Created by Tim on 14-11-6.
//  Copyright (c) 2014年 mudi. All rights reserved.
//

#import <Foundation/Foundation.h>



@interface MDBgAutoRefreshQuestions : NSOperation

// 重置刷新状态
- (void)reset;

// 触发一次消息：尝试结束任务
- (void)signal;

@end




