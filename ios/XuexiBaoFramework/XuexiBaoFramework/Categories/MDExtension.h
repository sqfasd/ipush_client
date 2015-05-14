//
//  EPExtension.h
//  everpath
//
//  Created by Tim on 13-10-30.
//  Copyright (c) 2013年 Tim. All rights reserved.
//


#import <Foundation/Foundation.h>



@interface NSString (MyExtensions)
- (NSString *)md5;
- (NSString *)reverse;
@end



@interface NSData (MyExtensions)
+ (NSData*)gzipData:(NSData*)pUncompressedData;
+ (NSData *)ungzipData:(NSData *)compressedData;

- (NSString*)md5;
@end





@interface UIImage (ImgOperations)

- (UIImage *)adjustOrientation;

@end






