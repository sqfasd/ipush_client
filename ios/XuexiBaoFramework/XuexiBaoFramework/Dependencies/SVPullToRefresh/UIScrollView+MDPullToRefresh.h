//
// UIScrollView+MDPullToRefresh.h
//
// Created by Sam Vermette on 23.04.12.
// Copyright (c) 2012 samvermette.com. All rights reserved.
//
// https://github.com/samvermette/MDPullToRefresh
//

#import <UIKit/UIKit.h>
#import <AvailabilityMacros.h>


@class MDPullToRefreshView;

@interface UIScrollView (MDPullToRefresh)

typedef NS_ENUM(NSUInteger, MDPullToRefreshPosition) {
    MDPullToRefreshPositionTop = 0,
    MDPullToRefreshPositionBottom,
};

- (void)addPullToRefreshWithActionHandler:(void (^)(void))actionHandler;
- (void)addPullToRefreshWithActionHandler:(void (^)(void))actionHandler position:(MDPullToRefreshPosition)position;
- (void)triggerPullToRefresh;

- (void)setOriginalTopInset:(float)topInset;

@property (nonatomic, strong, readonly) MDPullToRefreshView *pullToRefreshView;
@property (nonatomic, assign) BOOL showsPullToRefresh;

@end


typedef NS_ENUM(NSUInteger, MDPullToRefreshState) {
    MDPullToRefreshStateStopped = 0,
    MDPullToRefreshStateTriggered,
    MDPullToRefreshStateLoading,
    MDPullToRefreshStateAll = 10
};

@interface MDPullToRefreshView : UIView

@property (nonatomic, strong) UIColor *arrowColor;
@property (nonatomic, strong) UIColor *textColor;
@property (nonatomic, strong, readonly) UILabel *titleLabel;
@property (nonatomic, strong, readonly) UILabel *subtitleLabel;
@property (nonatomic, strong, readwrite) UIColor *activityIndicatorViewColor NS_AVAILABLE_IOS(5_0);
@property (nonatomic, readwrite) UIActivityIndicatorViewStyle activityIndicatorViewStyle;

@property (nonatomic, readonly) MDPullToRefreshState state;
@property (nonatomic, readonly) MDPullToRefreshPosition position;

@property (nonatomic, strong) NSArray *pullImages;
@property (nonatomic, strong) NSArray *loadingImages;

- (void)setTitle:(NSString *)title forState:(MDPullToRefreshState)state;
- (void)setSubtitle:(NSString *)subtitle forState:(MDPullToRefreshState)state;
- (void)setCustomView:(UIView *)view forState:(MDPullToRefreshState)state;

- (void)startAnimating;
- (void)stopAnimating;

// deprecated; use setSubtitle:forState: instead
@property (nonatomic, strong, readonly) UILabel *dateLabel DEPRECATED_ATTRIBUTE;
@property (nonatomic, strong) NSDate *lastUpdatedDate DEPRECATED_ATTRIBUTE;
@property (nonatomic, strong) NSDateFormatter *dateFormatter DEPRECATED_ATTRIBUTE;

// deprecated; use [self.scrollView triggerPullToRefresh] instead
- (void)triggerRefresh DEPRECATED_ATTRIBUTE;

@end
