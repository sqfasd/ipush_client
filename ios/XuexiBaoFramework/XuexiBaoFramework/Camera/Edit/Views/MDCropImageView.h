//
//  MDCropImageView.h
//  education
//
//  Created by Tim on 14-10-27.
//  Copyright (c) 2014年 mudi. All rights reserved.
//

#import <UIKit/UIKit.h>




#pragma mark Protocols
@protocol MDCameraCropRect
@required
/**
 *  Add cropRect for the frameView.
 */
@property (nonatomic, assign) CGRect cropRect;
@end


#pragma mark MDCropImageView
@interface MDCropImageView : UIImageView <MDCameraCropRect>

@end
