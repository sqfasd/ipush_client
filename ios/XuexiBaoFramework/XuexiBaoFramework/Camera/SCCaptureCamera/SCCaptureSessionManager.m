//
//  SCCaptureSessionManager.m
//  SCCaptureCameraDemo
//
//  Created by Aevitx on 14-1-16.
//  Copyright (c) 2014年 Aevitx. All rights reserved.
//

#import "SCCaptureSessionManager.h"
#import <ImageIO/ImageIO.h>
#import "UIImage+Resize.h"
#import "SCCommon.h"
//#import "UIImage+Rotating.h"
#import "UIImage+Utility.h"
#import <CoreMotion/CoreMotion.h>
#import "MDCameraCoverView.h"
#import "SCDefines.h"



static void * CapturingStillImageContext = &CapturingStillImageContext;
static void * RecordingContext = &RecordingContext;
static void * SessionRunningAndDeviceAuthorizedContext = &SessionRunningAndDeviceAuthorizedContext;


typedef enum : NSUInteger {
    FLASH_TYPE_OFF = 0,
    FLASH_TYPE_ON = 1,
    FLASH_TYPE_AUTO = 2
} FLASH_TYPE;


#pragma mark MACROs
//#define MOTION_VALUE_FINE 1.5
//#define ATTITUDE_VALUE_FINE 0.15
//#define MOTION_UPD_HZ 20

#define MOTION_VALUE_FINE 0.75
#define ATTITUDE_VALUE_FINE 0.075
#define MOTION_UPD_HZ 10
#define MOTION_RECORD_MAXTIME 3.0f


#pragma mark Code
@interface SCCaptureSessionManager ()

{
    int adjustingFocusFailCount;
    NSInteger _flashType;

    NSDate *startCameraTime;
    
    // 一秒稳定累计数据
    NSInteger motionDataCount;
    double motionTotalValue;
    double attitudeTotalValue;
    
    // 加速计的平均计数
    double resultTotalXValue;
    double resultTotalYValue;
    double resultTotalZValue;
    double resultTotalDataCount;

    // 半秒防抖累计数据
    NSInteger shakeDataCount;
    double shakeMotionTotalValue;
    double shakeAttitudeTotalValue;
    
    CMAttitude *lastAttitude;
}

@property (nonatomic, strong) CMDeviceMotion *motionData;
@property (nonatomic, strong) CMMotionManager *motionManager;
@property (nonatomic, strong) UIView *preview;
//@property (nonatomic, strong) UIImageView *imageView;

@end

@implementation SCCaptureSessionManager


#pragma mark -
#pragma mark configure
- (id)init {
    self = [super init];
    if (self != nil) {
        _scaleNum = 1.f;
        _preScaleNum = 1.f;
        adjustingFocusFailCount = 0;
        _flashType = FLASH_TYPE_OFF;

        [self motionReset];
    }
    return self;
}

- (void)dealloc {
//    [self.inputDevice removeObserver:self forKeyPath:@"adjustingFocus"];
}


#pragma mark Properties
- (CMMotionManager *)motionManager
{
    if (!_motionManager) {
        _motionManager = [[CMMotionManager alloc] init];
        _motionManager.deviceMotionUpdateInterval = 1.0/MOTION_UPD_HZ;
    }
    
    return _motionManager;
}

- (void)startDetectingOrientation
{
    [self.motionManager startAccelerometerUpdates];
}

- (void)stopDetectingOrientation
{
    [self.motionManager stopDeviceMotionUpdates];
//    [self.motionManager stopAccelerometerUpdates];
}

- (void)configureWithParentLayer:(UIView*)parent previewRect:(CGRect)preivewRect {
    
    self.preview = parent;
    
    //1、队列
    [self createQueue];
    
    //2、session
    [self addSession];
    
    //3、previewLayer
    [self addVideoPreviewLayerWithRect:preivewRect];
    [parent.layer addSublayer:_previewLayer];
    
    //4、input
    [self addVideoInputFrontCamera:NO];
    
    //5、output
    [self addStillImageOutput];
    
    // 6. KVO
    [self configKVO];
    
//    //6、preview imageview
//    [self addPreviewImageView];
    
//    //6、default flash mode
//    [self switchFlashMode:nil];
    
//    //7、default focus mode
//    [self setDefaultFocusMode];
}

/**
 *  创建一个队列，防止阻塞主线程
 */
- (void)createQueue {
	dispatch_queue_t sessionQueue = dispatch_queue_create("session queue", DISPATCH_QUEUE_SERIAL);
    self.sessionQueue = sessionQueue;
}

/**
 *  session
 */
- (void)addSession {
    AVCaptureSession *tmpSession = [[AVCaptureSession alloc] init];
    self.session = tmpSession;

    //设置质量
//    if ([self.session canSetSessionPreset:AVCaptureSessionPreset1920x1080]) {
//        self.session.sessionPreset = AVCaptureSessionPreset1920x1080;
//    }
    
    if (IS_IPHONE_4) {
        if ([self.session canSetSessionPreset:AVCaptureSessionPreset1920x1080]) {
            self.session.sessionPreset = AVCaptureSessionPreset1920x1080;
        }
        else if ([self.session canSetSessionPreset:AVCaptureSessionPresetHigh]) {
            self.session.sessionPreset = AVCaptureSessionPresetHigh;
        }
    }
    else {
        if ([self.session canSetSessionPreset:AVCaptureSessionPresetPhoto]) {
            self.session.sessionPreset = AVCaptureSessionPresetPhoto;
        }
        else if ([self.session canSetSessionPreset:AVCaptureSessionPreset1920x1080]) {
            self.session.sessionPreset = AVCaptureSessionPreset1920x1080;
        }
    }
    
}

/**
 *  相机的实时预览页面
 *
 *  @param previewRect 预览页面的frame
 */
- (void)addVideoPreviewLayerWithRect:(CGRect)previewRect {
    
    AVCaptureVideoPreviewLayer *preview = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_session];
    preview.videoGravity = AVLayerVideoGravityResizeAspectFill;
    preview.frame = previewRect;
    self.previewLayer = preview;
}

/**
 *  添加输入设备
 *
 *  @param front 前或后摄像头
 */
- (void)addVideoInputFrontCamera:(BOOL)front {
    
    NSArray *devices = [AVCaptureDevice devices];
    AVCaptureDevice *frontCamera;
    AVCaptureDevice *backCamera;
    
    for (AVCaptureDevice *device in devices) {
        
        SCDLog(@"Device name: %@", [device localizedName]);
        
        if ([device hasMediaType:AVMediaTypeVideo]) {
            
            if ([device position] == AVCaptureDevicePositionBack) {
                SCDLog(@"Device position : back");
                backCamera = device;
                
            }  else {
                SCDLog(@"Device position : front");
                frontCamera = device;
            }
        }
    }
    
    NSError *error = nil;
    
    if (front) {
        AVCaptureDeviceInput *frontFacingCameraDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:frontCamera error:&error];
        if (!error) {
            if ([_session canAddInput:frontFacingCameraDeviceInput]) {
                [_session addInput:frontFacingCameraDeviceInput];
                self.inputDevice = frontFacingCameraDeviceInput;
                
            } else {
                SCDLog(@"Couldn't add front facing video input");
            }
        }
    } else {
        if ([backCamera lockForConfiguration:&error]) {
            if ([backCamera isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]) {
                CGPoint autofocusPoint = CGPointMake(0.5f, 0.5f);
                [backCamera setFocusPointOfInterest:autofocusPoint];
                [backCamera setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
            }
            [backCamera unlockForConfiguration];
        }
        
        AVCaptureDeviceInput *backFacingCameraDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:backCamera error:&error];
        
        if (!error) {
            if ([_session canAddInput:backFacingCameraDeviceInput]) {
                [_session addInput:backFacingCameraDeviceInput];
                self.inputDevice = backFacingCameraDeviceInput;
            } else {
                SCDLog(@"Couldn't add back facing video input");
            }
        }
    }
}

/**
 *  添加输出设备
 */
- (void)addStillImageOutput {
    
    AVCaptureStillImageOutput *tmpOutput = [[AVCaptureStillImageOutput alloc] init];
    NSDictionary *outputSettings = [[NSDictionary alloc] initWithObjectsAndKeys:AVVideoCodecJPEG,AVVideoCodecKey,nil];//输出jpeg
    tmpOutput.outputSettings = outputSettings;
    if (IOS_VERSION >= 7.0) {
        if (tmpOutput.stillImageStabilizationSupported) {
            [tmpOutput setAutomaticallyEnablesStillImageStabilizationWhenAvailable:YES];
        }
    }
    
//    AVCaptureConnection *videoConnection = [self findVideoConnection];
    
    if (_session && [_session canAddOutput:tmpOutput]) {
        [_session addOutput:tmpOutput];
        
//        [_session startRunning];
    }
    
    self.stillImageOutput = tmpOutput;
}

/*
 *
 */
- (void)configKVO {
//    if (!self.inputDevice || !self.inputDevice.device) {
//        return;
//    }
    
    [self.inputDevice.device addObserver:self forKeyPath:@"adjustingFocus" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)clearKVO {
    [self.inputDevice.device removeObserver:self forKeyPath:@"adjustingFocus"];
}


- (void)startCameraCompletion:(void (^)())completion
{
    dispatch_async(dispatch_get_main_queue(), ^{
    
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionRuntimeErrored:) name:AVCaptureSessionRuntimeErrorNotification object:self.session];
        
        [[self session] startRunning];
        
        if (self.session.isInterrupted) {
            MDLog(@"startCameraCompletion session interrupted %@", self.session);
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.previewLayer setNeedsDisplay];

            if (completion) {
                completion();
            }
        });
    });
}

- (void)stopCamera
{
    if (!self.session || !self.session.isRunning)
        return;
    
    // 1. 清除KVO
    [self clearKVO];
    
    // 2. 停止camera session
    dispatch_async(dispatch_get_main_queue(), ^{
        [self stopDetectingOrientation];

        if (self.session && self.session.isRunning) {
            [[self session] stopRunning];
        }
        
        [[NSNotificationCenter defaultCenter] removeObserver:self];
                
        self.previewLayer = nil;
        self.session = nil;
        self.stillImageOutput = nil;
    });
}

- (void)sessionRuntimeErrored:(NSNotification *)notification
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([notification object] == self.session) {
            NSError *error = [[notification userInfo] objectForKey:AVCaptureSessionErrorKey];
            if (error) {
                NSInteger errorCode = [error code];
                switch (errorCode) {
                    case AVErrorMediaServicesWereReset:
                    {
                        MDLog(@"error media services were reset");
                        if (self.delegate && [self.delegate respondsToSelector:@selector(sessionManagerError:)]) {
                            [self.delegate sessionManagerError:self];
                        }
                        break;
                    }
                    case AVErrorDeviceIsNotAvailableInBackground:
                    {
                        MDLog(@"error media services not available in background");
                        break;
                    }
                    default:
                    {
                        MDLog(@"error media services failed, error (%@)", error);
                        if (self.delegate && [self.delegate respondsToSelector:@selector(sessionManagerError:)]) {
                            [self.delegate sessionManagerError:self];
                        }
                        
                        break;
                    }
                }
            }
        }
    });
}

/**
 *  拍完照片后预览图片
 */
//- (void)addPreviewImageView {
//    CGFloat headHeight = _previewLayer.bounds.size.height - SC_APP_SIZE.width;
//    CGRect imageFrame = _previewLayer.bounds;
//    imageFrame.origin.y = headHeight;
//    
//    UIImageView *imgView = [[UIImageView alloc] initWithFrame:imageFrame];
//    imgView.contentMode = UIViewContentModeScaleAspectFill;
//    [_preview addSubview:imgView];
//    
//    self.imageView = imgView;
//}

-(void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context {
    if([keyPath isEqualToString:@"adjustingFocus"]){
        BOOL adjustingFocus =[[change objectForKey:NSKeyValueChangeNewKey] isEqualToNumber:[NSNumber numberWithInt:1]];
        NSLog(@"Is adjusting focus? %@", adjustingFocus ? @"YES" : @"NO");
        NSLog(@"Change dictionary: %@", change);
        if (++adjustingFocusFailCount > 3) {
            NSLog(@"Adjusting focus retry too much");
        }
        else {
            adjustingFocusFailCount = 0;
        }

        if (self.inputDevice.device.focusMode == AVCaptureFocusModeContinuousAutoFocus) {
            // 如果正在对焦
            if (adjustingFocus) {
                if (self.delegate && [self.delegate respondsToSelector:@selector(didAutoFocusStarted:)]) {
                    [self.delegate didAutoFocusStarted:self];
                }
            }
            // 如果完成对焦
            else {
                if (self.delegate && [self.delegate respondsToSelector:@selector(didAutoFocusSucceed:)]) {
                    [self.delegate didAutoFocusSucceed:self];
                }
            }
        }
    }
}


// 一下ENUM摘自系统定义
//typedef NS_ENUM(NSInteger, UIInterfaceOrientation) {
//    UIInterfaceOrientationPortrait           = UIDeviceOrientationPortrait,
//    UIInterfaceOrientationPortraitUpsideDown = UIDeviceOrientationPortraitUpsideDown,
//    UIInterfaceOrientationLandscapeLeft      = UIDeviceOrientationLandscapeRight,
//    UIInterfaceOrientationLandscapeRight     = UIDeviceOrientationLandscapeLeft
//};
- (AVCaptureVideoOrientation)getCurrentOrientationWith:(CGFloat)x andY:(CGFloat)y andZ:(CGFloat)z
{
    // Get the current device angle
    float xx = -x;
    float yy = y;
    float angle = atan2(yy, xx);
    
    MDLog(@"getCurrentOrientation %f xx:%f yy:%f", angle, xx, yy);
    
//    if(angle >= -2.25 && angle <= -0.25) {
//    if(angle >= -2.00 && angle <= -0.25) {
//        MDLog(@"getCurrentOrientationWith return Portrait");
//        
//        return AVCaptureVideoOrientationPortrait;
//    }

    MDLog(@"getCurrentOrientationWith return LandscapeRight");

    return AVCaptureVideoOrientationLandscapeRight;
    
    
    NSInteger deviceOrientation = UIInterfaceOrientationPortrait;
    
    // Read my blog for more details on the angles. It should be obvious that you
    // could fire a custom shouldAutorotateToInterfaceOrientation-event here.
    if(angle >= -2.25 && angle <= -0.25)
    {
        deviceOrientation = UIInterfaceOrientationPortrait;
    }
    else if(angle >= -1.75 && angle <= 0.75)
    {
        deviceOrientation = UIInterfaceOrientationLandscapeRight;
    }
    else if(angle >= 0.75 && angle <= 2.25)
    {
        deviceOrientation = UIInterfaceOrientationPortraitUpsideDown;
    }
    else if(angle <= -2.25 || angle >= 2.25)
    {
        deviceOrientation = UIInterfaceOrientationLandscapeLeft;
    }
    
    AVCaptureVideoOrientation newOrientation;
    switch (deviceOrientation) {
        case UIDeviceOrientationPortrait:
            newOrientation = AVCaptureVideoOrientationPortrait;
            break;
        case UIDeviceOrientationPortraitUpsideDown:
            newOrientation = AVCaptureVideoOrientationPortraitUpsideDown;
            break;
        case UIDeviceOrientationLandscapeLeft:
            newOrientation = AVCaptureVideoOrientationLandscapeRight;
            break;
        case UIDeviceOrientationLandscapeRight:
            newOrientation = AVCaptureVideoOrientationLandscapeLeft;
            break;
        default:
            newOrientation = AVCaptureVideoOrientationPortrait;
    }
    
    return newOrientation;
}

- (void)motionReset
{
    self.motionData = nil;

    [self resetMotionTotalData];
    
    [self resetShakeTotalData];
    
    [self resetResultTotalData];
}

- (void)resetMotionTotalData
{
    // 一秒累计数据
    motionDataCount = motionTotalValue = attitudeTotalValue = 0;
}

- (void)resetShakeTotalData
{
    // 防抖累计数据
    shakeDataCount = shakeMotionTotalValue = shakeAttitudeTotalValue = 0;
    
    startCameraTime = nil;
}

- (void)resetResultTotalData
{
    // 最终结果计数
    resultTotalXValue = resultTotalYValue = resultTotalZValue = resultTotalDataCount = 0;
}

- (void)startTakingPicture:(AVCaptureConnection *)connection withBLock:(DidCapturePhotoBlock)block
{
    [self motionReset];
	SCDLog(@"startTakingPicture begin");

    // Anti-shake
    if (self.delegate && [self.delegate respondsToSelector:@selector(didCometoSteadyForTakingPicture:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate didCometoSteadyForTakingPicture:self];
        });
    }
    
    
    MDLog(@"got acce data");
    
    CGFloat x = resultTotalXValue / ((resultTotalDataCount > 0) ? resultTotalDataCount : 1);
    CGFloat y = resultTotalYValue / ((resultTotalDataCount > 0) ? resultTotalDataCount : 1);
    CGFloat z = resultTotalZValue / ((resultTotalDataCount > 0) ? resultTotalDataCount : 1);
    
    // 重置结果数据累计
    [self resetResultTotalData];
    
    //            CGFloat x = motion.userAcceleration.x + motion.gravity.x;
    //            CGFloat y = motion.userAcceleration.y + motion.gravity.y;
    //            CGFloat z = motion.userAcceleration.z + motion.gravity.z;
    
    [connection setVideoOrientation:[self getCurrentOrientationWith:x andY:y andZ:z]];
    
    [self stopDetectingOrientation];
    
    if (!connection || !connection.isActive) {
        MDLog(@"startTakingPicture connection inactive/invalid");
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.delegate && [self.delegate respondsToSelector:@selector(sessionManagerError:)]) {
                [self.delegate sessionManagerError:self];
            }
        });
        
        return;
    }
    
    MDLog(@"About to captureStillImageAsynchronouslyFromConnection");
    
    [_stillImageOutput captureStillImageAsynchronouslyFromConnection:connection completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
        
        MDLog(@"After captureStillImageAsynchronouslyFromConnection");
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(didGotPhotoData:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.delegate didGotPhotoData:self];
            });
        }
        
        CFDictionaryRef exifAttachments = CMGetAttachment(imageDataSampleBuffer, kCGImagePropertyExifDictionary, NULL);
        if (exifAttachments) {
            SCDLog(@"attachements: %@", exifAttachments);
        } else {
            SCDLog(@"no attachments");
        }
        
        /* CVBufferRelease(imageBuffer); */  // do not call this!
        
        NSData *imageData = nil;
        UIImage *oriImage = nil;
        if (CMSampleBufferIsValid(imageDataSampleBuffer)) {
            imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
            oriImage = [[UIImage alloc] initWithData:imageData];
        }
        
        MDLog(@"capOriSize:%@", NSStringFromCGSize(oriImage.size));
        
        
        UIImage *image = oriImage;
        //                image = [oriImage imageRotatedByDegrees:90];
        
        image = [image rotate90Clockwise];
        
        //                image = [image rotateInDegrees:-90.0f];
        
        MDLog(@"capOriSize after rotate90:%@", NSStringFromCGSize(image.size));
        
        
        UIImage *croppedImage = image; //[scaledImage croppedImage:cropFrame];
        
        
        //block、delegate、notification 3选1，传值
        dispatch_async(dispatch_get_main_queue(), ^{
            if (block) {
                block(croppedImage);
            } else if ([_delegate respondsToSelector:@selector(didCapturePhoto:)]) {
                [_delegate didCapturePhoto:croppedImage];
            } else {
                [[NSNotificationCenter defaultCenter] postNotificationName:kCapturedPhotoSuccessfully object:croppedImage];
            }
        });
    }];
    
    
//    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
//
//    // Anti-shake
//    if (self.delegate && [self.delegate respondsToSelector:@selector(didStartTakingPicture:)]) {
//        dispatch_async(dispatch_get_main_queue(), ^{
//            [self.delegate didStartTakingPicture:self];
//        });
//    }
//    
//
//    if (![self.motionManager isDeviceMotionAvailable]) {
//        [SVProgressHUD showStatus:@"很抱歉，我们暂不支持您的设备拍照"];
//        return;
//    }
//    
//    startCameraTime = [NSDate date];
//    
//    [self.motionManager startDeviceMotionUpdatesToQueue:queue withHandler:^(CMDeviceMotion *motion, NSError *error) {
//        
//        // 0. 累计数据
//        float iXYZ = fabs(motion.userAcceleration.x) + fabs(motion.userAcceleration.y) + fabs(motion.userAcceleration.z);
//        // Motion数据
//        motionTotalValue += iXYZ;
//        // 防抖数据
//        shakeMotionTotalValue += iXYZ;
//        
//        // 计算结果的数据
//        resultTotalXValue += motion.userAcceleration.x + motion.gravity.x;
//        resultTotalYValue += motion.userAcceleration.y + motion.gravity.y;
//        resultTotalZValue += motion.userAcceleration.z + motion.gravity.z;
//        resultTotalDataCount++;
//        
//        
//        if (!lastAttitude) {
//            lastAttitude = motion.attitude;
//        }
//        else {
//            float iAttitude = fabs(motion.attitude.yaw - lastAttitude.yaw) + fabs(motion.attitude.roll - lastAttitude.roll) + fabs(motion.attitude.pitch - lastAttitude.pitch);
//            // Motion数据
//            attitudeTotalValue += iAttitude;
//            // 防抖数据
//            shakeMotionTotalValue += iAttitude;
//            
//            MDLog(@"attitude change yaw:%f roll:%f pitch:%f", motion.attitude.yaw - lastAttitude.yaw, motion.attitude.roll - lastAttitude.roll, motion.attitude.pitch - lastAttitude.pitch);
//            
//            lastAttitude = motion.attitude;
//        }
//        
//        MDLog(@"i totalvalue:%f count:%ld x:%f y:%f z:%f", motionTotalValue, (long)motionDataCount, motion.userAcceleration.x, motion.userAcceleration.y, motion.userAcceleration.z);
//
//        
//        // 1. 判断
//        // 1.1. 防抖数据如果在半秒以上
//        if (++shakeDataCount > MOTION_UPD_HZ / 2) {
//            
//            // 1.1.1. 如果半秒内是抖动的
//            if (shakeMotionTotalValue >= MOTION_VALUE_FINE / 2 || shakeAttitudeTotalValue >= ATTITUDE_VALUE_FINE / 2) {
//                if (self.delegate && [self.delegate respondsToSelector:@selector(didDetectShake:)]) {
//                    dispatch_async(dispatch_get_main_queue(), ^{
//                        [self.delegate didDetectShake:self];
//                    });
//                }
//            }
//            // 1.1.2. 如果半秒内是稳定的
//            else {
//                if (self.delegate && [self.delegate respondsToSelector:@selector(didDetectSteady:)]) {
//                    dispatch_async(dispatch_get_main_queue(), ^{
//                        [self.delegate didDetectSteady:self];
//                    });
//                }
//            }
//            
//            // 防抖数据
//            [self resetShakeTotalData];
//        }
//        
//        // 1.2. 必须收集到一秒以上
//        if (++motionDataCount <= MOTION_UPD_HZ) {
//            return;
//        }
//
//        MDLog(@"totalValue: %f totalAttitude:%f", motionTotalValue, attitudeTotalValue);
//
//        
//        // 2. 如果在抖动
//        if (motionTotalValue > MOTION_VALUE_FINE || attitudeTotalValue > ATTITUDE_VALUE_FINE) {
//            MDLog(@"continue steady");
//            
//            [self resetMotionTotalData];
//
//            NSDate *now = [NSDate date];
//            if (startCameraTime && [now timeIntervalSinceDate:startCameraTime] < MOTION_RECORD_MAXTIME) {
//                return;
//            }
//        }
//
//        // Motion数据
//        [self resetMotionTotalData];
//        
//        // 防抖数据
//        [self resetShakeTotalData];
//
//        // Anti-shake
//        if (self.delegate && [self.delegate respondsToSelector:@selector(didCometoSteadyForTakingPicture:)]) {
//            dispatch_async(dispatch_get_main_queue(), ^{
//                [self.delegate didCometoSteadyForTakingPicture:self];
//            });
//        }
//        
//
//        // 3. 如果没有抖动
//        if (!self.motionData) {
//            self.motionData = motion;
//
//            MDLog(@"got acce data");
//
//            CGFloat x = resultTotalXValue / ((resultTotalDataCount > 0) ? resultTotalDataCount : 1);
//            CGFloat y = resultTotalYValue / ((resultTotalDataCount > 0) ? resultTotalDataCount : 1);
//            CGFloat z = resultTotalZValue / ((resultTotalDataCount > 0) ? resultTotalDataCount : 1);
//
//            // 重置结果数据累计
//            [self resetResultTotalData];
//            
////            CGFloat x = motion.userAcceleration.x + motion.gravity.x;
////            CGFloat y = motion.userAcceleration.y + motion.gravity.y;
////            CGFloat z = motion.userAcceleration.z + motion.gravity.z;
//            
//            [connection setVideoOrientation:[self getCurrentOrientationWith:x andY:y andZ:z]];
//            
//            [self stopDetectingOrientation];
//            
//            if (!connection || !connection.isActive) {
//                MDLog(@"startTakingPicture connection inactive/invalid");
//                dispatch_async(dispatch_get_main_queue(), ^{
//                    if (self.delegate && [self.delegate respondsToSelector:@selector(sessionManagerError:)]) {
//                        [self.delegate sessionManagerError:self];
//                    }
//                });
//                
//                return;
//            }
//            
//            MDLog(@"About to captureStillImageAsynchronouslyFromConnection");
//            
//            [_stillImageOutput captureStillImageAsynchronouslyFromConnection:connection completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
//                
//                MDLog(@"After captureStillImageAsynchronouslyFromConnection");
//                
//                if (self.delegate && [self.delegate respondsToSelector:@selector(didGotPhotoData:)]) {
//                    dispatch_async(dispatch_get_main_queue(), ^{
//                        [self.delegate didGotPhotoData:self];
//                    });
//                }
//
//                CFDictionaryRef exifAttachments = CMGetAttachment(imageDataSampleBuffer, kCGImagePropertyExifDictionary, NULL);
//                if (exifAttachments) {
//                    SCDLog(@"attachements: %@", exifAttachments);
//                } else {
//                    SCDLog(@"no attachments");
//                }
//                
//                /* CVBufferRelease(imageBuffer); */  // do not call this!
//                
//                NSData *imageData = nil;
//                UIImage *oriImage = nil;
//                if (CMSampleBufferIsValid(imageDataSampleBuffer)) {
//                    imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
//                    oriImage = [[UIImage alloc] initWithData:imageData];
//                }
//                
//                MDLog(@"capOriSize:%@", NSStringFromCGSize(oriImage.size));
//
//
//                UIImage *image = oriImage;
////                image = [oriImage imageRotatedByDegrees:90];
//                
//                image = [image rotate90Clockwise];
//                
////                image = [image rotateInDegrees:-90.0f];
//                
//                MDLog(@"capOriSize after rotate90:%@", NSStringFromCGSize(image.size));
//                
//
//                UIImage *croppedImage = image; //[scaledImage croppedImage:cropFrame];
//                
//                
//                //block、delegate、notification 3选1，传值
//                dispatch_async(dispatch_get_main_queue(), ^{
//                    if (block) {
//                        block(croppedImage);
//                    } else if ([_delegate respondsToSelector:@selector(didCapturePhoto:)]) {
//                        [_delegate didCapturePhoto:croppedImage];
//                    } else {
//                        [[NSNotificationCenter defaultCenter] postNotificationName:kCapturedPhotoSuccessfully object:croppedImage];
//                    }
//                });
//            }];
//        }
//    }];
}

- (UIImage *)rotateImage:(UIImage *)image forDegree:(CGFloat)degree
{
    if (!image)
        return nil;
    
    
    CIImage *ciImage = [[CIImage alloc] initWithImage:image];
    CIFilter *filter = [CIFilter filterWithName:@"CIAffineTransform" keysAndValues:kCIInputImageKey, ciImage, nil];
    
    NSLog(@"%@", [filter attributes]);
    
    [filter setDefaults];
    
    CGFloat arg = -0.5 * M_PI;
    
    CATransform3D transform = CATransform3DIdentity;
    transform = CATransform3DRotate(transform, arg, 0, 0, 1);
    transform = CATransform3DRotate(transform, 0, 0, 1, 0);
    transform = CATransform3DRotate(transform, 0, 1, 0, 0);

    [filter setValue:[NSValue valueWithBytes:&transform objCType:@encode(CGAffineTransform)] forKey:@"inputTransform"];
    
    CIContext *context = [CIContext contextWithOptions:nil];
    CIImage *outputImage = [filter outputImage];
    CGImageRef cgImage = [context createCGImage:outputImage fromRect:[outputImage extent]];
    
    UIImage *result = [UIImage imageWithCGImage:cgImage];
    
    CGImageRelease(cgImage);
    
    return result;
}

#pragma mark - actions
/**
 *  拍照
 */
- (void)takePicture:(DidCapturePhotoBlock)block {
	SCDLog(@"about to request a capture from: %@", _stillImageOutput);
    
    AVCaptureConnection *videoConnection = [self findVideoConnection];

	SCDLog(@"After find video connection");
    
    [videoConnection setVideoScaleAndCropFactor:_scaleNum];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self startTakingPicture:videoConnection withBLock:block];
    });
}

- (CGImageRef)imageRefFromBufferRef:(CMSampleBufferRef)buffer
{
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(buffer);
    CVPixelBufferLockBaseAddress(imageBuffer,0);        // Lock the image buffer
    
    uint8_t *baseAddress = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0);   // Get information of the image
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    CGContextRef newContext = CGBitmapContextCreate(baseAddress, width, height, 8, bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    CGImageRef newImage = CGBitmapContextCreateImage(newContext);
    CGContextRelease(newContext);
    
    CGColorSpaceRelease(colorSpace);
    CVPixelBufferUnlockBaseAddress(imageBuffer,0);

    return newImage;
}

- (AVCaptureVideoOrientation)avOrientationForDeviceOrientation:(UIDeviceOrientation)deviceOrientation
{
	AVCaptureVideoOrientation result = (AVCaptureVideoOrientation)deviceOrientation;
	if ( deviceOrientation == UIDeviceOrientationLandscapeLeft )
		result = AVCaptureVideoOrientationLandscapeRight;
	else if ( deviceOrientation == UIDeviceOrientationLandscapeRight )
		result = AVCaptureVideoOrientationLandscapeLeft;
	return result;
}

/**
 *  切换前后摄像头
 *
 *  @param isFrontCamera YES:前摄像头  NO:后摄像头
 */
- (void)switchCamera:(BOOL)isFrontCamera {
    if (!_inputDevice) {
        return;
    }
    [_session beginConfiguration];
    
    [_session removeInput:_inputDevice];
    
    [self addVideoInputFrontCamera:isFrontCamera];
    
    [_session commitConfiguration];
}

/**
 *  拉近拉远镜头
 *
 *  @param scale 拉伸倍数
 */
- (void)pinchCameraViewWithScalNum:(CGFloat)scale {
    _scaleNum = scale;
    if (_scaleNum < MIN_PINCH_SCALE_NUM) {
        _scaleNum = MIN_PINCH_SCALE_NUM;
    } else if (_scaleNum > MAX_PINCH_SCALE_NUM) {
        _scaleNum = MAX_PINCH_SCALE_NUM;
    }
    [self doPinch];
    _preScaleNum = scale;
}

- (void)pinchCameraView:(UIPinchGestureRecognizer *)gesture {
    
    BOOL allTouchesAreOnThePreviewLayer = YES;
	NSUInteger numTouches = [gesture numberOfTouches], i;
	for ( i = 0; i < numTouches; ++i ) {
		CGPoint location = [gesture locationOfTouch:i inView:_preview];
		CGPoint convertedLocation = [_previewLayer convertPoint:location fromLayer:_previewLayer.superlayer];
		if ( ! [_previewLayer containsPoint:convertedLocation] ) {
			allTouchesAreOnThePreviewLayer = NO;
			break;
		}
	}
	
	if ( allTouchesAreOnThePreviewLayer ) {
		_scaleNum = _preScaleNum * gesture.scale;
        
        if (_scaleNum < MIN_PINCH_SCALE_NUM) {
            _scaleNum = MIN_PINCH_SCALE_NUM;
        } else if (_scaleNum > MAX_PINCH_SCALE_NUM) {
            _scaleNum = MAX_PINCH_SCALE_NUM;
        }
        
        [self doPinch];
	}
    
    if ([gesture state] == UIGestureRecognizerStateEnded ||
        [gesture state] == UIGestureRecognizerStateCancelled ||
        [gesture state] == UIGestureRecognizerStateFailed) {
        _preScaleNum = _scaleNum;
        SCDLog(@"final scale: %f", _scaleNum);
    }
}

- (void)doPinch {
//    AVCaptureStillImageOutput* output = (AVCaptureStillImageOutput*)[_session.outputs objectAtIndex:0];
//    AVCaptureConnection *videoConnection = [output connectionWithMediaType:AVMediaTypeVideo];
    
    AVCaptureConnection *videoConnection = [self findVideoConnection];
    
    CGFloat maxScale = videoConnection.videoMaxScaleAndCropFactor;//videoScaleAndCropFactor这个属性取值范围是1.0-videoMaxScaleAndCropFactor。iOS5+才可以用
    if (_scaleNum > maxScale) {
        _scaleNum = maxScale;
    }
    
//    videoConnection.videoScaleAndCropFactor = _scaleNum;
    [CATransaction begin];
    [CATransaction setAnimationDuration:.025];
    [_previewLayer setAffineTransform:CGAffineTransformMakeScale(_scaleNum, _scaleNum)];
    [CATransaction commit];
}

// 如果开了闪光灯，尝试关闭
- (void)closeFlashIfPossible:(UIButton *)button
{
    Class captureDeviceClass = NSClassFromString(@"AVCaptureDevice");
    if (!captureDeviceClass) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"提示信息" message:@"您的设备没有拍照功能" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles: nil];
        [alert show];
        return;
    }

    NSString *imgStr = @"";
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    [device lockForConfiguration:nil];

    if ([device hasFlash]) {
        if (_flashType == FLASH_TYPE_ON) {
            device.flashMode = AVCaptureFlashModeAuto;
            imgStr = XXBRSRC_NAME(@"camera_flash_auto"); //@"flashing_auto.png";
            if ([device hasTorch]) {
                [device setTorchMode: AVCaptureTorchModeOff];
            }
            
            _flashType = FLASH_TYPE_AUTO;

            if (button && [button isKindOfClass:[UIButton class]]) {
                [button setImage:[UIImage imageNamed:imgStr] forState:UIControlStateNormal];
            }
        }
        
    }

    [device unlockForConfiguration];
}

/**
 *  切换闪光灯模式
 *  （切换顺序：最开始是auto，然后是off，最后是on，一直循环）
 *  @param sender: 闪光灯按钮
 */
- (void)switchFlashMode:(UIButton*)sender {
    
    Class captureDeviceClass = NSClassFromString(@"AVCaptureDevice");
    if (!captureDeviceClass) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"提示信息" message:@"您的设备没有拍照功能" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles: nil];
        [alert show];
        return;
    }
    
    NSString *imgStr = @"";
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    [device lockForConfiguration:nil];
    if ([device hasFlash]) {
//        if (!sender) {//设置默认的闪光灯模式
//            device.flashMode = AVCaptureFlashModeAuto;
//        } else {
        if (_flashType == FLASH_TYPE_OFF) {
            device.flashMode = AVCaptureFlashModeOff; //AVCaptureFlashModeOn;
            imgStr = XXBRSRC_NAME(@"camera_flash_on"); //@"flashing_on.png";
            if ([device hasTorch]) {
                [device setTorchMode: AVCaptureTorchModeOn];
            }

            _flashType = FLASH_TYPE_ON;
        }
        else if (_flashType == FLASH_TYPE_ON) {
            device.flashMode = AVCaptureFlashModeAuto;
            imgStr = XXBRSRC_NAME(@"camera_flash_auto"); //@"flashing_auto.png";
            if ([device hasTorch]) {
                [device setTorchMode: AVCaptureTorchModeOff];
            }
            
            _flashType = FLASH_TYPE_AUTO;
        }
        else if (_flashType == FLASH_TYPE_AUTO) {
            device.flashMode = AVCaptureFlashModeOff;
            imgStr = XXBRSRC_NAME(@"camera_flash_off"); //@"flashing_off.png";
            if ([device hasTorch]) {
                [device setTorchMode: AVCaptureTorchModeOff];
            }

            _flashType = FLASH_TYPE_OFF;
        }
        
        if (sender) {
            [sender setImage:[UIImage imageNamed:imgStr] forState:UIControlStateNormal];
        }
        
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"提示信息" message:@"您的设备没有闪光灯功能" delegate:nil cancelButtonTitle:@"噢T_T" otherButtonTitles: nil];
        [alert show];
    }
    [device unlockForConfiguration];
}

/**
 *  点击后对焦
 *
 *  @param devicePoint 点击的point
 */
- (void)focusInPoint:(CGPoint)devicePoint {
//    if (CGRectContainsPoint(_previewLayer.bounds, devicePoint) == NO) {
//        return;
//    }
    
    devicePoint = [self convertToPointOfInterestFromViewCoordinates:devicePoint];
	[self focusWithMode:AVCaptureFocusModeAutoFocus exposeWithMode:AVCaptureExposureModeContinuousAutoExposure atDevicePoint:devicePoint monitorSubjectAreaChange:YES];
}

- (void)focusWithMode:(AVCaptureFocusMode)focusMode exposeWithMode:(AVCaptureExposureMode)exposureMode atDevicePoint:(CGPoint)point monitorSubjectAreaChange:(BOOL)monitorSubjectAreaChange
{
    
	dispatch_async(_sessionQueue, ^{
		AVCaptureDevice *device = [_inputDevice device];
		NSError *error = nil;
		if ([device lockForConfiguration:&error])
		{
			if ([device isFocusPointOfInterestSupported] && [device isFocusModeSupported:focusMode])
			{
				[device setFocusMode:focusMode];
				[device setFocusPointOfInterest:point];
			}

			if ([device isExposurePointOfInterestSupported] && [device isExposureModeSupported:exposureMode])
			{
				[device setExposureMode:exposureMode];
				[device setExposurePointOfInterest:point];
			}

            if ([device isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance]) {
                [device setWhiteBalanceMode:AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance];
            }

			[device setSubjectAreaChangeMonitoringEnabled:monitorSubjectAreaChange];
			[device unlockForConfiguration];
		}
		else
		{
			SCDLog(@"%@", error);
		}
	});
}

/**
 *  外部的point转换为camera需要的point(外部point/相机页面的frame)
 *
 *  @param viewCoordinates 外部的point
 *
 *  @return 相对位置的point
 */
- (CGPoint)convertToPointOfInterestFromViewCoordinates:(CGPoint)viewCoordinates {
    CGPoint pointOfInterest = CGPointMake(.5f, .5f);
    CGSize frameSize = _previewLayer.bounds.size;
    
    AVCaptureVideoPreviewLayer *videoPreviewLayer = self.previewLayer;
    
    if([[videoPreviewLayer videoGravity]isEqualToString:AVLayerVideoGravityResize]) {
        pointOfInterest = CGPointMake(viewCoordinates.y / frameSize.height, 1.f - (viewCoordinates.x / frameSize.width));
    } else {
        CGRect cleanAperture;
        for(AVCaptureInputPort *port in [[self.session.inputs lastObject]ports]) {
            if([port mediaType] == AVMediaTypeVideo) {
                cleanAperture = CMVideoFormatDescriptionGetCleanAperture([port formatDescription], YES);
                CGSize apertureSize = cleanAperture.size;
                CGPoint point = viewCoordinates;
                
                CGFloat apertureRatio = apertureSize.height / apertureSize.width;
                CGFloat viewRatio = frameSize.width / frameSize.height;
                CGFloat xc = .5f;
                CGFloat yc = .5f;
                
                if([[videoPreviewLayer videoGravity]isEqualToString:AVLayerVideoGravityResizeAspect]) {
                    if(viewRatio > apertureRatio) {
                        CGFloat y2 = frameSize.height;
                        CGFloat x2 = frameSize.height * apertureRatio;
                        CGFloat x1 = frameSize.width;
                        CGFloat blackBar = (x1 - x2) / 2;
                        if(point.x >= blackBar && point.x <= blackBar + x2) {
                            xc = point.y / y2;
                            yc = 1.f - ((point.x - blackBar) / x2);
                        }
                    } else {
                        CGFloat y2 = frameSize.width / apertureRatio;
                        CGFloat y1 = frameSize.height;
                        CGFloat x2 = frameSize.width;
                        CGFloat blackBar = (y1 - y2) / 2;
                        if(point.y >= blackBar && point.y <= blackBar + y2) {
                            xc = ((point.y - blackBar) / y2);
                            yc = 1.f - (point.x / x2);
                        }
                    }
                } else if([[videoPreviewLayer videoGravity]isEqualToString:AVLayerVideoGravityResizeAspectFill]) {
                    if(viewRatio > apertureRatio) {
                        CGFloat y2 = apertureSize.width * (frameSize.width / apertureSize.height);
                        xc = (point.y + ((y2 - frameSize.height) / 2.f)) / y2;
                        yc = (frameSize.width - point.x) / frameSize.width;
                    } else {
                        CGFloat x2 = apertureSize.height * (frameSize.height / apertureSize.width);
                        yc = 1.f - ((point.x + ((x2 - frameSize.width) / 2)) / x2);
                        xc = point.y / frameSize.height;
                    }
                    
                }
                
                pointOfInterest = CGPointMake(xc, yc);
                break;
            }
        }
    }
    
    return pointOfInterest;
}

/**
 *  显示/隐藏网格
 *
 *  @param toShow 显示或隐藏
 */
- (void)switchGridLines:(BOOL)toShow
{
    if (!toShow) {
        NSArray *layersArr = [NSArray arrayWithArray:_preview.layer.sublayers];
        for (CALayer *layer in layersArr) {
            if (layer.frame.size.width == 1 || layer.frame.size.height == 1) {
                [layer removeFromSuperlayer];
            }
        }
        return;
    }
    
    //    CGFloat headHeight = _previewLayer.bounds.size.height - SC_APP_SIZE.width - 80;
    CGFloat headWidth = 0; //_previewLayer.bounds.size.height - SC_APP_SIZE.width;
    CGFloat squareWidth = SC_APP_SIZE.width;
    CGFloat squareHeight = _previewLayer.bounds.size.height - 60;
    CGFloat eachAreaHeight = squareHeight / 3;
    CGFloat eachAreaWidth = squareWidth / 3;
    
    for (int i = 0; i < 4; i++) {
        CGRect frame = CGRectZero;
        if (i == 0 || i == 1) {//画横线
            CGFloat additionalOriY = 0;
            if (i == 0) {
                additionalOriY = -20;
            }
            else if (i == 1) {
                additionalOriY = 20;
            }
            
            frame = CGRectMake(0, (i + 1) * eachAreaHeight + additionalOriY, squareWidth, 1);
        } else {
            CGFloat additionalH = 0;
            if (!isHigherThaniPhone4_SC) {
                additionalH = -8;
            }
            frame = CGRectMake((i - 1) * eachAreaWidth, headWidth, 1, squareHeight + additionalH);
            
        }
        NSLog(@"LineFrame:%@ for i:%d", NSStringFromCGRect(frame), i);
        [SCCommon drawALineWithFrame:frame andColor:[[UIColor whiteColor] colorWithAlphaComponent:0.3] inLayer:_preview.layer];
    }
}

- (void)switchAlphaCover:(BOOL)toShow {
    // 2.0
    if (!toShow) {
        return;
    }
    
    MDCameraCoverView *coverView = [XXBFRAMEWORK_BUNDLE loadNibNamed:@"CameraCover" owner:self options:nil].firstObject;
    CGRect coverFrame = self.preview.frame;
    coverFrame.size.height -= 60;
    coverView.frame = coverFrame;
    [self.preview addSubview:coverView];
    
    return;
}

////画一条线
//+ (void)drawALineWithFrame:(CGRect)frame andColor:(UIColor*)color inLayer:(CALayer*)parentLayer {
//    CALayer *layer = [CALayer layer];
//    layer.frame = frame;
//    layer.backgroundColor = color.CGColor;
//    [parentLayer addSublayer:layer];
//}

//
//AVAsset* asset = // your input
//
//AVMutableComposition *videoComposition = [AVMutableComposition composition];
//
//AVMutableCompositionTrack *compositionVideoTrack = [videoComposition  addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
//
//AVAssetTrack *clipVideoTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
//
//AVMutableVideoComposition* videoComposition = [[AVMutableVideoComposition videoComposition]retain];
//videoComposition.renderSize = CGSizeMake(320, 320);
//videoComposition.frameDuration = CMTimeMake(1, 30);
//
//AVMutableVideoCompositionInstruction *instruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
//instruction.timeRange = CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(60, 30) );
//
//AVMutableVideoCompositionLayerInstruction* transformer = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:clipVideoTrack];
//CGAffineTransform finalTransform = // setup a transform that grows the video, effectively causing a crop
//[transformer setTransform:finalTransform atTime:kCMTimeZero];
//instruction.layerInstructions = [NSArray arrayWithObject:transformer];
//videoComposition.instructions = [NSArray arrayWithObject: instruction];
//
//exporter = [[AVAssetExportSession alloc] initWithAsset:saveComposition presetName:AVAssetExportPresetHighestQuality] ;
//exporter.videoComposition = videoComposition;
//exporter.outputURL=url3;
//exporter.outputFileType=AVFileTypeQuickTimeMovie;
//
//[exporter exportAsynchronouslyWithCompletionHandler:^(void){}];


//- (void)saveImageToPhotoAlbum:(UIImage*)image {
//    UIImageWriteToSavedPhotosAlbum(image, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
//}
//
//- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
//    if (error != NULL) {
//        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"出错了!" message:@"存不了T_T" delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
//        [alert show];
//    } else {
//        SCDLog(@"保存成功111");
//    }
//}


#pragma mark ---------------private--------------
- (AVCaptureConnection*)findVideoConnection {
    AVCaptureConnection *videoConnection = nil;
	for (AVCaptureConnection *connection in _stillImageOutput.connections) {
		for (AVCaptureInputPort *port in connection.inputPorts) {
			if ([[port mediaType] isEqual:AVMediaTypeVideo]) {
				videoConnection = connection;
				break;
			}
		}
		if (videoConnection) {
            break;
        }
	}
    return videoConnection;
}



@end
