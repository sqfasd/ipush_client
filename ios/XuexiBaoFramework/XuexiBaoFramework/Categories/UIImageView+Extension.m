//
//  UIImageView+Extension.m
//  education
//
//  Created by kimziv on 14-6-3.
//  Copyright (c) 2014年 mudi. All rights reserved.
//

#import "UIImageView+Extension.h"
#import "UIImageView+WebCache.h"
@implementation UIImageView (Extension)

- (void)setInfoImageWithURL:(NSString *)url placeHolder:(UIImage*)placeHolder
{
    //NSString *infoDir=[MDUserUtil sharedInstance].userInfoDir;
    [self sd_setImageWithURL:[NSURL URLWithString:url?url:@""] placeholderImage:placeHolder];
   // [self setImageWithURL:[NSURL URLWithString:url?url:@""] placeholderImage:placeHolder cacheDir:infoDir];
}

- (void)setCircleImageWithURL:(NSString *)url placeHolder:(UIImage*)placeHolder
{
    //NSString *circleDir=[MDUserUtil sharedInstance].userCircleDir;
    [self sd_setImageWithURL:[NSURL URLWithString:url?url:@""] placeholderImage:placeHolder];
    //[self setImageWithURL:[NSURL URLWithString:url?url:@""] placeholderImage:placeHolder cacheDir:circleDir];
}

- (void)setGeneralImageWithURL:(NSString *)url placeHolder:(UIImage*)placeHolder
{
    //NSString *imgsDir=[MDUserUtil sharedInstance].imgsDir;
    [self sd_setImageWithURL:[NSURL URLWithString:url?url:@""] placeholderImage:placeHolder];
    //[self setImageWithURL:[NSURL URLWithString:url?url:@""] placeholderImage:placeHolder cacheDir:imgsDir];
}

@end
