//
//  UIImage+Extension.h
//  education
//
//  Created by kimziv on 14-5-6.
//  Copyright (c) 2014年 mudi. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface UIImage (Extension)

+ (UIImage *)imageWithName:(NSString *)name inBundle:(NSBundle *)bundle;
+ (UIImage *)imageWithColor:(UIColor *)color;
+ (UIImage *)imageWithColor:(UIColor *)color size:(CGSize)size;
+ (UIImage *)imageWithHexColor:(NSInteger)hexValue;
+ (UIImage *)scaleImage:(UIImage *)image toScale:(float)scaleSize;
+ (UIImage *)constrainImage:(UIImage *)image withMaxLength:(CGFloat)length;

//size
- (UIImage *) scaleToSize:(CGSize) size;
- (UIImage*) imageByScalingAndCroppingForSize:(CGSize)targetSize;
-(UIImage*)getSubImage:(CGRect)rect;

@end
