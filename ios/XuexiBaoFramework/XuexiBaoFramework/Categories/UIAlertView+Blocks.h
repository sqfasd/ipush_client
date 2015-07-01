//
//  UIAlertView+Blocks.h
//  Bitbao
//
//  Created by kimziv on 13-6-25.
//  Copyright (c) 2013年 bitbao. All rights reserved.
//

#import <UIKit/UIKit.h>
typedef void(^UIAlertViewHandler)(UIAlertView *alertView, NSInteger buttonIndex);
@interface UIAlertView (Blocks)<UIAlertViewDelegate>


- (void)showWithHandler:(UIAlertViewHandler)handler;

@end
