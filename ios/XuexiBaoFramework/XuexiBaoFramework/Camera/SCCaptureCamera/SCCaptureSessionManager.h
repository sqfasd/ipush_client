//
//  SCCaptureSessionManager.h
//  SCCaptureCameraDemo
//
//  Created by Aevitx on 14-1-16.
//  Copyright (c) 2014年 Aevitx. All rights reserved.
//



#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
//#import "SCDefines.h"

#define MAX_PINCH_SCALE_NUM   3.f
#define MIN_PINCH_SCALE_NUM   1.f

// 布局需要增加的额外高度
#define LAYOUT_ADDITIONAL_H (isHigherThaniPhone4_SC ? 160 : 80)


@protocol SCCaptureSessionManager;

typedef void(^DidCapturePhotoBlock)(UIImage *stillImage);






@interface SCCaptureSessionManager : NSObject

@property (nonatomic) dispatch_queue_t sessionQueue;
@property (nonatomic, strong) AVCaptureSession *session;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;
@property (nonatomic, strong) AVCaptureDeviceInput *inputDevice;
@property (nonatomic, strong) AVCaptureStillImageOutput *stillImageOutput;
//@property (nonatomic, strong) UIImage *stillImage;

//pinch
@property (nonatomic, assign) CGFloat preScaleNum;
@property (nonatomic, assign) CGFloat scaleNum;


@property (nonatomic, assign) id <SCCaptureSessionManager> delegate;

- (CGImageRef)imageRefFromBufferRef:(CMSampleBufferRef)buffer;

- (void)configureWithParentLayer:(UIView*)parent previewRect:(CGRect)preivewRect;

- (void)startDetectingOrientation;
- (void)stopDetectingOrientation;

- (void)takePicture:(DidCapturePhotoBlock)block;
- (void)switchCamera:(BOOL)isFrontCamera;
- (void)pinchCameraViewWithScalNum:(CGFloat)scale;
- (void)pinchCameraView:(UIPinchGestureRecognizer*)gesture;

- (void)switchFlashMode:(UIButton*)sender;
// 如果开了闪光灯，尝试关闭
- (void)closeFlashIfPossible:(UIButton *)button;

- (void)focusInPoint:(CGPoint)devicePoint;

// V2.3 显示网格
- (void)switchGridLines:(BOOL)toShow;
// 显示半透明边界
- (void)switchAlphaCover:(BOOL)toShow;

- (void)focusWithMode:(AVCaptureFocusMode)focusMode exposeWithMode:(AVCaptureExposureMode)exposureMode atDevicePoint:(CGPoint)point monitorSubjectAreaChange:(BOOL)monitorSubjectAreaChange;

- (void)startCameraCompletion:(void (^)())completion;
- (void)stopCamera;

@end





@protocol SCCaptureSessionManager <NSObject>

@optional
- (void)didCapturePhoto:(UIImage*)stillImage;

- (void)sessionManagerError:(SCCaptureSessionManager *)sessionManager;

// Anti-shake
- (void)didDetectShake:(SCCaptureSessionManager *)sessionMgr;
- (void)didDetectSteady:(SCCaptureSessionManager *)sessionMgr;

- (void)didStartTakingPicture:(SCCaptureSessionManager *)sessionMgr;
- (void)didCometoSteadyForTakingPicture:(SCCaptureSessionManager *)sessionMgr;
- (void)didGotPhotoData:(SCCaptureSessionManager *)sessionMgr;

- (void)didAutoFocusStarted:(SCCaptureSessionManager *)sessionMgr;
- (void)didAutoFocusSucceed:(SCCaptureSessionManager *)sessionMgr;

- (void)stopDetectingOrientation;

@end




