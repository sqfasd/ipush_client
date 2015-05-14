//
//  CLClippingTool.m
//
//  Created by sho yakushiji on 2013/10/18.
//  Copyright (c) 2013年 CALACULU. All rights reserved.
//

#import "CLClippingTool.h"

#import <QuartzCore/QuartzCore.h>
#import "UIImage+Utility.h"
#import "UIView+Frame.h"
#import "UIColor+Extension.h"



#pragma mark- CLClippintTool


#define CROPCORNER_LEFTTOP 0
#define CROPCORNER_LEFTBOTTOM 1
#define CROPCORNER_RIGHTTOP 2
#define CROPCORNER_RIGHTBOTTOM 3

#define CROP_BORDER_LEFT 4
#define CROP_BORDER_RIGHT 5
#define CROP_BORDER_TOP 6
#define CROP_BORDER_BOTTOM 7


@interface CLClippingTool()
@property (nonatomic, strong) CLRatioMenuItem *selectedMenu;
@end

@implementation CLClippingTool
{
    CLClippingPanel *_gridView;
}


+ (NSString*)title
{
    return @"Crop";
}

+ (BOOL)isAvailable
{
    return YES;
}

- (void)setup
{
    _gridView = [[CLClippingPanel alloc] initWithSuperview:self.editor.view frame:RECT_CROPFRAME];
//    _gridView.clipTool = self;
//    [_gridView setClippingRect:RECT_CROPFRAME];
    
    self.editor.clipPanel = _gridView;
    
    NSLog(@"GridViewFrame: %@", NSStringFromCGRect(_gridView.frame));
    NSLog(@"editor imageviewFrame: %@", NSStringFromCGRect(self.editor.captureImageView.frame));
    _gridView.backgroundColor = [UIColor clearColor];
    
    _gridView.bgColor = [[UIColor blackColor] colorWithAlphaComponent:0.8];
    _gridView.gridColor = [UIColor colorWithHex:0x0091ff];
    _gridView.clipsToBounds = NO;
}

- (void)cleanup
{
    [self.editor resetZoomScaleWithAnimate:YES];
    [_gridView removeFromSuperview];
    
//    [UIView animateWithDuration:kCLImageToolAnimationDuration
//                     animations:^{
//                         _menuContainer.transform = CGAffineTransformMakeTranslation(0, self.editor.view.height-_menuScroll.top);
//                     }
//                     completion:^(BOOL finished) {
//                         [_menuContainer removeFromSuperview];
//                     }];
}

- (void)executeWithCompletionBlock:(void (^)(UIImage *, NSError *, NSDictionary *))completionBlock
{
    if (!self.editor.captureImageView.image) {
        completionBlock([[UIImage alloc] init], nil, nil);
        return;
    }
    
    CGSize imageSize = self.editor.captureImageView.image.size;
    if (imageSize.width <= 0) {
        imageSize.width = 1;
    }
    if (imageSize.height <= 0) {
        imageSize.height = 1;
    }
    
    MDLog(@"executeWithCompletionBlock ivSize:%@ imgSize:%@", NSStringFromCGSize(self.editor.captureImageView.frame.size), NSStringFromCGSize(imageSize));

    CGFloat zoomScale = imageSize.width >= imageSize.height ?
    self.editor.captureImageView.frame.size.width / imageSize.width :
    self.editor.captureImageView.frame.size.height / imageSize.height; //self.editor.scrollView.zoomScale;
    CGRect rct = _gridView.clippingRect;
    
    MDLog(@"zoomScale:%f clipRect:%@", zoomScale, NSStringFromCGRect(_gridView.clippingRect));
    
    rct.size.width  /= zoomScale;
    rct.size.height /= zoomScale;
    rct.origin.x    /= zoomScale;
    rct.origin.y    /= zoomScale;
    
    MDLog(@"finalClipRect: %@", NSStringFromCGRect(rct));
    
    UIImage *result = [self.editor.captureImageView.image crop:rct];
    completionBlock(result, nil, nil);
}

#pragma mark-

- (void)pushedRotateBtn:(UIButton*)sender
{
//    for(CLRatioMenuItem *item in _menuScroll.subviews){
//        if([item isKindOfClass:[CLRatioMenuItem class]]){
//            [item changeOrientation];
//        }
//    }
    
    if(_gridView.clippingRatio.ratio!=0 && _gridView.clippingRatio.ratio!=1){
        [_gridView clippingRatioDidChange];
    }
}

@end



#pragma mark -
#pragma mark - UI components
@implementation CLClippingCircle

- (void)drawRect:(CGRect)rect
{
    // 2.3版本，不绘制圆角蓝色
//    CGContextRef context = UIGraphicsGetCurrentContext();
//    
//    CGRect rct = self.bounds;
//    rct.origin.x = rct.size.width/2-rct.size.width/6;
//    rct.origin.y = rct.size.height/2-rct.size.height/6;
//    rct.size.width /= 3;
//    rct.size.height /= 3;
//    
//    CGContextSetFillColorWithColor(context, self.bgColor.CGColor);
//    CGContextFillEllipseInRect(context, rct);
}

@end



@implementation CLBorderMovingSpot

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGRect rct = self.bounds;
    rct.origin.x = rct.size.width/2-rct.size.width/8;
    rct.origin.y = rct.size.height/2-rct.size.height/8;
    rct.size.width /= 4;
    rct.size.height /= 4;
    
    CGContextSetFillColorWithColor(context, self.bgColor.CGColor);
    CGContextFillEllipseInRect(context, rct);
}

@end



#pragma mark -
#pragma mark - CLGridLayer
@interface CLGridLayar : CALayer

@property (nonatomic, assign) CGRect clippingRect;
@property (nonatomic, strong) UIColor *bgColor;
@property (nonatomic, strong) UIColor *gridColor;

@property (nonatomic) BOOL isFingerTouching;

@end

@implementation CLGridLayar

+ (BOOL)needsDisplayForKey:(NSString*)key
{
    if ([key isEqualToString:@"clippingRect"]) {
        return YES;
    }
    return [super needsDisplayForKey:key];
}

- (id)initWithLayer:(id)layer
{
    self = [super initWithLayer:layer];
    if(self && [layer isKindOfClass:[CLGridLayar class]]){
        self.bgColor   = ((CLGridLayar*)layer).bgColor;
        self.gridColor = ((CLGridLayar*)layer).gridColor;
        self.clippingRect = ((CLGridLayar*)layer).clippingRect;
    }
    return self;
}

- (void)drawInContext:(CGContextRef)context
{
    CGRect rct = self.bounds;
    CGContextSetFillColorWithColor(context, self.bgColor.CGColor);
    CGContextFillRect(context, rct);
    
    CGContextClearRect(context, _clippingRect);
    
    CGContextSetStrokeColorWithColor(context, self.gridColor.CGColor);
    CGContextSetLineWidth(context, 2);
    
    rct = self.clippingRect;
    
    CGContextBeginPath(context);
    CGFloat dW = 0;
    for(int i=0; i<4; ++i) {
        if (i == 1 || i == 2) {
            dW += _clippingRect.size.width/3;
            continue;
//            CGContextSetLineWidth(context, 1);
        }
        
        CGContextMoveToPoint(context, rct.origin.x+dW, rct.origin.y);
        CGContextAddLineToPoint(context, rct.origin.x+dW, rct.origin.y+rct.size.height);
        dW += _clippingRect.size.width/3;

    }
    
    dW = 0;
    for(int i=0; i<4; ++i) {
        if (i == 1 || i == 2) {
            dW += rct.size.height/3;
            continue;
//            CGContextSetLineWidth(context, 1);
        }
        
        CGContextMoveToPoint(context, rct.origin.x, rct.origin.y+dW);
        CGContextAddLineToPoint(context, rct.origin.x+rct.size.width, rct.origin.y+dW);
        dW += rct.size.height/3;

    }
    CGContextStrokePath(context);
}

@end



#pragma mark -
#pragma mark - CLClippingPanel
@implementation CLClippingPanel

{
    CLGridLayar *_gridLayer;
}

- (CLBorderMovingSpot *)borderMovingSpotWithTag:(NSInteger)tag
{
    CLBorderMovingSpot *spot = [[CLBorderMovingSpot alloc] initWithFrame:CGRectMake(0, 0, 44, 44)];
    spot.bgColor = [[UIColor colorWithHex:0x0091ff] colorWithAlphaComponent:0.8];
    spot.userInteractionEnabled = YES;
    spot.backgroundColor = [UIColor clearColor];
    spot.tag = tag;
    
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panBorderSpot:)];
    panGesture.delegate = self;
    [spot addGestureRecognizer:panGesture];
    
    [self.superview addSubview:spot];
    
    return spot;
}

- (CLClippingCircle*)clippingCircleWithTag:(NSInteger)tag
{
    CLClippingCircle *view = [[CLClippingCircle alloc] initWithFrame:CGRectMake(0, 0, 40, 40)];
    view.panel = self;

    view.backgroundColor = [UIColor clearColor];
    //view.clipsToBounds = NO;
    view.bgColor = [UIColor blackColor];
    view.tag = tag;
    view.userInteractionEnabled = YES;
    
//    UIImageView *iconImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"ic_zoom.png"]];
//    iconImageView.frame = CGRectMake(5, 5, 30, 30);
//    iconImageView.userInteractionEnabled = NO;
//    [view addSubview:iconImageView];
    UIImageView *imgV = [[UIImageView alloc] init];
    imgV.backgroundColor = [UIColor clearColor];
    CGRect frame = imgV.frame;

    switch (tag) {
        case CROPCORNER_LEFTTOP:
            imgV.image = [UIImage imageNamed:@"crop_lt"];
            frame.origin.x = frame.origin.y = 18;
            break;
        case CROPCORNER_LEFTBOTTOM:
            imgV.image = [UIImage imageNamed:@"crop_lb"];
            frame.origin.x = 18;
            frame.origin.y = -19;
            break;
        case CROPCORNER_RIGHTTOP:
            imgV.image = [UIImage imageNamed:@"crop_rt"];
            frame.origin.x = -20;
            frame.origin.y = 18;
            break;
        case CROPCORNER_RIGHTBOTTOM:
            imgV.image = [UIImage imageNamed:@"crop_rb"];
            frame.origin.x = frame.origin.y = -19;
            break;
            
        default:
            imgV.image = [UIImage imageNamed:@""];
            break;
    }
    frame.size = imgV.image.size;
    imgV.frame = frame;
    [view addSubview:imgV];
    
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panCircleView:)];
    panGesture.delegate = self;
    [view addGestureRecognizer:panGesture];
    
    [self.superview addSubview:view];
    
    return view;
}

- (id)initWithSuperview:(UIView*)superview frame:(CGRect)frame
{
    CGRect gridFrame = frame;
    self = [super initWithFrame:gridFrame];
    
    if(self){
        [superview addSubview:self];

        //self.clipsToBounds = NO;
        self.userInteractionEnabled = YES;
        
        _gridLayer = [[CLGridLayar alloc] init];
        _gridLayer.frame = self.bounds;
//        _gridLayer.bgColor   = [UIColor colorWithWhite:1 alpha:1];
        _gridLayer.bgColor = [UIColor colorWithHex:0x0091ff];

//        _gridLayer.gridColor = [UIColor colorWithWhite:0 alpha:1];
        _gridLayer.gridColor = [UIColor colorWithHex:0x0091ff];

        [self.layer addSublayer:_gridLayer];
        
        _ltView = [self clippingCircleWithTag:CROPCORNER_LEFTTOP];
        _lbView = [self clippingCircleWithTag:CROPCORNER_LEFTBOTTOM];
        _rtView = [self clippingCircleWithTag:CROPCORNER_RIGHTTOP];
        _rbView = [self clippingCircleWithTag:CROPCORNER_RIGHTBOTTOM];
        
        _leftSpot = [self borderMovingSpotWithTag:CROP_BORDER_LEFT];
        _rightSpot = [self borderMovingSpotWithTag:CROP_BORDER_RIGHT];
        _topSpot = [self borderMovingSpotWithTag:CROP_BORDER_TOP];
        _bottomSpot = [self borderMovingSpotWithTag:CROP_BORDER_BOTTOM];
        
        UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGridView:)];
        panGesture.delegate = self;
        [self addGestureRecognizer:panGesture];
        
        CGRect gridInitFrame = self.bounds;
//        gridInitFrame.origin.x = self.bounds.size.width / 8;
//        gridInitFrame.origin.y = self.bounds.size.height / 8;
//        gridInitFrame.size.width = self.bounds.size.width / 4 * 3;
//        gridInitFrame.size.height = self.bounds.size.height / 4 * 3;
        
        self.clippingRect = gridInitFrame; //self.bounds;
        NSLog(@"ClippingPanel clippingRect: %@", NSStringFromCGRect(self.clippingRect));
    }
    return self;
}

- (void)removeFromSuperview
{
    [super removeFromSuperview];
    
    [_ltView removeFromSuperview];
    [_lbView removeFromSuperview];
    [_rtView removeFromSuperview];
    [_rbView removeFromSuperview];
    
    [_leftSpot removeFromSuperview];
    [_rightSpot removeFromSuperview];
    [_topSpot removeFromSuperview];
    [_bottomSpot removeFromSuperview];
}

- (void)setBgColor:(UIColor *)bgColor
{
    _gridLayer.bgColor = bgColor;
}

- (void)setGridColor:(UIColor *)gridColor
{
    _gridLayer.gridColor = gridColor;

//    _ltView.bgColor = _lbView.bgColor = _rtView.bgColor = _rbView.bgColor = [gridColor colorWithAlphaComponent:0.8];
}

- (void)setClippingRect:(CGRect)clippingRect
{
//    CGRect finalRect = CGRectIntersection(clippingRect, self.clipTool.editor.imageViewRect);
    _clippingRect = clippingRect;
//    MDLog(@"\nclipRect:%@\nimgVRect:%@\nfinalRect:%@\n\n", NSStringFromCGRect(clippingRect), NSStringFromCGRect(self.clipTool.editor.imageViewRect), NSStringFromCGRect(finalRect));
    
    _ltView.center = [self.superview convertPoint:CGPointMake(_clippingRect.origin.x, _clippingRect.origin.y) fromView:self];
    _lbView.center = [self.superview convertPoint:CGPointMake(_clippingRect.origin.x, _clippingRect.origin.y+_clippingRect.size.height) fromView:self];
    _rtView.center = [self.superview convertPoint:CGPointMake(_clippingRect.origin.x+_clippingRect.size.width, _clippingRect.origin.y) fromView:self];
    _rbView.center = [self.superview convertPoint:CGPointMake(_clippingRect.origin.x+_clippingRect.size.width, _clippingRect.origin.y+_clippingRect.size.height) fromView:self];
    
    _leftSpot.center = [self.superview convertPoint:CGPointMake(_clippingRect.origin.x, _clippingRect.origin.y + _clippingRect.size.height / 2) fromView:self];
    _rightSpot.center = [self.superview convertPoint:CGPointMake(_clippingRect.origin.x + _clippingRect.size.width, _clippingRect.origin.y + _clippingRect.size.height / 2) fromView:self];
    _topSpot.center = [self.superview convertPoint:CGPointMake(_clippingRect.origin.x + _clippingRect.size.width / 2, _clippingRect.origin.y) fromView:self];
    _bottomSpot.center = [self.superview convertPoint:CGPointMake(_clippingRect.origin.x + _clippingRect.size.width / 2, _clippingRect.origin.y + _clippingRect.size.height) fromView:self];
    
    _gridLayer.clippingRect = clippingRect;
    [self setNeedsDisplay];
}

- (void)setClippingRect:(CGRect)clippingRect animated:(BOOL)animated
{
    if(animated){
        _ltView.center = [self.superview convertPoint:CGPointMake(clippingRect.origin.x, clippingRect.origin.y) fromView:self];
        _lbView.center = [self.superview convertPoint:CGPointMake(clippingRect.origin.x, clippingRect.origin.y+clippingRect.size.height) fromView:self];
        _rtView.center = [self.superview convertPoint:CGPointMake(clippingRect.origin.x+clippingRect.size.width, clippingRect.origin.y) fromView:self];
        _rbView.center = [self.superview convertPoint:CGPointMake(clippingRect.origin.x+clippingRect.size.width, clippingRect.origin.y+clippingRect.size.height) fromView:self];
        
        CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"clippingRect"];
        animation.duration = kCLImageToolFadeoutDuration;
        animation.fromValue = [NSValue valueWithCGRect:_clippingRect];
        animation.toValue = [NSValue valueWithCGRect:clippingRect];
        [_gridLayer addAnimation:animation forKey:nil];
        
        _gridLayer.clippingRect = clippingRect;
        _clippingRect = clippingRect;
        [self setNeedsDisplay];
    }
    else{
        self.clippingRect = clippingRect;
    }
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];

    _gridLayer.isFingerTouching = NO;
    for (UITouch *touch in touches) {
        CGPoint touchLocation = [touch locationInView:self];
        if (CGRectContainsPoint(_gridLayer.clippingRect, touchLocation)) {
            _gridLayer.isFingerTouching = YES;
            break;
        }
        
        touchLocation = [touch locationInView:_ltView];
        if (CGRectContainsPoint(_ltView.frame, touchLocation)) {
            _gridLayer.isFingerTouching = YES;
            break;
        }

        touchLocation = [touch locationInView:_lbView];
        if (CGRectContainsPoint(_lbView.frame, touchLocation)) {
            _gridLayer.isFingerTouching = YES;
            break;
        }
        
        touchLocation = [touch locationInView:_rtView];
        if (CGRectContainsPoint(_rtView.frame, touchLocation)) {
            _gridLayer.isFingerTouching = YES;
            break;
        }

        touchLocation = [touch locationInView:_rbView];
        if (CGRectContainsPoint(_rbView.frame, touchLocation)) {
            _gridLayer.isFingerTouching = YES;
            break;
        }
    }
    
    [_gridLayer setNeedsDisplay];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesMoved:touches withEvent:event];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesEnded:touches withEvent:event];
    
    _gridLayer.isFingerTouching = NO;
    
    [_gridLayer setNeedsDisplay];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    if ([gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]] && [otherGestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]] && ![gestureRecognizer.view isKindOfClass:[CLClippingPanel class]]) {
        return NO;
    }
    
    return YES;
}

- (void)clippingRatioDidChange
{
    CGRect rect = self.bounds;
    if(self.clippingRatio){
        CGFloat H = rect.size.width * self.clippingRatio.ratio;
        if(H<=rect.size.height){
            rect.size.height = H;
        }
        else{
            rect.size.width *= rect.size.height / H;
        }
        
        rect.origin.x = (self.bounds.size.width - rect.size.width) / 2;
        rect.origin.y = (self.bounds.size.height - rect.size.height) / 2;
    }
    [self setClippingRect:rect animated:YES];
}

- (void)setClippingRatio:(CLRatio *)clippingRatio
{
    if(clippingRatio != _clippingRatio){
        _clippingRatio = clippingRatio;
        [self clippingRatioDidChange];
    }
}

- (void)setNeedsDisplay
{
    [super setNeedsDisplay];
    [_gridLayer setNeedsDisplay];
}

- (void)panBorderSpot:(UIPanGestureRecognizer *)sender
{
    MDLog(@"panBorderSpot: %@", sender);
    
    [self panCircleView:sender];
}

- (void)panCircleView:(UIPanGestureRecognizer*)sender
{
//    MDLog(@"panCircleView: %@", sender);
    
    CGPoint point = [sender locationInView:self];
    CGPoint dp = [sender translationInView:self];
    
    [self panUpdateCircleView:sender.view withPoint:point andDP:dp];
}

- (void)panUpdateCircleView:(UIView *)view withPoint:(CGPoint)point andDP:(CGPoint)dp
{
    CGRect rct = self.clippingRect;
    
    const CGFloat W = self.frame.size.width;
    const CGFloat H = self.frame.size.height;
    CGFloat minX = 0;
    CGFloat minY = 0;
    CGFloat maxX = W;
    CGFloat maxY = H;
    
    CGFloat ratio = (view.tag == 1 || view.tag==2) ? -self.clippingRatio.ratio : self.clippingRatio.ratio;
//    CGFloat ratio = (sender.view.tag == 1 || sender.view.tag==2) ? -self.clippingRatio.ratio : self.clippingRatio.ratio;
    
    switch (view.tag) {
//    switch (sender.view.tag) {
        case CROPCORNER_LEFTTOP: // upper left
        {
            maxX = MAX((rct.origin.x + rct.size.width)  - 0.1 * W, 0.1 * W);
            maxY = MAX((rct.origin.y + rct.size.height) - 0.1 * H, 0.1 * H);
            
            if(ratio!=0){
                CGFloat y0 = rct.origin.y - ratio * rct.origin.x;
                CGFloat x0 = -y0 / ratio;
                minX = MAX(x0, 0);
                minY = MAX(y0, 0);
                
                point.x = MAX(minX, MIN(point.x, maxX));
                point.y = MAX(minY, MIN(point.y, maxY));
                
                if(-dp.x*ratio + dp.y > 0){ point.x = (point.y - y0) / ratio; }
                else{ point.y = point.x * ratio + y0; }
            }
            else{
                point.x = MAX(minX, MIN(point.x, maxX));
                point.y = MAX(minY, MIN(point.y, maxY));
            }
            
            rct.size.width  = rct.size.width  - (point.x - rct.origin.x);
            rct.size.height = rct.size.height - (point.y - rct.origin.y);
            rct.origin.x = point.x;
            rct.origin.y = point.y;
            break;
        }
        case CROPCORNER_LEFTBOTTOM: // lower left
        {
            maxX = MAX((rct.origin.x + rct.size.width)  - 0.1 * W, 0.1 * W);
            minY = MAX(rct.origin.y + 0.1 * H, 0.1 * H);
            
            if(ratio!=0){
                CGFloat y0 = (rct.origin.y + rct.size.height) - ratio* rct.origin.x ;
                CGFloat xh = (H - y0) / ratio;
                minX = MAX(xh, 0);
                maxY = MIN(y0, H);
                
                point.x = MAX(minX, MIN(point.x, maxX));
                point.y = MAX(minY, MIN(point.y, maxY));
                
                if(-dp.x*ratio + dp.y < 0){ point.x = (point.y - y0) / ratio; }
                else{ point.y = point.x * ratio + y0; }
            }
            else{
                point.x = MAX(minX, MIN(point.x, maxX));
                point.y = MAX(minY, MIN(point.y, maxY));
            }
            
            rct.size.width  = rct.size.width  - (point.x - rct.origin.x);
            rct.size.height = point.y - rct.origin.y;
            rct.origin.x = point.x;
            break;
        }
        case CROPCORNER_RIGHTTOP: // upper right
        {
            minX = MAX(rct.origin.x + 0.1 * W, 0.1 * W);
            maxY = MAX((rct.origin.y + rct.size.height) - 0.1 * H, 0.1 * H);
            
            if(ratio!=0){
                CGFloat y0 = rct.origin.y - ratio * (rct.origin.x + rct.size.width);
                CGFloat yw = ratio * W + y0;
                CGFloat x0 = -y0 / ratio;
                maxX = MIN(x0, W);
                minY = MAX(yw, 0);
                
                point.x = MAX(minX, MIN(point.x, maxX));
                point.y = MAX(minY, MIN(point.y, maxY));
                
                if(-dp.x*ratio + dp.y > 0){ point.x = (point.y - y0) / ratio; }
                else{ point.y = point.x * ratio + y0; }
            }
            else{
                point.x = MAX(minX, MIN(point.x, maxX));
                point.y = MAX(minY, MIN(point.y, maxY));
            }
            
            rct.size.width  = point.x - rct.origin.x;
            rct.size.height = rct.size.height - (point.y - rct.origin.y);
            rct.origin.y = point.y;
            break;
        }
        case CROPCORNER_RIGHTBOTTOM: // lower right
        {
            minX = MAX(rct.origin.x + 0.1 * W, 0.1 * W);
            minY = MAX(rct.origin.y + 0.1 * H, 0.1 * H);
            
            if(ratio!=0){
                CGFloat y0 = (rct.origin.y + rct.size.height) - ratio * (rct.origin.x + rct.size.width);
                CGFloat yw = ratio * W + y0;
                CGFloat xh = (H - y0) / ratio;
                maxX = MIN(xh, W);
                maxY = MIN(yw, H);
                
                point.x = MAX(minX, MIN(point.x, maxX));
                point.y = MAX(minY, MIN(point.y, maxY));
                
                if(-dp.x*ratio + dp.y < 0){ point.x = (point.y - y0) / ratio; }
                else{ point.y = point.x * ratio + y0; }
            }
            else{
                point.x = MAX(minX, MIN(point.x, maxX));
                point.y = MAX(minY, MIN(point.y, maxY));
            }
            
            rct.size.width  = point.x - rct.origin.x;
            rct.size.height = point.y - rct.origin.y;
            break;
        }
        case CROP_BORDER_LEFT:  // Border left
        {
            maxX = MAX((rct.origin.x + rct.size.width)  - 0.1 * W, 0.1 * W);
            
            if(ratio!=0){
                CGFloat y0 = rct.origin.y - ratio * rct.origin.x;
                CGFloat x0 = -y0 / ratio;
                minX = MAX(x0, 0);
                
                point.x = MAX(minX, MIN(point.x, maxX));
                
                if(-dp.x*ratio + dp.y > 0){ point.x = (point.y - y0) / ratio; }
                else{ point.y = point.x * ratio + y0; }
            }
            else{
                point.x = MAX(minX, MIN(point.x, maxX));
            }
            
            rct.size.width  = rct.size.width  - (point.x - rct.origin.x);
            rct.origin.x = point.x;
            break;
        }
        case CROP_BORDER_RIGHT: // Border right
        {
            minX = MAX(rct.origin.x + 0.1 * W, 0.1 * W);
            
            if(ratio!=0){
                CGFloat y0 = (rct.origin.y + rct.size.height) - ratio * (rct.origin.x + rct.size.width);
                CGFloat xh = (H - y0) / ratio;
                maxX = MIN(xh, W);
                
                point.x = MAX(minX, MIN(point.x, maxX));
                
                if(-dp.x*ratio + dp.y < 0){ point.x = (point.y - y0) / ratio; }
                else{ point.y = point.x * ratio + y0; }
            }
            else{
                point.x = MAX(minX, MIN(point.x, maxX));
            }
            
            rct.size.width  = point.x - rct.origin.x;
            break;
        }
        case CROP_BORDER_TOP:   // Border top
        {
            maxY = MAX((rct.origin.y + rct.size.height) - 0.1 * H, 0.1 * H);
            
            if(ratio!=0){
                CGFloat y0 = rct.origin.y - ratio * rct.origin.x;
                minY = MAX(y0, 0);
                
                point.y = MAX(minY, MIN(point.y, maxY));
                
                if(-dp.x*ratio + dp.y > 0){ point.x = (point.y - y0) / ratio; }
                else{ point.y = point.x * ratio + y0; }
            }
            else{
                point.y = MAX(minY, MIN(point.y, maxY));
            }
            
            rct.size.height = rct.size.height - (point.y - rct.origin.y);
            rct.origin.y = point.y;
            break;
        }
        case CROP_BORDER_BOTTOM:    // Border bottom
        {
            minY = MAX(rct.origin.y + 0.1 * H, 0.1 * H);
            
            if(ratio!=0){
                CGFloat y0 = (rct.origin.y + rct.size.height) - ratio * (rct.origin.x + rct.size.width);
                CGFloat yw = ratio * W + y0;
                maxY = MIN(yw, H);
                
                point.y = MAX(minY, MIN(point.y, maxY));
                
                if(-dp.x*ratio + dp.y < 0){ point.x = (point.y - y0) / ratio; }
                else{ point.y = point.x * ratio + y0; }
            }
            else{
                point.y = MAX(minY, MIN(point.y, maxY));
            }
            
            rct.size.height = point.y - rct.origin.y;
            break;
        }
        default:
            break;
    }
    self.clippingRect = rct;
}

- (void)panGridView:(UIPanGestureRecognizer*)sender
{
    static BOOL dragging = NO;
    static CGRect initialRect;
    
    if ([sender.view isEqual:_ltView] || [sender.view isEqual:_rtView] || [sender.view isEqual:_lbView] || [sender.view isEqual:_rbView]) {
        MDLog(@"panGridView: touch corner");
    }
    else {
        if(sender.state==UIGestureRecognizerStateBegan){
            CGPoint point = [sender locationInView:self];
            dragging = CGRectContainsPoint(_clippingRect, point);
            initialRect = self.clippingRect;
        }
        else if(dragging){
            CGPoint point = [sender translationInView:self];
            CGFloat left  = MIN(MAX(initialRect.origin.x + point.x, 0), self.frame.size.width-initialRect.size.width);
            CGFloat top   = MIN(MAX(initialRect.origin.y + point.y, 0), self.frame.size.height-initialRect.size.height);
            
            CGRect rct = self.clippingRect;
            rct.origin.x = left;
            rct.origin.y = top;
            self.clippingRect = rct;
        }
    }
}
@end




@implementation CLRatio
{
    NSInteger _longSide;
    NSInteger _shortSide;
}

- (id)initWithValue1:(NSInteger)value1 value2:(NSInteger)value2
{
    self = [super init];
    if(self){
        _longSide  = MAX(labs(value1), labs(value2));
        _shortSide = MIN(labs(value1), labs(value2));
    }
    return self;
}

- (NSString*)description
{
    if(_longSide==0 || _shortSide==0){
        return @"Custom";
    }
    
    if(self.isLandscape){
        return [NSString stringWithFormat:@"%ld : %ld", (long)_longSide, (long)_shortSide];
    }
    return [NSString stringWithFormat:@"%ld : %ld", (long)_shortSide, (long)_longSide];
}

- (CGFloat)ratio
{
    if(_longSide==0 || _shortSide==0){
        return 0;
    }
    
    if(self.isLandscape){
        return _shortSide / (CGFloat)_longSide;
    }
    return _longSide / (CGFloat)_shortSide;
}

@end


@implementation CLRatioMenuItem
{
    UIImageView *_iconView;
    UILabel *_titleLabel;
}

- (id)initWithFrame:(CGRect)frame iconImage:(UIImage *)iconImage
{
    self = [super initWithFrame:frame];
    if(self){
        _iconView = [[UIImageView alloc] initWithFrame:CGRectMake(10, 5, 50, 50)];
        _iconView.backgroundColor = [UIColor colorWithWhite:0 alpha:1];
        _iconView.image = iconImage;
        _iconView.clipsToBounds = YES;
        _iconView.contentMode = UIViewContentModeScaleAspectFill;
        _iconView.layer.cornerRadius = 3;
        [self addSubview:_iconView];
        
        _titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, frame.size.width-10, frame.size.width, 15)];
        _titleLabel.backgroundColor = [UIColor clearColor];
        _titleLabel.font = [UIFont systemFontOfSize:10];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        [self addSubview:_titleLabel];
    }
    return self;
}

- (void)setRatio:(CLRatio *)ratio
{
    if(ratio != _ratio){
        _ratio = ratio;
        [self refreshViews];
    }
}

- (void)refreshViews
{
    _titleLabel.text = [_ratio description];
    
    CGPoint center = _iconView.center;
    CGFloat W, H;
    if(_ratio.ratio!=0){
        if(_ratio.isLandscape){
            W = 50;
            H = 50*_ratio.ratio;
        }
        else{
            W = 50/_ratio.ratio;
            H = 50;
        }
    }
    else{
        CGFloat maxW  = MAX(_iconView.image.size.width, _iconView.image.size.height);
        W = 50 * _iconView.image.size.width / maxW;
        H = 50 * _iconView.image.size.height / maxW;
    }
    _iconView.frame = CGRectMake(center.x-W/2, center.y-H/2, W, H);
}

- (void)changeOrientation
{
    self.ratio.isLandscape = !self.ratio.isLandscape;
    
    [UIView animateWithDuration:kCLImageToolFadeoutDuration
                     animations:^{
                         [self refreshViews];
                     }
     ];
}

@end
