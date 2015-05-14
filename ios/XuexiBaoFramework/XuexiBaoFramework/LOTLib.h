//
//  LOTLib.h
//  XuexiBaoFramework
//
//  Created by 王俊 on 15/5/12.
//  Copyright (c) 2015年 杭州皆冠科技有限公司. All rights reserved.
//



#import <Foundation/Foundation.h>




@interface LOTLib : NSObject

/*!
 *  @method sharedInstance
 *
 *  @abstract
 *  returns shared instance of XuexiBaoManager
 *
 *  @return
 *  返回实例
 */
+ (instancetype)sharedInstance;

/*!
 *  @method sharedInstance
 *
 *  @abstract
 *  进行XuexiBaoManager的初始化工作
 *
 *  @discussion
 *  尽可能在App运行早期调用
 *  推荐：UIApplicationDelegate -> didFinishLaunchingWithOptions
 */
- (void)doInit;

@end
