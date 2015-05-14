//
//  NSString+Additions.h
//  zhishuo
//
//  Created by kimziv on 14-9-4.
//  Copyright (c) 2014年 kimziv. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (Additions)
// Wrap the verbose >=iOS7 string size methods in a <iOS7 compatible form
- (CGSize)sizeWithFont7:(UIFont*)font;
- (CGSize)sizeWithFont7:(UIFont*)font constrainedToSize:(CGSize)size;
- (CGSize)sizeWithFont7:(UIFont*)font constrainedToSize:(CGSize)size lineBreakMode:(NSLineBreakMode)lineBreakMode;
-(NSString *)thumbnailUrl;
@end
