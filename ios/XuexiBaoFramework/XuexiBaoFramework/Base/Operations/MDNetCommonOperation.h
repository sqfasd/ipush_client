//
//  MDNetCommonOperation.h
//  education
//
//  Created by Tim on 14-5-16.
//  Copyright (c) 2014年 mudi. All rights reserved.
//

#import <Foundation/Foundation.h>



@protocol NetCommonOperationDelegate <NSObject>

@required
- (void)operation:(NSOperation *)operation didSuccess:(id)responseObject;
- (void)operation:(NSOperation *)operation didFail:(NSError *)error;

@end


@interface MDNetCommonOperation : NSOperation

@property (nonatomic, assign) id<NetCommonOperationDelegate> delegate;

- (id)initWithMethod:(NSString *)method andURL:(NSString *)url andData:(NSDictionary *)input;

@property (nonatomic, strong) NSString *requestMethod;
@property (nonatomic, strong) NSString *url;
@property (nonatomic, strong) NSDictionary *input;

@end
