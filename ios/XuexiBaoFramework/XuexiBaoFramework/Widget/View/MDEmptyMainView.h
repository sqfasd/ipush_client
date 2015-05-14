//
//  MDEmptyMainView.h
//  education
//
//  Created by Tim on 15/1/13.
//  Copyright (c) 2015年 mudi. All rights reserved.
//

#import <UIKit/UIKit.h>



@class MDEmptyMainView;

@protocol MDEmptyMainViewDelegate <NSObject>

@required
- (void)emptyViewDidOpenCamera:(MDEmptyMainView *)emptyMainView;

@end



@interface MDEmptyMainView : UIView

+ (MDEmptyMainView *)sharedView;

@property (nonatomic, assign) id<MDEmptyMainViewDelegate> delegate;

@property (strong, nonatomic) IBOutlet UIButton *cameraBtn;

- (void)initDisplay;
- (void)shineStars;

@end
