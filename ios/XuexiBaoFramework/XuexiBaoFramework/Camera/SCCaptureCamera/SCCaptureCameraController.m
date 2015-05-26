//
//  SCCaptureCameraController.m
//  SCCaptureCameraDemo
//
//  Created by Aevitx on 14-1-16.
//  Copyright (c) 2014年 Aevitx. All rights reserved.
//

#import "SCCaptureCameraController.h"
#import "SCSlider.h"
#import "SCCommon.h"
#import "SCDefines.h"
#import "SVProgressHUD.h"
//#import "EAIntroView.h"
#import "SCNavigationController.h"
#import "MDEditPhotoViewController.h"
#import "UIImage+GIF.h"
#import "MDExtension.h"
#import "UIColor+Extension.h"
#import "SCCaptureSessionManager.h"
#import "UIImage+Extension.h"



//static void * CapturingStillImageContext = &CapturingStillImageContext;
//static void * RecordingContext = &RecordingContext;
//static void * SessionRunningAndDeviceAuthorizedContext = &SessionRunningAndDeviceAuthorizedContext;

#define SWITCH_SHOW_FOCUSVIEW_UNTIL_FOCUS_DONE      0   //对焦框是否一直闪到对焦完成

#define SWITCH_SHOW_DEFAULT_IMAGE_FOR_NONE_CAMERA   1   //没有拍照功能的设备，是否给一张默认图片体验一下


//color
#define bottomContainerView_UP_COLOR     [UIColor colorWithRed:51/255.0f green:51/255.0f blue:51/255.0f alpha:1.f]       //bottomContainerView的上半部分
#define bottomContainerView_DOWN_COLOR   [UIColor colorWithRed:68/255.0f green:68/255.0f blue:68/255.0f alpha:1.f]       //bottomContainerView的下半部分
#define DARK_GREEN_COLOR        [UIColor colorWithRed:10/255.0f green:107/255.0f blue:42/255.0f alpha:1.f]    //深绿色
#define LIGHT_GREEN_COLOR       [UIColor colorWithRed:143/255.0f green:191/255.0f blue:62/255.0f alpha:1.f]    //浅绿色


//对焦
#define ADJUSTINT_FOCUS @"adjustingFocus"
#define LOW_ALPHA   0.7f
#define HIGH_ALPHA  1.0f

//typedef enum {
//    bottomContainerViewTypeCamera    =   0,  //拍照页面
//    bottomContainerViewTypeAudio     =   1   //录音页面
//} BottomContainerViewType;

@interface SCCaptureCameraController () <SCCaptureSessionManager, UIImagePickerControllerDelegate, UINavigationControllerDelegate, MDEditPhotoViewControllerDelegate> {
    int alphaTimes;
    CGPoint currTouchPoint;
}

@property (nonatomic, strong) SCCaptureSessionManager *captureManager;

@property (nonatomic, strong) UIView *topContainerView;//顶部view

//@property (nonatomic, strong) UIButton *topFlashBtn; // 顶部闪光灯调整按钮
@property (nonatomic, strong) UILabel *remindLabel; // 提示用户对准白线的Label

@property (nonatomic, strong) UILabel *operLb;          // 中央区域“请横屏拍摄”提示
@property (nonatomic, strong) UIImageView *operBgImgV;  // 中央区域蓝色背景
@property (nonatomic, strong) UIImageView *cameraBtnLoadingImgV; // 拍照按钮的Loading状态imageview
@property (nonatomic, strong) UIView *flashCover;       // 拍照瞬间闪光的效果
@property (nonatomic, strong) UIImageView *helperImgV;  // 拍题引导页面

@property (nonatomic, strong) UIView *bottomContainerView;//除了顶部标题、拍照区域剩下的所有区域

@property (nonatomic, strong) NSMutableSet *cameraBtnSet;

@property (nonatomic, strong) UIView *doneCameraUpView;
@property (nonatomic, strong) UIView *doneCameraDownView;
@property (nonatomic, strong) UIImageView *processingImgV;

@property (nonatomic, strong) UIButton *cameraButton;
@property (nonatomic, strong) UIButton *flashButton;
@property (nonatomic, strong) UIButton *helpButton;

//对焦
@property (nonatomic, strong) UIImageView *focusImageView;

@property (nonatomic, strong) UIImageView *shakeCoverImageView;

@property (nonatomic, strong) SCSlider *scSlider;

//@property (nonatomic) id runtimeErrorHandlingObserver;
//@property (nonatomic) BOOL lockInterfaceRotation;

- (void)orientationDidChange:(NSNotification*)noti;

@end

@implementation SCCaptureCameraController

#pragma mark -------------life cycle---------------
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        alphaTimes = -1;
        currTouchPoint = CGPointZero;
        
        _cameraBtnSet = [[NSMutableSet alloc] init];
        
        _isProMode = YES;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
#if SWITCH_SHOW_DEFAULT_IMAGE_FOR_NONE_CAMERA
    if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        [SVProgressHUD showStatus:@"设备不支持拍照功能，给个妹纸给你喵喵T_T"];
        
        UIImageView *imgView = [[UIImageView alloc] initWithFrame:CGRectMake(0, CAMERA_TOPVIEW_HEIGHT, self.view.frame.size.width, self.view.frame.size.width)];
        imgView.clipsToBounds = YES;
        imgView.contentMode = UIViewContentModeScaleAspectFill;
        imgView.image = [UIImage imageWithContentsOfFile:[XXBFRAMEWORK_BUNDLE pathForResource:@"meizi" ofType:@"jpg"]];
        [self.view addSubview:imgView];
        
        return;
    }
#endif
    
    
    //notification
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kNotificationOrientationChange object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationDidChange:) name:kNotificationOrientationChange object:nil];
    //    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    //    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationDidChange:) name:UIDeviceOrientationDidChangeNotification object:nil];
    
    //session manager
    SCCaptureSessionManager *manager = [[SCCaptureSessionManager alloc] init];
    manager.delegate = self;
    
    //AvcaptureManager
    if (CGRectEqualToRect(_previewRect, CGRectZero)) {
        self.previewRect = CGRectMake(0, 0, SC_APP_SIZE.width, SCREEN_HEIGHT);
        //        self.previewRect = CGRectMake(0, 0, SC_APP_SIZE.width, SC_APP_SIZE.width + CAMERA_TOPVIEW_HEIGHT + additionalH);
    }
    [manager configureWithParentLayer:self.view previewRect:_previewRect];
    self.captureManager = manager;
    
    self.view.backgroundColor = [UIColor blackColor];
    
    if (self.isProMode) {
        //        [_captureManager switchAlphaCover:YES];
        [_captureManager switchGridLines:YES];
        [self addRemindLabel];
        
        [self addCentralDisplay];
    }
    
    [self addTopViewWithText:@"拍照"];
    [self addbottomContainerView];
    [self addCameraMenuView];
    
    [self addFocusView];
    [self addCameraCover];
    [self addPinchGesture];
    
    [self.captureManager startCameraCompletion:^{
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(subjectAreaDidChange:) name:AVCaptureDeviceSubjectAreaDidChangeNotification object:[_captureManager.inputDevice device]];
        
        self.view.backgroundColor = [UIColor clearColor];
    }];
    
    //    [_captureManager.session startRunning];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
//    [MobClick beginLogPageView:NSStringFromClass([SCCaptureCameraController class])];
    [TalkingData trackPageBegin:NSStringFromClass([SCCaptureCameraController class])];
}

- (void)viewWillDisappear:(BOOL)animated
{
//    [self switchActivityView:NO];

//    [MobClick endLogPageView:NSStringFromClass([SCCaptureCameraController class])];
    [TalkingData trackPageEnd:NSStringFromClass([SCCaptureCameraController class])];

    [super viewWillDisappear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    
    if (self.isProMode) {
        if (!CanUseCamera()) {
            [self showCentralInfoArea:@"拍题前请先允许访问相机" autoDisappear:YES];
        }
        else {
            [self showCentralInfoArea:@"请横屏拍摄" autoDisappear:YES];
        }
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self orientationDidChange:nil];
        });
    }
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (UIStatusBarAnimation )preferredStatusBarUpdateAnimation
{
    return UIStatusBarAnimationSlide;
}

- (void)switchShakeCover:(BOOL)toShow
{
    if (toShow && self.shakeCoverImageView.alpha == 0) {
        [UIView animateWithDuration:0.2 animations:^{
            self.shakeCoverImageView.alpha = 1;
        }];
        
        return;
    }
    
    if (!toShow && self.shakeCoverImageView.alpha == 1) {
        [UIView animateWithDuration:0.2 animations:^{
            self.shakeCoverImageView.alpha = 0;
        }];
        
        return;
    }
}

- (UIImageView *)shakeCoverImageView
{
    if (!_shakeCoverImageView) {
        _shakeCoverImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"fangdou"]];
        
        CGRect frame = _shakeCoverImageView.frame;
        frame.origin.x = SCREEN_WIDTH / 2 - frame.size.width / 2;
        frame.origin.y = (SCREEN_HEIGHT - 60)/ 2 - frame.size.height / 2 + 10;
        
        _shakeCoverImageView.frame = frame;
        _shakeCoverImageView.alpha = 0;
        
        [self.view addSubview:_shakeCoverImageView];
    }
    
    return _shakeCoverImageView;
}


- (void)subjectAreaDidChange:(NSNotification *)notification
{
    CGPoint devicePoint = CGPointMake(.5, .5);
    [self.captureManager focusWithMode:AVCaptureFocusModeContinuousAutoFocus exposeWithMode:AVCaptureExposureModeContinuousAutoExposure atDevicePoint:devicePoint monitorSubjectAreaChange:NO];
}

//- (void)viewWillAppear:(BOOL)animated {
//	dispatch_async(_captureManager.sessionQueue, ^{
//		[self addObserver:self forKeyPath:@"sessionRunningAndDeviceAuthorized" options:(NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew) context:SessionRunningAndDeviceAuthorizedContext];
//		[self addObserver:self forKeyPath:@"stillImageOutput.capturingStillImage" options:(NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew) context:CapturingStillImageContext];
//		[self addObserver:self forKeyPath:@"movieFileOutput.recording" options:(NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew) context:RecordingContext];
//		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(subjectAreaDidChange:) name:AVCaptureDeviceSubjectAreaDidChangeNotification object:[_captureManager.inputDevice device]];
//
//		WEAKSELF_SC
//		[self setRuntimeErrorHandlingObserver:[[NSNotificationCenter defaultCenter] addObserverForName:AVCaptureSessionRuntimeErrorNotification object:_captureManager.session queue:nil usingBlock:^(NSNotification *note) {
//			SCCaptureCameraController *strongSelf = weakSelf_SC;
//			dispatch_async(strongSelf.captureManager.sessionQueue, ^{
//				// Manually restarting the session since it must have been stopped due to an error.
//				[strongSelf.captureManager.session startRunning];
//			});
//		}]];
//		[_captureManager.session startRunning];
//	});
//}
//
//- (void)viewDidDisappear:(BOOL)animated
//{
//	dispatch_async(_captureManager.sessionQueue, ^{
//		[_captureManager.session stopRunning];
//
//		[[NSNotificationCenter defaultCenter] removeObserver:self name:AVCaptureDeviceSubjectAreaDidChangeNotification object:[_captureManager.inputDevice device]];
//		[[NSNotificationCenter defaultCenter] removeObserver:[self runtimeErrorHandlingObserver]];
//
//		[self removeObserver:self forKeyPath:@"sessionRunningAndDeviceAuthorized" context:SessionRunningAndDeviceAuthorizedContext];
//		[self removeObserver:self forKeyPath:@"stillImageOutput.capturingStillImage" context:CapturingStillImageContext];
//		[self removeObserver:self forKeyPath:@"movieFileOutput.recording" context:RecordingContext];
//	});
//}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    
    //    if (!self.navigationController) {
    //        if ([UIApplication sharedApplication].statusBarHidden != _isStatusBarHiddenBeforeShowCamera) {
    //            [[UIApplication sharedApplication] setStatusBarHidden:_isStatusBarHiddenBeforeShowCamera withAnimation:UIStatusBarAnimationSlide];
    //        }
    //    }
    
    MDLog(@"+++++++++++++SCCaptureCameraController dealloc++++++++++++++");
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVCaptureDeviceSubjectAreaDidChangeNotification object:[_captureManager.inputDevice device]];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kNotificationOrientationChange object:nil];
    
#if SWITCH_SHOW_FOCUSVIEW_UNTIL_FOCUS_DONE
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if (device && [device isFocusPointOfInterestSupported]) {
        [device removeObserver:self forKeyPath:ADJUSTINT_FOCUS context:nil];
    }
#endif
    
    [self.captureManager stopCamera];
    
    self.captureManager = nil;
}

- (void)flashScreen
{
    [UIView animateWithDuration:0.1 animations:^{
        self.flashCover.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.6];
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.1 animations:^{
            self.flashCover.backgroundColor = [UIColor clearColor];
        }];
    }];
}

#pragma mark --
#pragma mark -- Properties
- (UIImageView *)helperImgV
{
    if (!_helperImgV) {
        _helperImgV = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)];
        _helperImgV.backgroundColor = [UIColor clearColor];
        _helperImgV.contentMode = UIViewContentModeScaleAspectFill;
        UIImage *img = nil;
        if (IS_IPHONE_4) {
            img = [UIImage imageNamed:XXBRSRC_NAME(@"camera_help_960.jpg")];
        }
        else {
            img = [UIImage imageNamed:XXBRSRC_NAME(@"camera_help_1136.jpg")];
        }
        
        _helperImgV.image = img;
        _helperImgV.alpha = 0;
        
        [self.view addSubview:_helperImgV];
        [self.view bringSubviewToFront:_helperImgV];
    }
    
    return _helperImgV;
}

- (UIView *)flashCover
{
    if (!_flashCover) {
        _flashCover = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT - 60)];
        _flashCover.backgroundColor = [UIColor clearColor];

        [self.view addSubview:_flashCover];
        [self.view bringSubviewToFront:_flashCover];
    }
    
    return _flashCover;
}

- (UIImageView *)cameraBtnLoadingImgV
{
    if (!_cameraBtnLoadingImgV) {
        _cameraBtnLoadingImgV = [[UIImageView alloc] initWithFrame:CGRectMake((SC_APP_SIZE.width + 2 - 60) / 2, 0, 60, 60)];
        _cameraBtnLoadingImgV.backgroundColor = [UIColor clearColor];

        
        _cameraBtnLoadingImgV.animationImages = @[[UIImage imageNamed:XXBRSRC_NAME(@"camera_loading_1")],
                                                  [UIImage imageNamed:XXBRSRC_NAME(@"camera_loading_2")],
                                                  [UIImage imageNamed:XXBRSRC_NAME(@"camera_loading_3")],
                                                  [UIImage imageNamed:XXBRSRC_NAME(@"camera_loading_4")],
                                                  [UIImage imageNamed:XXBRSRC_NAME(@"camera_loading_5")],
                                                  [UIImage imageNamed:XXBRSRC_NAME(@"camera_loading_6")]
                                                  ];
        _cameraBtnLoadingImgV.animationDuration = 0.7;
        _cameraBtnLoadingImgV.animationRepeatCount = 0;
        _cameraBtnLoadingImgV.alpha = 0;
        [_cameraBtnLoadingImgV stopAnimating];
    }
    
    return _cameraBtnLoadingImgV;
}

- (UILabel *)operLb
{
    if (!_operLb) {
        CGFloat width = SCREEN_WIDTH / 2;
        CGFloat height = 60;
        _operLb = [[UILabel alloc] initWithFrame:CGRectMake(SCREEN_WIDTH / 4, (SCREEN_HEIGHT - 60) / 2 - 30, width, height)];
        _operLb.backgroundColor = [UIColor clearColor];
        _operLb.textAlignment = NSTextAlignmentCenter;
        _operLb.font = [UIFont boldSystemFontOfSize:18];
        _operLb.numberOfLines = 2;
        _operLb.text = @"请横屏拍摄";
        _operLb.textColor = [UIColor whiteColor];
        _operLb.alpha = 0;
    }
    
    return _operLb;
}

- (UIImageView *)operBgImgV
{
    if (!_operBgImgV) {
        CGFloat width = SCREEN_WIDTH / 3;
        CGFloat height = (SCREEN_HEIGHT - 60) / 3;
        _operBgImgV = [[UIImageView alloc] initWithFrame:CGRectMake(width + 1, height + 1 - 20, width - 1, height - 1 + 40)];
        _operBgImgV.backgroundColor = [[UIColor colorWithHex:0x0091ff] colorWithAlphaComponent:0.3];
        _operBgImgV.alpha = 0;
    }
    
    return _operBgImgV;
}



#pragma mark -------------UI---------------
//顶部标题
- (void)addTopViewWithText:(NSString*)text {
    if (!_topContainerView) {
        CGRect topFrame = CGRectMake(0, 0, SC_APP_SIZE.width, CAMERA_TOPVIEW_HEIGHT);
        
        UIView *tView = [[UIView alloc] initWithFrame:topFrame];
        tView.backgroundColor = [UIColor clearColor];
        [self.view addSubview:tView];
        self.topContainerView = tView;
    }
}

// 中央区域提示
- (void)addCentralDisplay {
    [self.view addSubview:self.operBgImgV];
    
    [self.view addSubview:self.operLb];
    [self.view bringSubviewToFront:self.operLb];
}

// 拍照提示中文
- (void)addRemindLabel
{
    UILabel *label = nil;
    
    if (IS_IPHONE_4) {
        CGFloat bottomY = (SCREEN_HEIGHT - 60) / 2 - 20; //_captureManager.previewLayer.frame.origin.y + _captureManager.previewLayer.frame.size.height / 2 - 20;
        CGRect labelFrame = CGRectMake(-60, bottomY, 170, SC_REMINDLABEL_HEIGHT);
        
        label = [[UILabel alloc] initWithFrame:labelFrame];
        label.font = [UIFont boldSystemFontOfSize:16];
    }
    else {
        CGFloat bottomY = (SCREEN_HEIGHT - 60) / 2 - 19; //_captureManager.previewLayer.frame.origin.y + _captureManager.previewLayer.frame.size.height / 2 - 20;
        CGRect labelFrame = CGRectMake(-65, bottomY, 190, SC_REMINDLABEL_HEIGHT);
        
        label = [[UILabel alloc] initWithFrame:labelFrame];
        label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    }
    
    label.textColor = [UIColor whiteColor];
    label.numberOfLines = 1;
    label.textAlignment = NSTextAlignmentCenter;
    label.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.8];
    label.clipsToBounds = YES;
    label.layer.cornerRadius = 5.0f;
    
    label.text = @"题目文字与参考线平行"; //NSLocalizedString(@"camera_remind", @"");
    label.alpha = 0.85;
    [self.view addSubview:label];
    self.remindLabel = label;
    
    CGAffineTransform transform = CGAffineTransformMakeRotation(M_PI_2);
    _remindLabel.transform = transform;
}

//bottomContainerView，总体
- (void)addbottomContainerView {
    
    CGFloat bottomH = 60;
    
    CGRect bottomFrame = CGRectMake(0, SCREEN_HEIGHT - bottomH, SC_APP_SIZE.width, bottomH);
    
//    CGRect bottomFrame = CGRectMake(0, SC_APP_FRAME.size.height - bottomH, SC_APP_SIZE.width, bottomH);
    
    UIView *view = [[UIView alloc] initWithFrame:bottomFrame];
    view.backgroundColor = [UIColor blackColor]; //bottomContainerView_UP_COLOR;
    view.alpha = 0.8;
    [self.view addSubview:view];
    self.bottomContainerView = view;
}

//拍照菜单栏
- (void)addCameraMenuView {
    
    //拍照按钮
    //    CGFloat downH = 24; //(isHigherThaniPhone4_SC ? CAMERA_MENU_VIEW_HEIGH : 0);
    CGFloat cameraBtnLength = 60;
    CGRect cameraBtnFrame = CGRectMake((SC_APP_SIZE.width + 2 - cameraBtnLength) / 2, 0, 60, 60);
    //    CGRect cameraBtnFrame = CGRectMake((SC_APP_SIZE.width - cameraBtnLength) / 2, (_bottomContainerView.frame.size.height - downH - cameraBtnLength) / 2 , 87, 76);
    UIButton *cameraBtn = [self buildButton:cameraBtnFrame
                               normalImgStr:XXBRSRC_NAME(@"camera_55")
                            highlightImgStr:XXBRSRC_NAME(@"camera_55_h")
                             selectedImgStr:XXBRSRC_NAME(@"camera_55_h")
                                     action:@selector(takePictureBtnPressed:)
                                 parentView:_bottomContainerView];
    cameraBtn.showsTouchWhenHighlighted = YES;
    self.cameraButton = cameraBtn;
    
    [self.bottomContainerView addSubview:self.cameraBtnLoadingImgV];
    [self.bottomContainerView bringSubviewToFront:self.cameraBtnLoadingImgV];
    
    [self addMenuViewButtons];
}

//拍照菜单栏上的按钮
- (void)addMenuViewButtons {
    // 相册按钮 @"album_btn.png",
    // 闪光灯开关按钮 @"ic_flash_off.png", @"", @"", @"flashBtnPressed:",
    NSMutableArray *normalArr = [[NSMutableArray alloc] initWithObjects:@"camera_cancle", @"camera_album", @"camera_flash_off", @"camera_help", nil];
    NSMutableArray *highlightArr = [[NSMutableArray alloc] initWithObjects:@"camera_cancle_hi", @"camera_album_h", @"", @"camera_help_hi", nil];
    NSMutableArray *selectedArr = [[NSMutableArray alloc] initWithObjects:@"camera_cancle_hi", @"camera_album_h", @"", @"camera_help_hi", nil];
    
    NSMutableArray *actionArr = [[NSMutableArray alloc] initWithObjects:@"dismissBtnPressed:", @"albumBtnPressed:", @"flashBtnPressed:", @"helpBtnPressed:", nil];
    
    //    CGFloat eachW = SC_APP_SIZE.width / (isHigherThaniPhone4_SC ? (actionArr.count - 1) : actionArr.count);
    
    //    [SCCommon drawALineWithFrame:CGRectMake(eachW, 0, 1, CAMERA_MENU_VIEW_HEIGH) andColor:rgba_SC(102, 102, 102, 1.0000) inLayer:_cameraMenuView.layer];
    
    // 相册按钮
    UIButton *btn = [self buildButton:CGRectMake(_bottomContainerView.bounds.origin.x + 5, _bottomContainerView.bounds.size.height - CAMERA_MENU_BTN_SIZE, CAMERA_MENU_BTN_SIZE, CAMERA_MENU_BTN_SIZE)
                         normalImgStr:XXBRSRC_NAME(@"camera_album")
                      highlightImgStr:XXBRSRC_NAME(@"camera_album_h")
                       selectedImgStr:XXBRSRC_NAME(@"camera_album_h")
                               action:NSSelectorFromString(@"albumBtnPressed:")
                           parentView:_bottomContainerView];
    [_bottomContainerView bringSubviewToFront:btn];
//    btn.showsTouchWhenHighlighted = YES;
    [_cameraBtnSet addObject:btn];
    
    
    // 关闭按钮
    btn = [self buildButton:CGRectMake(_bottomContainerView.bounds.size.width - CAMERA_MENU_BTN_SIZE - 5, _bottomContainerView.bounds.size.height - CAMERA_MENU_BTN_SIZE, CAMERA_MENU_BTN_SIZE, CAMERA_MENU_BTN_SIZE)
               normalImgStr:XXBRSRC_NAME(@"camera_cancle")
            highlightImgStr:XXBRSRC_NAME(@"camera_cancle_h")
             selectedImgStr:XXBRSRC_NAME(@"camera_cancle_h")
                     action:NSSelectorFromString(@"dismissBtnPressed:")
                 parentView:_bottomContainerView];
    [_bottomContainerView bringSubviewToFront:btn];
//    btn.showsTouchWhenHighlighted = YES;
    [_cameraBtnSet addObject:btn];
    
    
    if (!self.isProMode) {
        // 前置相机按钮
        btn = [self buildButton:CGRectMake(10, 10, CAMERA_MENU_BTN_SIZE, CAMERA_MENU_BTN_SIZE)
                   normalImgStr:XXBRSRC_NAME(@"camera_around.png")
                highlightImgStr:XXBRSRC_NAME(@"")
                 selectedImgStr:XXBRSRC_NAME(@"camera_around.png")
                         action:NSSelectorFromString(@"switchCameraBtnPressed:")
                     parentView:_topContainerView];
        btn.showsTouchWhenHighlighted = YES;
        [_cameraBtnSet addObject:btn];
    }
    
    
    // 闪光灯按钮
    btn = [self buildButton:CGRectMake(0, 0, CAMERA_TOP_BTN_SIZE + 10, CAMERA_TOP_BTN_SIZE + 10)
               normalImgStr:XXBRSRC_NAME([normalArr objectAtIndex:2])
            highlightImgStr:XXBRSRC_NAME([highlightArr objectAtIndex:2])
             selectedImgStr:XXBRSRC_NAME([selectedArr objectAtIndex:2])
                     action:NSSelectorFromString([actionArr objectAtIndex:2])
                 parentView:_topContainerView];
    btn.showsTouchWhenHighlighted = YES;
    //    [_cameraBtnSet addObject:btn];
    
    CGAffineTransform transform = CGAffineTransformMakeRotation(M_PI_2);
    btn.transform = transform;
    _flashButton = btn;
    
    
    // 拍题攻略按钮
    btn = [self buildButton:CGRectMake(SCREEN_WIDTH - CAMERA_TOP_BTN_SIZE - 10, 0, CAMERA_TOP_BTN_SIZE + 10, CAMERA_TOP_BTN_SIZE + 10)
               normalImgStr:XXBRSRC_NAME([normalArr objectAtIndex:3])
            highlightImgStr:XXBRSRC_NAME([highlightArr objectAtIndex:3])
             selectedImgStr:XXBRSRC_NAME([selectedArr objectAtIndex:3])
                     action:NSSelectorFromString([actionArr objectAtIndex:3])
                 parentView:_topContainerView];
    //    [_cameraBtnSet addObject:btn];
    btn.transform = transform;
    _helpButton = btn;
}

- (UIButton *)buildTextButton:(CGRect)frame
                        title:(NSString *)title
                    textColor:(UIColor *)color
                       action:(SEL)action
                   parentView:(UIView *)parentView
{
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.frame = frame;
    btn.backgroundColor = [UIColor clearColor];
    [btn setTitle:title forState:UIControlStateNormal];
    [btn setTitle:title forState:UIControlStateHighlighted];
    [btn setTitle:title forState:UIControlStateSelected];
    [btn setTitleColor:color forState:UIControlStateNormal];
    [btn setTitleColor:color forState:UIControlStateHighlighted];
    [btn setTitleColor:color forState:UIControlStateSelected];
    [btn addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    [parentView addSubview:btn];
    
    return btn;
}

- (UIButton*)buildButton:(CGRect)frame
            normalImgStr:(NSString*)normalImgStr
         highlightImgStr:(NSString*)highlightImgStr
          selectedImgStr:(NSString*)selectedImgStr
                  action:(SEL)action
              parentView:(UIView*)parentView {
    
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.frame = frame;
    if (normalImgStr.length > 0) {
        [btn setImage:[UIImage imageNamed:normalImgStr] forState:UIControlStateNormal];
    }
    if (highlightImgStr.length > 0) {
        UIImage *img = [UIImage imageNamed:highlightImgStr];
        [btn setImage:img forState:UIControlStateHighlighted];
    }
    if (selectedImgStr.length > 0) {
        UIImage *img = [UIImage imageNamed:selectedImgStr];
        [btn setImage:img forState:UIControlStateSelected];
    }
    [btn addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    [parentView addSubview:btn];
    
    return btn;
}

//对焦的框
- (void)addFocusView {
    UIImageView *imgView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:XXBRSRC_NAME(@"touch_focus_x.png")]];
    imgView.alpha = 0;
    [self.view addSubview:imgView];
    self.focusImageView = imgView;
    
#if SWITCH_SHOW_FOCUSVIEW_UNTIL_FOCUS_DONE
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if (device && [device isFocusPointOfInterestSupported]) {
        [device addObserver:self forKeyPath:ADJUSTINT_FOCUS options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:nil];
    }
#endif
}

//拍完照后的遮罩
- (void)addCameraCover {
    UIView *upView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SC_APP_SIZE.width, 0)];
    upView.backgroundColor = [UIColor blackColor];
    [self.view addSubview:upView];
    self.doneCameraUpView = upView;
    
    UIView *downView = [[UIView alloc] initWithFrame:CGRectMake(0, _bottomContainerView.frame.origin.y, SC_APP_SIZE.width, 0)];
    downView.backgroundColor = [UIColor blackColor];
    [self.view addSubview:downView];
    self.doneCameraDownView = downView;
    
    const int imageWidth = 30;
    
    UIImageView *imgV = [[UIImageView alloc] initWithFrame:CGRectMake(SCREEN_WIDTH / 2 - imageWidth / 2, SCREEN_HEIGHT / 2 - imageWidth / 2, imageWidth, imageWidth)];
    imgV.backgroundColor = [UIColor clearColor];
    imgV.clipsToBounds = YES;
    imgV.layer.cornerRadius = 3.0f;
    //imgV.image = [UIImage sd_animatedGIFNamed:@"loading"];
    imgV.hidden = YES;
    
    NSArray *images=[NSArray arrayWithObjects:[UIImage imageNamed:XXBRSRC_NAME(@"LoadingImage1")],[UIImage imageNamed:XXBRSRC_NAME(@"LoadingImage2")],[UIImage imageNamed:XXBRSRC_NAME(@"LoadingImage3")],[UIImage imageNamed:XXBRSRC_NAME(@"LoadingImage4")],[UIImage imageNamed:XXBRSRC_NAME(@"LoadingImage5")],[UIImage imageNamed:XXBRSRC_NAME(@"LoadingImage6")], nil];
    imgV.animationImages = images;
    imgV.animationDuration = 0.3;
    [imgV startAnimating];
    
    [self.view addSubview:imgV];
    self.processingImgV = imgV;
}

- (void)showCentralInfoArea:(NSString *)text autoDisappear:(BOOL)isAuto
{
    // 1. 如果没有设置文字，认为需要隐藏
    if (!text || text.length <= 0) {
        [UIView animateWithDuration:0.15 animations:^{
            self.operLb.alpha = self.operBgImgV.alpha = 0;
        } completion:^(BOOL finished) {
            self.operLb.hidden = self.operBgImgV.hidden = YES;
        }];
        
        return;
    }
    
    // 2. 如果之前是隐藏，显示展现过程
    if (self.operLb.alpha == 0 || self.operBgImgV.alpha == 0) {
        self.operLb.text = text;
        
        self.operLb.hidden = self.operBgImgV.hidden = NO;
        [UIView animateWithDuration:0.15 animations:^{
            self.operLb.alpha = self.operBgImgV.alpha = 1;
        } completion:^(BOOL finished) {
            
        }];
    }
    
    // 3. 如果是定时自动消失，安排定时任务
    if (isAuto) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [UIView animateWithDuration:0.15 animations:^{
                self.operLb.alpha = self.operBgImgV.alpha = 0;
            } completion:^(BOOL finished) {
                self.operLb.hidden = self.operBgImgV.hidden = YES;
            }];
        });
    }
}

- (void)showCameraCover:(BOOL)toShow
{
    //    CGFloat additionalH = LAYOUT_ADDITIONAL_H / 2;
    
    [UIView animateWithDuration:0.38f animations:^{
        CGRect upFrame = _doneCameraUpView.frame;
        upFrame.size.height = (toShow ? SC_APP_SIZE.height / 2 : 0);
        //        upFrame.size.height = (toShow ? SC_APP_SIZE.width / 2 + CAMERA_TOPVIEW_HEIGHT + additionalH : 0);
        _doneCameraUpView.frame = upFrame;
        
        if (toShow) {
            self.processingImgV.hidden = NO;
        }
        else {
            self.processingImgV.hidden = YES;
        }
        
        CGRect downFrame = _doneCameraDownView.frame;
        downFrame.origin.y = (toShow ? SC_APP_SIZE.height / 2 : _bottomContainerView.frame.origin.y);
        downFrame.size.height = (toShow ? SC_APP_SIZE.height / 2 : 0);
        //        downFrame.origin.y = (toShow ? SC_APP_SIZE.width / 2 + CAMERA_TOPVIEW_HEIGHT + additionalH : _bottomContainerView.frame.origin.y);
        //        downFrame.size.height = (toShow ? SC_APP_SIZE.width / 2 + additionalH : 0);
        _doneCameraDownView.frame = downFrame;
    }];
}

//伸缩镜头的手势
- (void)addPinchGesture {
    UIPinchGestureRecognizer *pinch = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinch:)];
    [self.view addGestureRecognizer:pinch];
    
    //横向
    //    CGFloat width = _previewRect.size.width - 100;
    //    CGFloat height = 40;
    //    SCSlider *slider = [[SCSlider alloc] initWithFrame:CGRectMake((SC_APP_SIZE.width - width) / 2, SC_APP_SIZE.width + CAMERA_MENU_VIEW_HEIGH - height, width, height)];
    
    //竖向
    CGFloat width = 40;
    CGFloat height = _previewRect.size.height - 100;
    SCSlider *slider = [[SCSlider alloc] initWithFrame:CGRectMake(_previewRect.size.width - width, (_previewRect.size.height + CAMERA_MENU_VIEW_HEIGH - height) / 2, width, height) direction:SCSliderDirectionVertical];
    slider.alpha = 0.f;
    slider.minValue = MIN_PINCH_SCALE_NUM;
    slider.maxValue = MAX_PINCH_SCALE_NUM;
    
    WEAKSELF_SC
    [slider buildDidChangeValueBlock:^(CGFloat value) {
        [weakSelf_SC.captureManager pinchCameraViewWithScalNum:value];
    }];
    [slider buildTouchEndBlock:^(CGFloat value, BOOL isTouchEnd) {
        [weakSelf_SC setSliderAlpha:isTouchEnd];
    }];
    
    [self.view addSubview:slider];
    
    self.scSlider = slider;
}

void c_slideAlpha() {
    
}

- (void)setSliderAlpha:(BOOL)isTouchEnd {
    if (_scSlider) {
        _scSlider.isSliding = !isTouchEnd;
        
        if (_scSlider.alpha != 0.f && !_scSlider.isSliding) {
            double delayInSeconds = 3.88;
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                if (_scSlider.alpha != 0.f && !_scSlider.isSliding) {
                    [UIView animateWithDuration:0.3f animations:^{
                        _scSlider.alpha = 0.f;
                    }];
                }
            });
        }
    }
}

#pragma mark -------------touch to focus---------------
#if SWITCH_SHOW_FOCUSVIEW_UNTIL_FOCUS_DONE
//监听对焦是否完成了
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:ADJUSTINT_FOCUS]) {
        BOOL isAdjustingFocus = [[change objectForKey:NSKeyValueChangeNewKey] isEqualToNumber:[NSNumber numberWithInt:1] ];
        //        SCDLog(@"Is adjusting focus? %@", isAdjustingFocus ? @"YES" : @"NO" );
        //        SCDLog(@"Change dictionary: %@", change);
        if (!isAdjustingFocus) {
            alphaTimes = -1;
        }
    }
}

- (void)showFocusInPoint:(CGPoint)touchPoint {
    
    [UIView animateWithDuration:0.1f delay:0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
        
        int alphaNum = (alphaTimes % 2 == 0 ? HIGH_ALPHA : LOW_ALPHA);
        self.focusImageView.alpha = alphaNum;
        alphaTimes++;
        
    } completion:^(BOOL finished) {
        
        if (alphaTimes != -1) {
            [self showFocusInPoint:currTouchPoint];
        } else {
            self.focusImageView.alpha = 0.0f;
        }
    }];
}
#else
- (void)showFocusInPoint:(CGPoint)touchPoint {
    //对焦框
    [_focusImageView setCenter:touchPoint];
    _focusImageView.transform = CGAffineTransformMakeScale(2.0, 2.0);

    [UIView animateWithDuration:0.3f delay:0.f options:UIViewAnimationOptionAllowUserInteraction animations:^{
        _focusImageView.alpha = 1.f;
        _focusImageView.transform = CGAffineTransformMakeScale(1.0, 1.0);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.5f delay:0.5f options:UIViewAnimationOptionAllowUserInteraction animations:^{
            _focusImageView.alpha = 0.f;
        } completion:nil];
    }];
}

#endif

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    //    [super touchesBegan:touches withEvent:event];
    if (self.helperImgV.alpha == 1) {
        [UIView animateWithDuration:0.3 animations:^{
            self.helperImgV.alpha = 0;
        }];
        
        [super touchesBegan:touches withEvent:event];
        return;
    }
    
    
    alphaTimes = -1;
    
    UITouch *touch = [touches anyObject];
    // 如果点中闪光灯按钮
    CGPoint touchPoint = [touch locationInView:self.flashButton];
    if (CGRectContainsPoint(self.flashButton.bounds, touchPoint)) {
        [super touchesBegan:touches withEvent:event];
        return;
    }
    
    // 如果点中帮助按钮
    touchPoint = [touch locationInView:self.helpButton];
    if (CGRectContainsPoint(self.helpButton.bounds, touchPoint)) {
        [super touchesBegan:touches withEvent:event];
        return;
    }
    
    // 如果点中底部菜单区域
    touchPoint = [touch locationInView:self.bottomContainerView];
    if (CGRectContainsPoint(self.bottomContainerView.bounds, touchPoint)) {
        [super touchesBegan:touches withEvent:event];
        return;
    }
    
    currTouchPoint = [touch locationInView:self.view];
    
    if (CGRectContainsPoint(_captureManager.previewLayer.bounds, currTouchPoint) == NO) {
        return;
    }
    
    [_captureManager focusInPoint:currTouchPoint];
    
    
#if SWITCH_SHOW_FOCUSVIEW_UNTIL_FOCUS_DONE
    //对焦框
    [_focusImageView setCenter:currTouchPoint];
    _focusImageView.transform = CGAffineTransformMakeScale(2.0, 2.0);

    [UIView animateWithDuration:0.1f animations:^{
        _focusImageView.alpha = HIGH_ALPHA;
        _focusImageView.transform = CGAffineTransformMakeScale(1.0, 1.0);
    } completion:^(BOOL finished) {
        [self showFocusInPoint:currTouchPoint];
    }];
#else
    [self showFocusInPoint:currTouchPoint];
#endif

}


#pragma mark MDEditPhotoViewControllerDelegate
- (void)willRepickPhoto
{
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
}

- (void)didSelectPhoto:(UIImage *)image
{
    WEAKSELF_SC
    
    SCNavigationController *nav = (SCNavigationController*)weakSelf_SC.navigationController;
    if (nav.scNaigationDelegate && [nav.scNaigationDelegate respondsToSelector:@selector(didEndEditPhoto:)]) {
        [nav.scNaigationDelegate didEndEditPhoto:image];
    }
    
    UIViewController *viewC = self;
    if (self.isProMode) {
        while (viewC.presentingViewController) {
            viewC = viewC.presentingViewController;
        }
    }
    
    [viewC dismissViewControllerAnimated:YES completion:^{
        
    }];
}


#pragma mark SCCaptureSessionManager delegate
- (void)didCapturePhoto:(UIImage*)stillImage
{
    if (!stillImage) {
        ShowAlertView(@"提示", @"获取照片异常，请重新拍摄", @"确定", nil);
        return;
    }
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [SCCommon saveImageToPhotoAlbum:stillImage];//存至本机
    });
    
    
    //    WEAKSELF_SC
    //    double delayInSeconds = .3f;
    //    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    //    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
    //        MDEditPhotoViewController *editViewController = [[MDEditPhotoViewController alloc] initWithNibName:@"MDEditPhotoViewController" bundle:nil];
    //        [editViewController setImage:stillImage];
    //        editViewController.delegate = self;
    //
    //        editViewController.transitioningDelegate = self;
    //
    //        [self presentViewController:editViewController animated:YES completion:NULL];
    //    });
}

- (void)sessionManagerError:(SCCaptureSessionManager *)sessionManager
{
    [self dismissBtnPressed:nil];
}

- (void)didStartTakingPicture:(SCCaptureSessionManager *)sessionMgr
{
    //    [self switchShakeCover:YES];
}

- (void)didCometoSteadyForTakingPicture:(SCCaptureSessionManager *)sessionMgr
{
    //    [self switchShakeCover:NO];
    [self showCentralInfoArea:@"" autoDisappear:NO];
    
//    // 展示闪光效果
//    [self flashScreen];
}

- (void)didGotPhotoData:(SCCaptureSessionManager *)sessionMgr
{
    
}

- (void)didDetectShake:(SCCaptureSessionManager *)sessionMgr
{
    //    [self switchShakeCover:YES];
    [self showCentralInfoArea:@"请勿抖动相机" autoDisappear:NO];
}

- (void)didDetectSteady:(SCCaptureSessionManager *)sessionMgr
{
    //    [self switchShakeCover:NO];
    [self showCentralInfoArea:@"" autoDisappear:NO];
}

- (void)didAutoFocusStarted:(SCCaptureSessionManager *)sessionMgr {
    MDLog(@"didAutoFocusStarted");

    CGPoint previewCenter = CGPointMake(SCREEN_WIDTH / 2, (SCREEN_HEIGHT - self.bottomContainerView.size.height) / 2);
    
    [self showFocusInPoint:previewCenter];
}

- (void)didAutoFocusSucceed:(SCCaptureSessionManager *)sessionMgr {
    MDLog(@"didAutoFocusSucceed");
}






#pragma mark -------------button actions---------------
//拍照页面，拍照按钮
- (void)takePictureBtnPressed:(UIButton*)sender {
#if SWITCH_SHOW_DEFAULT_IMAGE_FOR_NONE_CAMERA
    if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        [SVProgressHUD showStatus:@"设备不支持拍照功能T_T"];
        return;
    }
#endif
    
//    [MobClick event:EVENT_SUB_CAM_OK];
    [TalkingData trackEvent:EVENT_SUB_CAM_OK];

//    [self switchActivityView:YES];
    sender.userInteractionEnabled = NO;
    
    [_captureManager takePicture:^(UIImage *stillImage) {
        sender.userInteractionEnabled = YES;
        
        if (!stillImage) {
            ShowAlertView(@"提示", @"获取照片异常，请重新拍摄", @"确定", nil);
            return;
        }
        
        [_captureManager closeFlashIfPossible:_flashButton];
        
        // 如果是拍题模式：
        if (self.isProMode) {            
            MDEditPhotoViewController *editViewController = [[MDEditPhotoViewController alloc] initWithNibName:@"MDEditPhotoViewController" bundle:XXBFRAMEWORK_BUNDLE];
            MDLog(@"editVC setImage:%@", NSStringFromCGSize(stillImage.size));
            
            [editViewController setImage:stillImage];
            editViewController.delegate = self;
            
//            editViewController.transitioningDelegate = (id<UIViewControllerTransitioningDelegate>)self;
            
            [self presentViewController:editViewController animated:YES completion:NULL];
        }
        // 如果是逛逛发帖模式
        else {
            [self didSelectPhoto:stillImage];
        }
        
        
        //or your code 1
        //        [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationTakePicture object:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:stillImage, kImage, nil]];
        
        //or your code 2
        //    PostViewController *con = [[PostViewController alloc] init];
        //    con.postImage = stillImage;
        //    [self.navigationController pushViewController:con animated:YES];
    }];
}

- (void)switchActivityView:(BOOL)show
{
    if (show) {
        [self.cameraBtnLoadingImgV startAnimating];

        [UIView animateWithDuration:0.15 animations:^{
            self.cameraButton.alpha = 0.0f;
            self.cameraBtnLoadingImgV.alpha = 1;
        } completion:^(BOOL finished) {

        }];
    }
    else {
        self.cameraBtnLoadingImgV.alpha = 0;;
        [self.cameraBtnLoadingImgV stopAnimating];
        
        [UIView animateWithDuration:0.15 animations:^{
            self.cameraButton.alpha = 1.0f;
        }];
    }
}

- (void)tmpBtnPressed:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

//拍照页面，"X"按钮
- (void)dismissBtnPressed:(id)sender {
//    [MobClick event:EVENT_SUB_CAM_CANCEL];
    [TalkingData trackEvent:EVENT_SUB_CAM_CANCEL];

    if (self.navigationController) {
        if (self.navigationController.viewControllers.count == 1) {
            [self.navigationController dismissViewControllerAnimated:YES completion:^{
//                [self.captureManager stopCamera];
            }];
        } else {
            [self.navigationController popViewControllerAnimated:YES];
        }
    } else {
        [self dismissViewControllerAnimated:YES completion:^{
//            [self.captureManager stopCamera];
        }];
    }
}


//拍照页面，相册按钮
- (void)albumBtnPressed:(UIButton *)sender {
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
    
    imagePicker.navigationBar.tintColor = [UIColor whiteColor];
    
    imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    //    [imagePicker setSourceType:UIImagePickerControllerSourceTypeSavedPhotosAlbum];
    
    [imagePicker setDelegate:self];
    
    // PathViewController被放到Container中之后，不能直接使用pathVC来present
    [self presentViewController:imagePicker animated:YES completion:^{
        
    }];
}

#pragma mark UIImagePickerControllerDelegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    if (!info || [info count] <= 0)
        return;
    
    NSLog(@"didFinishPickingMediaWithInfo:%@", info);
    
    // test 1387427103  1387427380
    UIImage *image = [[info objectForKey:UIImagePickerControllerOriginalImage] adjustOrientation];
    
//    [MobClick event:EVENT_SUB_CAM_SELPHOTO];
    [TalkingData trackEvent:EVENT_SUB_CAM_SELPHOTO];

    [self dismissViewControllerAnimated:YES completion:^{
        if (self.isProMode) {
            MDEditPhotoViewController *editViewController = [[MDEditPhotoViewController alloc] initWithNibName:@"MDEditPhotoViewController" bundle:nil];
            [editViewController setImage:image];
            editViewController.delegate = self;
            
//            editViewController.transitioningDelegate = (id<UIViewControllerTransitioningDelegate>)self;
            
            [self presentViewController:editViewController animated:YES completion:NULL];
        }
        // 如果是逛逛发帖模式
        else {
            [self didSelectPhoto:image];
        }
    }];
    
    //    WEAKSELF_SC
    //    //your code 0
    //    [self dismissViewControllerAnimated:YES completion:^{
    //        SCNavigationController *nav = (SCNavigationController*)weakSelf_SC.navigationController;
    //        if ([nav.scNaigationDelegate respondsToSelector:@selector(didCapturePhoto:image:)]) {
    //            [nav.scNaigationDelegate didCapturePhoto:nav image:image];
    //        }
    //    }];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
}


//拍照页面，网格按钮
- (void)gridBtnPressed:(UIButton*)sender {
    sender.selected = !sender.selected;
    [_captureManager switchAlphaCover:sender.selected];
}

//拍照页面，切换前后摄像头按钮按钮
- (void)switchCameraBtnPressed:(UIButton*)sender {
    sender.selected = !sender.selected;
    [_captureManager switchCamera:sender.selected];
}

//拍照页面，闪光灯按钮
- (void)flashBtnPressed:(UIButton*)sender {
    [_captureManager switchFlashMode:sender];
}

// 拍照攻略按钮
- (void)helpBtnPressed:(UIButton *)sender {
    MDLog(@"helpBtnPressed");
    
    [UIView animateWithDuration:0.3 animations:^{
        self.helperImgV.alpha = 1;
    }];
}

#pragma mark -------------pinch camera---------------
//伸缩镜头
- (void)handlePinch:(UIPinchGestureRecognizer*)gesture {
    [_captureManager pinchCameraView:gesture];
    
    if (_scSlider) {
        if (_scSlider.alpha != 1.f) {
            [UIView animateWithDuration:0.3f animations:^{
                _scSlider.alpha = 1.f;
            }];
        }
        [_scSlider setValue:_captureManager.scaleNum shouldCallBack:NO];
        
        if (gesture.state == UIGestureRecognizerStateEnded || gesture.state == UIGestureRecognizerStateCancelled) {
            [self setSliderAlpha:YES];
        } else {
            [self setSliderAlpha:NO];
        }
    }
}


//#pragma mark -------------save image to local---------------
////保存照片至本机
//- (void)saveImageToPhotoAlbum:(UIImage*)image {
//    UIImageWriteToSavedPhotosAlbum(image, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
//}
//
//- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
//    if (error != NULL) {
//        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"出错了!" message:@"存不了T_T" delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
//        [alert show];
//    } else {
//        SCDLog(@"保存成功");
//    }
//}

#pragma mark ------------notification-------------
- (void)orientationDidChange:(NSNotification*)noti
{
    //    [_captureManager.previewLayer.connection setVideoOrientation:(AVCaptureVideoOrientation)[UIDevice currentDevice].orientation];
    
    if (!_cameraBtnSet || _cameraBtnSet.count <= 0) {
        return;
    }
    
    __block CGAffineTransform transform = CGAffineTransformMakeRotation(0);
    transform = CGAffineTransformMakeRotation(M_PI_2);
    
    [_cameraBtnSet enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
        UIButton *btn = ([obj isKindOfClass:[UIButton class]] ? (UIButton*)obj : nil);
        if (!btn) {
            *stop = YES;
            return ;
        }
        
        btn.layer.anchorPoint = CGPointMake(0.5, 0.5);
        
        [UIView animateWithDuration:0.3f animations:^{
            btn.transform = transform;
        }];
    }];
    
    [UIView animateWithDuration:0.3f animations:^{
        self.cameraButton.transform = transform;
        self.operLb.transform = transform;
    }];
    
    self.shakeCoverImageView.transform = transform;
}

#pragma mark ---------rotate(only when this controller is presented, the code below effect)-------------
//<iOS6
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    //    [[NSNotificationCenter defaultCenter] postNotificationName:UIDeviceOrientationDidChangeNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationOrientationChange object:nil];
    
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_6_0
//iOS6+
- (BOOL)shouldAutorotate
{
    //    [[NSNotificationCenter defaultCenter] postNotificationName:UIDeviceOrientationDidChangeNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationOrientationChange object:nil];
    
    return NO;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
    
    //    return UIInterfaceOrientationMaskAll;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    return UIInterfaceOrientationPortrait;
    
    //    return [UIApplication sharedApplication].statusBarOrientation;
}
#endif

@end




