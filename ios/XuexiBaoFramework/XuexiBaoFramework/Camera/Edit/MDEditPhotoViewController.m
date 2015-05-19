//
//  MDEditPhotoViewController.m
//  education
//
//  Created by Tim on 14-5-8.
//  Copyright (c) 2014年 mudi. All rights reserved.
//

#import "MDEditPhotoViewController.h"
#import "UIView+Frame.h"
#import "UIImage+Utility.h"
#import "CLClippingTool.h"
#import <AVFoundation/AVFoundation.h>
#import "MDEditPhotoView.h"

#import "MDCameraCoverView.h"
#import "SCDefines.h"





#pragma mark MDEditPhotoViewController
@interface MDEditPhotoViewController ()

{
    UIImage *_oriImage;
    UIImage *_displayImage;
    
    // 旋转参数
    CGFloat rotateDegree;
    CATransform3D _initialTransform;

    CLClippingTool *_clippingTool;
    
    NSInteger statusBarOrientation;
    
//    CGRect rotatedCaptureImageViewFrame;
}

@property (strong, nonatomic) IBOutlet MDEditPhotoView *rootView;

@property (nonatomic, strong) UILabel *remindLabel;

@property (strong, nonatomic) IBOutlet UIButton *repickBtn;
@property (strong, nonatomic) IBOutlet UIButton *confirmBtn;
@property (strong, nonatomic) IBOutlet UIButton *cancelBtn;

@property (nonatomic,strong) UIPanGestureRecognizer *panRecognizer;
@property (nonatomic,strong) UIPinchGestureRecognizer *pinchRecognizer;
@property (nonatomic,strong) UITapGestureRecognizer *tapRecognizer;
@property (nonatomic, assign) NSUInteger gestureCount;
@property (nonatomic, assign) CGPoint touchCenter, rotationCenter, scaleCenter;
@property (nonatomic, assign) CGFloat scale;
@property (nonatomic, assign) CGRect initialImageFrame;
@property (nonatomic, assign) CGAffineTransform validTransform;

@property (nonatomic, assign) BOOL panEnabled, scaleEnabled, tapToResetEnabled;
/**
 *  The uotuput width, minimum and maximum scale
 */
@property (nonatomic, assign) CGFloat outputWidth, minimumScale, maximumScale;

@end



@implementation MDEditPhotoViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (id)initWithImage:(UIImage *)image
{
    self = [self init];
    if (self){
        _oriImage = [image deepCopy];
    }
    return self;
}

- (void)setImage:(UIImage *)image
{
    _oriImage = image;

    MDLog(@"mdEditPhotoVC set image:%@", NSStringFromCGSize(image.size));
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
//    _displayImage = [UIImage imageWithData:UIImageJPEGRepresentation(_oriImage, 0.6)];
    
    self.title = @"Edit";
    
    if([self respondsToSelector:@selector(automaticallyAdjustsScrollViewInsets)]){
        self.automaticallyAdjustsScrollViewInsets = NO;
    }
    
    if([self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]){
        self.navigationController.interactivePopGestureRecognizer.enabled = NO;
    }
    
    rotateDegree = 0;
    _initialTransform = self.captureImageView.layer.transform;
    
//    self.rootView.scrollView = self.scrollView;
    
    self.view.userInteractionEnabled = YES;
    [self enableGestures:YES];
    
    [self initCropFrame];

    [self refreshImageView];

    [self initDisplayCover];
    [self initRemindLabel];
    [self initFunctionButtons];
//    [self initSubjectsView];
    
    [self makeInitTransform];
    
    statusBarOrientation = [UIApplication sharedApplication].statusBarOrientation;
}

- (void)viewWillAppear:(BOOL)animated
{
    [self reset:NO];
    
    [super viewWillAppear:animated];
//    [MobClick beginLogPageView:NSStringFromClass([MDEditPhotoViewController class])];
    [TalkingData trackPageBegin:NSStringFromClass([MDEditPhotoViewController class])];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];

}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
//    [MobClick endLogPageView:NSStringFromClass([MDEditPhotoViewController class])];
    [TalkingData trackPageEnd:NSStringFromClass([MDEditPhotoViewController class])];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    [UIApplication sharedApplication].statusBarOrientation = statusBarOrientation;
}


- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (UIStatusBarAnimation )preferredStatusBarUpdateAnimation
{
    return UIStatusBarAnimationSlide;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Properties
- (void) setCropRect:(CGRect)cropRect
{
    [self.captureImageView setCropRect:cropRect];
}

- (CGRect) cropRect
{
    return RECT_CROPFRAME;
    
    if( self.captureImageView.cropRect.size.width == 0 || self.captureImageView.cropRect.size.height == 0 )
        [self.captureImageView setCropRect:(CGRect){ ( CGRectGetWidth(self.captureImageView.bounds) - kDefaultCropWidth ) * .5,
            ( CGRectGetHeight(self.captureImageView.bounds) - kDefaultCropHeight ) * .5,
            kDefaultCropWidth, kDefaultCropHeight }];
    
    return self.captureImageView.cropRect;
}

- (CGRect)imageViewRect
{
    return self.captureImageView.frame;
}


- (void) setSourceImage:(UIImage *)sourceImage
{
    if( sourceImage != _sourceImage) {
        _sourceImage = sourceImage;
    }
}

- (void) enableGestures:(BOOL)enable
{
    [self setTapToResetEnabled:enable];
    [self setPanEnabled:enable];
    [self setScaleEnabled:enable];
}


#pragma mark - Initialization
- (void)initCropFrame
{
    _captureImageView = [[MDCropImageView alloc] initWithFrame:RECT_CROPFRAME];
    _captureImageView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.8];
    _captureImageView.contentMode = UIViewContentModeScaleAspectFill;
    _captureImageView.userInteractionEnabled = YES;
    
    [self.view addSubview:_captureImageView];
    [self.view sendSubviewToBack:_captureImageView];

    
    UIPanGestureRecognizer *panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    [panRecognizer setCancelsTouchesInView:NO];
    [panRecognizer setDelegate:self];
    [panRecognizer setEnabled:self.panEnabled];
    [self.view addGestureRecognizer:panRecognizer];
    
    [self setPanRecognizer:panRecognizer];

    
    UIPinchGestureRecognizer *pinchRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinch:)];
    [pinchRecognizer setCancelsTouchesInView:NO];
    [pinchRecognizer setDelegate:self];
    [pinchRecognizer setEnabled:self.scaleEnabled];
    [self.view addGestureRecognizer:pinchRecognizer];

    [self setPinchRecognizer:pinchRecognizer];
    
    
//    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
//    [tapRecognizer setNumberOfTapsRequired:2];
//    [tapRecognizer setEnabled:self.tapToResetEnabled];
//    [self.view addGestureRecognizer:tapRecognizer];

//    [self setTapRecognizer:tapRecognizer];
}

- (void)initDisplayCover
{
    MDCameraCoverView *coverView = [XXBFRAMEWORK_BUNDLE loadNibNamed:@"CameraCover" owner:self options:nil].firstObject;
    [coverView switchCoverAlpha:0.8 andColor:[UIColor blackColor]];
    coverView.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT - 60);
    self.view.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
    [self.view addSubview:coverView];
    return;

//    UIView *coverView = [[NSBundle mainBundle] loadNibNamed:@"CameraCover" owner:self options:nil].firstObject;
//    CGRect coverFrame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT - 60);
//    coverView.frame = coverFrame;
//
//    [self.view addSubview:coverView];
}

- (void)initRemindLabel
{
    UILabel *remindLabel = [[UILabel alloc] initWithFrame:CGRectMake(-125, (SCREEN_HEIGHT - 60) / 2, 280, 25)];
    remindLabel.backgroundColor = [UIColor clearColor];
    remindLabel.textColor = [UIColor whiteColor];
    remindLabel.font = [UIFont boldSystemFontOfSize:17];
    remindLabel.textAlignment = NSTextAlignmentCenter;
    remindLabel.text = @"只能识别一道题，请调整好范围"; //NSLocalizedString(@"editphoto_remind_text", @"");
    self.remindLabel = remindLabel;

    [self.view addSubview:remindLabel];
}

- (void)initFunctionButtons
{
//    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
//    btn.frame = CGRectMake(SCREEN_WIDTH / 2 - 25, -7, 50, 57);
//    btn.backgroundColor = [UIColor clearColor];
//    [btn setImage:[UIImage imageNamed:@"left_rotating_nor"] forState:UIControlStateNormal];
//    [btn setImage:[UIImage imageNamed:@"left_rotating_pre"] forState:UIControlStateHighlighted];
//    //[btn setImage:[UIImage imageNamed:@"left_rotating"] forState:UIControlStateSelected];
//    [btn addTarget:self action:@selector(rotateLeft90BtnClick:) forControlEvents:UIControlEventTouchUpInside];
//
//    self.rotateButton = btn;
//    
//    [self.view addSubview:btn];
}

//- (void)initSubjectsView
//{
//    NSArray *views = [[NSBundle mainBundle] loadNibNamed:@"SelectSubjectView" owner:self options:nil];
//    MDSubjectSelectView *selectView = views.firstObject;
//    CGRect viewFrame = selectView.frame;
//    viewFrame.origin.x = -195;
//    viewFrame.origin.y = viewFrame.size.width / 2 - 10;
//    selectView.frame = viewFrame;
//    self.subSelectView = selectView;
//    
//    [self.view addSubview:selectView];
//    
//    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC);
//    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
//        [self.subSelectView showSubjects:YES];
//    });
//}

- (void)makeInitTransform
{
    CGAffineTransform transform = CGAffineTransformMakeRotation(M_PI_2);

    self.remindLabel.transform = transform;
//    self.rotateButton.transform = transform;
    self.repickBtn.transform = transform;
    self.confirmBtn.transform = transform;
    self.cancelBtn.transform = transform;
    
//    self.captureImageView.transform = transform;
//    self.validTransform = transform;
}

#pragma mark -
#pragma mark - Gestures
- (void) handleTouches:(NSSet*)touches
{
    self.touchCenter = CGPointZero;
    if ( touches.count < 2 ) return;
    
    [touches enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
        UITouch *touch = (UITouch*)obj;
        CGPoint touchLocation = [touch locationInView:self.captureImageView];
        self.touchCenter = (CGPoint){ self.touchCenter.x + touchLocation.x, self.touchCenter.y +touchLocation.y };
    }];
    self.touchCenter = (CGPoint){ self.touchCenter.x / touches.count, self.touchCenter.y / touches.count };
}

-(void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
//    MDLog(@"touchesBegan: %@ event: %@", touches, event);

    [self handleTouches:[event allTouches]];
}

- (void) touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
//    MDLog(@"touchesMoved: %@ event: %@", touches, event);

    [self handleTouches:[event allTouches]];
}

- (void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
//    MDLog(@"touchesEnded: %@ event: %@", touches, event);

    [self handleTouches:[event allTouches]];
}

- (void) touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
//    MDLog(@"touchesCancelled: %@ event: %@", touches, event);

    [self handleTouches:[event allTouches]];
}


- (CGFloat) boundedScale:(CGFloat)scale;
{
    CGFloat boundedScale = scale;
    if ( self.minimumScale > 0 && scale < self.minimumScale )
        boundedScale = self.minimumScale;
    else if ( self.maximumScale > 0 && scale > self.maximumScale )
        boundedScale = self.maximumScale;
    return boundedScale;
}

- (BOOL) handleGestureState:(UIGestureRecognizerState)state
{
    BOOL handle = YES;
//    MDLog(@"handleGestureState: %li", state);
    
    switch (state) {
        case UIGestureRecognizerStateBegan:
            self.gestureCount++;
            break;
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateEnded: {
            self.gestureCount--;
            handle = NO;
            MDLog(@"gestureCount: %lu", (unsigned long)self.gestureCount);
            
            if( self.gestureCount == 0 ) {
                CGFloat scale = [self boundedScale:self.scale];
                if( scale != self.scale ) {
                    CGFloat deltaX = self.scaleCenter.x - self.captureImageView.bounds.size.width * .5;
                    CGFloat deltaY = self.scaleCenter.y - self.captureImageView.bounds.size.height * .5;
                    
                    CGAffineTransform transform =  CGAffineTransformTranslate(self.captureImageView.transform, deltaX, deltaY);
                    transform = CGAffineTransformScale(transform, scale/self.scale , scale/self.scale);
                    transform = CGAffineTransformTranslate(transform, -deltaX, -deltaY);
                    [self checkBoundsWithTransform:transform];
                    self.view.userInteractionEnabled = NO;
                    [UIView animateWithDuration:kAnimationIntervalTransform delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                        self.captureImageView.transform = self.validTransform;
                    } completion:^(BOOL finished) {
                        self.view.userInteractionEnabled = YES;
                        self.scale = scale;
                    }];
                    
                } else {
//                    [self adjustCaptureImageViewFrame];
                    
                    self.view.userInteractionEnabled = NO;
                    MDLog(@"handleGestureState end before assign:%@", NSStringFromCGRect(self.captureImageView.frame));
                    
                    [UIView animateWithDuration:kAnimationIntervalTransform delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                        MDLog(@"handleGestureState end capTran:%@ validTran:%@", NSStringFromCGAffineTransform(self.captureImageView.transform), NSStringFromCGAffineTransform(self.validTransform));
                        
                        self.captureImageView.transform = self.validTransform;
                        
                        MDLog(@"handleGestureState end after assign block:%@", NSStringFromCGRect(self.captureImageView.frame));
                    } completion:^(BOOL finished) {
                        self.view.userInteractionEnabled = YES;
                    }];
                    
                    self.captureImageView.transform = self.validTransform;
                }
            }
        } break;
        default:
            break;
    }
    return handle;
}


- (void) checkBoundsWithTransform:(CGAffineTransform)transform
{
    if (CGRectContainsRect(self.captureImageView.frame, RECT_CROPFRAME)) {
        self.validTransform = transform;
    }
//    else {
//        // 保证长边完整显示
//        CGRect imgvFrame = self.captureImageView.frame;
//
//        // 如果横向是长边：
//        if (self.captureImageView.size.width >= RECT_CROPFRAME.size.width) {
//            // 横向必须包含CropRect
//            if (imgvFrame.origin.x <= RECT_CROPFRAME.origin.x && (imgvFrame.origin.x + imgvFrame.size.width) >= (RECT_CROPFRAME.origin.x + RECT_CROPFRAME.size.width)) {
//                // 纵向必须不能超过选择区域
//                if (imgvFrame.origin.y >= RECT_CROPFRAME.origin.y && (imgvFrame.origin.y + imgvFrame.size.height) <= (RECT_CROPFRAME.origin.y + RECT_CROPFRAME.size.height)) {
//                    self.validTransform = transform;
//                }
//            }
//        }
//        // 纵向是长边：
//        else if (self.captureImageView.size.height >= RECT_CROPFRAME.size.height) {
//            // 纵向必须包含CropRect
//            if (imgvFrame.origin.y <= RECT_CROPFRAME.origin.y && (imgvFrame.origin.y + imgvFrame.size.height) >= (RECT_CROPFRAME.origin.y + RECT_CROPFRAME.size.height)) {
//                // 横向必须不能超过选择区域
//                self.validTransform = transform;
//            }
//        }
//    }
    
    return;

    
    CGRect r1 = RECT_CROPFRAME; //[self boundingBoxForRect:self.cropRect rotatedByRadians:[self imageRotation]];
    
    Rectangle r2 = [self applyTransform:transform toRect:self.initialImageFrame];
    
    CGAffineTransform t = CGAffineTransformMakeTranslation(CGRectGetMidX(self.cropRect), CGRectGetMidY(self.cropRect));
    t = CGAffineTransformRotate(t, -[self imageRotation]);
    t = CGAffineTransformTranslate(t, -CGRectGetMidX(self.cropRect), -CGRectGetMidY(self.cropRect));
    
    Rectangle r3 = [self applyTransform:t toRectangle:r2];
    
    CGRect rectR3 = [self CGRectFromRectangle:r3];
    MDLog(@"\ncheckBoundsWithTransform:\nfirRect:%@\ncropRect:%@\ntransform:%@", NSStringFromCGRect(rectR3), NSStringFromCGRect(r1), NSStringFromCGAffineTransform(transform));
    
    if( CGRectContainsRect( rectR3, r1 ) ) {
        MDLog(@"first rect contains second rect");
        self.validTransform = transform;
    }
}

- (void) handlePan:(UIPanGestureRecognizer *)recognizer
{
    BOOL handle = [self handleGestureState:recognizer.state];
    
    CGPoint location = [recognizer locationInView:self.clipPanel];
    if (CGRectContainsPoint(self.clipPanel.clippingRect, location)) {
//        MDLog(@"location in ClipPanel: %@", NSStringFromCGRect(self.clipPanel.clippingRect));
        [self checkBoundsWithTransform:self.captureImageView.transform];
        
        return;
    }
    else {
        if(handle) {
//            MDLog(@"handlePan before: %@", NSStringFromCGRect(self.captureImageView.frame));

            CGPoint translation = [recognizer translationInView:self.captureImageView];
            CGAffineTransform transform = CGAffineTransformTranslate( self.captureImageView.transform, translation.x, translation.y);
            self.captureImageView.transform = transform;
            
//            MDLog(@"handlePan before: %@", NSStringFromCGRect(self.captureImageView.frame));

            [self checkBoundsWithTransform:transform];
            
            [recognizer setTranslation:(CGPoint){ 0, 0 } inView:self.captureImageView];
        }
    }
}

- (void) handleRotation:(UIRotationGestureRecognizer *)recognizer
{
    if ( [self handleGestureState:recognizer.state] ) {
        if ( recognizer.state == UIGestureRecognizerStateBegan )
            self.rotationCenter = self.touchCenter;
        
        CGFloat deltaX = self.rotationCenter.x - self.captureImageView.bounds.size.width * .5;
        CGFloat deltaY = self.rotationCenter.y - self.captureImageView.bounds.size.height * .5;
        
        CGAffineTransform transform =  CGAffineTransformTranslate( self.captureImageView.transform, deltaX, deltaY );
        transform = CGAffineTransformRotate(transform, recognizer.rotation);
        transform = CGAffineTransformTranslate(transform, -deltaX, -deltaY);
        self.captureImageView.transform = transform;
        [self checkBoundsWithTransform:transform];
        
        recognizer.rotation = 0;
    }
}

- (void) handlePinch:(UIPinchGestureRecognizer *)recognizer
{
    if([self handleGestureState:recognizer.state]) {
        if(recognizer.state == UIGestureRecognizerStateBegan){
            self.scaleCenter = self.touchCenter;
        }
        CGFloat deltaX = self.scaleCenter.x-self.captureImageView.bounds.size.width/2.0;
        CGFloat deltaY = self.scaleCenter.y-self.captureImageView.bounds.size.height/2.0;
        
        MDLog(@"handlePinch before: %@", NSStringFromCGRect(self.captureImageView.frame));
        
        CGAffineTransform transform =  CGAffineTransformTranslate(self.captureImageView.transform, deltaX, deltaY);
        transform = CGAffineTransformScale(transform, recognizer.scale, recognizer.scale);
        transform = CGAffineTransformTranslate(transform, -deltaX, -deltaY);
        self.scale *= recognizer.scale;
        self.captureImageView.transform = transform;
        
        MDLog(@"handlePinch after: %@", NSStringFromCGRect(self.captureImageView.frame));

        recognizer.scale = 1;
        
        [self checkBoundsWithTransform:transform];
    }
}

- (void) handleTap:(UITapGestureRecognizer *)recogniser
{
    MDLog(@"handleTap: %@", recogniser);
    
    [self reset:YES];
}

- (void)adjustCaptureImageViewFrame
{
    if (!self.captureImageView.image) {
        return;
    }
    
    MDLog(@"adjustCaptureImageViewFrame imgV transform:%@", NSStringFromCGAffineTransform(self.captureImageView.transform));
    
    CGRect imgVFrame = self.captureImageView.frame;
    MDLog(@"imgVFrame:%@", NSStringFromCGRect(imgVFrame));
    
    UIView *tmpView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.captureImageView.image.size.width, self.captureImageView.image.size.height)];
    tmpView.transform = self.captureImageView.transform;
    
    CGSize imageSize = tmpView.size; //self.captureImageView.image.size;
    imgVFrame.size = imageSize;
    

    MDLog(@"RECT_CROP: %@ imageSize: %@ adjFrame:%@",
          NSStringFromCGRect(RECT_CROPFRAME),
          NSStringFromCGSize(imageSize),
          NSStringFromCGRect(imgVFrame));
    
    CGFloat xDistance = RECT_CROPFRAME.size.width - imageSize.width;
    CGFloat yDistance = RECT_CROPFRAME.size.height - imageSize.height;
    
    CGFloat scale = 1;
    CGFloat xScale = RECT_CROPFRAME.size.width / imageSize.width;
    CGFloat yScale = RECT_CROPFRAME.size.height / imageSize.height;

    scale = MAX(xScale, yScale);
    
    CGFloat newWidth = imageSize.width * scale;
    CGFloat newHeight = imageSize.height * scale;
    [UIView animateWithDuration:0.3 animations:^{
        CGRect newFrame = CGRectMake(CGRectGetMidX(RECT_CROPFRAME) - (newWidth / 2),
                                     CGRectGetMidY(RECT_CROPFRAME) - (newHeight / 2),
                                     newWidth,
                                     newHeight);
        MDLog(@"newFrame: %@ scale: %f xDis: %f yDis: %f", NSStringFromCGRect(newFrame), scale, xDistance, yDistance);
        
        self.captureImageView.frame = newFrame;
    }];
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    return YES;
}

- (BOOL) gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    if ([gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]] && [otherGestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]]) {
        return NO;
    }
    
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldBeRequiredToFailByGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return NO;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRequireFailureOfGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return NO;
}


#pragma mark -
#pragma mark - Util
- (CGRect)boundingBoxForRect:(CGRect)rect rotatedByRadians:(CGFloat)angle
{
    CGAffineTransform t = CGAffineTransformMakeTranslation(CGRectGetMidX(rect), CGRectGetMidY(rect));
    t = CGAffineTransformRotate(t,angle);
    t = CGAffineTransformTranslate(t,-CGRectGetMidX(rect), -CGRectGetMidY(rect));
    return CGRectApplyAffineTransform(rect, t);
}

- (void) reset:(BOOL)animated
{
//    CGFloat sourceAspect = self.sourceImage.size.height / self.sourceImage.size.width;
//    CGFloat cropAspect = self.cropRect.size.height / self.cropRect.size.width;
    
//    CGFloat w = 0.0f;
//    CGFloat h = 0.0f;
//    if( sourceAspect > cropAspect ) {
//        w = CGRectGetWidth(self.cropRect);
//        h = sourceAspect * w;
//    } else {
//        h = CGRectGetHeight(self.cropRect);
//        w = h / sourceAspect;
//    }
    
    self.scale = 1;
    self.minimumScale = 1;
    
    self.initialImageFrame = RECT_CROPFRAME; //(CGRect){ CGRectGetMidX(self.cropRect) - w/2, CGRectGetMidY(self.cropRect) - h/2,w,h };
    self.validTransform = CGAffineTransformMakeScale(self.scale, self.scale);
    
    void (^doReset)(void) = ^{
        self.captureImageView.transform = CGAffineTransformIdentity;
        self.captureImageView.layer.transform = CATransform3DIdentity;
        self.captureImageView.frame = self.initialImageFrame;
        self.captureImageView.transform = self.validTransform;
        
        [self adjustCaptureImageViewFrame];
        
//        if (!self.captureImageView.image) {
//            self.minimumScale = 1;
//        }
//        else {
//            CGFloat xScale = RECT_CROPFRAME.size.width / self.captureImageView.width;
//            CGFloat yScale = RECT_CROPFRAME.size.height / self.captureImageView.height;
            
//            self.minimumScale = MIN(xScale, yScale);
//        }
    };
    
    if( animated ) {
        self.view.userInteractionEnabled = NO;
        [UIView animateWithDuration:kAnimationIntervalReset animations:doReset completion:^(BOOL finished) {
            self.view.userInteractionEnabled = YES;
        }];
    } else
        doReset();
}

- (CGFloat) imageRotation
{
    CGAffineTransform t = self.captureImageView.transform;
    return atan2f(t.b, t.a);
}

- (Rectangle) applyTransform:(CGAffineTransform)transform toRect:(CGRect)rect
{
    CGAffineTransform t = CGAffineTransformMakeTranslation(CGRectGetMidX(rect), CGRectGetMidY(rect));
    t = CGAffineTransformConcat(self.captureImageView.transform, t);
    t = CGAffineTransformTranslate(t,-CGRectGetMidX(rect), -CGRectGetMidY(rect));
    
    Rectangle r = [self RectangleFromCGRect:rect];
    return (Rectangle) {
        .tl = CGPointApplyAffineTransform(r.tl, t),
        .tr = CGPointApplyAffineTransform(r.tr, t),
        .br = CGPointApplyAffineTransform(r.br, t),
        .bl = CGPointApplyAffineTransform(r.bl, t)
    };
}

- (Rectangle) applyTransform:(CGAffineTransform)t toRectangle:(Rectangle)r
{
    return (Rectangle) {
        .tl = CGPointApplyAffineTransform(r.tl, t),
        .tr = CGPointApplyAffineTransform(r.tr, t),
        .br = CGPointApplyAffineTransform(r.br, t),
        .bl = CGPointApplyAffineTransform(r.bl, t)
    };
}

- (CGRect) CGRectFromRectangle:(Rectangle)rect
{
    return (CGRect) {
        .origin = rect.tl,
        .size = (CGSize){.width = rect.tr.x - rect.tl.x, .height = rect.bl.y - rect.tl.y}
    };
}

- (Rectangle) RectangleFromCGRect:(CGRect)rect
{
    return (Rectangle) {
        .tl = (CGPoint){rect.origin.x, rect.origin.y},
        .tr = (CGPoint){CGRectGetMaxX(rect), rect.origin.y},
        .br = (CGPoint){CGRectGetMaxX(rect), CGRectGetMaxY(rect)},
        .bl = (CGPoint){rect.origin.x, CGRectGetMaxY(rect)}
    };
}



- (void)refreshImageView
{
    dispatch_async(dispatch_get_main_queue(), ^{
        // V1.X
//        _imageView.image = _originalImage;
//        
//        [self resetScrollViewFrame];
//        
//        [self resetImageViewFrame];
//        [self resetZoomScaleWithAnimate:NO];

        // V2.0
        self.captureImageView.image = _displayImage ? _displayImage : _oriImage;
        self.captureImageView.clipsToBounds = NO;
        [self adjustCaptureImageViewFrame];

        CGRect captureFrame = self.captureImageView.frame;
        captureFrame.origin.x -= 10;
        captureFrame.origin.y -= 10;
        captureFrame.size.width += 20;
        captureFrame.size.height += 20;
        self.captureImageView.frame = captureFrame;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if(!_clippingTool)
                _clippingTool = [[CLClippingTool alloc] initWithImageEditor:self];
            [_clippingTool cleanup];
            [_clippingTool setup];
        });
    });
}

- (void)resetScrollViewFrame
{
//    CGRect scrollFrame = self.scrollView.frame;
//    NSLog(@"ScrollFrame: %@", NSStringFromCGRect(scrollFrame));
//    
//    scrollFrame.origin.x = 33;
//    scrollFrame.origin.y = 44;
//    scrollFrame.size.width = SCREEN_WIDTH - 60;
//    scrollFrame.size.height = SCREEN_HEIGHT - 44 - 60 - 25;
//    
//    self.scrollView.frame = scrollFrame;
}

- (void)resetImageViewFrame
{
//    dispatch_async(dispatch_get_main_queue(), ^{
//        CGRect rct = _imageView.frame;
//        rct.size = CGSizeMake(_scrollView.zoomScale*_imageView.image.size.width, _scrollView.zoomScale*_imageView.image.size.height);
////        _imageView.frame = rct;
//        _imageView.frame = AVMakeRectWithAspectRatioInsideRect(_imageView.image.size, _scrollView.bounds);
//        NSLog(@"ScrollViewFrame: %@", NSStringFromCGRect(_scrollView.frame));
//        NSLog(@"ImageViewFrame: %@", NSStringFromCGRect(_imageView.frame));
//    });
}

- (CATransform3D)rotateTransform:(CATransform3D)initialTransform
{
    CGFloat arg = rotateDegree * M_PI;
    
    CATransform3D transform = initialTransform;
    transform = CATransform3DRotate(transform, arg, 0, 0, 1);
    transform = CATransform3DRotate(transform, 0, 0, 1, 0);
    transform = CATransform3DRotate(transform, 0, 1, 0, 0);
    
    return transform;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void)resetZoomScaleWithAnimate:(BOOL)animated
{
//    dispatch_async(dispatch_get_main_queue(), ^{
//        CGFloat Rw = _scrollView.frame.size.width/_imageView.image.size.width;
//        CGFloat Rh = _scrollView.frame.size.height/_imageView.image.size.height;
//        CGFloat ratio = MIN(Rw, Rh);
//        
//        _scrollView.contentSize = _imageView.frame.size;
//        MDLog(@"scrFrame:%@ conSize:%@", NSStringFromCGRect(_scrollView.frame), NSStringFromCGSize(_scrollView.contentSize));
//        
//        _scrollView.minimumZoomScale = ratio;
//        _scrollView.maximumZoomScale = MAX(ratio/240, 1/ratio);
//        
//        [_scrollView setZoomScale:_scrollView.minimumZoomScale animated:animated];
//    });
}

- (IBAction)rotateLeft90BtnClick:(id)sender {
    [UIView animateWithDuration:kCLImageToolAnimationDuration
                     animations:^{
                         rotateDegree -= 0.5;
                         if (rotateDegree <= -1) {
                             rotateDegree = 1;
                         }

//                         self.imageView.layer.transform = [self rotateTransform:CATransform3DIdentity];
//                         self.scrollView.layer.transform = [self rotateTransform:CATransform3DIdentity];
                         MDLog(@"captureIV before rotate left: %@", NSStringFromCGRect(self.captureImageView.frame));
                         
                         CGFloat deltaX = - self.captureImageView.size.width * .5;
                         CGFloat deltaY = - self.captureImageView.size.height * .5;
                         
                         CGAffineTransform transform =  CGAffineTransformTranslate( self.captureImageView.transform, deltaX, deltaY );
                         transform = CGAffineTransformRotate(transform, -M_PI_2);
                         transform = CGAffineTransformTranslate(transform, -deltaX, -deltaY);
                         self.captureImageView.transform = transform;
                         
                         MDLog(@"captureIV after rotate left: %@", NSStringFromCGRect(self.captureImageView.frame));
                         
                         [self adjustCaptureImageViewFrame];
                         
                         [self checkBoundsWithTransform:transform];
                     }
                     completion:^(BOOL finished) {
                         dispatch_async(dispatch_get_main_queue(), ^{
                             [self refreshImageView];
                         });
                     }
     ];
}

- (IBAction)rotateRight90BtnClick:(id)sender {
    [UIView animateWithDuration:kCLImageToolAnimationDuration
                     animations:^{
                         rotateDegree += 0.5;
                         if (rotateDegree > 1) {
                             rotateDegree = -0.5;
                         }

//                         self.imageView.layer.transform = [self rotateTransform:CATransform3DIdentity];
//                         self.scrollView.layer.transform = [self rotateTransform:CATransform3DIdentity];
                         self.captureImageView.layer.transform = [self rotateTransform:CATransform3DIdentity];
                         self.validTransform = CGAffineTransformTranslate(self.captureImageView.transform, 0, 0);
                     }
                     completion:^(BOOL finished) {
                         dispatch_async(dispatch_get_main_queue(), ^{
                             [self refreshImageView];
                         });
                     }
     ];
}

- (IBAction)repickBtnClick:(id)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(willRepickPhoto)]) {
        [self.delegate willRepickPhoto];
    }
}

- (IBAction)confirmBtnClick:(id)sender {
//    [MobClick event:EVENT_SUB_EDIT_OK];
    [TalkingData trackEvent:EVENT_SUB_EDIT_OK];

    
    if (!self.captureImageView.image) {
        MDLog(@"EditPhoto capture image nil");
        return;
    }
    
    CGFloat scale = fmin(self.captureImageView.size.width,self.captureImageView.size.height) / fmin(self.captureImageView.image.size.width, self.captureImageView.image.size.height);
    CGPoint superViewTranslate = [self.view convertPoint:self.clipPanel.clippingRect.origin fromView:self.clipPanel];
    
    
    CGRect rct = self.clipPanel.clippingRect;
    
    CGRect captureFrame = self.captureImageView.frame;
    CGPoint clipOrigin = CGPointMake(superViewTranslate.x - captureFrame.origin.x, superViewTranslate.y - captureFrame.origin.y);
    rct.origin = clipOrigin;
    
    MDLog(@"capSuper:%@\nclipSuper:%@\ncontrollerView:%@",
          self.captureImageView.superview,
          self.clipPanel.superview,
          self.view);

    MDLog(@"ImgV Frame:%@ imageSize:%@",
          NSStringFromCGRect(self.captureImageView.frame),
          NSStringFromCGSize(self.captureImageView.image.size));
    MDLog(@"superViewTranslate:%@", NSStringFromCGPoint(superViewTranslate));

    
    MDLog(@"relativeClipRect:%@", NSStringFromCGRect(rct));
    rct.size.width /= scale;
    rct.size.height /= scale;
    rct.origin.x /= scale;
    rct.origin.y /= scale;
    MDLog(@"finalClipRect:%@", NSStringFromCGRect(rct));
    
    
    CGRect finalCropRct = [self computeRealCropRect:rct withinSize:self.captureImageView.image.size];
    MDLog(@"real Croprect: %@", NSStringFromCGRect(finalCropRct));
    
    UIImage *image = [_oriImage crop:finalCropRct]; //[self.captureImageView.image crop:rct];
    UIImage *finalImage = [self buildImage:image];
//    UIImage *finalImage = image;
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(didSelectPhoto:)]) {
        [self.delegate didSelectPhoto:finalImage];
    }

    return;
}

- (IBAction)cancelEditBtnClicked:(id)sender {
//    [MobClick event:EVENT_SUB_EDIT_CANCLE];
    [TalkingData trackEvent:EVENT_SUB_EDIT_CANCLE];
    
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
}

- (CGRect)computeRealCropRect:(CGRect)inputRect withinSize:(CGSize)size
{
    CGRect finalRect = inputRect;

    // 左转90度
    if (rotateDegree == -0.5) {
        finalRect = CGRectMake(size.width - inputRect.origin.y - inputRect.size.height,
                               inputRect.origin.x,
                               inputRect.size.height,
                               inputRect.size.width);
    }
    // 左转180度
    else if (rotateDegree == -1 || rotateDegree == 1) {
        finalRect = CGRectMake(size.width - inputRect.size.width - inputRect.origin.x,
                               size.height - inputRect.size.height - inputRect.origin.y,
                               inputRect.size.width,
                               inputRect.size.height);
    }
    // 左转270度
    else if (rotateDegree == 0.5) {
        finalRect = CGRectMake(inputRect.origin.y,
                               size.height - inputRect.origin.x - inputRect.size.width,
                               inputRect.size.height,
                               inputRect.size.width);
    }
    
    return finalRect;
}

- (UIImage*)buildImage:(UIImage*)image
{
    CIImage *ciImage = [[CIImage alloc] initWithImage:image];
    CIFilter *filter = [CIFilter filterWithName:@"CIAffineTransform" keysAndValues:kCIInputImageKey, ciImage, nil];
    
    NSLog(@"%@", [filter attributes]);
    
    [filter setDefaults];
    
    rotateDegree = -rotateDegree;
    rotateDegree += 0.5;
    if (rotateDegree > 1) {
        rotateDegree = -0.5;
    }

    CGAffineTransform transform = CATransform3DGetAffineTransform([self rotateTransform:CATransform3DIdentity]);
    [filter setValue:[NSValue valueWithBytes:&transform objCType:@encode(CGAffineTransform)] forKey:@"inputTransform"];
    
    CIContext *context = [CIContext contextWithOptions:nil];
    CIImage *outputImage = [filter outputImage];
    CGImageRef cgImage = [context createCGImage:outputImage fromRect:[outputImage extent]];
    
    UIImage *result = [UIImage imageWithCGImage:cgImage];
    
    CGImageRelease(cgImage);
    
    return result;
}

@end




