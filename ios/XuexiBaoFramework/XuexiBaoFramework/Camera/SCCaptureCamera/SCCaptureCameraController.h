//
//  SCCaptureCameraController.h
//  SCCaptureCameraDemo
//
//  Created by Aevitx on 14-1-16.
//  Copyright (c) 2014年 Aevitx. All rights reserved.
//

#import <UIKit/UIKit.h>
//#import "BaseViewController.h"



@interface SCCaptureCameraController : UIViewController

@property (nonatomic, assign) CGRect previewRect;
@property (nonatomic, assign) BOOL isStatusBarHiddenBeforeShowCamera;

@property (nonatomic) BOOL isProMode;

- (void)showCameraCover:(BOOL)toShow;
- (void)switchShakeCover:(BOOL)toShow;

- (void)showCentralInfoArea:(NSString *)text autoDisappear:(BOOL)isAuto;

@end
