//
//  SVProgressHUD.m
//
//  Copyright 2011-2014 Sam Vermette. All rights reserved.
//
//  https://github.com/samvermette/SVProgressHUD
//

#if !__has_feature(objc_arc)
#error SVProgressHUD is ARC only. Either turn on ARC for the project or use -fobjc-arc flag
#endif

#import "SVProgressHUD.h"
#import "UIImageView+WebCache.h"
#import "UIImage+GIF.h"
#import "SVIndefiniteAnimatedView.h"
#import <QuartzCore/QuartzCore.h>

NSString * const SVProgressHUDDidReceiveTouchEventNotification = @"SVProgressHUDDidReceiveTouchEventNotification";
NSString * const SVProgressHUDDidTouchDownInsideNotification = @"SVProgressHUDDidTouchDownInsideNotification";
NSString * const SVProgressHUDWillDisappearNotification = @"SVProgressHUDWillDisappearNotification";
NSString * const SVProgressHUDDidDisappearNotification = @"SVProgressHUDDidDisappearNotification";
NSString * const SVProgressHUDWillAppearNotification = @"SVProgressHUDWillAppearNotification";
NSString * const SVProgressHUDDidAppearNotification = @"SVProgressHUDDidAppearNotification";

NSString * const SVProgressHUDStatusUserInfoKey = @"SVProgressHUDStatusUserInfoKey";

static UIColor *SVProgressHUDBackgroundColor;
static UIColor *SVProgressHUDForegroundColor;
static CGFloat SVProgressHUDRingThickness;
static UIFont *SVProgressHUDFont;
static UIImage *SVProgressHUDInfoImage;
static UIImage *SVProgressHUDSuccessImage;
static UIImage *SVProgressHUDErrorImage;
static UIImage *SVProgressHUDBusyingImage;

//----------自定义变量-------------
static UIImage *    SVProgressHUDOwnerSuccessImage;
static UIImage *    SVProgressHUDOwnerErrorImage;
static UIImage *    SVProgressHUDOwnerSuccessTipImage;
static UIImage *    SVProgressHUDOwnerErrorTipImage;
static UIImage *    SVProgressHUDOwnerLoadingTipImage;

//-------------------------------

static SVProgressHUDMaskType SVProgressHUDDefaultMaskType;
static UIView *SVProgressHUDExtensionView;

static const CGFloat SVProgressHUDRingRadius = 18;
static const CGFloat SVProgressHUDRingNoTextRadius = 24;
static const CGFloat SVProgressHUDParallaxDepthPoints = 10;
static const CGFloat SVProgressHUDUndefinedProgress = -1;

//自定义内容
//static const CGFloat HudWidth = 200;                //背景框宽度度
static const CGFloat HudHeight = 140;               //背景框高度
//static const CGFloat imageViewOffsetX = 35;         //提示图片左偏移
static const CGFloat imageViewOffsetY = 15;         //提示图片上偏移
static const CGFloat TipViewWidth = 75;             //背景框宽度度
static const CGFloat TipViewHeight = 90;            //背景框高度

@interface SVProgressHUD ()

@property (nonatomic, readwrite) SVProgressHUDMaskType maskType;
@property (nonatomic, strong, readonly) NSTimer *fadeOutTimer;
@property (nonatomic, readonly, getter = isClear) BOOL clear;

@property (nonatomic, strong) UIControl *overlayView;
@property (nonatomic, strong) UIView *hudView;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndiV;
@property (nonatomic, strong) UILabel *stringLabel;
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) SVIndefiniteAnimatedView *indefiniteAnimatedView;

@property (nonatomic, strong) UIButton      *   clickButton;

@property (nonatomic, readwrite) CGFloat progress;
@property (nonatomic, readwrite) NSUInteger activityCount;
@property (nonatomic, strong) CAShapeLayer *backgroundRingLayer;
@property (nonatomic, strong) CAShapeLayer *ringLayer;

@property (nonatomic, readonly) CGFloat visibleKeyboardHeight;
@property (nonatomic, assign) UIOffset offsetFromCenter;

@property (nonatomic, copy)   HudBlockHandler       blockHandler;

//扩展属性

//@property (nonatomic, assign) BOOL isOwnerDraw;
@property (nonatomic, strong) UIImageView *tipImageView;        //提示框中右侧图片


- (void)showProgress:(float)progress status:(NSString*)string maskType:(SVProgressHUDMaskType)hudMaskType isOwnerDraw:(BOOL)isOwnerDraw;
- (void)showImage:(UIImage*)image status:(NSString*)status duration:(NSTimeInterval)duration maskType:(SVProgressHUDMaskType)hudMaskType isOwnerDraw:(BOOL)isOwnerDraw;

- (void)dismiss;

- (void)setStatus:(NSString*)string;
- (void)registerNotifications;
- (NSDictionary *)notificationUserInfo;
- (void)moveToPoint:(CGPoint)newCenter rotateAngle:(CGFloat)angle;
- (void)positionHUD:(NSNotification*)notification;
- (NSTimeInterval)displayDurationForString:(NSString*)string;

@end


@implementation SVProgressHUD

+ (SVProgressHUD*)sharedView {
    static dispatch_once_t once;
    static SVProgressHUD *sharedView;
    dispatch_once(&once, ^ { sharedView = [[self alloc] initWithFrame:[[UIScreen mainScreen] bounds]]; });
    return sharedView;
}

#pragma mark - Setters

+ (void)setStatus:(NSString *)string {
	[[self sharedView] setStatus:string];
}

+ (void)setBackgroundColor:(UIColor *)color {
    [self sharedView].hudView.backgroundColor = color;
    SVProgressHUDBackgroundColor = color;
}

+ (void)setForegroundColor:(UIColor *)color {
    [self sharedView];
    SVProgressHUDForegroundColor = color;
}

+ (void)setFont:(UIFont *)font {
    [self sharedView];
    SVProgressHUDFont = font;
}

+ (void)setRingThickness:(CGFloat)width {
    [self sharedView];
    SVProgressHUDRingThickness = width;
}

+ (void)setInfoImage:(UIImage*)image{
    [self sharedView];
    SVProgressHUDInfoImage = image;
}

+ (void)setSuccessImage:(UIImage *)image {
    [self sharedView];
    SVProgressHUDSuccessImage = image;
}

+ (void)setErrorImage:(UIImage *)image {
    [self sharedView];
    SVProgressHUDErrorImage = image;
}

+ (void)setBusyingImage:(UIImage *)image {
    [self sharedView];
    SVProgressHUDBusyingImage = image;
}

+ (void)setDefaultMaskType:(SVProgressHUDMaskType)maskType{
    [self sharedView];
    SVProgressHUDDefaultMaskType = maskType;
}

+ (void)setViewForExtension:(UIView *)view{
    [self sharedView];
    SVProgressHUDExtensionView = view;
}


#pragma mark - Show Methods

+ (void)showStatus:(NSString*)status {
    [self sharedView];
    [self showImage:nil status:status maskType:SVProgressHUDDefaultMaskType isOwnerDraw:NO];
}

+ (void)showStatusWithBlockHandler:(NSString*)status blockHandler:(HudBlockHandler)blockHandler
{
    SVProgressHUD * instance = [self sharedView];
    [self showImage:nil status:status maskType:SVProgressHUDMaskTypeNone isOwnerDraw:NO];
    instance.blockHandler = blockHandler;
}

+ (void)show {
    [self showWithStatus:nil];
}

+ (void)showWithMaskType:(SVProgressHUDMaskType)maskType {
    [self showProgress:SVProgressHUDUndefinedProgress maskType:maskType];
}

+ (void)showWithStatus:(NSString *)status {
    [self showProgress:SVProgressHUDUndefinedProgress status:status isOwnerDraw:NO];
}

+ (void)showMDBusying
{
    [self showProgress:SVProgressHUDUndefinedProgress status:nil isOwnerDraw:YES];
}

+ (void)showMDBusying:(NSString*)message
{
    [self showProgress:SVProgressHUDUndefinedProgress status:message isOwnerDraw:YES];
}

+ (void)showMDBusyingWithTimeOut:(NSString*)message timeout:(float)timeout
{
    [self showProgress:SVProgressHUDUndefinedProgress status:message isOwnerDraw:YES];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(timeout * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self dismiss];
    });
}

+ (void)showMDBusyingWithStatus:(NSString*)status {
    [self showProgress:SVProgressHUDUndefinedProgress status:status isOwnerDraw:YES];
}

+ (void)showWithStatus:(NSString*)status maskType:(SVProgressHUDMaskType)maskType isOwnerDraw:(BOOL)isOwnerDraw{
    [self showProgress:SVProgressHUDUndefinedProgress status:status maskType:maskType isOwnerDraw:NO];
}

+ (void)showProgress:(float)progress {
    [self sharedView];
    [self showProgress:progress maskType:SVProgressHUDDefaultMaskType];
}

+ (void)showProgress:(float)progress status:(NSString*)status
{
    [self sharedView];
    [self showProgress:progress status:status maskType:SVProgressHUDDefaultMaskType isOwnerDraw:NO];
}

+ (void)showProgress:(float)progress maskType:(SVProgressHUDMaskType)maskType{
    [self showProgress:progress status:nil maskType:maskType isOwnerDraw:NO];
}

+ (void)showProgress:(float)progress status:(NSString *)status isOwnerDraw:(BOOL)isOwnerDraw{
    [self sharedView];
    [self showProgress:progress status:status maskType:SVProgressHUDDefaultMaskType isOwnerDraw:isOwnerDraw];
}

+ (void)showProgress:(float)progress status:(NSString *)status maskType:(SVProgressHUDMaskType)maskType isOwnerDraw:(BOOL)isOwnerDraw{
    [[self sharedView] showProgress:progress status:status maskType:maskType isOwnerDraw:isOwnerDraw];
}


#pragma mark - Show then dismiss methods

+ (void)showInfoWithStatus:(NSString *)string {
    [self sharedView];
    [self showInfoWithStatus:string maskType:SVProgressHUDDefaultMaskType isOwnerDraw:NO];
}

+ (void)showMDInfoWithStatus:(NSString *)string {
    [self sharedView];
    [self showInfoWithStatus:string maskType:SVProgressHUDDefaultMaskType isOwnerDraw:YES];
}

+ (void)showInfoWithStatus:(NSString *)string maskType:(SVProgressHUDMaskType)maskType  isOwnerDraw:(BOOL)isOwnerDraw{
    [self sharedView];
    [self showImage:SVProgressHUDInfoImage status:string maskType:maskType  isOwnerDraw:isOwnerDraw];
}

+ (void)showSuccessWithStatus:(NSString *)string {
    [self sharedView];
    [self showSuccessWithStatus:string maskType:SVProgressHUDDefaultMaskType isOwnerDraw:NO];
}

+ (void)showMDSuccessWithStatus:(NSString*)string{
    [self sharedView];
    [self showSuccessWithStatus:string maskType:SVProgressHUDDefaultMaskType isOwnerDraw:YES];
}

+ (void)showSuccessWithStatus:(NSString *)string maskType:(SVProgressHUDMaskType)maskType isOwnerDraw:(BOOL)isOwnerDraw {
    [self sharedView];
    UIImage * image = (isOwnerDraw ? SVProgressHUDOwnerSuccessImage :  SVProgressHUDSuccessImage);
    [self showImage:image status:string maskType:maskType isOwnerDraw:isOwnerDraw];
}

+ (void)showErrorWithStatus:(NSString *)string {
    [self sharedView];
    [self showErrorWithStatus:string maskType:SVProgressHUDDefaultMaskType isOwnerDraw:NO];
}

+ (void)showMDErrorWithStatus:(NSString *)string {
    if (!string || ! [string isKindOfClass:[NSString class]] ||
        string.length <= 0) {
        return;
    }
    
    [self sharedView];
    [self showErrorWithStatus:string maskType:SVProgressHUDDefaultMaskType isOwnerDraw:YES];
}

+ (void)showErrorWithStatus:(NSString *)string maskType:(SVProgressHUDMaskType)maskType  isOwnerDraw:(BOOL)isOwnerDraw{
    [self sharedView];
    UIImage * image = (isOwnerDraw ? SVProgressHUDOwnerErrorImage :  SVProgressHUDErrorImage);
    [self showImage:image status:string maskType:maskType isOwnerDraw:isOwnerDraw];
}

+ (void)showImage:(UIImage *)image status:(NSString *)string {
    [self sharedView];
    [self showImage:image status:string maskType:SVProgressHUDDefaultMaskType isOwnerDraw:NO];
}

+ (void)showImage:(UIImage *)image status:(NSString *)string maskType:(SVProgressHUDMaskType)maskType isOwnerDraw:(BOOL)isOwnerDraw{
    NSTimeInterval displayInterval = [[self sharedView] displayDurationForString:string];
    [[self sharedView] showImage:image status:string duration:displayInterval maskType:maskType isOwnerDraw:isOwnerDraw];
}

+ (void)showBusying
{
    [self showMDBusyingWithStatus:@"正在执行操作"];
}

+ (float)durationWithString:(NSString*)string
{
    NSTimeInterval displayInterval = [[self sharedView] displayDurationForString:string];
    return (float)displayInterval;
}


#pragma mark - Dismiss Methods

+ (void)popActivity {
    if([self sharedView].activityCount > 0)
        [self sharedView].activityCount--;
    if([self sharedView].activityCount == 0)
        [[self sharedView] dismiss];
}

+ (void)dismiss {
    if ([self isVisible]) {
        [[self sharedView] dismiss];
    }
}


#pragma mark - Offset

+ (void)setOffsetFromCenter:(UIOffset)offset {
    [self sharedView].offsetFromCenter = offset;
}

+ (void)resetOffsetFromCenter {
    [self setOffsetFromCenter:UIOffsetZero];
}


#pragma mark - Instance Methods

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        self.userInteractionEnabled = NO;
        
        self.backgroundColor = [UIColor clearColor];
		self.alpha = 0.0f;
        self.activityCount = 0;
        
        SVProgressHUDBackgroundColor = [UIColor whiteColor];
        SVProgressHUDForegroundColor = [UIColor blackColor];
        if ([UIFont respondsToSelector:@selector(preferredFontForTextStyle:)]) {
            SVProgressHUDFont = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
        } else {
            SVProgressHUDFont = [UIFont systemFontOfSize:14.0f];
            SVProgressHUDBackgroundColor = [UIColor colorWithWhite:0.0f alpha:0.8f];
            SVProgressHUDForegroundColor = [UIColor whiteColor];
        }
        if ([[UIImage class] instancesRespondToSelector:@selector(imageWithRenderingMode:)]) {
            SVProgressHUDInfoImage = [[UIImage imageNamed:@"SVProgressHUD.bundle/info"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            SVProgressHUDSuccessImage = [[UIImage imageNamed:@"SVProgressHUD.bundle/success"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            SVProgressHUDErrorImage = [[UIImage imageNamed:@"SVProgressHUD.bundle/error"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        } else {
            SVProgressHUDInfoImage = [UIImage imageNamed:@"SVProgressHUD.bundle/info"];
            SVProgressHUDSuccessImage = [UIImage imageNamed:@"SVProgressHUD.bundle/success"];
            SVProgressHUDErrorImage = [UIImage imageNamed:@"SVProgressHUD.bundle/error"];
        }
        SVProgressHUDOwnerSuccessImage = [UIImage imageNamed:@"hud_success"];
        SVProgressHUDOwnerErrorImage = [UIImage imageNamed:@"hud_error"];
        SVProgressHUDOwnerSuccessTipImage = [UIImage imageNamed:@"hud_success_cartoon"];
        SVProgressHUDOwnerErrorTipImage = [UIImage imageNamed:@"hud_error_cartoon"];
        SVProgressHUDOwnerLoadingTipImage = [UIImage imageNamed:@"hud_loading_cartoon"];
        SVProgressHUDBusyingImage = nil; //[UIImage sd_animatedGIFNamed:@"loading"];
        
        SVProgressHUDRingThickness = 2;
        SVProgressHUDDefaultMaskType = SVProgressHUDMaskTypeBlack;
    }
	
    return self;
}

- (void)drawRect:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    switch (self.maskType) {
        case SVProgressHUDMaskTypeBlack: {
            
            [[UIColor colorWithWhite:0 alpha:0.7] set];
            CGContextFillRect(context, self.bounds);
            
            break;
        }
        case SVProgressHUDMaskTypeGradient: {
            
            size_t locationsCount = 2;
            CGFloat locations[2] = {0.0f, 1.0f};
            CGFloat colors[8] = {0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.75f};
            CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
            CGGradientRef gradient = CGGradientCreateWithColorComponents(colorSpace, colors, locations, locationsCount);
            CGColorSpaceRelease(colorSpace);
            
            CGFloat freeHeight = CGRectGetHeight(self.bounds) - self.visibleKeyboardHeight;
            
            CGPoint center = CGPointMake(CGRectGetWidth(self.bounds)/2, freeHeight/2);
            float radius = MIN(CGRectGetWidth(self.bounds) , CGRectGetHeight(self.bounds)) ;
            CGContextDrawRadialGradient (context, gradient, center, 0, center, radius, kCGGradientDrawsAfterEndLocation);
            CGGradientRelease(gradient);
            
            break;
        }
        default:
            break;
    }
}

- (void)updatePosition:(BOOL)isOwnerDraw isProgress:(BOOL)isProgress
{
	
    CGFloat hudWidth = 100.0f;
    CGFloat hudHeight = 100.0f;
    CGFloat stringHeightBuffer = 20.0f;
    CGFloat stringAndContentHeightBuffer = 80.0f;
    
    CGFloat stringWidth = 0.0f;
    CGFloat stringHeight = 0.0f;
    CGRect labelRect = CGRectZero;
    
    NSString *string = self.stringLabel.text;
    
    // Check if an image or progress ring is displayed
    BOOL imageUsed = (self.imageView.image) || (self.imageView.hidden);
    BOOL progressUsed = (self.progress != SVProgressHUDUndefinedProgress) && (self.progress >= 0.0f);
    
    [self initStringLabel];
    
    if(string) {
        CGSize constraintSize = CGSizeMake(200.0f, 300.0f);
        CGRect stringRect;
        if ([string respondsToSelector:@selector(boundingRectWithSize:options:attributes:context:)]) {
            if(imageUsed){
                stringRect = [string boundingRectWithSize:constraintSize
                                            options:(NSStringDrawingUsesFontLeading|NSStringDrawingTruncatesLastVisibleLine|NSStringDrawingUsesLineFragmentOrigin)
                                         attributes:@{NSFontAttributeName: self.stringLabel.font}
                                            context:NULL];
            }else{
                NSUInteger beginPos = [string rangeOfString:@"<BTN>"].location;
                NSUInteger endPos = [string rangeOfString:@"</BTN>"].location;
                
                if(beginPos != NSNotFound && endPos != NSNotFound){
                    NSString * title = [string substringWithRange:NSMakeRange(beginPos + 5, endPos - beginPos - 5)];
                    string = [string substringToIndex:beginPos];
                    
                    self.clickButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 20, 30)];
                    self.clickButton.titleLabel.font = [UIFont systemFontOfSize:15];
                    [self.clickButton setTitleColor:COLOR_THEME_BLUE forState:UIControlStateNormal];
                    [self.clickButton setTitle:title forState:UIControlStateNormal];
                    [self.clickButton addTarget:self action:@selector(onTappedClickButton) forControlEvents:UIControlEventTouchUpInside];
                    [self.clickButton sizeToFit];
                    
                    self.userInteractionEnabled = YES;
                    self.hudView.userInteractionEnabled = YES;
                    
                    [self.hudView addSubview:self.clickButton];
                }
                
                NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:string];
                NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
                
                //[paragraphStyle setLineSpacing:10];//调整行间距
                [paragraphStyle setAlignment:NSTextAlignmentCenter];//调整行间距

                [attributedString addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, [string length])];
                [attributedString addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:15] range:NSMakeRange(0, [string length])];
                
                for(int i = 0;i < string.length ;i++ ){
                    NSString * subString = [string substringWithRange:NSMakeRange(i, 1)];
                    NSString *trimmedString = [subString stringByTrimmingCharactersInSet:[NSCharacterSet decimalDigitCharacterSet]];
                    if(trimmedString.length == 0){
                        [attributedString addAttribute:NSForegroundColorAttributeName value:color_with_rgb(248, 97, 97) range:NSMakeRange(i, 1)];
                    }
                }
                
                self.stringLabel.attributedText = attributedString;
                self.stringLabel.hidden = YES;
                
                
                stringRect = [attributedString boundingRectWithSize:constraintSize options:NSStringDrawingUsesLineFragmentOrigin context:nil];
                stringRect.size.height += 20;
            }
        } else {
            CGSize stringSize;
            
            if ([string respondsToSelector:@selector(sizeWithAttributes:)])
                stringSize = [string sizeWithAttributes:@{NSFontAttributeName:[UIFont fontWithName:self.stringLabel.font.fontName size:self.stringLabel.font.pointSize]}];
            else
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"
                stringSize = [string sizeWithFont:self.stringLabel.font constrainedToSize:CGSizeMake(200.0f, 300.0f)];
#pragma clang diagnostic pop
            
            stringRect = CGRectMake(0.0f, 0.0f, stringSize.width, stringSize.height);
        }
        stringWidth = stringRect.size.width;
        stringHeight = ceil(CGRectGetHeight(stringRect));
        
        if (imageUsed || progressUsed)
            hudHeight = stringAndContentHeightBuffer + stringHeight;
        else
            hudHeight = stringHeightBuffer + stringHeight;
        
        if(stringWidth > hudWidth)
            hudWidth = ceil(stringWidth/2)*2;
        
        CGFloat labelRectY = (imageUsed || progressUsed) ? 68.0f : 9.0f;
        
        float labelPadding = 0;
        if(hudHeight > 100.f || isOwnerDraw){
            labelPadding = 10;
        }
        hudWidth += 24.0f;
        labelRect = CGRectMake(labelPadding, labelRectY, hudWidth, stringHeight);
    }
    
    if(!isOwnerDraw){
        if(string && !imageUsed){
            hudWidth += 40;
            hudHeight += 30;
            if(self.clickButton){
                hudWidth += self.clickButton.width + 10;
            }
        }
        
       	self.hudView.bounds = CGRectMake(0.0f, 0.0f, hudWidth, hudHeight);
        self.hudView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.7];
        
        self.imageView.width = 28;
        self.imageView.height = 28;
        self.maskType = SVProgressHUDMaskTypeNone;
        self.stringLabel.textColor = [UIColor whiteColor];

        if(string){
            self.imageView.center = CGPointMake(CGRectGetWidth(self.hudView.bounds)/2, 36.0f);
        }else{
            self.imageView.center = CGPointMake(CGRectGetWidth(self.hudView.bounds)/2,
                                                CGRectGetHeight(self.hudView.bounds)/2);
        }
        
        if(self.tipImageView != nil && self.tipImageView.hidden == NO){
            [self.tipImageView setHidden:YES];
        }
    }else{
        BOOL hasContent = (self.stringLabel.text.length != 0);
        
        float hudWidth = hasContent ? SCREEN_WIDTH - 100 : 30;
        float hudHeight = hasContent ? HudHeight : 30;
        
        self.hudView.bounds = CGRectMake(0.0f, 0.0f,hudWidth , hudHeight);
        self.hudView.backgroundColor = SVProgressHUDBackgroundColor;
        self.maskType = SVProgressHUDMaskTypeBlack;
        
        if(hasContent && !isProgress){
            
            [self addTipImageView];
            CGSize labelSize = [self setupOwnerDrawStringLabel];
            
            self.imageView.width = 50;
            self.imageView.height = 50;
            labelRect.size = labelSize;
            
            self.imageView.centerX = labelRect.origin.x + labelSize.width / 2;
            self.imageView.top = self.tipImageView.top + imageViewOffsetY;
            
            labelRect.origin.y = self.imageView.bottom;
            labelRect.size.height = self.hudView.height - self.imageView.bottom - 10;
            
        }else{
            self.imageView.size = CGSizeMake(30, 30);
            self.imageView.top = 0;
            self.imageView.left = 0;
            
            self.stringLabel.textColor = [UIColor whiteColor];
            
            [self playBusyingAnimation];
            
            if(hasContent){
                labelRect.origin.y = self.hudView.height - 40 -10;
                labelRect.size.height = 40;
            }
        }
        self.tipImageView.hidden = !hasContent;
    }
    
	self.stringLabel.hidden = NO;
    self.stringLabel.frame = labelRect;
    
    if(isProgress){
        self.stringLabel.centerX = self.hudView.width / 2;
    }
    if(!imageUsed){
        self.stringLabel.center = CGPointMake(self.hudView.width / 2, self.hudView.height / 2);
    }
    
    if(self.clickButton){
        self.stringLabel.left = 20;
        self.clickButton.left = self.stringLabel.right;
        self.clickButton.centerY = self.stringLabel.centerY;
    }
    
    [CATransaction begin];
    [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
	
	if(string) {
        self.indefiniteAnimatedView.radius = SVProgressHUDRingRadius;
        [self.indefiniteAnimatedView sizeToFit];
        
        CGPoint center = CGPointMake((CGRectGetWidth(self.hudView.bounds)/2), 36.0f);
        
        if(isOwnerDraw){
            center = CGPointMake(labelRect.origin.x + labelRect.size.width / 2,self.tipImageView.top + imageViewOffsetY);
        }
        self.indefiniteAnimatedView.center = center;

        if(self.progress != SVProgressHUDUndefinedProgress)
            self.backgroundRingLayer.position = self.ringLayer.position = CGPointMake((CGRectGetWidth(self.hudView.bounds)/2), 36.0f);
	} else {
        self.indefiniteAnimatedView.radius = SVProgressHUDRingNoTextRadius;
        [self.indefiniteAnimatedView sizeToFit];
        
        CGPoint center = CGPointMake((CGRectGetWidth(self.hudView.bounds)/2), CGRectGetHeight(self.hudView.bounds)/2);
        self.indefiniteAnimatedView.center = center;
        
        if(self.progress != SVProgressHUDUndefinedProgress)
            self.backgroundRingLayer.position = self.ringLayer.position = CGPointMake((CGRectGetWidth(self.hudView.bounds)/2), CGRectGetHeight(self.hudView.bounds)/2);
    }
    
    
    [CATransaction commit];
}

- (void)initStringLabel
{
    self.stringLabel.numberOfLines = 0;
    self.stringLabel.font = [UIFont systemFontOfSize:15];
    self.stringLabel.textColor = color_with_rgb(119, 119, 119);
    self.stringLabel.textAlignment = NSTextAlignmentCenter;
}

- (CGSize)setupOwnerDrawStringLabel
{
    const float maxWidth = 120;
    self.stringLabel.numberOfLines = 2;
    self.stringLabel.font = [UIFont systemFontOfSize:13];
    self.stringLabel.textColor = color_with_rgb(119, 119, 119);
    
    NSDictionary * fontDic = [NSDictionary dictionaryWithObjectsAndKeys:NSFontAttributeName,[UIFont systemFontOfSize:13], nil];
    CGSize labelSize = [self.stringLabel.text boundingRectWithSize:CGSizeMake(maxWidth, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin attributes:fontDic context:nil].size;
    labelSize.height += 5;
    
    if(labelSize.width < maxWidth){
        labelSize.width = maxWidth;
    }
    if(labelSize.height > 34){
        labelSize.height = 34;
    }
    
    return labelSize;
}

- (void)setStatus:(NSString *)string {
	self.stringLabel.text = string;
    [self updatePosition:NO isProgress:NO];
}

- (void)setFadeOutTimer:(NSTimer *)newTimer {
    if(_fadeOutTimer)
        [_fadeOutTimer invalidate], _fadeOutTimer = nil;
    
    if(newTimer)
        _fadeOutTimer = newTimer;
}


- (void)registerNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(positionHUD:)
                                                 name:UIApplicationDidChangeStatusBarOrientationNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(positionHUD:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(positionHUD:)
                                                 name:UIKeyboardDidHideNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(positionHUD:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(positionHUD:)
                                                 name:UIKeyboardDidShowNotification
                                               object:nil];
}


- (NSDictionary *)notificationUserInfo{
    return (self.stringLabel.text ? @{SVProgressHUDStatusUserInfoKey : self.stringLabel.text} : nil);
}


- (void)positionHUD:(NSNotification*)notification {
    
    CGFloat keyboardHeight = 0.0f;
    double animationDuration = 0.0;
    
    self.frame = UIScreen.mainScreen.bounds;
    
#if !defined(SV_APP_EXTENSIONS)
    UIInterfaceOrientation orientation = UIApplication.sharedApplication.statusBarOrientation;
#else
    UIInterfaceOrientation orientation = CGRectGetWidth(self.frame) > CGRectGetHeight(self.frame) ? UIInterfaceOrientationLandscapeLeft : UIInterfaceOrientationPortrait;
#endif
    // no transforms applied to window in iOS 8, but only if compiled with iOS 8 sdk as base sdk, otherwise system supports old rotation logic.
    BOOL ignoreOrientation = NO;
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
    if ([[NSProcessInfo processInfo] respondsToSelector:@selector(operatingSystemVersion)]) {
        ignoreOrientation = YES;
    }
#endif

    if(notification) {
        NSDictionary* keyboardInfo = [notification userInfo];
        CGRect keyboardFrame = [[keyboardInfo valueForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue];
        animationDuration = [[keyboardInfo valueForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
        
        if(notification.name == UIKeyboardWillShowNotification || notification.name == UIKeyboardDidShowNotification) {
            if(ignoreOrientation || UIInterfaceOrientationIsPortrait(orientation))
                keyboardHeight = CGRectGetHeight(keyboardFrame);
            else
                keyboardHeight = CGRectGetWidth(keyboardFrame);
        }
    } else {
        keyboardHeight = self.visibleKeyboardHeight;
    }
    
    CGRect orientationFrame = self.bounds;
#if !defined(SV_APP_EXTENSIONS)
    CGRect statusBarFrame = UIApplication.sharedApplication.statusBarFrame;
#else
    CGRect statusBarFrame = CGRectZero;
#endif
    
    if(!ignoreOrientation && UIInterfaceOrientationIsLandscape(orientation)) {
        float temp = CGRectGetWidth(orientationFrame);
        orientationFrame.size.width = CGRectGetHeight(orientationFrame);
        orientationFrame.size.height = temp;
        
        temp = CGRectGetWidth(statusBarFrame);
        statusBarFrame.size.width = CGRectGetHeight(statusBarFrame);
        statusBarFrame.size.height = temp;
    }
    
    CGFloat activeHeight = CGRectGetHeight(orientationFrame);
    
    if(keyboardHeight > 0)
        activeHeight += CGRectGetHeight(statusBarFrame)*2;
    
    activeHeight -= keyboardHeight;
    CGFloat posY = floor(activeHeight*0.45);
    CGFloat posX = CGRectGetWidth(orientationFrame)/2;
    
    CGPoint newCenter;
    CGFloat rotateAngle;
    
    if (ignoreOrientation) {
        rotateAngle = 0.0;
        newCenter = CGPointMake(posX, posY);
    } else {
        switch (orientation) {
            case UIInterfaceOrientationPortraitUpsideDown:
                rotateAngle = M_PI;
                newCenter = CGPointMake(posX, CGRectGetHeight(orientationFrame)-posY);
                break;
            case UIInterfaceOrientationLandscapeLeft:
                rotateAngle = -M_PI/2.0f;
                newCenter = CGPointMake(posY, posX);
                break;
            case UIInterfaceOrientationLandscapeRight:
                rotateAngle = M_PI/2.0f;
                newCenter = CGPointMake(CGRectGetHeight(orientationFrame)-posY, posX);
                break;
            default: // as UIInterfaceOrientationPortrait
                rotateAngle = 0.0;
                newCenter = CGPointMake(posX, posY);
                break;
        }
    }
    
//    if(notification) {
//        [UIView animateWithDuration:animationDuration
//                              delay:0
//                            options:UIViewAnimationOptionAllowUserInteraction
//                         animations:^{
//                             [self moveToPoint:newCenter rotateAngle:rotateAngle];
//                             [self.hudView setNeedsDisplay];
//                         } completion:NULL];
//    } else {
        [self moveToPoint:newCenter rotateAngle:rotateAngle];
        [self.hudView setNeedsDisplay];
//    }
    
}

- (void)moveToPoint:(CGPoint)newCenter rotateAngle:(CGFloat)angle {
    self.hudView.transform = CGAffineTransformMakeRotation(angle);
    CGPoint center = [UIApplication sharedApplication].keyWindow.center;
    self.hudView.center = CGPointMake(center.x + self.offsetFromCenter.horizontal, center.y + self.offsetFromCenter.vertical);
}

- (void)overlayViewDidReceiveTouchEvent:(id)sender forEvent:(UIEvent *)event {
    [[NSNotificationCenter defaultCenter] postNotificationName:SVProgressHUDDidReceiveTouchEventNotification object:event];
    
    UITouch *touch = event.allTouches.anyObject;
    CGPoint touchLocation = [touch locationInView:self];
    
    if (CGRectContainsPoint(self.hudView.frame, touchLocation)) {
        [[NSNotificationCenter defaultCenter] postNotificationName:SVProgressHUDDidTouchDownInsideNotification object:event];
    }
}


#pragma mark - Master show/dismiss methods

- (void)showProgress:(float)progress status:(NSString*)string maskType:(SVProgressHUDMaskType)hudMaskType isOwnerDraw:(BOOL)isOwnerDraw{
    if(!self.overlayView.superview){
#if !defined(SV_APP_EXTENSIONS)
        NSEnumerator *frontToBackWindows = [UIApplication.sharedApplication.windows reverseObjectEnumerator];
        for (UIWindow *window in frontToBackWindows){
            BOOL windowOnMainScreen = window.screen == UIScreen.mainScreen;
            BOOL windowIsVisible = !window.hidden && window.alpha > 0;
            BOOL windowLevelNormal = window.windowLevel == UIWindowLevelNormal;
            
            if (windowOnMainScreen && windowIsVisible && windowLevelNormal) {
                [window addSubview:self.overlayView];
                break;
            }
        }
#else
        if(SVProgressHUDExtensionView){
            [SVProgressHUDExtensionView addSubview:self.overlayView];
        }
#endif
    } else {
        // Ensure that overlay will be exactly on top of rootViewController (which may be changed during runtime).
        [self.overlayView.superview bringSubviewToFront:self.overlayView];
    }
    
    
    [self dismiss];
    
    if(!self.superview)
        [self.overlayView addSubview:self];
    
    self.fadeOutTimer = nil;
    self.imageView.hidden = YES;
    self.maskType = hudMaskType;
    self.progress = progress;
    
    self.stringLabel.text = string;
    [self updatePosition:isOwnerDraw isProgress:YES];
    
    if(progress >= 0) {
        self.imageView.image = nil;
        self.imageView.hidden = NO;
        [self.indefiniteAnimatedView removeFromSuperview];
        
        self.ringLayer.strokeEnd = progress;
        
        if(progress == 0)
            self.activityCount++;
    } else {
        self.activityCount++;
        [self cancelRingLayerAnimation];
        
        if(!isOwnerDraw){
            [self.hudView addSubview:self.indefiniteAnimatedView];
        }else{
            self.imageView.hidden = NO;
            self.imageView.image = SVProgressHUDBusyingImage;
            self.tipImageView.image = SVProgressHUDOwnerLoadingTipImage;
            [self.indefiniteAnimatedView removeFromSuperview];
        }
    }
    
    if(self.maskType != SVProgressHUDMaskTypeNone) {
        self.overlayView.userInteractionEnabled = YES;
        self.accessibilityLabel = string;
        self.isAccessibilityElement = YES;
    } else {
        self.overlayView.userInteractionEnabled = YES;
        self.hudView.accessibilityLabel = string;
        self.hudView.isAccessibilityElement = YES;
    }
    
    [self.overlayView setHidden:NO];
    self.overlayView.backgroundColor = [UIColor clearColor];
    [self positionHUD:nil];
    
    if(self.alpha != 1 || self.hudView.alpha != 1) {
        NSDictionary *userInfo = [self notificationUserInfo];
        [[NSNotificationCenter defaultCenter] postNotificationName:SVProgressHUDWillAppearNotification
                                                            object:nil
                                                          userInfo:userInfo];
        
        [self registerNotifications];
        self.hudView.transform = CGAffineTransformScale(self.hudView.transform, 1.3, 1.3);
        
        if(self.isClear) {
            self.alpha = 1;
            self.hudView.alpha = 0;
        }
        
        [UIView animateWithDuration:0.15
                              delay:0
                            options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationCurveEaseOut | UIViewAnimationOptionBeginFromCurrentState
                         animations:^{
                             self.hudView.transform = CGAffineTransformScale(self.hudView.transform, 1/1.3, 1/1.3);
                             
                             if(self.isClear) // handle iOS 7 and 8 UIToolbar which not answers well to hierarchy opacity change
                                 self.hudView.alpha = 1;
                             else
                                 self.alpha = 1;
                         }
                         completion:^(BOOL finished){
                             [[NSNotificationCenter defaultCenter] postNotificationName:SVProgressHUDDidAppearNotification
                                                                                 object:nil
                                                                               userInfo:userInfo];
                             UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, nil);
                             UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, string);
                         }];
        
        [self setNeedsDisplay];
    }
}

- (UIImage *)image:(UIImage *)image withTintColor:(UIColor *)color{
    CGRect rect = CGRectMake(0.0f, 0.0f, image.size.width, image.size.height);
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, image.scale);
    CGContextRef c = UIGraphicsGetCurrentContext();
    [image drawInRect:rect];
    CGContextSetFillColorWithColor(c, [color CGColor]);
    CGContextSetBlendMode(c, kCGBlendModeSourceAtop);
    CGContextFillRect(c, rect);
    UIImage *tintedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return tintedImage;
}

- (void)showImage:(UIImage *)image status:(NSString *)string duration:(NSTimeInterval)duration maskType:(SVProgressHUDMaskType)hudMaskType  isOwnerDraw:(BOOL)isOwnerDraw{
    self.progress = SVProgressHUDUndefinedProgress;
    [self cancelRingLayerAnimation];
    
    [self dismiss];
    
    if(![self.class isVisible])
        [self.class show];

    if ([self.imageView respondsToSelector:@selector(setTintColor:)]) {
        self.imageView.tintColor = SVProgressHUDForegroundColor;
    } else {
        image = [self image:image withTintColor:SVProgressHUDForegroundColor];
    }
    self.imageView.image = nil;
    self.imageView.image = image;
    self.imageView.hidden = NO;
    self.maskType = hudMaskType;
  
    self.stringLabel.text = string;
    [self updatePosition:isOwnerDraw isProgress:NO];
    [self.indefiniteAnimatedView removeFromSuperview];
    
    if(self.maskType != SVProgressHUDMaskTypeNone) {
        self.accessibilityLabel = string;
        self.isAccessibilityElement = YES;
    } else {
        self.hudView.accessibilityLabel = string;
        self.hudView.isAccessibilityElement = YES;
    }
    
    UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, nil);
    UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, string);
    
    self.fadeOutTimer = [NSTimer timerWithTimeInterval:duration target:self selector:@selector(dismiss) userInfo:nil repeats:NO];
    [[NSRunLoop mainRunLoop] addTimer:self.fadeOutTimer forMode:NSRunLoopCommonModes];
}

- (void)dismiss {
    
    [self.imageView stopAnimating];

    [self.activityIndiV stopAnimating];
    self.activityIndiV.hidden = YES;
    self.clickButton = nil;
    self.blockHandler = nil;
    
    NSDictionary *userInfo = [self notificationUserInfo];
    [[NSNotificationCenter defaultCenter] postNotificationName:SVProgressHUDWillDisappearNotification
                                                        object:nil
                                                      userInfo:userInfo];
    
    self.activityCount = 0;
    [UIView animateWithDuration:0.15
                          delay:0
                        options:UIViewAnimationCurveEaseIn | UIViewAnimationOptionAllowUserInteraction
                     animations:^{
                         
                         if(self.isClear) // handle iOS 7 UIToolbar not answer well to hierarchy opacity change
                             self.hudView.alpha = 0.0f;
                         else
                             self.alpha = 0.0f;
                     }
                     completion:^(BOOL finished){
                         if(self.alpha == 0.0f || self.hudView.alpha == 0.0f) {
                             self.alpha = 0.0f;
                             self.hudView.alpha = 0.0f;
                             
                             [[NSNotificationCenter defaultCenter] removeObserver:self];
                             [self cancelRingLayerAnimation];
                             [_hudView removeFromSuperview];
                             _hudView = nil;
                             
                             [_overlayView removeFromSuperview];
                             _overlayView = nil;
                             
                             [_indefiniteAnimatedView removeFromSuperview];
                             _indefiniteAnimatedView = nil;
                             
                             UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, nil);
                             
                             [[NSNotificationCenter defaultCenter] postNotificationName:SVProgressHUDDidDisappearNotification
                                                                                 object:nil
                                                                               userInfo:userInfo];
                             
                             // Tell the rootViewController to update the StatusBar appearance
#if !defined(SV_APP_EXTENSIONS)
                             UIViewController *rootController = [[UIApplication sharedApplication] keyWindow].rootViewController;
                             if ([rootController respondsToSelector:@selector(setNeedsStatusBarAppearanceUpdate)]) {
                                 [rootController setNeedsStatusBarAppearanceUpdate];
                             }
#endif
                             // uncomment to make sure UIWindow is gone from app.windows
                             //NSLog(@"%@", [UIApplication sharedApplication].windows);
                             //NSLog(@"keyWindow = %@", [UIApplication sharedApplication].keyWindow);
                         }
                     }];
}


#pragma mark - Ring progress animation

- (SVIndefiniteAnimatedView *)indefiniteAnimatedView {
    if (_indefiniteAnimatedView == nil) {
        _indefiniteAnimatedView = [[SVIndefiniteAnimatedView alloc] initWithFrame:CGRectZero];
        _indefiniteAnimatedView.strokeThickness = SVProgressHUDRingThickness;
        _indefiniteAnimatedView.strokeColor = SVProgressHUDForegroundColor;
        _indefiniteAnimatedView.radius = self.stringLabel.text ? SVProgressHUDRingRadius : SVProgressHUDRingNoTextRadius;
        [_indefiniteAnimatedView sizeToFit];
    }
    return _indefiniteAnimatedView;
}

- (CAShapeLayer *)ringLayer {
    if(!_ringLayer) {
        CGPoint center = CGPointMake(CGRectGetWidth(_hudView.frame)/2, CGRectGetHeight(_hudView.frame)/2);
        _ringLayer = [self createRingLayerWithCenter:center
                                              radius:SVProgressHUDRingRadius
                                           lineWidth:SVProgressHUDRingThickness
                                               color:SVProgressHUDForegroundColor];
        [self.hudView.layer addSublayer:_ringLayer];
    }
    return _ringLayer;
}

- (CAShapeLayer *)backgroundRingLayer {
    if(!_backgroundRingLayer) {
        CGPoint center = CGPointMake(CGRectGetWidth(_hudView.frame)/2, CGRectGetHeight(_hudView.frame)/2);
        _backgroundRingLayer = [self createRingLayerWithCenter:center
                                                        radius:SVProgressHUDRingRadius
                                                     lineWidth:SVProgressHUDRingThickness
                                                         color:[SVProgressHUDForegroundColor colorWithAlphaComponent:0.1f]];
        _backgroundRingLayer.strokeEnd = 1;
        [self.hudView.layer addSublayer:_backgroundRingLayer];
    }
    return _backgroundRingLayer;
}

- (void)cancelRingLayerAnimation {
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    [_hudView.layer removeAllAnimations];
    
    _ringLayer.strokeEnd = 0.0f;
    if (_ringLayer.superlayer) {
        [_ringLayer removeFromSuperlayer];
    }
    _ringLayer = nil;
    
    if (_backgroundRingLayer.superlayer) {
        [_backgroundRingLayer removeFromSuperlayer];
    }
    _backgroundRingLayer = nil;
    
    [CATransaction commit];
}

- (CAShapeLayer *)createRingLayerWithCenter:(CGPoint)center radius:(CGFloat)radius lineWidth:(CGFloat)lineWidth color:(UIColor *)color {
    
    UIBezierPath* smoothedPath = [UIBezierPath bezierPathWithArcCenter:CGPointMake(radius, radius) radius:radius startAngle:-M_PI_2 endAngle:(M_PI + M_PI_2) clockwise:YES];
    
    CAShapeLayer *slice = [CAShapeLayer layer];
    slice.contentsScale = [[UIScreen mainScreen] scale];
    slice.frame = CGRectMake(center.x-radius, center.y-radius, radius*2, radius*2);
    slice.fillColor = [UIColor clearColor].CGColor;
    slice.strokeColor = color.CGColor;
    slice.lineWidth = lineWidth;
    slice.lineCap = kCALineCapRound;
    slice.lineJoin = kCALineJoinBevel;
    slice.path = smoothedPath.CGPath;
    
    return slice;
}

#pragma mark - Utilities

+ (BOOL)isVisible {
    return ([self sharedView].alpha == 1);
}


#pragma mark - Getters

- (NSTimeInterval)displayDurationForString:(NSString*)string {
    return MIN((float)string.length*0.06 + 1, 5.0);
}

- (BOOL)isClear { // used for iOS 7 and above
    return (self.maskType == SVProgressHUDMaskTypeClear || self.maskType == SVProgressHUDMaskTypeNone);
}

- (UIControl *)overlayView {
    if(!_overlayView) {
        _overlayView = [[UIControl alloc] initWithFrame:[UIScreen mainScreen].bounds];
        _overlayView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _overlayView.backgroundColor = [UIColor clearColor];
        [_overlayView addTarget:self action:@selector(overlayViewDidReceiveTouchEvent:forEvent:) forControlEvents:UIControlEventTouchDown];
    }
    return _overlayView;
}

- (UIActivityIndicatorView *)activityIndiV
{
    if (!_activityIndiV) {
        _activityIndiV = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        _activityIndiV.color = [UIColor whiteColor];
        _activityIndiV.hidden = YES;
        [self addSubview:_activityIndiV];
        [self bringSubviewToFront:_activityIndiV];
    }
    
    return _activityIndiV;
}

- (UIView *)hudView {
    if(!_hudView) {
        _hudView = [[UIView alloc] initWithFrame:CGRectZero];
        _hudView.backgroundColor = SVProgressHUDBackgroundColor;
        _hudView.layer.cornerRadius = 5;
        _hudView.layer.masksToBounds = YES;

        _hudView.autoresizingMask = (UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin |
                                     UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin);

        if ([_hudView respondsToSelector:@selector(addMotionEffect:)]) {
            UIInterpolatingMotionEffect *effectX = [[UIInterpolatingMotionEffect alloc] initWithKeyPath: @"center.x" type: UIInterpolatingMotionEffectTypeTiltAlongHorizontalAxis];
            effectX.minimumRelativeValue = @(-SVProgressHUDParallaxDepthPoints);
            effectX.maximumRelativeValue = @(SVProgressHUDParallaxDepthPoints);

            UIInterpolatingMotionEffect *effectY = [[UIInterpolatingMotionEffect alloc] initWithKeyPath: @"center.y" type: UIInterpolatingMotionEffectTypeTiltAlongVerticalAxis];
            effectY.minimumRelativeValue = @(-SVProgressHUDParallaxDepthPoints);
            effectY.maximumRelativeValue = @(SVProgressHUDParallaxDepthPoints);

            UIMotionEffectGroup *effectGroup = [[UIMotionEffectGroup alloc] init];
            effectGroup.motionEffects = @[effectX, effectY];
            [_hudView addMotionEffect:effectGroup];
        }
    }
    
    if(!_hudView.superview)
        [self addSubview:_hudView];
    
    return _hudView;
}

- (UILabel *)stringLabel {
    if (!_stringLabel) {
        _stringLabel = [[UILabel alloc] initWithFrame:CGRectZero];
		_stringLabel.backgroundColor = [UIColor clearColor];
		//_stringLabel.adjustsFontSizeToFitWidth = YES;
        _stringLabel.textAlignment = NSTextAlignmentCenter;
		_stringLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
        _stringLabel.numberOfLines = 0;
        
        _stringLabel.textColor = SVProgressHUDForegroundColor;
        _stringLabel.font = SVProgressHUDFont;
    }
    
    if(!_stringLabel.superview)
        [self.hudView addSubview:_stringLabel];
    
    return _stringLabel;
}

- (UIImageView *)imageView {
    if (!_imageView)
        _imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 28.0f, 28.0f)];
    
    if(!_imageView.superview)
        [self.hudView addSubview:_imageView];
    
    return _imageView;
}


- (CGFloat)visibleKeyboardHeight {
#if !defined(SV_APP_EXTENSIONS)
    UIWindow *keyboardWindow = nil;
    for (UIWindow *testWindow in [[UIApplication sharedApplication] windows]) {
        if(![[testWindow class] isEqual:[UIWindow class]]) {
            keyboardWindow = testWindow;
            break;
        }
    }
    
    for (__strong UIView *possibleKeyboard in [keyboardWindow subviews]) {
        if ([possibleKeyboard isKindOfClass:NSClassFromString(@"UIPeripheralHostView")] || [possibleKeyboard isKindOfClass:NSClassFromString(@"UIKeyboard")]) {
            return CGRectGetHeight(possibleKeyboard.bounds);
        } else if ([possibleKeyboard isKindOfClass:NSClassFromString(@"UIInputSetContainerView")]) {
            for (__strong UIView *possibleKeyboardSubview in [possibleKeyboard subviews]) {
                if ([possibleKeyboardSubview isKindOfClass:NSClassFromString(@"UIInputSetHostView")]) {
                    return CGRectGetHeight(possibleKeyboardSubview.bounds);
                }
            }
        }
    }
#endif
    return 0;
}

- (void)addTipImageView {
    
    UIImage * imageView = nil;

    [self.imageView stopAnimating];
    
    if([self.imageView.image isEqual:SVProgressHUDOwnerSuccessImage]){
        imageView = SVProgressHUDOwnerSuccessTipImage;
    }
    else if([self.imageView.image isEqual:SVProgressHUDOwnerErrorImage]){
        imageView = SVProgressHUDOwnerErrorTipImage;
        self.imageView.image = SVProgressHUDOwnerErrorImage;
    }
    else {
        imageView = SVProgressHUDOwnerLoadingTipImage;
    }
    
    if(self.tipImageView == nil){
        self.tipImageView = [[UIImageView alloc] initWithFrame:CGRectMake(SCREEN_WIDTH - 100 - TipViewWidth - 10, 25.f, TipViewWidth, TipViewHeight)];
    }
    //[self.tipImageView setBackgroundColor:[UIColor redColor]];
    self.tipImageView.image = nil;
    self.tipImageView.image = imageView;
    [self.hudView addSubview:self.tipImageView];
    [self.tipImageView setHidden:NO];
    
    self.hudView.backgroundColor = SVProgressHUDBackgroundColor;
}

- (void)playBusyingAnimation
{
    self.activityIndiV.center = CGPointMake(self.bounds.size.width / 2, self.bounds.size.height / 2);
    [self.activityIndiV startAnimating];
    self.activityIndiV.hidden = NO;
    
//    self.imageView.image = nil;
//    
//    if(self.imageView.animationImages == nil){
//        NSArray *images=[NSArray arrayWithObjects:[UIImage imageNamed:@"LoadingImage1"],[UIImage imageNamed:@"LoadingImage2"],[UIImage imageNamed:@"LoadingImage3"],[UIImage imageNamed:@"LoadingImage4"],[UIImage imageNamed:@"LoadingImage5"],[UIImage imageNamed:@"LoadingImage6"], nil];
//        self.imageView.animationImages = images;
//    }
//    self.imageView.animationDuration = 0.4;
//    self.imageView.animationRepeatCount = 0;
//    [self.imageView startAnimating];

    self.hudView.backgroundColor = [UIColor clearColor];
}

- (void)onTappedClickButton
{
    if(self.blockHandler){
        self.blockHandler();
    }
}

@end


