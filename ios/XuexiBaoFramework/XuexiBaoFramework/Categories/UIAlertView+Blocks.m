//
//  UIAlertView+Blocks.m
//  Bitbao
//
//  Created by kimziv on 13-6-25.
//  Copyright (c) 2013年 bitbao. All rights reserved.
//

#import "UIAlertView+Blocks.h"
#import <objc/runtime.h>
static NSString *kUIAlertViewHandlerAssociatedKey = @"kUIAlertViewHandlerAssociatedKey";

@implementation UIAlertView (Blocks)

- (void)showWithHandler:(UIAlertViewHandler)handler
{
    objc_setAssociatedObject(self, (__bridge const void *)(kUIAlertViewHandlerAssociatedKey), handler, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    self.delegate=self;
    [self show];
}

#pragma mark - UIAlertView Delegate


//- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
//{
//    UIAlertViewHandler handler=objc_getAssociatedObject(self, (__bridge const void *)(kUIAlertViewHandlerAssociatedKey));
//    if (handler) {
//        handler(alertView ,buttonIndex);
//    }
//    
//}

-(void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex
{
    UIAlertViewHandler handler=objc_getAssociatedObject(self, (__bridge const void *)(kUIAlertViewHandlerAssociatedKey));
    if (handler) {
        handler(alertView ,buttonIndex);
    }
}


@end
