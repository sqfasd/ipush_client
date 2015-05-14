//
//  MDNoNetHeader.m
//  education
//
//  Created by Tim on 15/3/31.
//  Copyright (c) 2015年 mudi. All rights reserved.
//

#import "MDNoNetHeader.h"



@implementation MDNoNetHeader

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/
- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self addSubview:self.infoL];
    }
    
    return self;
}

- (UILabel *)infoL {
    if (!_infoL) {
        _infoL = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.size.width, self.size.height)];
        _infoL.textColor = [UIColor colorWithHex:0xc06d30];
        _infoL.backgroundColor = [UIColor colorWithHex:0xffedc2];
        _infoL.font = [UIFont systemFontOfSize:13];
        _infoL.textAlignment = NSTextAlignmentCenter;
        _infoL.text = NSLocalizedString(@"没有网络了，快检查一下你的网络设置吧！", @"");
    }
    
    return _infoL;
}

@end




