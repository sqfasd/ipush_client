//
//  MDEditPhotoBottomView.m
//  education
//
//  Created by Tim on 14-5-7.
//  Copyright (c) 2014年 mudi. All rights reserved.
//

#import "MDEditPhotoBottomView.h"



@implementation MDEditPhotoBottomView

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

- (IBAction)rotateLeft90BtnClicked:(id)sender {
    if (self.delegate) {
        [self.delegate rotateRight90Option];
    }
}

- (IBAction)rotateRight90BtnClicked:(id)sender {
    if (self.delegate) {
        [self.delegate rotateRight90Option];
    }
}

- (IBAction)repickPhotoBtnClicked:(id)sender {
    if (self.delegate) {
        [self.delegate repickOption];
    }
}

- (IBAction)confirmBtnClicked:(id)sender {
    if (self.delegate) {
        [self.delegate didconfirmPickOption];
    }
}

@end




