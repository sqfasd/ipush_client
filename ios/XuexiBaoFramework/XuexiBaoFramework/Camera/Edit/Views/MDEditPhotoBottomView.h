//
//  MDEditPhotoBottomView.h
//  education
//
//  Created by Tim on 14-5-7.
//  Copyright (c) 2014年 mudi. All rights reserved.
//

#import <UIKit/UIKit.h>


@class MDEditPhotoBottomView;

@protocol MDEditPhotoBottomViewDelegate <NSObject>

@required
- (void)rotateLeft90Option;
- (void)rotateRight90Option;
- (void)repickOption;
- (void)didconfirmPickOption;

@end


@interface MDEditPhotoBottomView : UIView

@property (nonatomic, assign) id<MDEditPhotoBottomViewDelegate> delegate;

- (IBAction)rotateLeft90BtnClicked:(id)sender;
- (IBAction)rotateRight90BtnClicked:(id)sender;
- (IBAction)repickPhotoBtnClicked:(id)sender;
- (IBAction)confirmBtnClicked:(id)sender;

@end

