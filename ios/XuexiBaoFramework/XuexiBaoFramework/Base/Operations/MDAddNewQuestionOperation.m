//
//  MDAddNewQuestionOperation.m
//  education
//
//  Created by Tim on 14-10-17.
//  Copyright (c) 2014年 mudi. All rights reserved.
//

#import "MDAddNewQuestionOperation.h"
#import "MDUploadSubjectOperation.h"
#import "MDXuexiBaoOperationMgr.h"
#import "imagecd.h"


// Return a bitmap context using alpha/red/green/blue byte values
CGContextRef CreateRGBABitmapContext (CGImageRef inImage)
{
    CGContextRef context = NULL;
    CGColorSpaceRef colorSpace;
    void *bitmapData;
    int bitmapByteCount;
    int bitmapBytesPerRow;
    size_t pixelsWide = CGImageGetWidth(inImage);
    size_t pixelsHigh = CGImageGetHeight(inImage);
    bitmapBytesPerRow    = (int)(pixelsWide * 4);
    bitmapByteCount    = (int)(bitmapBytesPerRow * pixelsHigh);
    colorSpace = CGColorSpaceCreateDeviceRGB();
    if (colorSpace == NULL)
    {
        fprintf(stderr, "Error allocating color space\n");
        return NULL;
    }
    
    // allocate the bitmap & create context
    bitmapData = malloc( bitmapByteCount );
    if (bitmapData == NULL)
    {
        fprintf (stderr, "Memory not allocated!");
        CGColorSpaceRelease( colorSpace );
        return NULL;
    }
    context = CGBitmapContextCreate (bitmapData,
                                     pixelsWide,
                                     pixelsHigh,
                                     8,
                                     bitmapBytesPerRow,
                                     colorSpace,
                                     kCGImageAlphaPremultipliedFirst);
    //                                     kCGImageAlphaPremultipliedLast);
    if (context == NULL)
    {
        free (bitmapData);
        fprintf (stderr, "Context not created!");
    }
    CGColorSpaceRelease( colorSpace );
    
    return context;
}

// Return Image Pixel data as an RGBA bitmap
unsigned char *RequestImagePixelData(UIImage *inImage)
{
    CGImageRef img = [inImage CGImage];
    CGSize size = [inImage size];
    CGContextRef cgctx = CreateRGBABitmapContext(img);
    
    if (cgctx == NULL)
        return NULL;
    
    CGRect rect = {{0,0},{size.width, size.height}};
    CGContextDrawImage(cgctx, rect, img);
    unsigned char *data = (unsigned char *)CGBitmapContextGetData (cgctx);
    CGContextRelease(cgctx);
    
    return data;
}


@implementation MDAddNewQuestionOperation

#pragma mark Initialization
+ (MDAddNewQuestionOperation *)operationWithImage:(UIImage *)image success:(BlockResponseOK)success failure:(BlockResponseFailure)failure
{
    MDAddNewQuestionOperation *newOp = [[MDAddNewQuestionOperation alloc] init];
    newOp.cropImage = image;
    newOp.blockSuccess = success;
    newOp.blockFailure = failure;
    
    return newOp;
}

- (id)init
{
    self = [super init];
    if (self) {
        
    }
    
    return self;
}

- (void)main
{
    // 0. 有效性判断
    if (!self.cropImage) {
        dispatch_main_sync_safe(^{
            NSError *error = [NSError errorWithDomain:ERROR_DOMAIN code:ERROR_PARAM_INVALID userInfo:nil];
            self.blockFailure(error);
        });
        
        return;
    }
    
    
    // 1. 文件管理（存储）：保存原图
    NSString *filePrefix = gen_uuid();
    MDLog(@"AddNewQueOperation fleuuid gen:%@", filePrefix);
    
    NSString *imgFullPath = [DIR_ORV2 stringByAppendingPathComponent:filePrefix];
    // 1.1. 保存原图
    [[MDFileUtil sharedInstance] saveFileContent:UIImageJPEGRepresentation(self.cropImage, 1.0) toFolder:DIR_ORV2 withFileName:filePrefix];
    NSString *binFullPath = imgFullPath;
    MDLog(@"AddNewQueOperation saveOriFile to:%@", imgFullPath);
    
    // 1.2. 保存压缩后的彩图（用于展现本地缓存图片）
    UIImage * compressedImage = [UIImage scaleImage:self.cropImage toScale:0.5];
    compressedImage = [UIImage constrainImage:self.cropImage withMaxLength:960];
    NSData *compressedData = UIImageJPEGRepresentation(compressedImage, 0.7);
    [[MDFileUtil sharedInstance] saveFileContent:compressedData toFolder:DIR_DATA withFileName:filePrefix];
    MDLog(@"AddNewQueOperation save compress image to DATADIR %@", filePrefix);
    
    
    // 2. 二值化
    unsigned char *bitmapChars = RequestImagePixelData(self.cropImage);
//    LogFile(@"GenPixelData OK");
    
    // 2.0. 如果获取bitmap无效
    if (NULL == bitmapChars) {
//        LogFile(@"RequestImagePixelData empty");
        
        MDLog(@"AddNewQueOperation get bitmapChars failed");
        
        dispatch_main_sync_safe(^{
            NSError *error = [NSError errorWithDomain:ERROR_DOMAIN code:ERROR_PARAM_INVALID userInfo:nil];
            self.blockFailure(error);
        });
        
        return;
    }
    
    MDLog(@"getImagePath: %@", NSStringFromCGSize(self.cropImage.size));
    
    NSString *cachedBinPath = nil;
    
    char *charDocu = (char *)[MDFileUtil.documentFolder UTF8String];
    MDLog(@"param: %s height: %d width: %d", charDocu, (int)self.cropImage.size.height, (int)self.cropImage.size.width);
    char *charFullPath = getImagePath([MDFileUtil.documentFolder UTF8String], bitmapChars, self.cropImage.size.height, self.cropImage.size.width);
    free(bitmapChars);
    
    MDLog(@"AddNewQueOperation binaryfile path:%s", charFullPath);
    
    // 2.1. 如果二值化失败，则使用原图
//    LogFile([NSString stringWithFormat:@"getImagePath OK %s %@", charFullPath, NSStringFromCGSize(self.cropImage.size)]);
    
    if (!charFullPath || [[NSString stringWithUTF8String:charFullPath] isEqualToString:@"NULL"]) {
//        LogFile(@"GenBinPath empty");
        
        cachedBinPath = nil;
    }
    // 2.2. 如果二值化成功，保存二值化文件
    else {
        cachedBinPath = [NSString stringWithUTF8String:charFullPath];
        
        NSData *data = [NSData dataWithContentsOfFile:cachedBinPath];
        
        if (data.length < BIN_MIN_SIZE) {
//            LogFile([NSString stringWithFormat:@"GenBinPath size too small:%lu %@", (unsigned long)data.length, filePrefix]);
        }
        else {
//            LogFile([NSString stringWithFormat:@"GenBinPath OK %s", charFullPath]);
        }
        
        binFullPath = [DIR_BIV2 stringByAppendingPathComponent:filePrefix];
        [[MDFileUtil sharedInstance] saveFileContent:data toFolder:DIR_BIV2 withFileName:filePrefix];
    }
    
    MDLog(@"AddNewQueOperation binFullPath: %@", binFullPath);
    
    // *********** 3. 入库新题目记录：记录中带“原图路径”+“二值化文件路径”
    // 4. 触发MDUploadSubjectOperation开始工作
    [[MDCoreDataUtil sharedInstance] queAddQueWhenBinImgCreated:filePrefix oriImgPath:imgFullPath binImgPath:binFullPath completion:^(NSManagedObjectID *objectId) {
        if (objectId) {
            MDLog(@"AddNewQueOperation addQueWhenBinImgCreated:%@ objectID:%@", filePrefix, objectId);
            
            [[NSNotificationCenter defaultCenter] postNotificationName:kNTF_QUE_NEW_START object:nil];
            
            MDUploadSubjectOperation *updOperation = [MDUploadSubjectOperation operationWithImage:self.cropImage binPath:cachedBinPath guid:filePrefix managedObjectID:objectId success:self.blockSuccess failure:self.blockFailure];
            
            [[MDXuexiBaoOperationMgr sharedInstance].operationQueue addOperation:updOperation];
        }
    }];
}

@end




