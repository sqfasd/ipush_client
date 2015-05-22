
//  MDNetworking.m
//  education

//  Created by Tim on 14-5-4.
//  Copyright (c) 2014年 mudi. All rights reserved.


#import "MDNetworking.h"
#import <AFNetworking/AFNetworking.h>
#import <AFHTTPRequestOperation.h>
#import <AFHTTPRequestOperationManager.h>
#import "MDQuestionV2.h"
#import "MSWeakTimer.h"

@interface MDNetworking ()
{
    // MSWeakTimer *_timer;
}
@property (nonatomic, strong, readonly) NSOperationQueue *operationQueue;
@property (nonatomic, strong, readonly) AFHTTPRequestOperationManager *requestManager;
@property (nonatomic, strong, readonly) AFHTTPRequestSerializer *httpRequestSerializer;
@property (nonatomic, strong, readonly) AFJSONRequestSerializer *jsonRequestSerializer;
@end



@implementation MDNetworking

@synthesize requestManager = _requestManager;
@synthesize operationQueue = _operationQueue;
@synthesize httpRequestSerializer=_httpRequestSerializer;
@synthesize jsonRequestSerializer=_jsonRequestSerializer;

+ (MDNetworking *)sharedInstance
{
    static MDNetworking *sharedMDNetworking = nil;
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        sharedMDNetworking = [[self alloc] init];
    });
    
    return sharedMDNetworking;
}

- (id)init
{
    self = [super init];
    if (self) {
        
    }
    
    return self;
}


#pragma mark Properties
- (AFHTTPRequestOperationManager *)requestManager
{
    if (!_requestManager) {
        _requestManager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:[NSURL URLWithString:MD_DOMAIN]];
        _requestManager.securityPolicy=[AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeNone];
        _requestManager.securityPolicy.allowInvalidCertificates=YES;
//        _requestManager.requestSerializer = [AFHTTPRequestSerializer serializer];
//        
//        NSString *lastUsedCookie = [[MDStoreUtil sharedInstance] getObjectForKey:UD_NET_LASTUSED_COOKIE];
//        if (lastUsedCookie && [lastUsedCookie length] > 0) {
//            [_requestManager.requestSerializer setValue:lastUsedCookie forHTTPHeaderField:UD_NET_COOKIE];
//        }
//        
//        //[_requestManager.requestSerializer setValue:[MDStoreUtil userAgent] forHTTPHeaderField:UD_NET_USER_AGENT];

        _requestManager.responseSerializer = [AFJSONResponseSerializer serializer];
        _requestManager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/json", @"text/plain", @"text/html", @"multipart/form-data", @"image/webp", @"*/*", @"application/xml", @"application/xhtml+xml", nil];
    }

    return _requestManager;
}

-(AFHTTPRequestSerializer *)requestSerializerForType:(ParamForm)paramForm
{
    AFHTTPRequestSerializer *requestSerializer=nil;
    switch (paramForm) {
        case ParamFormURL:
            requestSerializer=self.httpRequestSerializer;
            break;
         case ParamFormJson:
            requestSerializer=self.jsonRequestSerializer;
            break;
        default:
            requestSerializer=self.httpRequestSerializer;
            break;
    }
    
    NSString *lastUsedCookie = [[MDStoreUtil sharedInstance] getObjectForKey:UD_NET_LASTUSED_COOKIE];
    if (lastUsedCookie && [lastUsedCookie length] > 0) {
        [requestSerializer setValue:lastUsedCookie forHTTPHeaderField:UD_NET_COOKIE];
    }
    [requestSerializer setValue:[MDStoreUtil standardUserAgent] forHTTPHeaderField:UD_NET_USER_AGENT];

    return requestSerializer;
}

-(AFHTTPRequestSerializer *)httpRequestSerializer
{
     if (!_httpRequestSerializer) {
         _httpRequestSerializer = [AFHTTPRequestSerializer serializer];
     }
      return _httpRequestSerializer;
}

-(AFJSONRequestSerializer *)jsonRequestSerializer
{
    if (!_jsonRequestSerializer) {
        _jsonRequestSerializer=[AFJSONRequestSerializer serializer];
    }
    return _jsonRequestSerializer;
}

- (void)setRequestCookie:(NSString *)cookie
{
    if (!cookie || ![cookie isKindOfClass:[NSString class]] || cookie.length <= 0)
        return;
    
    if ([cookie hasPrefix:@"liveaa_club"]) {
//        MDLog(@"set-cookie: %@", cookie);
        NSRange semiColon = [cookie rangeOfString:@";"];
        NSString *finalCookie = nil;
        if (semiColon.location == NSNotFound) {
            finalCookie = cookie;
        }
        else {
            finalCookie = [cookie substringToIndex:semiColon.location + 1];
        }
        [[MDStoreUtil sharedInstance] setObject:finalCookie forKey:UD_NET_LASTUSED_COOKIE];
        [self.requestManager.requestSerializer setValue:finalCookie forHTTPHeaderField:UD_NET_COOKIE];
    }
}

- (NSOperationQueue *)operationQueue
{
    if (!_operationQueue) {
        _operationQueue = [[NSOperationQueue alloc] init];
        [_operationQueue setMaxConcurrentOperationCount:QUEUE_DEFAULT_THREADCOUNT];
    }
    return _operationQueue;
}


#pragma mark Operations
- (void)sendGETRequest:(NSString *)strURL withData:(NSDictionary *)data withTimeout:(NSTimeInterval)timeout success:(BlockResponse)success failure:(BlockResponseFailure)failure
{
      self.requestManager.requestSerializer=[self requestSerializerForType:ParamFormJson];
    NSMutableURLRequest *request = [self.requestManager.requestSerializer requestWithMethod:@"GET" URLString:[[NSURL URLWithString:strURL relativeToURL:self.requestManager.baseURL] absoluteString] parameters:data error:nil];
    [request setTimeoutInterval:timeout];
    
    AFHTTPRequestOperation *requestOperation = [self.requestManager HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
        MDLog(@"send:%@", strURL);

        NSString *setCookie = [operation.response.allHeaderFields objectForKey:HTTP_HEADER_SETCOOKIR];
        if (setCookie) {
            [self setRequestCookie:setCookie];
        }

        if (success) {
            dispatch_async(dispatch_get_main_queue(), ^{
                success(responseObject);
            });
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        MDLog(@"\nsend:%@\nget:%@\nerror: %@", strURL, data, error);
        if (failure) {
            dispatch_async(dispatch_get_main_queue(), ^{
                failure(error);
            });
        }
    }];
    
    [self.requestManager.operationQueue addOperation:requestOperation];
}

- (void)sendPOSTRequest:(NSString *)strURL withData:(NSDictionary *)data withTimeout:(NSTimeInterval)timeout success:(BlockResponse)success failure:(BlockResponseFailure)failure
{
    [self sendPOSTRequest:strURL withData:data withTimeout:timeout showAlert:YES success:success failure:failure];
}

- (void)sendPOSTRequest:(NSString *)strUrl withData:(NSDictionary *)data withTimeout:(NSTimeInterval)timeout showAlert:(BOOL)show success:(BlockResponse)success failure:(BlockResponseFailure)failure {
    //添加user_agent, token
    NSString *userAgent=[MDStoreUtil userAgent];
    NSString *token=[MDUserUtil sharedInstance].token;
    
    
    NSString *lastUsedCookie = [[MDStoreUtil sharedInstance] getObjectForKey:UD_NET_LASTUSED_COOKIE];
    
    // channel bid
    NSMutableDictionary *fixeData=@{@"user_agent":userAgent?userAgent:@"",@"token":token?token:@"",@"cookie":lastUsedCookie?lastUsedCookie:@"", @"channel":PARAM_CHANNEL, @"bid":[NSBundle mainBundle].bundleIdentifier, @"ver_client":@"2-litefull"}.mutableCopy;
    if (data) {
        [fixeData addEntriesFromDictionary:data];
    }
    
    //MDLog(@"params:%@", fixeData);
    self.requestManager.requestSerializer=[self requestSerializerForType:ParamFormJson];
    NSMutableURLRequest *request = [self.requestManager.requestSerializer requestWithMethod:@"POST" URLString:[[NSURL URLWithString:strUrl relativeToURL:self.requestManager.baseURL] absoluteString] parameters:fixeData error:nil];
    [request setTimeoutInterval:timeout];
    
    // MDLog(@"params:%@", [[NSString alloc] initWithData:request.HTTPBody encoding:NSUTF8StringEncoding]);
    
    AFHTTPRequestOperation *requestOperation = [self.requestManager HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
        MDLog(@"\nsend:%@\npost:%@\nsucess:%@", strUrl, fixeData, responseObject);
        if (operation.response.statusCode == ERROR_403) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:kNTF_REQ_403 object:nil userInfo:nil];
            });
            failure(nil);
            
            return;
        }
        
        NSString *setCookie = [operation.response.allHeaderFields objectForKey:HTTP_HEADER_SETCOOKIR];
        if (setCookie) {
            [self setRequestCookie:setCookie];
        }
        
        if (success) {
            dispatch_async(dispatch_get_main_queue(), ^{
                success(responseObject);
            });
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        MDLog(@"\nsend:%@\npost:%@\nerror: %@", strUrl, fixeData, error);
        if (failure) {
            if (operation.response.statusCode == ERROR_403) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [SVProgressHUD dismiss];
                    [[NSNotificationCenter defaultCenter] postNotificationName:kNTF_REQ_403 object:nil userInfo:@{kAPI_URL:strUrl}];
                });
            }else if (operation.response.statusCode == ERROR_401) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [SVProgressHUD dismiss];
                    [[NSNotificationCenter defaultCenter] postNotificationName:kNTF_REQ_401 object:nil userInfo:@{kAPI_URL:strUrl}];
                });
                
            }else {
                if (show) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if(![SVProgressHUD isVisible]){
                            [SVProgressHUD showStatus:@"没有网络了，检查一下吧！"];
                        }
                    });
                }
            }
            
            failure(error);
        }
    }];
    
    [self.requestManager.operationQueue addOperation:requestOperation];
}


//-(void)post401Notification:(MSWeakTimer *)timer
//{
//    dispatch_async(dispatch_get_main_queue(), ^{
//        [SVProgressHUD dismiss];
//        [[NSNotificationCenter defaultCenter] postNotificationName:kNTF_REQ_401 object:nil userInfo:timer.userInfo];
//        [_timer invalidate];
//        _timer=nil;
//   });
//}

- (void)POSTForFileContent:(NSString *)strURL withInput:(NSDictionary *)input timeout:(NSTimeInterval)timeout success:(BlockResponse)success failure:(BlockResponseFailure)failure
{
    
    //添加user_agent, token
    NSString *userAgent=[MDStoreUtil userAgent];
    NSString *token=[MDUserUtil sharedInstance].token;

    
     NSString *lastUsedCookie = [[MDStoreUtil sharedInstance] getObjectForKey:UD_NET_LASTUSED_COOKIE];
    NSDictionary *fixeData=@{@"user_agent":userAgent?userAgent:@"",@"token":token?token:@"",@"cookie":lastUsedCookie?lastUsedCookie:@""};
    MDLog(@"params:%@", fixeData);
     self.requestManager.requestSerializer=[self requestSerializerForType:ParamFormJson];
    AFHTTPRequestOperation *reqOperation = [self.requestManager POST:strURL parameters:fixeData
    constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        // 直接以 key value 的形式向 formData 中追加二进制数据
        if (input) {
            NSString *token = [[MDStoreUtil sharedInstance] getObjectForKey:UD_PUSH_TOKEN];
            if (token) {
#ifdef MD_DEBUG
//#ifdef DEBUG
                [formData appendPartWithFormData:[token dataUsingEncoding:NSUTF8StringEncoding] name:@"aidtoken"];
                MDLog(@"UpdSubImg form: aidtoken=%@", [token dataUsingEncoding:NSUTF8StringEncoding]);
//#endif
#endif

#ifndef MD_DEBUG
//#ifndef DEBUG
                [formData appendPartWithFormData:[token dataUsingEncoding:NSUTF8StringEncoding] name:@"aidtoken"];
                MDLog(@"UpdSubImg form: aidtoken=%@", [token dataUsingEncoding:NSUTF8StringEncoding]);
//#endif
#endif
            }
            
            for (NSString *key in [input allKeys]) {
                if ([key isEqualToString:@"userfile"] || [key isEqualToString:@"files[]"]) {
                    [formData appendPartWithFileData:[input objectForKey:key] name:key
                                            fileName:@"img.jpg" mimeType:@"image/jpeg"];
                    MDLog(@"UpdSubImg form: image/jpeg img.jpg files[]");
                }
                else if ([key isEqualToString:@"files2[]"]) {
                    [formData appendPartWithFileData:[input objectForKey:key] name:@"files[]" fileName:@"realimg.jpg" mimeType:@"image/jpeg"];
                    MDLog(@"UpdSubImg form: image/jpeg realimg.jpg files[]=");
                }
                else {
                    [formData appendPartWithFormData:[input objectForKey:key] name:key];
                    MDLog(@"UpdSubImg form: %@=%@", key, [input objectForKey:key]);
                }
            }
            
            [formData appendPartWithFormData:[@"2-litefull" dataUsingEncoding:NSUTF8StringEncoding] name:@"ver_client"];
            
            MDLog(@"UpdSubImg form: ver_client=2-litefull");
        }
    }
                      success:^(AFHTTPRequestOperation *operation, id responseObject) {
                          // 成功后的处理
                          MDLog(@"POST file response: %@", responseObject);
                          success(responseObject);
                      }
                      failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                          // 失败后的处理
                          MDLog(@"POST file fail: %@", error);
                          failure(error);
                      }];
    
    NSMutableURLRequest *urlReq = (NSMutableURLRequest *)reqOperation.request;
    if ([urlReq isKindOfClass:[NSMutableURLRequest class]]) {
        
    }
}

#pragma mark - key value参数传递方式
- (void)sendPOSTRequest:(NSString *)strURL withData:(NSDictionary *)data paramForm:(ParamForm)paramForm withTimeout:(NSTimeInterval)timeout success:(BlockResponse)success failure:(BlockResponseFailure)failure
{
    [self sendPOSTRequest:strURL withData:data paramForm:paramForm withTimeout:timeout showAlert:YES success:success failure:failure];
}

- (void)sendPOSTRequest:(NSString *)strURL withData:(NSDictionary *)data paramForm:(ParamForm)paramForm withTimeout:(NSTimeInterval)timeout showAlert:(BOOL)show  success:(BlockResponse)success failure:(BlockResponseFailure)failure
{
    //添加user_agent, token
    NSString *userAgent=[MDStoreUtil userAgent];
    NSString *token=[MDUserUtil sharedInstance].token;
    
    NSString *lastUsedCookie = [[MDStoreUtil sharedInstance] getObjectForKey:UD_NET_LASTUSED_COOKIE];
    
    // channel bid
    NSMutableDictionary *fixeData=@{@"user_agent":userAgent?userAgent:@"",@"token":token?token:@"",@"cookie":lastUsedCookie?lastUsedCookie:@"", @"channel":PARAM_CHANNEL, @"bid":[NSBundle mainBundle].bundleIdentifier, @"ver_client":@"2-litefull"}.mutableCopy;
    if (data) {
        [fixeData addEntriesFromDictionary:data];
    }
    
    //MDLog(@"params:%@", fixeData);
    self.requestManager.requestSerializer=[self requestSerializerForType:paramForm];
    
    NSMutableURLRequest *request = [self.requestManager.requestSerializer requestWithMethod:@"POST" URLString:[[NSURL URLWithString:strURL relativeToURL:self.requestManager.baseURL] absoluteString] parameters:fixeData error:nil];
    [request setTimeoutInterval:timeout];
    
    // MDLog(@"params:%@", [[NSString alloc] initWithData:request.HTTPBody encoding:NSUTF8StringEncoding]);
    
    AFHTTPRequestOperation *requestOperation = [self.requestManager HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
        MDLog(@"\nsend:%@\npost:%@\nsucess: %@", strURL, fixeData, responseObject);
        if (operation.response.statusCode == ERROR_403) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:kNTF_REQ_403 object:nil userInfo:nil];
            });
            failure(nil);
            
            return;
        }
        
        NSString *setCookie = [operation.response.allHeaderFields objectForKey:HTTP_HEADER_SETCOOKIR];
        if (setCookie) {
            [self setRequestCookie:setCookie];
        }
        
        if (success) {
            dispatch_async(dispatch_get_main_queue(), ^{
                success(responseObject);
            });
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        MDLog(@"\nsend:%@\npost:%@\nerror: %@", strURL, fixeData, error);
        if (failure) {
            if (operation.response.statusCode == ERROR_403) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [SVProgressHUD dismiss];
                    [[NSNotificationCenter defaultCenter] postNotificationName:kNTF_REQ_403 object:nil userInfo:@{kAPI_URL:strURL}];
                });
            }else if (operation.response.statusCode == ERROR_401) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [SVProgressHUD dismiss];
                    [[NSNotificationCenter defaultCenter] postNotificationName:kNTF_REQ_401 object:nil userInfo:@{kAPI_URL:strURL}];
                });
                
            }else {
                if(show){
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [SVProgressHUD showStatus:@"没有网络了，检查一下吧！"];
                    });
                }
            }
            
            failure(error);
        }
    }];
    
    [self.requestManager.operationQueue addOperation:requestOperation];
}

#pragma mark 后台操作
/*
 *****************************
 后台任务
 *****************************
 考虑：在开始后台任务之前，将这些managedobjectid数组放到一个后台任务列表中；
    列表中任意一个获得答案的题目，采用统一的隐式通知的方式来刷新界面（例如：弱提示“有题目获得了最新答案”，或者某处显示红色计数标记）
 */


@end




