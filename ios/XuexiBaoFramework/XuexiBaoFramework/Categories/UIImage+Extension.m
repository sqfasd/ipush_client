//
//  UIImage+Extension.m
//  education
//
//  Created by kimziv on 14-5-6.
//  Copyright (c) 2014年 mudi. All rights reserved.
//

#import "UIImage+Extension.h"


@implementation UIImage (Extension)

+ (UIImage *)imageWithName:(NSString *)name inBundle:(NSBundle *)bundle {
    if (!bundle) {
        return [UIImage imageNamed:@"name"];
    }
    
    NSString *imgPath = [bundle pathForResource:name ofType:@"png"];
    
    return [UIImage imageWithContentsOfFile:imgPath];
}

+ (UIImage *)imageWithColor:(UIColor *)color
{
//    CGRect rect = CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
//    UIGraphicsBeginImageContext(rect.size);
//    CGContextRef context = UIGraphicsGetCurrentContext();
//    
//    CGContextSetFillColorWithColor(context, [color CGColor]);
//    CGContextFillRect(context, rect);
//    
//    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
//    UIGraphicsEndImageContext();
//    
//    return image;
    return [self imageWithColor:color size:CGSizeMake(1.0f,1.0f)];
}

+ (UIImage *)imageWithColor:(UIColor *)color size:(CGSize)size
{
    CGRect rect = (CGRect){0.0f, 0.0f, size};
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

+ (UIImage *)imageWithHexColor:(NSInteger)hexValue
{
    return [self imageWithColor:[UIColor colorWithHex:hexValue]];
}

+ (UIImage *)scaleImage:(UIImage *)image toScale:(float)scaleSize
{
    UIGraphicsBeginImageContext(CGSizeMake(image.size.width * scaleSize, image.size.height * scaleSize));
    [image drawInRect:CGRectMake(0, 0, image.size.width * scaleSize, image.size.height * scaleSize)];
    UIImage *scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return scaledImage;
}

+ (UIImage *)constrainImage:(UIImage *)image withMaxLength:(CGFloat)length
{
    float maxLength = MAX(image.size.width, image.size.height);
    if (maxLength < length)
        return image;

    float scaleSize = 1;
    scaleSize = length / maxLength;
    
    UIGraphicsBeginImageContext(CGSizeMake(image.size.width * scaleSize, image.size.height * scaleSize));
    [image drawInRect:CGRectMake(0, 0, image.size.width * scaleSize, image.size.height * scaleSize)];
    UIImage *scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return scaledImage;
}

- (UIImage *) scaleToSize:(CGSize) size {
    UIGraphicsBeginImageContext(size);
    [self drawInRect:CGRectMake(0,0,size.width,size.height)];
    UIImage * newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

- (UIImage*)imageByScalingAndCroppingForSize:(CGSize)targetSize
{
    CGFloat scaleRate = self.size.width > self.size.height ? targetSize.height / self.size.height : targetSize.height / self.size.width;
    
    CGSize finalTargetSize = CGSizeMake(self.size.width * scaleRate, self.size.height * scaleRate);
    
    UIImage *scaledImage = [self scaleToSize:finalTargetSize];
    
    return [scaledImage getSubImage:CGRectMake((scaledImage.size.width - finalTargetSize.width) / 2,
                                               (scaledImage.size.height - finalTargetSize.height) / 2,
                                               finalTargetSize.width,
                                               finalTargetSize.height)];
}

-(UIImage*)getSubImage:(CGRect)rect
{
    CGImageRef subImageRef = CGImageCreateWithImageInRect(self.CGImage, rect);
    CGRect smallBounds = CGRectMake(0, 0, CGImageGetWidth(subImageRef), CGImageGetHeight(subImageRef));
    
    UIGraphicsBeginImageContext(smallBounds.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextDrawImage(context, smallBounds, subImageRef);
    UIImage* smallImage = [UIImage imageWithCGImage:subImageRef];
    UIGraphicsEndImageContext();
    
    return smallImage;
}


@end




