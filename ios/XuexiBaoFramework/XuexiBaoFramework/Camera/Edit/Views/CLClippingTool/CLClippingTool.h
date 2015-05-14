//
//  CLClippingTool.h
//
//  Created by sho yakushiji on 2013/10/18.
//  Copyright (c) 2013年 CALACULU. All rights reserved.
//

#import "CLImageToolBase.h"



@interface CLRatio : NSObject
@property (nonatomic, assign) BOOL isLandscape;
@property (nonatomic, readonly) CGFloat ratio;
- (id)initWithValue1:(NSInteger)value1 value2:(NSInteger)value2;
- (NSString*)description;
@end



@interface CLRatioMenuItem : UIView
@property (nonatomic, strong) CLRatio *ratio;
- (id)initWithFrame:(CGRect)frame iconImage:(UIImage*)iconImage;
- (void)changeOrientation;
@end



@class CLClippingCircle;
@class CLBorderMovingSpot;
@class CLClippingTool;


@interface CLClippingPanel : UIView <UIGestureRecognizerDelegate>

@property (nonatomic, assign) CLClippingTool *clipTool;

@property (nonatomic, assign) CGRect clippingRect;
@property (nonatomic, strong) CLRatio *clippingRatio;

// 四角移动点
@property (nonatomic, strong) CLClippingCircle *ltView;
@property (nonatomic, strong) CLClippingCircle *lbView;
@property (nonatomic, strong) CLClippingCircle *rtView;
@property (nonatomic, strong) CLClippingCircle *rbView;

// 边线移动点
@property (nonatomic, strong) CLBorderMovingSpot *leftSpot;
@property (nonatomic, strong) CLBorderMovingSpot *rightSpot;
@property (nonatomic, strong) CLBorderMovingSpot *topSpot;
@property (nonatomic, strong) CLBorderMovingSpot *bottomSpot;

- (id)initWithSuperview:(UIView*)superview frame:(CGRect)frame;
- (void)setBgColor:(UIColor*)bgColor;
- (void)setGridColor:(UIColor*)gridColor;
- (void)clippingRatioDidChange;
- (void)panUpdateCircleView:(UIView *)view withPoint:(CGPoint)point andDP:(CGPoint)dp;

- (void)panGridView:(UIPanGestureRecognizer*)sender;

@end



@interface CLBorderMovingSpot : UIView

@property (nonatomic, strong) UIColor *bgColor;

@end



@interface CLClippingCircle : UIView

@property (nonatomic, strong) UIColor *bgColor;
@property (nonatomic, assign) CLClippingPanel *panel;

@end



@interface CLClippingTool : CLImageToolBase

@end
