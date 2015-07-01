//
//  MDCameraCoverView.m
//  education
//
//  Created by Tim on 14-10-13.
//  Copyright (c) 2014年 mudi. All rights reserved.
//

#import "MDCameraCoverView.h"



@interface MDCameraCoverView ()

@end



@implementation MDCameraCoverView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (id)init
{
    self = [super init];
    if (self) {

    }
    
    return self;
}

- (void)switchCoverAlpha:(CGFloat)alpha andColor:(UIColor *)color
{
    self.topCover.alpha = self.leftCover.alpha = self.rightCover.alpha = self.bottomCover.alpha = alpha;
    
    self.topCover.backgroundColor = self.leftCover.backgroundColor = self.rightCover.backgroundColor = self.bottomCover.backgroundColor = color;
}

@end
