//
//  MDEditPhotoView.m
//  education
//
//  Created by Tim on 14-7-11.
//  Copyright (c) 2014年 mudi. All rights reserved.
//

#import "MDEditPhotoView.h"
#import "CLClippingTool.h"


@implementation MDEditPhotoView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    CGPoint location = CGPointZero;
    for (UIView *view in self.subviews) {
        if ([view isKindOfClass:[CLClippingCircle class]]) {
            location = [view convertPoint:point fromView:self];
//            MDLog(@"hitTest loc:%@", NSStringFromCGPoint(location));

            if ([view pointInside:location withEvent:event]) {
                MDLog(@"hitTest found:%@", view);
                return view;
            }
        }
    }
    
    return [super hitTest:point withEvent:event];
}

@end
