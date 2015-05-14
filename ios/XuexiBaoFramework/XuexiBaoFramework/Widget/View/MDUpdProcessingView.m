//
//  MDUpdProcessingView.m
//  education
//
//  Created by Tim on 14-10-31.
//  Copyright (c) 2014年 mudi. All rights reserved.
//

#import "MDUpdProcessingView.h"




@interface MDUpdProcessingView ()

@property (nonatomic, strong) UILabel *textLabel;

@end



@implementation MDUpdProcessingView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self addSubview:self.textLabel];
        self.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"bg_proc"]];
    }
    
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/


#pragma mark -
#pragma mark - Properties
- (UILabel *)textLabel
{
    if (!_textLabel) {
        _textLabel = [[UILabel alloc] initWithFrame:CGRectMake(SCREEN_WIDTH / 2 - 100, 10, 200, 17)];
        _textLabel.textAlignment = NSTextAlignmentCenter;
        _textLabel.backgroundColor = [UIColor clearColor];
        _textLabel.font = [UIFont boldSystemFontOfSize:14];
        _textLabel.textColor = [UIColor whiteColor];
    }
    
    return _textLabel;
}

- (void)setUploadingCount:(NSInteger)uploadingCount
{
    if (uploadingCount <= 0) {
        self.hidden = YES;
        return;
    }
    else {
        self.hidden = NO;
    }
    
    _uploadingCount = uploadingCount;
    self.textLabel.text = [NSString stringWithFormat:@"%li道题目正在识别中...", (long)_uploadingCount];
}

@end




