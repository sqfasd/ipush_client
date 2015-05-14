//
//  MDEditPhotoViewController.h
//  education
//
//  Created by Tim on 14-5-8.
//  Copyright (c) 2014年 mudi. All rights reserved.
//

#import <UIKit/UIKit.h>
//#import "BaseViewController.h"
#import "MDCropImageView.h"



static const CGFloat kMaxUIImageSize = 1024;
static const CGFloat kPreviewImageSize = 120;
static const CGFloat kDefaultCropWidth = 320;
static const CGFloat kDefaultCropHeight = 320;
static const NSTimeInterval kAnimationIntervalReset = 0.25;
static const NSTimeInterval kAnimationIntervalTransform = 0.2;

static const CGFloat kCropLeftMargin = 33;
static const CGFloat kCropRightMargin = 27;
static const CGFloat kCropTopMargin = 44;
static const CGFloat kCropBottomMargin = 25;

static const CGFloat kBottomBarHeight = 60;

#define RECT_CROPFRAME CGRectMake(kCropLeftMargin, kCropTopMargin, SCREEN_WIDTH - kCropLeftMargin - kCropRightMargin, SCREEN_HEIGHT - kCropTopMargin - kCropBottomMargin - kBottomBarHeight)




typedef struct {
    CGPoint tl,tr,bl,br;
} Rectangle;




#pragma mark MDEditPhotoViewController
@class CLClippingPanel;
@class MDEditPhotoViewController;

@protocol MDEditPhotoViewControllerDelegate <NSObject>

- (void)willRepickPhoto;
- (void)didSelectPhoto:(UIImage *)image;

@end




@interface MDEditPhotoViewController : UIViewController <UIGestureRecognizerDelegate>

@property (nonatomic, assign) id<MDEditPhotoViewControllerDelegate> delegate;

@property (nonatomic, assign) CLClippingPanel *clipPanel;

@property (nonatomic, readonly) CGRect imageViewRect;


//// V1.X
//@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;
//@property (strong, nonatomic) IBOutlet UIImageView *imageView;

// V2.0
@property (nonatomic, strong) UIImageView<MDCameraCropRect> *captureImageView;
/**
 *  The crop rect
 */
@property (nonatomic, assign) CGRect cropRect;

/**
 *  The source image
 */
@property (nonatomic, copy) UIImage *sourceImage;
/**
 *  Enable the crop gestures
 *
 *  @param enable BOOL value to set enable value
 */
- (void) enableGestures:(BOOL)enable;


- (id)initWithImage:(UIImage *)image;
- (void)setImage:(UIImage *)image;

- (void)resetZoomScaleWithAnimate:(BOOL)animated;

- (IBAction)rotateLeft90BtnClick:(id)sender;
- (IBAction)rotateRight90BtnClick:(id)sender;
- (IBAction)repickBtnClick:(id)sender;
- (IBAction)confirmBtnClick:(id)sender;

@end




