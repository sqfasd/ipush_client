//
//  MDNetworking.h
//  education
//
//  Created by Tim on 14-5-4.
//  Copyright (c) 2014年 mudi. All rights reserved.
//

#import <Foundation/Foundation.h>


#define QUEUE_DEFAULT_THREADCOUNT 1

@interface MDNetworking : NSObject

+ (MDNetworking *)sharedInstance;

- (void)setRequestCookie:(NSString *)cookie;

- (void)sendGETRequest:(NSString *)strURL withData:(NSDictionary *)data withTimeout:(NSTimeInterval)timeout success:(BlockResponse)success failure:(BlockResponseFailure)failure;

- (void)sendPOSTRequest:(NSString *)strURL withData:(NSDictionary *)data withTimeout:(NSTimeInterval)timeout success:(BlockResponse)success failure:(BlockResponseFailure)failure;

- (void)POSTForFileContent:(NSString *)strURL withInput:(NSDictionary *)input timeout:(NSTimeInterval)timeout success:(BlockResponse)success failure:(BlockResponseFailure)failure;

- (void)sendPOSTRequest:(NSString *)strUrl withData:(NSDictionary *)data withTimeout:(NSTimeInterval)timeout showAlert:(BOOL)show success:(BlockResponse)success failure:(BlockResponseFailure)failure;


- (void)sendPOSTRequest:(NSString *)strURL withData:(NSDictionary *)data paramForm:(ParamForm)paramForm withTimeout:(NSTimeInterval)timeout success:(BlockResponse)success failure:(BlockResponseFailure)failure;

- (void)sendPOSTRequest:(NSString *)strURL withData:(NSDictionary *)data paramForm:(ParamForm)paramForm withTimeout:(NSTimeInterval)timeout showAlert:(BOOL)show  success:(BlockResponse)success failure:(BlockResponseFailure)failure;


@end




