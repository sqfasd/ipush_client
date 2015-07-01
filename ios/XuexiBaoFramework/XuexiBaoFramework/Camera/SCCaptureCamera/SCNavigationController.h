//
//  SCNavigationController.h
//  SCCaptureCameraDemo
//
//  Created by Aevitx on 14-1-17.
//  Copyright (c) 2014年 Aevitx. All rights reserved.
//

#import <UIKit/UIKit.h>


@protocol SCNavigationControllerDelegate;

@interface SCNavigationController : UINavigationController


- (void)showCameraWithParentController:(UIViewController*)parentController isPro:(BOOL)pro;

@property (nonatomic, assign) id <SCNavigationControllerDelegate> scNaigationDelegate;

//@property (nonatomic, assign) UIViewController *parentViewController;

@end



@protocol SCNavigationControllerDelegate <NSObject>

@required
- (void)didEndEditPhoto:(UIImage *)image;

@optional
//- (void)didCapturePhoto:(SCNavigationController*)navigationController image:(UIImage*)image;
- (BOOL)willDismissNavigationController:(SCNavigationController*)navigatonController;

@end




