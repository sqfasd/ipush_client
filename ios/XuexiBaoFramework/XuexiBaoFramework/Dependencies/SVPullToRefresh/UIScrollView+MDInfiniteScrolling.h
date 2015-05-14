//
// UIScrollView+MDInfiniteScrolling.h
//
// Created by Sam Vermette on 23.04.12.
// Copyright (c) 2012 samvermette.com. All rights reserved.
//
// https://github.com/samvermette/SVPullToRefresh
//

#import <UIKit/UIKit.h>

@class MDInfiniteScrollingView;

@interface UIScrollView (SVInfiniteScrolling)

- (void)addInfiniteScrollingWithActionHandler:(void (^)(void))actionHandler;
- (void)triggerInfiniteScrolling;

@property (nonatomic, strong, readonly) MDInfiniteScrollingView *infiniteScrollingView;
@property (nonatomic, assign) BOOL showsInfiniteScrolling;

@end


enum {
	MDInfiniteScrollingStateStopped = 0,
    MDInfiniteScrollingStateTriggered,
    MDInfiniteScrollingStateLoading,
    MDInfiniteScrollingStateAll = 10
};

typedef NSUInteger MDInfiniteScrollingState;

@interface MDInfiniteScrollingView : UIView

@property (nonatomic, readwrite) UIActivityIndicatorViewStyle activityIndicatorViewStyle;
@property (nonatomic, readonly) MDInfiniteScrollingState state;
@property (nonatomic, readwrite) BOOL enabled;

@property (nonatomic, strong) NSArray *pullImages;

- (void)setCustomView:(UIView *)view forState:(MDInfiniteScrollingState)state;

- (void)startAnimating;
- (void)stopAnimating;

@end
