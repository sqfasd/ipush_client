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
- (void)startWithAppKey:(NSString *)appKey secret:(NSString *)secret;



//#pragma mark --
//#pragma mark -- 题目接口
///*!
// *  @method queCountOfSubUpdFailed
// *
// *  @abstract
// *  获取上传失败的题目数量
// *
// *  @return
// *  返回数量
// *
// *  @discussion
// *  UI界面根据需要查询上传出错的题目数量
// */
//- (NSInteger)queCountOfSubUpdFailed;
//
///*!
// *  @method queReuploadSubUpdFailed
// *
// *  @abstract
// *  触发重新上传失败的题目
// *
// *  @discussion
// *  UI界面根据需要调用
// */
//- (void)queReuploadSubUpdFailed;
//
///*!
// *  @method queCountOfSubProcessing
// *
// *  @abstract
// *  获取上传中的题目数量
// *
// *  @discussion
// *  UI界面根据需要调用
// */
//- (NSInteger)queCountOfSubProcessing;
//
///*!
// *  @method queCheckAnySubGetAnswer
// *
// *  @abstract
// *  调用以确认是否有任何题目完成了上传，获得了答案
// *
// *  @discussion
// *  UI界面根据需要调用
// */
//- (void)queCheckAnySubGetAnswer:(NSArray *)queList;

@end




