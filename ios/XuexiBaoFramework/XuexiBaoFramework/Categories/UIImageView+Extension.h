//
//  UIImageView+Extension.h
//  education
//
//  Created by kimziv on 14-6-3.
//  Copyright (c) 2014年 mudi. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImageView (Extension)

//用户信息相关图片异步加载
- (void)setInfoImageWithURL:(NSString *)url placeHolder:(UIImage*)placeHolder;
//学习圈列表图片异步加载
- (void)setCircleImageWithURL:(NSString *)url placeHolder:(UIImage*)placeHolder;
//其他图片异步加载
- (void)setGeneralImageWithURL:(NSString *)url placeHolder:(UIImage*)placeHolder;
@end
