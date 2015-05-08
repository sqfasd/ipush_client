//
//  MDCropImageView.m
//  education
//
//  Created by Tim on 14-10-27.
//  Copyright (c) 2014年 mudi. All rights reserved.
//

#import "MDCropImageView.h"



#pragma mark MDCropImageView
@interface MDCropImageView ()

@end


@implementation MDCropImageView

@synthesize cropRect = _cropRect;

- (void) setCropRect:(CGRect)cropRect
{
    if( !CGRectEqualToRect(_cropRect, cropRect) ){
        // center the rect
        cropRect = (CGRect){ 0, 0, cropRect.size.width, cropRect.size.height };
        cropRect = CGRectOffset(cropRect, (CGRectGetWidth(self.frame) - CGRectGetWidth(cropRect)) * .5, (CGRectGetHeight(self.frame) - CGRectGetHeight(cropRect)) * .5);
        
        _cropRect = CGRectOffset(cropRect, self.frame.origin.x, self.frame.origin.y);
        UIGraphicsBeginImageContextWithOptions(self.bounds.size, NO, 0.f);
        
        CGContextRef context = UIGraphicsGetCurrentContext();
        [[UIColor blackColor] setFill];
        UIRectFill(self.bounds);
        
        CGContextSetStrokeColorWithColor(context, [[UIColor whiteColor] colorWithAlphaComponent:0.5].CGColor);
        CGContextStrokeRect(context, cropRect);
        [[UIColor clearColor] setFill];
        UIRectFill(CGRectInset(cropRect, 1, 1));
        
        [self setImage:UIGraphicsGetImageFromCurrentImageContext()];
        
        UIGraphicsEndImageContext();
    }
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    MDLog(@"MDCropImageView touchesBegan");
    
    [super touchesBegan:touches withEvent:event];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    MDLog(@"MDCropImageView touchesEnded");

    [super touchesEnded:touches withEvent:event];
}

@end




