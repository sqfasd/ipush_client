//
//  MDCameraCoverView.h
//  education
//
//  Created by Tim on 14-10-13.
//  Copyright (c) 2014年 mudi. All rights reserved.
//

#import <UIKit/UIKit.h>



@interface MDCameraCoverView : UIView

@property (strong, nonatomic) IBOutlet UIView *topCover;
@property (strong, nonatomic) IBOutlet UIView *leftCover;
@property (strong, nonatomic) IBOutlet UIView *rightCover;
@property (strong, nonatomic) IBOutlet UIView *bottomCover;

- (void)switchCoverAlpha:(CGFloat)alpha andColor:(UIColor *)color;

@end



