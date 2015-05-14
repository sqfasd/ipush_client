//
//  MDXuexiBaoAPI.m
//  education
//
//  Created by Tim on 14-5-8.
//  Copyright (c) 2014年 mudi. All rights reserved.
//

#import "MDXuexiBaoAPI.h"
#import "MDNetworking.h"
#import "NSData+Base64.h"
#import "imagecd.h"
#import <Security/Security.h>
#import "MDFileUtil.h"
#import "MDQuestionV2.h"
#import  "EGOCache.h"
#import "MSWeakTimer.h"
#import "MDAddNewQuestionOperation.h"
#import "MDXuexiBaoOperationMgr.h"
#import "MDLogUtil.h"



#define QUE_NOTIFICATION_TIMEOUT 20


@interface MDXuexiBaoAPI ()<UIAlertViewDelegate>

{
    SecKeyRef _public_key;
    
    SecKeyRef publicKey;
    SecCertificateRef certificate;
    SecPolicyRef policy;
    SecTrustRef trust;
    size_t maxPlainLen;
    
    UIImage *cachedUpdImage;
    NSString *cachedBinPath;
    
    NSLock *bgQueArrayLock;
    MSWeakTimer *_searchTimer;
}

@property (nonatomic, strong) NSMutableArray *bgQueArray;

@end



@implementation MDXuexiBaoAPI

@synthesize bgQueArray = _bgQueArray;

+ (MDXuexiBaoAPI *)sharedInstance
{
    static MDXuexiBaoAPI *sharedAPIInstance = nil;
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        sharedAPIInstance = [[self alloc] init];
    });
    
    return sharedAPIInstance;
}

- (id)init
{
    self = [super init];
    if (self) {
    }
    
    return self;
}

-(void)dealloc
{
    if (_searchTimer) {
        [_searchTimer invalidate];//释放timer
    }
}



#pragma mark --
#pragma mark Properties
+ (NSDateFormatter *)paramTimeFormatter
{
    static NSDateFormatter *formatter = nil;
    if (!formatter) {
        formatter = [[NSDateFormatter alloc] init];
        formatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"zh_CN"];
        formatter.timeZone = [NSTimeZone localTimeZone];
        formatter.dateFormat = @"yyyy-MM-dd HH:mm";
    }
    
    return formatter;
}

+ (NSDateFormatter *)shortTimeFormatter
{
    static NSDateFormatter *shortFormatter = nil;
    if (!shortFormatter) {
        shortFormatter = [[NSDateFormatter alloc] init];
        shortFormatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"zh_CN"];
        shortFormatter.timeZone = [NSTimeZone localTimeZone];
        shortFormatter.dateFormat = @"HH:mm:ss";
    }
    
    return shortFormatter;
}

+ (NSDateFormatter *)dateTimeFormatter
{
    static NSDateFormatter *dateFormatter = nil;
    if (!dateFormatter) {
        dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"zh_CN"];
        dateFormatter.timeZone = [NSTimeZone localTimeZone];
        dateFormatter.dateFormat = @"MM-dd";
    }
    
    return dateFormatter;
}

+ (NSDateFormatter *)yearMonthTimeFormatter
{
    static NSDateFormatter *yearFormatter = nil;
    if (!yearFormatter) {
        yearFormatter = [[NSDateFormatter alloc] init];
        yearFormatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"zh_CN"];
        yearFormatter.timeZone = [NSTimeZone localTimeZone];
        yearFormatter.dateFormat = @"yyyy-MM";
    }
    
    return yearFormatter;
}

+ (NSDateFormatter *)yearMonthDayTimeFormatter
{
    static NSDateFormatter *formatter = nil;
    if (!formatter) {
        formatter = [[NSDateFormatter alloc] init];
        formatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"zh_CN"];
        formatter.timeZone = [NSTimeZone localTimeZone];
        formatter.dateFormat = @"yyyy-MM-dd";
    }
    
    return formatter;
}

+ (NSDateFormatter *)weekdayTimeFormatter {
    static NSDateFormatter *formatter = nil;
    if (!formatter) {
        formatter = [[NSDateFormatter alloc] init];
        formatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"zh_CN"];
        formatter.timeZone = [NSTimeZone localTimeZone];
        formatter.dateFormat = @"EEEE";
    }
    
    return formatter;
}


- (NSMutableArray *)bgQueArray
{
    if (!_bgQueArray) {
        _bgQueArray = [[NSMutableArray alloc] init];
        bgQueArrayLock = [[NSLock alloc] init];
    }
    
    return _bgQueArray;
}



#pragma mark --
#pragma mark -- 通用接口
- (void)postForAPI:(NSString *)strUrl api:(NSString *)api post:(NSDictionary *)input showAlert:(BOOL)show success:(BlockResponse)success failure:(BlockResponseFailure)failure {
    if (!api || api.length <= 0) {
        NSError *error = [NSError errorWithDomain:ERROR_DOMAIN code:ERROR_PARAM_INVALID userInfo:nil];
        failure(error);
        return;
    }
    
    NSString *finalURL = [NSString stringWithFormat:@"%@%@", strUrl, api];
    [[MDNetworking sharedInstance] sendPOSTRequest:finalURL withData:input withTimeout:HTTP_REQ_TIMEOUT showAlert:show success:^(id responseObject) {
        if (success) {
            success(responseObject);
        }
    } failure:failure];
}

- (void)postForAPI:(NSString *)strURL api:(NSString *)api post:(NSDictionary *)input success:(BlockResponse)success failure:(BlockResponseFailure)failure
{
    if (!api || api.length <= 0) {
        NSError *error = [NSError errorWithDomain:ERROR_DOMAIN code:ERROR_PARAM_INVALID userInfo:nil];
        failure(error);
        return;
    }
    
    if (!input || input.count <= 0) {
        NSError *error = [NSError errorWithDomain:ERROR_DOMAIN code:ERROR_PARAM_INVALID userInfo:nil];
        failure(error);
        return;
    }
    
    NSString *finalURL = [NSString stringWithFormat:@"%@%@", strURL, api];
    [[MDNetworking sharedInstance] sendPOSTRequest:finalURL withData:input withTimeout:HTTP_REQ_TIMEOUT success:^(id responseObject) {
        if (success) {
            success(responseObject);
        }
    } failure:failure];
}



- (void)postForAPI:(NSString *)strURL api:(NSString *)api post:(NSDictionary *)input paramForm:(ParamForm)paramForm success:(BlockResponse)success failure:(BlockResponseFailure)failure
{
    if (!api || api.length <= 0) {
        NSError *error = [NSError errorWithDomain:ERROR_DOMAIN code:ERROR_PARAM_INVALID userInfo:nil];
        failure(error);
        return;
    }
    
    if (!input || input.count <= 0) {
        NSError *error = [NSError errorWithDomain:ERROR_DOMAIN code:ERROR_PARAM_INVALID userInfo:nil];
        failure(error);
        return;
    }
    
    NSString *finalURL = [NSString stringWithFormat:@"%@%@", strURL, api];
    [[MDNetworking sharedInstance] sendPOSTRequest:finalURL withData:input paramForm:paramForm withTimeout:HTTP_REQ_TIMEOUT success:^(id responseObject) {
        if (success) {
            success(responseObject);
        }
    } failure:failure];
}

- (void)postForAPI:(NSString *)strURL api:(NSString *)api post:(NSDictionary *)input paramForm:(ParamForm)paramForm showAlert:(BOOL)show  success:(BlockResponse)success failure:(BlockResponseFailure)failure
{
    if (!api || api.length <= 0) {
        NSError *error = [NSError errorWithDomain:ERROR_DOMAIN code:ERROR_PARAM_INVALID userInfo:nil];
        failure(error);
        return;
    }
    
    if (!input || input.count <= 0) {
        NSError *error = [NSError errorWithDomain:ERROR_DOMAIN code:ERROR_PARAM_INVALID userInfo:nil];
        failure(error);
        return;
    }
    
    NSString *finalURL = [NSString stringWithFormat:@"%@%@", strURL, api];

    [[MDNetworking sharedInstance] sendPOSTRequest:finalURL withData:input paramForm:paramForm withTimeout:HTTP_REQ_TIMEOUT  showAlert:show success:^(id responseObject) {
        if (success) {
            success(responseObject);
        }
    } failure:failure];
}


- (void)addBgUploadTasks:(NSArray *)list
{
    if (!list)
        return;
    
    [bgQueArrayLock lock];
    for (MDQuestionV2 *question in list) {
        if ([self.bgQueArray containsObject:question])
            continue;
        
        [self.bgQueArray addObject:question];
    }
    [bgQueArrayLock unlock];
}

- (void)internalStartBgFetchAnswer
{
    if (self.bgQueArray <= 0)
        return;
}




#pragma mark -
#pragma mark - V2.0 API

- (void)getQuestionAnswers:(NSDictionary *)params success:(void(^)(id responseObject, BOOL cached))success failure:(BlockResponseFailure)failure
{
    if (params ==nil || params.count==0) {
        NSError *error = [NSError errorWithDomain:ERROR_DOMAIN code:ERROR_PARAM_INVALID userInfo:nil];
        failure(error);
        return;
    }
    NSString *imgId=[params nonNullValueForKeyPath:@"image_id"];
    id cache = [[EGOCache globalCache] objectForKey:[NSString stringWithFormat:kCACHE_KEY_QUE_DETAIL_FORMAT,imgId]];
    if (IsResponseOK(cache)) {
        if (success) {
            success(cache,YES);
        }
        return;
    }
    NSString *url =[NSString stringWithFormat:@"%@%@", MD_DOMAIN, OP_QUESTION_ANSWERS];
    [[MDNetworking sharedInstance] sendPOSTRequest:url withData:params paramForm:ParamFormURL withTimeout:HTTP_REQ_TIMEOUT success:^(id responseObject) {
        if (IsResponseOK(responseObject)) {
            NSNumber *searchType=[responseObject nonNullValueForKeyPath:@"result.question.search_type"];
            if (searchType && searchType.intValue==200) {
                [[EGOCache globalCache] setObject:responseObject forKey:[NSString stringWithFormat:kCACHE_KEY_QUE_DETAIL_FORMAT,imgId] withTimeoutInterval:kTIME_INTERVAL_ONE_WEEK];
            }
        }
        if (success) {
            success(responseObject,NO);
        }
    }failure:failure];
}



//获取学科列表
-(void)fetchSubjects:(BlockResponse)success failure:(BlockResponseFailure)failure
{
    NSString *url=[NSString stringWithFormat:@"%@%@", MD_DOMAIN, OP_SUBJECTS_GET];
    
    [[MDNetworking sharedInstance] sendPOSTRequest:url withData:nil  withTimeout:HTTP_REQ_TIMEOUT showAlert:NO success:^(id responseObject) {
        
        if (IsResponseOK(responseObject)) {
            
            NSArray *subjects = [responseObject nonNullObjectForKey:@"result"];
            
            [[EGOCache globalCache] setObject:subjects forKey:SUBJECTS_LIST withTimeoutInterval:kTIME_INTERVAL_INFINITE];
            
            if (success) {
                success(subjects);
            }
        }
    } failure:failure];
}



#pragma mark -
#pragma mark - V1.4~1.5 API


// V1.5more App首次使用激活
- (void)activateApp:(BlockResponseOK)success failure:(BlockResponseFailure)failure
{
    NSString *url = [NSString stringWithFormat:@"%@%@", MD_DOMAIN_AD, OP_APP_ACTIVATE];
    
    NSDictionary *input = [NSDictionary dictionaryWithObjectsAndKeys:IMEI(), @"muid", @"ios", @"app_type", nil];
    
    [[MDNetworking sharedInstance] sendPOSTRequest:url withData:input withTimeout:HTTP_REQ_TIMEOUT showAlert:NO success:^(id responseObject) {
        MDLog(@"activate resp: %@", responseObject);
    } failure:failure];
}


/***** Begin API in v1.4 **************/
//绑定设备
- (void)bindDevice:(NSDictionary *)params success:(BlockResponse)success failure:(BlockResponseFailure)failure
{
    [self postForAPI:MD_DOMAIN api:OP_DEVICE_BIND post:params success:success failure:failure];
}

- (void)getQueList:(NSDictionary *)params success:(BlockResponse)success failure:(BlockResponseFailure)failure
{
    if (params==nil && params.count==0) {
        return;
    }
    
    NSNumber *subject=[params nonNullObjectForKey:@"subject"];
    NSNumber *searchType=[params nonNullObjectForKey:@"search_type"];
    id lastId=[params nonNullObjectForKey:@"id"];
    BOOL isNumber=[lastId isKindOfClass:[NSNumber class]];
    NSString *cacheKey=nil;
    if (!isNumber) {
        cacheKey= [NSString stringWithFormat:kCACHE_KEY_QUE_LIST_FORMAT,
                   (int)(subject?subject.integerValue:0),
                   (int)(searchType?searchType.integerValue:0),
                   0];
    }
    
    
    NSString *url = [NSString stringWithFormat:@"%@%@", MD_DOMAIN, OP_QUE_LIST_GET];
    [[MDNetworking sharedInstance] sendPOSTRequest:url withData:params withTimeout:HTTP_REQ_TIMEOUT success:^(id responseObject) {
        if (IsResponseOK(responseObject)) {
            if (!isNumber && cacheKey) {
                [[EGOCache globalCache] setObject:responseObject forKey:cacheKey withTimeoutInterval:kTIME_INTERVAL_ONE_DAY];
            }
        }
        if (success) {
            success(responseObject);
        }
        
    }failure:^(NSError *error) {
        if (!isNumber && cacheKey) {
            id cache = [[EGOCache globalCache] objectForKey:cacheKey];
            if (IsResponseOK(cache)) {
                if (success) {
                    success(cache);
                }
                return;
            }
        }
        if (failure) {
            failure(error);
        }
        
    }];
}

- (void)getQueDetail:(NSString *)imgId success:(void(^)(id responseObject, BOOL cached))success failure:(BlockResponseFailure)failure
{
    if (imgId==nil || imgId.length==0) {
        MDLog(@"error:imgId is empty");
        return;
    }
    id cache = [[EGOCache globalCache] objectForKey:[NSString stringWithFormat:kCACHE_KEY_QUE_DETAIL_FORMAT,imgId]];
    if (IsResponseOK(cache)) {
        if (success) {
            success(cache,YES);
        }
        return;
    }
    
    NSString *url = [NSString stringWithFormat:@"%@%@/%@", MD_DOMAIN, OP_QUE_DETAIL_GET,imgId];
    [[MDNetworking sharedInstance] sendPOSTRequest:url withData:nil withTimeout:HTTP_REQ_TIMEOUT success:^(id responseObject) {
        
        if (IsResponseOK(responseObject)) {
            // NSArray *answers=[responseObject nonNullValueForKeyPath:@"result.answers"];
            NSNumber *searchType=[responseObject nonNullValueForKeyPath:@"result.question.search_type"];
            //NSNumber *imageSatus=[responseObject nonNullValueForKeyPath:@"result.question.image_status"];
            //            if (([answers isKindOfClass:[NSArray class]] && [answers count]!=0 && [answers[0] count]>0)||(imageSatus && imageSatus.integerValue==1)) {
            //                <#statements#>
            //            }
            if (searchType && searchType.intValue==200) {
                [[EGOCache globalCache] setObject:responseObject forKey:[NSString stringWithFormat:kCACHE_KEY_QUE_DETAIL_FORMAT,imgId] withTimeoutInterval:kTIME_INTERVAL_ONE_DAY];
            }
        }
        if (success) {
            success(responseObject,NO);
        }
    }failure:failure];
}

- (void)queryQues:(NSDictionary *)params success:(BlockResponse)success failure:(BlockResponseFailure)failure
{
    [self postForAPI:MD_DOMAIN api:OP_QUESTION_QUERY post:params success:success failure:failure];
}

/***** End API in v1.4 ***************/



#pragma mark -
#pragma mark - V1.* before 1.4
// 上传问题图片
// api/question/upload
- (void)uploadSubjectPicture:(UIImage *)inputImage success:(BlockResponse)success failure:(BlockResponseFailure)failure
{
    if (!inputImage) {
        NSError *error = [NSError errorWithDomain:ERROR_DOMAIN code:ERROR_PARAM_INVALID userInfo:nil];
        failure(error);
        return;
    }
    
    MDAddNewQuestionOperation *addNewQueOperation = [MDAddNewQuestionOperation operationWithImage:inputImage success:^{
        
    } failure:^(NSError *error) {
        
    }];
    
    [[MDXuexiBaoOperationMgr sharedInstance].operationQueue addOperation:addNewQueOperation];
    return;
}


- (void)processUploading:(BlockResponse)success failure:(BlockResponseFailure)failure
{
    NSData *data = nil;
    NSString *filePrefix = gen_uuid();
    NSLog(@"filePrefix: %@", filePrefix);
    NSString *binFileName = [NSString stringWithFormat:@"%@.bi", filePrefix];
    NSData *cacheImgData = nil;
    
    // 如果是二值化流程：
    if (cachedBinPath) {
        // 3. 读取和保存
        // 3.0. 读取二值化文件内容
        data = [NSData dataWithContentsOfFile:cachedBinPath];
        
        if ([data length] < BIN_MIN_SIZE) {
            LogFile(@"GenBinPath empty");

            NSError *error = [NSError errorWithDomain:ERROR_DOMAIN code:ERROR_BIN_EMPTY userInfo:nil];
            failure(error);
            
            return;
        }
        // 3.1. 保存二值化文件
        [[MDFileUtil sharedInstance] saveFileContent:data toFolder:DIR_DATA withFileName:binFileName];
        
        cachedUpdImage = [UIImage scaleImage:cachedUpdImage toScale:0.5];
        cachedUpdImage = [UIImage constrainImage:cachedUpdImage withMaxLength:960];
        cacheImgData = UIImageJPEGRepresentation(cachedUpdImage, 0.7);
    }
    else {
        if (!cachedUpdImage) {
            NSError *error = [NSError errorWithDomain:ERROR_DOMAIN code:ERROR_BIN_EMPTY userInfo:nil];
            failure(error);
            return;
        }
        
        cacheImgData = UIImageJPEGRepresentation(cachedUpdImage, 1.0);
        
        data = cacheImgData;
    }
    
    // 3.2. 保存彩图
    NSString *imageFileName = [NSString stringWithFormat:@"%@.or", filePrefix];
    
    [[MDFileUtil sharedInstance] saveFileContent:cacheImgData toFolder:DIR_DATA withFileName:imageFileName];

    LogFile(@"SaveFiles OK");
    
    
    // 4. 调用数据库接口，保存记录，将文件名传输进去
    NSString *binFullPath = [DIR_DATA stringByAppendingPathComponent:binFileName]; //[[[MDFileUtil sharedInstance].documentFolder stringByAppendingPathComponent:DIR_DATA] stringByAppendingPathComponent:binFileName];
    NSString *imgFullPath = [DIR_DATA stringByAppendingPathComponent:imageFileName]; //[[[MDFileUtil sharedInstance].documentFolder stringByAppendingString:DIR_DATA] stringByAppendingPathComponent:imageFileName];
    
    
    
    //    NSData *data = [NSData dataWithContentsOfFile:[MDFileUtil.documentFolder stringByAppendingPathComponent:binFullPath]];
    
    
    [[MDCoreDataUtil sharedInstance] queAddQueWhenBinImgCreated:@"" oriImgPath:imgFullPath binImgPath:binFullPath completion:^(NSManagedObjectID *objectId) {
        if (objectId) {
            // 5. 开始实际上传
            NSString *url = [NSString stringWithFormat:@"%@", MD_DOMAIN_PIC];
            NSDictionary *input = nil;
            if (cachedBinPath) {
                input = [NSDictionary dictionaryWithObjectsAndKeys:data, @"files[]", nil];
            }
            else {
                input = [NSDictionary dictionaryWithObjectsAndKeys:data, @"files2[]", nil];
            }
            [[MDNetworking sharedInstance] POSTForFileContent:url withInput:input timeout:60 success:^(id responseObject) {
                LogFile([NSString stringWithFormat:@"POSTFile OK: %@", responseObject]);
                
                // 6. 如果上传成功，调用数据库更新接口，更新Status
                [[MDCoreDataUtil sharedInstance] updateQueWhenBinImgUploaded:objectId data:responseObject completion:^(BOOL suc, NSError *error) {
                    
                    if (suc) {
                        
                        NSString *imgUuid=[responseObject nonNullObjectForKey:@"image_id"];
                        //重命名
                        NSString *oldPath =  [MDFileUtil.documentFolder  stringByAppendingPathComponent:imgFullPath];
                        NSString *newPath =  [MDFileUtil.documentFolder stringByAppendingPathComponent:[DIR_DATA stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.jpg",imgUuid]]];
                        //                        [[NSFileManager defaultManager] createFileAtPath:newPath contents:nil attributes:nil];
                        NSError *error;
                        if ([[NSFileManager defaultManager] fileExistsAtPath:oldPath]) {
                            if (![[NSFileManager defaultManager] moveItemAtPath:oldPath toPath:newPath error:&error]) {
                                //if (![[NSFileManager defaultManager] linkItemAtPath:oldPath toPath:newPath error:&error]) {
                                MDLog(@"Unable to move file: %@", [error localizedDescription]);
                            }
                        }else{
                            MDLog(@"file not exist at oldPath: %@", oldPath);
                        }
                        
                        //7. 调用success
                        success(responseObject);
                    }else{
                        LogFile(@"updateQueWhenBinImgUploaded fail!!!");

                        if (error!=nil) {//数据存储失败
                            // ShowAlertView(@"",[NSString stringWithFormat: @"updateQueWhenBinImgUploaded failure1:%@",error.description], @"确定", nil);
                            error = [NSError errorWithDomain:ERROR_DOMAIN code:ERROR_COREDATA userInfo:@{@"updateQueWhenBinImgUploaded":@"fail"}];
                            failure(error);
                        }
                    }
                }];
                //                    //7. 调用success
                //                    success(responseObject);
                
            } failure:^(NSError *error) {
                LogFile([NSString stringWithFormat:@"POSTFIle Fail: %@", error]);

                failure(error);
            }];
        } else {
            MDLog(@"add que failure:");
            
            LogFile(@"addQueWhenBinImgCreated fail!!!");
            
            NSError *error = [NSError errorWithDomain:ERROR_DOMAIN code:ERROR_COREDATA userInfo:@{@"objID":@"empty"}];
            failure(error);
        }
        
    }];
}


- (void)uploadBinFileWithBinPath:(NSString *)binFullPath andImgPath:(NSString *)imgFullPath success:(BlockResponse)success failure:(BlockResponseFailure)failure
{
    NSData *data = [NSData dataWithContentsOfFile:[MDFileUtil.documentFolder stringByAppendingPathComponent:binFullPath]];
    
    [[MDCoreDataUtil sharedInstance] queAddQueWhenBinImgCreated:@"" oriImgPath:imgFullPath binImgPath:binFullPath completion:^(NSManagedObjectID *objectId) {
        if (objectId) {
            // 5. 开始实际上传
            NSString *url = [NSString stringWithFormat:@"%@", MD_DOMAIN_PIC];
            NSDictionary *input = [NSDictionary dictionaryWithObjectsAndKeys:data, @"files[]", nil];
            [[MDNetworking sharedInstance] POSTForFileContent:url withInput:input timeout:60 success:^(id responseObject) {
                LogFile([NSString stringWithFormat:@"POSTFile OK: %@", responseObject]);
                
                // 6. 如果上传成功，调用数据库更新接口，更新Status
                [[MDCoreDataUtil sharedInstance] updateQueWhenBinImgUploaded:objectId data:responseObject completion:^(BOOL suc, NSError *error) {
                    
                    if (suc) {
                        //7. 调用success
                        success(responseObject);
                    }else{
                        LogFile(@"updateQueWhenBinImgUploaded fail!!!");
                        
                        if (error!=nil) {//数据存储失败
                            // ShowAlertView(@"",[NSString stringWithFormat: @"uploadBinFileWithBinPath failure1:%@",error.description], @"确定", nil);
                            error = [NSError errorWithDomain:ERROR_DOMAIN code:ERROR_COREDATA userInfo:@{@"updateQueWhenBinImgUploaded":@"fail"}];
                            failure(error);
                        }
                    }
                }];
                //                    //7. 调用success
                //                    success(responseObject);
                
            } failure:^(NSError *error) {
                LogFile([NSString stringWithFormat:@"POSTFIle Fail: %@", error]);

                failure(error);
                
            }];
        } else {
            MDLog(@"add que failure:");
            
            LogFile(@"addQueWhenBinImgCreated fail!!!");
            
            NSError *error = [NSError errorWithDomain:ERROR_DOMAIN code:ERROR_COREDATA userInfo:@{@"objID":@"empty"}];
            failure(error);
        }
        
    }];
}


// 请求问题答案
- (void)requestAnswer:(NSString *)imageID success:(BlockResponse)success failure:(BlockResponseFailure)failure
{
    if (!imageID) {
        NSError *error = [NSError errorWithDomain:ERROR_DOMAIN code:ERROR_PARAM_INVALID userInfo:nil];
        failure(error);
        return;
    }
    
    
}

// 删除问题
// api/question/del
- (void)deleteQuestion:(NSString *)imageId  success:(BlockResponse)success failure:(BlockResponseFailure)failure
{
    if (imageId==nil || imageId.length==0) {
        NSError *error = [NSError errorWithDomain:ERROR_DOMAIN code:ERROR_PARAM_INVALID userInfo:nil];
        failure(error);
        return;
    }
    
    NSDictionary *input = [NSDictionary dictionaryWithObjectsAndKeys:imageId, PARAM_IMAGE_ID, nil];
    NSString *strURL = [NSString stringWithFormat:@"%@%@", MD_DOMAIN, OP_QUESTION_DELETE];
    
    [[MDNetworking sharedInstance]sendPOSTRequest:strURL withData:input withTimeout:HTTP_REQ_TIMEOUT success:success failure:failure];
}

@end




