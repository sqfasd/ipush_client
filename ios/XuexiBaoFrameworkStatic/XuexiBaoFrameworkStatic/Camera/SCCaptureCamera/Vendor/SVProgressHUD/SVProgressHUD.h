//
//  SVProgressHUD.h
//
//  Copyright 2011-2014 Sam Vermette. All rights reserved.
//
//  https://github.com/samvermette/SVProgressHUD
//

#import <UIKit/UIKit.h>
#import <AvailabilityMacros.h>

extern NSString * const SVProgressHUDDidReceiveTouchEventNotification;
extern NSString * const SVProgressHUDDidTouchDownInsideNotification;
extern NSString * const SVProgressHUDWillDisappearNotification;
extern NSString * const SVProgressHUDDidDisappearNotification;
extern NSString * const SVProgressHUDWillAppearNotification;
extern NSString * const SVProgressHUDDidAppearNotification;

extern NSString * const SVProgressHUDStatusUserInfoKey;

typedef NS_ENUM(NSUInteger, SVProgressHUDMaskType) {
    SVProgressHUDMaskTypeNone = 1,  // allow user interactions while HUD is displayed
    SVProgressHUDMaskTypeClear,     // don't allow user interactions
    SVProgressHUDMaskTypeBlack,     // don't allow user interactions and dim the UI in the back of the HUD
    SVProgressHUDMaskTypeGradient   // don't allow user interactions and dim the UI with a a-la-alert-view background gradient
};

typedef void(^HudBlockHandler)();

@interface SVProgressHUD : UIView

#pragma mark - Customization

+ (void)setBackgroundColor:(UIColor*)color;                 // default is [UIColor whiteColor]
+ (void)setForegroundColor:(UIColor*)color;                 // default is [UIColor blackColor]
+ (void)setRingThickness:(CGFloat)width;                    // default is 4 pt
+ (void)setFont:(UIFont*)font;                              // default is [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline]
+ (void)setInfoImage:(UIImage*)image;                       // default is the bundled info image provided by Freepik
+ (void)setSuccessImage:(UIImage*)image;                    // default is the bundled success image provided by Freepik
+ (void)setErrorImage:(UIImage*)image;                      // default is the bundled error image provided by Freepik
+ (void)setDefaultMaskType:(SVProgressHUDMaskType)maskType; // default is SVProgressHUDMaskTypeNone
+ (void)setViewForExtension:(UIView*)view;                  // default is nil, only used if #define SV_APP_EXTENSIONS is set

#pragma mark - Show Methods

+ (void)show;
+ (void)showWithMaskType:(SVProgressHUDMaskType)maskType;
+ (void)showWithStatus:(NSString*)status;
+ (void)showWithStatus:(NSString*)status maskType:(SVProgressHUDMaskType)maskType   isOwnerDraw:(BOOL)isOwnerDraw;

+ (void)showProgress:(float)progress;
+ (void)showProgress:(float)progress maskType:(SVProgressHUDMaskType)maskType;
+ (void)showProgress:(float)progress status:(NSString*)status;
+ (void)showProgress:(float)progress status:(NSString*)status maskType:(SVProgressHUDMaskType)maskType   isOwnerDraw:(BOOL)isOwnerDraw;

+ (void)setStatus:(NSString*)string; // change the HUD loading status while it's showing

// stops the activity indicator, shows a glyph + status, and dismisses HUD a little bit later
+ (void)showInfoWithStatus:(NSString *)string;
+ (void)showInfoWithStatus:(NSString *)string maskType:(SVProgressHUDMaskType)maskType   isOwnerDraw:(BOOL)isOwnerDraw;

+ (void)showSuccessWithStatus:(NSString*)string;
+ (void)showSuccessWithStatus:(NSString*)string maskType:(SVProgressHUDMaskType)maskType   isOwnerDraw:(BOOL)isOwnerDraw;

+ (void)showErrorWithStatus:(NSString *)string;
+ (void)showErrorWithStatus:(NSString *)string maskType:(SVProgressHUDMaskType)maskType   isOwnerDraw:(BOOL)isOwnerDraw;

// use 28x28 white pngs
+ (void)showImage:(UIImage*)image status:(NSString*)status;
+ (void)showImage:(UIImage*)image status:(NSString*)status maskType:(SVProgressHUDMaskType)maskType   isOwnerDraw:(BOOL)isOwnerDraw;

+ (void)setOffsetFromCenter:(UIOffset)offset;
+ (void)resetOffsetFromCenter;

+ (void)popActivity; // decrease activity count, if activity count == 0 the HUD is dismissed
+ (void)dismiss;

+ (BOOL)isVisible;

#pragma mark - 自定义公共接口

+ (float)durationWithString:(NSString*)string;
+ (void)setBusyingImage:(UIImage*)image;
+ (void)showStatus:(NSString*)status;
+ (void)showStatusWithBlockHandler:(NSString*)status blockHandler:(HudBlockHandler)blockHandler;
+ (void)showMDInfoWithStatus:(NSString *)string;
+ (void)showMDSuccessWithStatus:(NSString*)string;
+ (void)showMDErrorWithStatus:(NSString *)string;
+ (void)showMDBusying;
+ (void)showMDBusying:(NSString*)message;
+ (void)showMDBusyingWithTimeOut:(NSString*)message timeout:(float)timeout;

//已废弃
//+ (void)showBusying;
//+ (void)showMDBusyingWithStatus:(NSString*)status;

@end

