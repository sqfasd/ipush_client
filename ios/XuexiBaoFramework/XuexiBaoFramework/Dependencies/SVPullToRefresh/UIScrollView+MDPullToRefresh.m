//
// UIScrollView+MDPullToRefresh.m
//
// Created by Sam Vermette on 23.04.12.
// Copyright (c) 2012 samvermette.com. All rights reserved.
//
// https://github.com/samvermette/MDPullToRefresh
//

#import <QuartzCore/QuartzCore.h>
#import "UIScrollView+MDPullToRefresh.h"

//fequal() and fequalzro() from http://stackoverflow.com/a/1614761/184130
#define fequal(a,b) (fabs((a) - (b)) < FLT_EPSILON)
#define fequalzero(a) (fabs(a) < FLT_EPSILON)

static CGFloat const MDPullToRefreshViewHeight = 60;

@interface MDPullToRefreshArrow : UIView

@property (nonatomic, strong) UIColor *arrowColor;

@end

//@interface MDPullToRefreshArrow : UIView
//
//@property (nonatomic, strong) UIColor *arrowColor;
//@property (nonatomic, strong) UIImage *arrowImg;
//@end


@interface MDPullToRefreshView ()

@property (nonatomic, copy) void (^pullToRefreshActionHandler)(void);

//@property (nonatomic, strong) MDPullToRefreshArrow *arrow;
@property (nonatomic, strong) UIImageView *picShowImgV;
//@property (nonatomic, strong) UIActivityIndicatorView *activityIndicatorView;
@property (nonatomic, strong, readwrite) UILabel *titleLabel;
@property (nonatomic, strong, readwrite) UILabel *subtitleLabel;
@property (nonatomic, readwrite) MDPullToRefreshState state;
@property (nonatomic, readwrite) MDPullToRefreshPosition position;

@property (nonatomic, strong) NSMutableArray *titles;
@property (nonatomic, strong) NSMutableArray *subtitles;
@property (nonatomic, strong) NSMutableArray *viewForState;

@property (nonatomic, weak) UIScrollView *scrollView;
@property (nonatomic, readwrite) CGFloat originalTopInset;
@property (nonatomic, readwrite) CGFloat originalBottomInset;

@property (nonatomic, assign) BOOL wasTriggeredByUser;
@property (nonatomic, assign) BOOL showsPullToRefresh;
@property (nonatomic, assign) BOOL showsDateLabel;
@property(nonatomic, assign) BOOL isObserving;

- (void)resetScrollViewContentInset;
- (void)setScrollViewContentInsetForLoading;
- (void)setScrollViewContentInset:(UIEdgeInsets)insets;
//- (void)rotateArrow:(float)degrees hide:(BOOL)hide;

@end



#pragma mark - UIScrollView (MDPullToRefresh)
#import <objc/runtime.h>

static char UIScrollViewPullToRefreshView;

@implementation UIScrollView (MDPullToRefresh)

@dynamic pullToRefreshView, showsPullToRefresh;

- (void)addPullToRefreshWithActionHandler:(void (^)(void))actionHandler position:(MDPullToRefreshPosition)position {
    
    if(!self.pullToRefreshView) {
        CGFloat yOrigin;
        switch (position) {
            case MDPullToRefreshPositionTop:
                yOrigin = -MDPullToRefreshViewHeight;
                break;
            case MDPullToRefreshPositionBottom:
                yOrigin = self.contentSize.height;
                break;
            default:
                return;
        }
        MDPullToRefreshView *view = [[MDPullToRefreshView alloc] initWithFrame:CGRectMake(0, yOrigin, self.bounds.size.width, MDPullToRefreshViewHeight)];
        view.pullToRefreshActionHandler = actionHandler;
        view.scrollView = self;
        [self addSubview:view];
        
        view.originalTopInset = self.contentInset.top;
        view.originalBottomInset = self.contentInset.bottom;
        view.position = position;
        self.pullToRefreshView = view;
        self.showsPullToRefresh = YES;
    }
    
}

- (void)addPullToRefreshWithActionHandler:(void (^)(void))actionHandler {
    [self addPullToRefreshWithActionHandler:actionHandler position:MDPullToRefreshPositionTop];
}

- (void)triggerPullToRefresh {
    self.pullToRefreshView.state = MDPullToRefreshStateTriggered;
    [self.pullToRefreshView startAnimating];
}

- (void)setPullToRefreshView:(MDPullToRefreshView *)pullToRefreshView {
    [self willChangeValueForKey:@"MDPullToRefreshView"];
    objc_setAssociatedObject(self, &UIScrollViewPullToRefreshView,
                             pullToRefreshView,
                             OBJC_ASSOCIATION_ASSIGN);
    [self didChangeValueForKey:@"MDPullToRefreshView"];
}

- (MDPullToRefreshView *)pullToRefreshView {
    return objc_getAssociatedObject(self, &UIScrollViewPullToRefreshView);
}

- (void)setOriginalTopInset:(float)topInset
{
    self.pullToRefreshView.originalTopInset = topInset;
}

- (void)setShowsPullToRefresh:(BOOL)showsPullToRefresh {
    self.pullToRefreshView.hidden = !showsPullToRefresh;
    
    if(!showsPullToRefresh) {
        if (self.pullToRefreshView.isObserving) {
            [self removeObserver:self.pullToRefreshView forKeyPath:@"contentOffset"];
            [self removeObserver:self.pullToRefreshView forKeyPath:@"contentSize"];
            [self removeObserver:self.pullToRefreshView forKeyPath:@"frame"];
            [self.pullToRefreshView resetScrollViewContentInset];
            self.pullToRefreshView.isObserving = NO;
        }
    }
    else {
        if (!self.pullToRefreshView.isObserving) {
            [self addObserver:self.pullToRefreshView forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew context:nil];
            [self addObserver:self.pullToRefreshView forKeyPath:@"contentSize" options:NSKeyValueObservingOptionNew context:nil];
            [self addObserver:self.pullToRefreshView forKeyPath:@"frame" options:NSKeyValueObservingOptionNew context:nil];
            self.pullToRefreshView.isObserving = YES;
            
            CGFloat yOrigin = 0;
            switch (self.pullToRefreshView.position) {
                case MDPullToRefreshPositionTop:
                    yOrigin = -MDPullToRefreshViewHeight;
                    break;
                case MDPullToRefreshPositionBottom:
                    yOrigin = self.contentSize.height;
                    break;
            }
            
            self.pullToRefreshView.frame = CGRectMake(0, yOrigin, self.bounds.size.width, MDPullToRefreshViewHeight);
        }
    }
}

- (BOOL)showsPullToRefresh {
    return !self.pullToRefreshView.hidden;
}

@end




#pragma mark - MDPullToRefresh
@implementation MDPullToRefreshView

// public properties
@synthesize pullToRefreshActionHandler, arrowColor, textColor, activityIndicatorViewColor, activityIndicatorViewStyle, lastUpdatedDate, dateFormatter;

@synthesize state = _state;
@synthesize scrollView = _scrollView;
@synthesize showsPullToRefresh = _showsPullToRefresh;
//@synthesize arrow = _arrow;
//@synthesize activityIndicatorView = _activityIndicatorView;

@synthesize titleLabel = _titleLabel;
@synthesize dateLabel = _dateLabel;

@synthesize pullImages = _pullImages;
@synthesize loadingImages = _loadingImages;

- (id)initWithFrame:(CGRect)frame {
    if(self = [super initWithFrame:frame]) {
        
        // default styling values
        self.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
        self.textColor = [UIColor darkGrayColor];
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        self.state = MDPullToRefreshStateStopped;
        self.showsDateLabel = NO;
        
        self.titles = [NSMutableArray arrayWithObjects:NSLocalizedString(@"下拉刷新…",),
                             NSLocalizedString(@"松开更新…",),
                             NSLocalizedString(@"加载中...",),
                                nil];
        
        self.subtitles = [NSMutableArray arrayWithObjects:@"", @"", @"", @"", nil];
        self.viewForState = [NSMutableArray arrayWithObjects:@"", @"", @"", @"", nil];
        self.wasTriggeredByUser = YES;
        
        self.pullImages = [NSArray arrayWithObjects:
                           [UIImage imageNamed:XXBRSRC_NAME(@"pulltorefresh_pull_1")],
                           [UIImage imageNamed:XXBRSRC_NAME(@"pulltorefresh_pull_2")],
                           [UIImage imageNamed:XXBRSRC_NAME(@"pulltorefresh_pull_3")],
                           [UIImage imageNamed:XXBRSRC_NAME(@"pulltorefresh_pull_4")],
                           [UIImage imageNamed:XXBRSRC_NAME(@"pulltorefresh_pull_5")],
                           nil];
        
        self.loadingImages = [NSArray arrayWithObjects:
                              [UIImage imageNamed:XXBRSRC_NAME(@"pulltorefresh_loading_1")],
                              [UIImage imageNamed:XXBRSRC_NAME(@"pulltorefresh_loading_1")],
                              [UIImage imageNamed:XXBRSRC_NAME(@"pulltorefresh_loading_1")],
                              [UIImage imageNamed:XXBRSRC_NAME(@"pulltorefresh_loading_2")],
                              [UIImage imageNamed:XXBRSRC_NAME(@"pulltorefresh_loading_2")],
                              [UIImage imageNamed:XXBRSRC_NAME(@"pulltorefresh_loading_2")],
                              [UIImage imageNamed:XXBRSRC_NAME(@"pulltorefresh_loading_3")],
                              [UIImage imageNamed:XXBRSRC_NAME(@"pulltorefresh_loading_3")],
                              [UIImage imageNamed:XXBRSRC_NAME(@"pulltorefresh_loading_3")],
                              nil];
    }
    
    return self;
}

- (void)willMoveToSuperview:(UIView *)newSuperview {
    if (self.superview && newSuperview == nil) {
        //use self.superview, not self.scrollView. Why self.scrollView == nil here?
        UIScrollView *scrollView = (UIScrollView *)self.superview;
        if (scrollView.showsPullToRefresh) {
            if (self.isObserving) {
                //If enter this branch, it is the moment just before "MDPullToRefreshView's dealloc", so remove observer here
                [scrollView removeObserver:self forKeyPath:@"contentOffset"];
                [scrollView removeObserver:self forKeyPath:@"contentSize"];
                [scrollView removeObserver:self forKeyPath:@"frame"];
                self.isObserving = NO;
            }
        }
    }
}

- (void)layoutSubviews {
    
    for(id otherView in self.viewForState) {
        if([otherView isKindOfClass:[UIView class]])
            [otherView removeFromSuperview];
    }
    
    id customView = [self.viewForState objectAtIndex:self.state];
    BOOL hasCustomView = [customView isKindOfClass:[UIView class]];
    
    self.titleLabel.hidden = hasCustomView;
    self.subtitleLabel.hidden = hasCustomView;
    self.picShowImgV.hidden = hasCustomView;
//    self.arrow.hidden = hasCustomView;
    
    if(hasCustomView) {
        [self addSubview:customView];
        CGRect viewBounds = [customView bounds];
        CGPoint origin = CGPointMake(roundf((self.bounds.size.width-viewBounds.size.width)/2), roundf((self.bounds.size.height-viewBounds.size.height)/2));
        [customView setFrame:CGRectMake(origin.x, origin.y, viewBounds.size.width, viewBounds.size.height)];
    }
    else {
        switch (self.state) {
            case MDPullToRefreshStateAll:
            case MDPullToRefreshStateStopped:
                self.picShowImgV.alpha = 1;
//                self.arrow.alpha = 1;
                
//                [self.activityIndicatorView stopAnimating];
                
                switch (self.position) {
                    case MDPullToRefreshPositionTop:
//                        [self rotateArrow:0 hide:NO];
                        break;
                    case MDPullToRefreshPositionBottom:
//                        [self rotateArrow:(float)M_PI hide:NO];
                        break;
                }
                break;
                
            case MDPullToRefreshStateTriggered:
                switch (self.position) {
                    case MDPullToRefreshPositionTop:
//                        [self rotateArrow:(float)M_PI hide:NO];
                        break;
                    case MDPullToRefreshPositionBottom:
//                        [self rotateArrow:0 hide:NO];
                        break;
                }
                break;
                
            case MDPullToRefreshStateLoading:
//                [self.activityIndicatorView startAnimating];
                switch (self.position) {
                    case MDPullToRefreshPositionTop:
//                        [self rotateArrow:0 hide:YES];
                        break;
                    case MDPullToRefreshPositionBottom:
//                        [self rotateArrow:(float)M_PI hide:YES];
                        break;
                }
                break;
        }
        
        CGFloat leftViewWidth = self.picShowImgV.bounds.size.width; //MAX(self.picShowImgV.bounds.size.width,self.activityIndicatorView.bounds.size.width);
//        CGFloat leftViewWidth = MAX(self.arrow.bounds.size.width,self.activityIndicatorView.bounds.size.width);
        
        CGFloat margin = 10;
        CGFloat marginY = 2;
        CGFloat labelMaxWidth = self.bounds.size.width - margin - leftViewWidth;
        
        self.titleLabel.text = [self.titles objectAtIndex:self.state];
        
        NSString *subtitle = [self.subtitles objectAtIndex:self.state];
        self.subtitleLabel.text = subtitle.length > 0 ? subtitle : nil;
        
        
        CGSize titleSize = textSizeForTextWithConstrain(self.titleLabel.text, self.titleLabel.font, CGSizeMake(labelMaxWidth,self.titleLabel.font.lineHeight));
//        CGSize titleSize = [self.titleLabel.text sizeWithFont:self.titleLabel.font
//                                            constrainedToSize:CGSizeMake(labelMaxWidth,self.titleLabel.font.lineHeight)
//                                                lineBreakMode:self.titleLabel.lineBreakMode];
        
  
        CGSize subtitleSize = textSizeForTextWithConstrain(self.subtitleLabel.text, self.subtitleLabel.font, CGSizeMake(labelMaxWidth,self.subtitleLabel.font.lineHeight));
//        CGSize subtitleSize = [self.subtitleLabel.text sizeWithFont:self.subtitleLabel.font
//                                                  constrainedToSize:CGSizeMake(labelMaxWidth,self.subtitleLabel.font.lineHeight)
//                                                      lineBreakMode:self.subtitleLabel.lineBreakMode];
        
        
        CGFloat maxLabelWidth = MAX(titleSize.width,subtitleSize.width);
        
        CGFloat totalMaxWidth;
        if (maxLabelWidth) {
        	totalMaxWidth = leftViewWidth + margin + maxLabelWidth;
        } else {
        	totalMaxWidth = leftViewWidth + maxLabelWidth;
        }
        
        CGFloat labelX = (self.bounds.size.width / 2) - (totalMaxWidth / 2) + leftViewWidth - 20; // + margin;
        
        if(subtitleSize.height > 0){
            CGFloat totalHeight = titleSize.height + subtitleSize.height + marginY;
            CGFloat minY = (self.bounds.size.height / 2)  - (totalHeight / 2);
            
            CGFloat titleY = minY;
            self.titleLabel.frame = CGRectIntegral(CGRectMake(labelX, titleY, titleSize.width, titleSize.height));
            self.subtitleLabel.frame = CGRectIntegral(CGRectMake(labelX, titleY + titleSize.height + marginY, subtitleSize.width, subtitleSize.height));
        }else{
            CGFloat totalHeight = titleSize.height;
            CGFloat minY = (self.bounds.size.height / 2)  - (totalHeight / 2);
            
            CGFloat titleY = minY;
            self.titleLabel.frame = CGRectIntegral(CGRectMake(labelX, titleY, titleSize.width, titleSize.height));
            self.subtitleLabel.frame = CGRectIntegral(CGRectMake(labelX, titleY + titleSize.height + marginY, subtitleSize.width, subtitleSize.height));
        }
        
//        CGFloat arrowX = (self.bounds.size.width / 2) - (totalMaxWidth / 2) + (leftViewWidth - self.arrow.bounds.size.width) / 2;
//        self.arrow.frame = CGRectMake(arrowX,
//                                      (self.bounds.size.height / 2) - (self.arrow.bounds.size.height / 2),
//                                      self.arrow.bounds.size.width,
//                                      self.arrow.bounds.size.height);
//        self.activityIndicatorView.center = self.arrow.center;
//        self.activityIndicatorView.center = self.picShowImgV.center;
    }
}

#pragma mark - Scroll View

- (void)resetScrollViewContentInset {
    UIEdgeInsets currentInsets = self.scrollView.contentInset;
    switch (self.position) {
        case MDPullToRefreshPositionTop:
            currentInsets.top = self.originalTopInset;
            break;
        case MDPullToRefreshPositionBottom:
            currentInsets.bottom = self.originalBottomInset;
            currentInsets.top = self.originalTopInset;
            break;
    }
    [self setScrollViewContentInset:currentInsets];
}

- (void)setScrollViewContentInsetForLoading {
    CGFloat offset = MAX(self.scrollView.contentOffset.y * -1, 0);
    UIEdgeInsets currentInsets = self.scrollView.contentInset;
    switch (self.position) {
        case MDPullToRefreshPositionTop:
            currentInsets.top = MIN(offset, self.originalTopInset + self.bounds.size.height);
            break;
        case MDPullToRefreshPositionBottom:
            currentInsets.bottom = MIN(offset, self.originalBottomInset + self.bounds.size.height);
            break;
    }
    [self setScrollViewContentInset:currentInsets];
}

- (void)setScrollViewContentInset:(UIEdgeInsets)contentInset {
    [UIView animateWithDuration:0.3
                          delay:0
                        options:UIViewAnimationOptionAllowUserInteraction|UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         self.scrollView.contentInset = contentInset;
                     }
                     completion:NULL];
}

#pragma mark - Observing

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if([keyPath isEqualToString:@"contentOffset"])
        [self scrollViewDidScroll:[[change valueForKey:NSKeyValueChangeNewKey] CGPointValue]];
    else if([keyPath isEqualToString:@"contentSize"]) {
        [self layoutSubviews];
        
        CGFloat yOrigin;
        switch (self.position) {
            case MDPullToRefreshPositionTop:
                yOrigin = -MDPullToRefreshViewHeight;
                break;
            case MDPullToRefreshPositionBottom:
                yOrigin = MAX(self.scrollView.contentSize.height, self.scrollView.bounds.size.height);
                break;
        }
        self.frame = CGRectMake(0, yOrigin, self.bounds.size.width, MDPullToRefreshViewHeight);
    }
    else if([keyPath isEqualToString:@"frame"])
        [self layoutSubviews];

}

- (void)scrollViewDidScroll:(CGPoint)contentOffset {
    static NSUInteger currentPullIndex = 0;
    static BOOL hasShowLoadingImgs = NO;
    
    if(self.state != MDPullToRefreshStateLoading) {
        CGFloat scrollOffsetThreshold = 0;
        switch (self.position) {
            case MDPullToRefreshPositionTop:
                scrollOffsetThreshold = self.frame.origin.y - self.originalTopInset;
                break;
            case MDPullToRefreshPositionBottom:
                scrollOffsetThreshold = MAX(self.scrollView.contentSize.height - self.scrollView.bounds.size.height, 0.0f) + self.bounds.size.height + self.originalBottomInset;
                break;
        }
        
//        MDLog(@"PullToRefresh setState: %lu\ncontentOffset: %f\nscrollThreshold: %f", self.state, contentOffset.y, scrollOffsetThreshold);
        CGFloat percent = 0;
        NSUInteger imgIndex = 0;
        if (self.state == MDPullToRefreshStateStopped) {
            if (contentOffset.y <= 0 && contentOffset.y >= scrollOffsetThreshold) {
                percent = fabs(contentOffset.y / scrollOffsetThreshold);
            }
            else {
                percent = 1;
            }
            imgIndex = percent * (self.pullImages.count - 1);
            
            if (imgIndex != currentPullIndex) {
                MDLog(@"picShowImgV stopAnimating");
                [self.picShowImgV stopAnimating];
                hasShowLoadingImgs = NO;

                self.picShowImgV.image = self.pullImages[imgIndex];
                currentPullIndex = imgIndex;
            }
        }
        else if (self.state == MDPullToRefreshStateLoading) {
            MDLog(@"state: %lu", self.state);
        }
        else {
            MDLog(@"state: %lu", self.state);
        }

        if(!self.scrollView.isDragging && self.state == MDPullToRefreshStateTriggered) {
            self.state = MDPullToRefreshStateLoading;

            if (!hasShowLoadingImgs) {
                hasShowLoadingImgs = YES;
                
                self.picShowImgV.animationImages = self.loadingImages;
                self.picShowImgV.animationDuration = 1.5;
                
                MDLog(@"picShowImgV startAnimating");
                [self.picShowImgV startAnimating];
            }
        }
        else if(contentOffset.y < scrollOffsetThreshold && self.scrollView.isDragging && self.state == MDPullToRefreshStateStopped && self.position == MDPullToRefreshPositionTop)
            self.state = MDPullToRefreshStateTriggered;
        else if(contentOffset.y >= scrollOffsetThreshold && self.state != MDPullToRefreshStateStopped && self.position == MDPullToRefreshPositionTop)
            self.state = MDPullToRefreshStateStopped;
        else if(contentOffset.y > scrollOffsetThreshold && self.scrollView.isDragging && self.state == MDPullToRefreshStateStopped && self.position == MDPullToRefreshPositionBottom)
            self.state = MDPullToRefreshStateTriggered;
        else if(contentOffset.y <= scrollOffsetThreshold && self.state != MDPullToRefreshStateStopped && self.position == MDPullToRefreshPositionBottom)
            self.state = MDPullToRefreshStateStopped;
    } else {
        CGFloat offset;
        UIEdgeInsets contentInset;
        switch (self.position) {
            case MDPullToRefreshPositionTop:
                offset = MAX(self.scrollView.contentOffset.y * -1, 0.0f);
                offset = MIN(offset, self.originalTopInset + self.bounds.size.height);
                contentInset = self.scrollView.contentInset;
                self.scrollView.contentInset = UIEdgeInsetsMake(offset, contentInset.left, contentInset.bottom, contentInset.right);
                break;
            case MDPullToRefreshPositionBottom:
                if (self.scrollView.contentSize.height >= self.scrollView.bounds.size.height) {
                    offset = MAX(self.scrollView.contentSize.height - self.scrollView.bounds.size.height + self.bounds.size.height, 0.0f);
                    offset = MIN(offset, self.originalBottomInset + self.bounds.size.height);
                    contentInset = self.scrollView.contentInset;
                    self.scrollView.contentInset = UIEdgeInsetsMake(contentInset.top, contentInset.left, offset, contentInset.right);
                } else if (self.wasTriggeredByUser) {
                    offset = MIN(self.bounds.size.height, self.originalBottomInset + self.bounds.size.height);
                    contentInset = self.scrollView.contentInset;
                    self.scrollView.contentInset = UIEdgeInsetsMake(-offset, contentInset.left, contentInset.bottom, contentInset.right);
                }
                break;
        }
    }
}

#pragma mark - Getters
- (UIImageView *)picShowImgV
{
    if (!_picShowImgV) {
        UIView *bottomLine = [[UIView alloc] initWithFrame:CGRectMake(0, self.bounds.size.height - 0.5, SCREEN_HEIGHT, 0.5)];
        bottomLine.backgroundColor = [UIColor colorWithHex:0xcdcdcd];
        [self addSubview:bottomLine];

        _picShowImgV = [[UIImageView alloc] initWithFrame:CGRectMake(SCREEN_WIDTH / 2 - 80, self.bounds.size.height - 48, 67, 50)];
        _picShowImgV.backgroundColor = [UIColor clearColor];
        [self addSubview:_picShowImgV];
    }
    
    return _picShowImgV;
}

//- (MDPullToRefreshArrow *)arrow {
//    if(!_arrow) {
//		_arrow = [[MDPullToRefreshArrow alloc]initWithFrame:CGRectMake(0, self.bounds.size.height-54, 22, 48)];
//        _arrow.backgroundColor = [UIColor clearColor];
//		[self addSubview:_arrow];
//    }
//    return _arrow;
//}

//- (UIActivityIndicatorView *)activityIndicatorView {
//    if(!_activityIndicatorView) {
//        _activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
//        _activityIndicatorView.hidesWhenStopped = YES;
//        [self addSubview:_activityIndicatorView];
//    }
//    return _activityIndicatorView;
//}

- (UILabel *)titleLabel {
    if(!_titleLabel) {
        _titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 210, 20)];
        _titleLabel.text = NSLocalizedString(@"下拉刷新…",);
        _titleLabel.font = [UIFont boldSystemFontOfSize:14];
        _titleLabel.backgroundColor = [UIColor clearColor];
        _titleLabel.textColor = textColor;
        _titleLabel.textAlignment = NSTextAlignmentLeft;
        [self addSubview:_titleLabel];
    }
    return _titleLabel;
}

- (UILabel *)subtitleLabel {
    if(!_subtitleLabel) {
        _subtitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 210, 20)];
        _subtitleLabel.font = [UIFont systemFontOfSize:12];
        _subtitleLabel.backgroundColor = [UIColor clearColor];
        _subtitleLabel.textColor = textColor;
        [self addSubview:_subtitleLabel];
    }
    return _subtitleLabel;
}

- (UILabel *)dateLabel {
    return self.showsDateLabel ? self.subtitleLabel : nil;
}

- (NSDateFormatter *)dateFormatter {
    if(!dateFormatter) {
        dateFormatter = [[NSDateFormatter alloc] init];
		[dateFormatter setDateStyle:NSDateFormatterShortStyle];
		[dateFormatter setTimeStyle:NSDateFormatterShortStyle];
		dateFormatter.locale = [NSLocale currentLocale];
    }
    return dateFormatter;
}

//- (UIColor *)arrowColor {
//	return self.arrow.arrowColor; // pass through
//}

- (UIColor *)textColor {
    return self.titleLabel.textColor;
}

//- (UIColor *)activityIndicatorViewColor {
//    return self.activityIndicatorView.color;
//}
//
//- (UIActivityIndicatorViewStyle)activityIndicatorViewStyle {
//    return self.activityIndicatorView.activityIndicatorViewStyle;
//}

#pragma mark - Setters

//- (void)setArrowColor:(UIColor *)newArrowColor {
//	self.arrow.arrowColor = newArrowColor; // pass through
//	[self.arrow setNeedsDisplay];
//}

- (void)setTitle:(NSString *)title forState:(MDPullToRefreshState)state {
    if(!title)
        title = @"";
    
    if(state == MDPullToRefreshStateAll)
        [self.titles replaceObjectsInRange:NSMakeRange(0, 3) withObjectsFromArray:@[title, title, title]];
    else
        [self.titles replaceObjectAtIndex:state withObject:title];
    
    [self setNeedsLayout];
}

- (void)setSubtitle:(NSString *)subtitle forState:(MDPullToRefreshState)state {
    if(!subtitle)
        subtitle = @"";
    
    if(state == MDPullToRefreshStateAll)
        [self.subtitles replaceObjectsInRange:NSMakeRange(0, 3) withObjectsFromArray:@[subtitle, subtitle, subtitle]];
    else
        [self.subtitles replaceObjectAtIndex:state withObject:subtitle];
    
    [self setNeedsLayout];
}

- (void)setCustomView:(UIView *)view forState:(MDPullToRefreshState)state {
    id viewPlaceholder = view;
    
    if(!viewPlaceholder)
        viewPlaceholder = @"";
    
    if(state == MDPullToRefreshStateAll)
        [self.viewForState replaceObjectsInRange:NSMakeRange(0, 3) withObjectsFromArray:@[viewPlaceholder, viewPlaceholder, viewPlaceholder]];
    else
        [self.viewForState replaceObjectAtIndex:state withObject:viewPlaceholder];
    
    [self setNeedsLayout];
}

- (void)setTextColor:(UIColor *)newTextColor {
    textColor = newTextColor;
    self.titleLabel.textColor = newTextColor;
	self.subtitleLabel.textColor = newTextColor;
}

//- (void)setActivityIndicatorViewColor:(UIColor *)color {
//    self.activityIndicatorView.color = color;
//}
//
//- (void)setActivityIndicatorViewStyle:(UIActivityIndicatorViewStyle)viewStyle {
//    self.activityIndicatorView.activityIndicatorViewStyle = viewStyle;
//}

- (void)setLastUpdatedDate:(NSDate *)newLastUpdatedDate {
    self.showsDateLabel = YES;
    self.dateLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Last Updated: %@",), newLastUpdatedDate?[self.dateFormatter stringFromDate:newLastUpdatedDate]:NSLocalizedString(@"Never",)];
}

- (void)setDateFormatter:(NSDateFormatter *)newDateFormatter {
	dateFormatter = newDateFormatter;
    self.dateLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Last Updated: %@",), self.lastUpdatedDate?[newDateFormatter stringFromDate:self.lastUpdatedDate]:NSLocalizedString(@"Never",)];
}

#pragma mark -

- (void)triggerRefresh {
    [self.scrollView triggerPullToRefresh];
}

- (void)startAnimating{
    switch (self.position) {
        case MDPullToRefreshPositionTop:
            
            if(fequalzero(self.scrollView.contentOffset.y)) {
                [self.scrollView setContentOffset:CGPointMake(self.scrollView.contentOffset.x, -self.frame.size.height) animated:YES];
                self.wasTriggeredByUser = NO;
            }
            else
                self.wasTriggeredByUser = YES;
            
            break;
        case MDPullToRefreshPositionBottom:
            
            if((fequalzero(self.scrollView.contentOffset.y) && self.scrollView.contentSize.height < self.scrollView.bounds.size.height)
               || fequal(self.scrollView.contentOffset.y, self.scrollView.contentSize.height - self.scrollView.bounds.size.height)) {
                [self.scrollView setContentOffset:(CGPoint){.y = MAX(self.scrollView.contentSize.height - self.scrollView.bounds.size.height, 0.0f) + self.frame.size.height} animated:YES];
                self.wasTriggeredByUser = NO;
            }
            else
                self.wasTriggeredByUser = YES;
            
            break;
    }
    
    self.state = MDPullToRefreshStateLoading;
}

- (void)stopAnimating {
    self.state = MDPullToRefreshStateStopped;

    if (self.pullImages && self.pullImages.count > 0) {
        [self.picShowImgV stopAnimating];
        self.picShowImgV.image = self.pullImages[0];
    }
    
    switch (self.position) {
        case MDPullToRefreshPositionTop:
            if(!self.wasTriggeredByUser)
                [self.scrollView setContentOffset:CGPointMake(self.scrollView.contentOffset.x, -self.originalTopInset) animated:YES];
            break;
        case MDPullToRefreshPositionBottom:
            if(!self.wasTriggeredByUser)
                [self.scrollView setContentOffset:CGPointMake(self.scrollView.contentOffset.x, self.scrollView.contentSize.height - self.scrollView.bounds.size.height + self.originalBottomInset) animated:YES];
            break;
    }
}

- (void)setState:(MDPullToRefreshState)newState {
    
    if(_state == newState)
        return;
    
    MDPullToRefreshState previousState = _state;
    _state = newState;

    [self setNeedsLayout];
    [self layoutIfNeeded];
    
    switch (newState) {
        case MDPullToRefreshStateAll:
        case MDPullToRefreshStateStopped:
            [self resetScrollViewContentInset];
            break;
            
        case MDPullToRefreshStateTriggered:
            break;
            
        case MDPullToRefreshStateLoading:
            [self setScrollViewContentInsetForLoading];
            
            if(previousState == MDPullToRefreshStateTriggered && pullToRefreshActionHandler)
                pullToRefreshActionHandler();
            
            break;
    }
}

//- (void)rotateArrow:(float)degrees hide:(BOOL)hide {
//    [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
//        self.arrow.layer.transform = CATransform3DMakeRotation(degrees, 0, 0, 1);
//        self.arrow.layer.opacity = !hide;
//        
//        //[self.arrow setNeedsDisplay];//ios 4
//    } completion:NULL];
//}

@end


#pragma mark - MDPullToRefreshArrow

//@implementation MDPullToRefreshArrow
////@synthesize arrowColor;
//@synthesize arrowImg=_arrowImg;
//static UIImage *_arrowImage;
//+(void)initialize
//{
//    if (self==[MDPullToRefreshArrow class]) {
//        _arrowImage=[UIImage imageNamed:@"pull_down_arrow"];
//    }
//}
//
////-(id)initWithFrame:(CGRect)frame
////{
////    if (self=[super initWithFrame:frame]) {
////        UIImageView *arrowIv=[[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 22, 48)];
////        [self addSubview:arrowIv];
////    }
////    return self;
////}
//
//- (UIColor *)arrowColor {
////	if (arrowColor) return arrowColor;
////	return [UIColor grayColor]; // default Color
//    return nil;
//}
//
//- (void)drawRect:(CGRect)rect {
//    [super drawRect:rect];
//	//CGContextRef c = UIGraphicsGetCurrentContext();
//	
//    [_arrowImage drawInRect:CGRectMake(0, 0, 22, 41)];
////	// the rects above the arrow
////	CGContextAddRect(c, CGRectMake(5, 0, 12, 4)); // to-do: use dynamic points
////	CGContextAddRect(c, CGRectMake(5, 6, 12, 4)); // currently fixed size: 22 x 48pt
////	CGContextAddRect(c, CGRectMake(5, 12, 12, 4));
////	CGContextAddRect(c, CGRectMake(5, 18, 12, 4));
////	CGContextAddRect(c, CGRectMake(5, 24, 12, 4));
////	CGContextAddRect(c, CGRectMake(5, 30, 12, 4));
////	
////	// the arrow
////	CGContextMoveToPoint(c, 0, 34);
////	CGContextAddLineToPoint(c, 11, 48);
////	CGContextAddLineToPoint(c, 22, 34);
////	CGContextAddLineToPoint(c, 0, 34);
////	CGContextClosePath(c);
////	
////	CGContextSaveGState(c);
////	CGContextClip(c);
////	
////	// Gradient Declaration
////	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
////	CGFloat alphaGradientLocations[] = {0, 0.8f};
////    
////	CGGradientRef alphaGradient = nil;
////    if([[[UIDevice currentDevice] systemVersion]floatValue] >= 5){
////        NSArray* alphaGradientColors = [NSArray arrayWithObjects:
////                                        (id)[self.arrowColor colorWithAlphaComponent:0].CGColor,
////                                        (id)[self.arrowColor colorWithAlphaComponent:1].CGColor,
////                                        nil];
////        alphaGradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)alphaGradientColors, alphaGradientLocations);
////    }else{
////        const CGFloat * components = CGColorGetComponents([self.arrowColor CGColor]);
////        size_t numComponents = CGColorGetNumberOfComponents([self.arrowColor CGColor]);
////        CGFloat colors[8];
////        switch(numComponents){
////            case 2:{
////                colors[0] = colors[4] = components[0];
////                colors[1] = colors[5] = components[0];
////                colors[2] = colors[6] = components[0];
////                break;
////            }
////            case 4:{
////                colors[0] = colors[4] = components[0];
////                colors[1] = colors[5] = components[1];
////                colors[2] = colors[6] = components[2];
////                break;
////            }
////        }
////        colors[3] = 0;
////        colors[7] = 1;
////        alphaGradient = CGGradientCreateWithColorComponents(colorSpace,colors,alphaGradientLocations,2);
////    }
////	
////	
////	CGContextDrawLinearGradient(c, alphaGradient, CGPointZero, CGPointMake(0, rect.size.height), 0);
////    
////	CGContextRestoreGState(c);
////	
////	CGGradientRelease(alphaGradient);
////	CGColorSpaceRelease(colorSpace);
//}
//@end

@implementation MDPullToRefreshArrow
@synthesize arrowColor;

- (UIColor *)arrowColor {
	if (arrowColor) return arrowColor;
	return [UIColor grayColor]; // default Color
}

- (void)drawRect:(CGRect)rect {
	CGContextRef c = UIGraphicsGetCurrentContext();
	
	// the rects above the arrow
	CGContextAddRect(c, CGRectMake(5, 0, 12, 4)); // to-do: use dynamic points
	CGContextAddRect(c, CGRectMake(5, 6, 12, 4)); // currently fixed size: 22 x 48pt
	CGContextAddRect(c, CGRectMake(5, 12, 12, 4));
	CGContextAddRect(c, CGRectMake(5, 18, 12, 4));
	CGContextAddRect(c, CGRectMake(5, 24, 12, 4));
	CGContextAddRect(c, CGRectMake(5, 30, 12, 4));
	
	// the arrow
	CGContextMoveToPoint(c, 0, 34);
	CGContextAddLineToPoint(c, 11, 48);
	CGContextAddLineToPoint(c, 22, 34);
	CGContextAddLineToPoint(c, 0, 34);
	CGContextClosePath(c);
	
	CGContextSaveGState(c);
	CGContextClip(c);
	
	// Gradient Declaration
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	CGFloat alphaGradientLocations[] = {0, 0.8f};
    
	CGGradientRef alphaGradient = nil;
    if([[[UIDevice currentDevice] systemVersion]floatValue] >= 5){
        NSArray* alphaGradientColors = [NSArray arrayWithObjects:
                                        (id)[self.arrowColor colorWithAlphaComponent:0].CGColor,
                                        (id)[self.arrowColor colorWithAlphaComponent:1].CGColor,
                                        nil];
        alphaGradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)alphaGradientColors, alphaGradientLocations);
    }else{
        const CGFloat * components = CGColorGetComponents([self.arrowColor CGColor]);
        size_t numComponents = CGColorGetNumberOfComponents([self.arrowColor CGColor]);
        CGFloat colors[8];
        switch(numComponents){
            case 2:{
                colors[0] = colors[4] = components[0];
                colors[1] = colors[5] = components[0];
                colors[2] = colors[6] = components[0];
                break;
            }
            case 4:{
                colors[0] = colors[4] = components[0];
                colors[1] = colors[5] = components[1];
                colors[2] = colors[6] = components[2];
                break;
            }
        }
        colors[3] = 0;
        colors[7] = 1;
        alphaGradient = CGGradientCreateWithColorComponents(colorSpace,colors,alphaGradientLocations,2);
    }
	
	
	CGContextDrawLinearGradient(c, alphaGradient, CGPointZero, CGPointMake(0, rect.size.height), 0);
    
	CGContextRestoreGState(c);
	
	CGGradientRelease(alphaGradient);
	CGColorSpaceRelease(colorSpace);
}
@end
