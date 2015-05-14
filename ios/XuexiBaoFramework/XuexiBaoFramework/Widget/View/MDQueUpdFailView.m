//
//  MDQueUpdFailView.m
//  education
//
//  Created by Tim on 15/3/31.
//  Copyright (c) 2015年 mudi. All rights reserved.
//

#import "MDQueUpdFailView.h"



@interface MDQueUpdFailView ()

@property (strong, nonatomic) IBOutlet UILabel *infoL;

@end



@implementation MDQueUpdFailView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (void)setFailCount:(NSInteger)failCount {
    self.infoL.text = [NSString stringWithFormat:@"%li道题目上传失败", (long)failCount];
}

@end
