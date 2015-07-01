//
//  MDEmptyMainView.m
//  education
//
//  Created by Tim on 15/1/13.
//  Copyright (c) 2015年 mudi. All rights reserved.
//

#import "MDEmptyMainView.h"
#import "AVFoundation/AVMediaFormat.h"
#import "AVFoundation/AVCaptureDevice.h"


@interface MDEmptyMainView ()

@property (strong, nonatomic) IBOutlet UIImageView *starRegionImgV;
@property (strong, nonatomic) IBOutlet UIImageView *studyRegionImgV;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *emptyCircleHC;


@end



@implementation MDEmptyMainView

+ (MDEmptyMainView *)sharedView
{
    static MDEmptyMainView *sharedInstance = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^ {
        NSArray *views = [XXBFRAMEWORK_BUNDLE loadNibNamed:@"EmptyMain" owner:nil options:nil];
        if (views && views.count > 0) {
            sharedInstance = views.firstObject;
        }
    });
    
    return sharedInstance;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
    }
    
    return self;
}


#pragma mark -
#pragma mark - Display
- (void)initDisplay
{
//    self.starRegionImgV.layer.shadowOpacity = 1;
//    self.starRegionImgV.layer.shadowOffset = CGSizeMake(0, 0);
//    self.starRegionImgV.layer.shadowColor = [UIColor whiteColor].CGColor;
//    self.starRegionImgV.layer.shadowRadius = 0.0f;
//    self.emptyCircleHC.constant = SCREEN_WIDTH;
    
    self.frame = SCREEN_RECT;
}


#pragma mark -
#pragma mark - Operations
- (IBAction)cameraBtnClicked:(id)sender {
    
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if(authStatus == AVAuthorizationStatusRestricted || authStatus == AVAuthorizationStatusDenied){
        NSString * msg = @"请在系统设置中打开\"相机\"来允许\"学习宝极速版\"打开您的相机";
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:msg delegate:nil cancelButtonTitle:@"知道了" otherButtonTitles:nil];
        [alert show];
        return;
    }

    if (self.delegate && [self.delegate respondsToSelector:@selector(emptyViewDidOpenCamera:)]) {
        [self.delegate emptyViewDidOpenCamera:self];
    }
}

@end




