//
//  UIColor+Extension.h
//  education
//
//  Created by kimziv on 14-5-6.
//  Copyright (c) 2014年 mudi. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIColor (Extension)
+ (UIColor*) colorWithHex:(NSInteger)hexValue alpha:(CGFloat)alphaValue;
+ (UIColor*) colorWithHex:(NSInteger)hexValue;
- (NSString*) hexFromUIColor;
@end
