//
//  MDNetCommonOperation.m
//  education
//
//  Created by Tim on 14-5-16.
//  Copyright (c) 2014年 mudi. All rights reserved.
//

#import "MDNetCommonOperation.h"



@implementation MDNetCommonOperation

- (id)initWithMethod:(NSString *)method andURL:(NSString *)url andData:(NSDictionary *)input
{
    self = [super init];
    if (self) {
        self.requestMethod = method;
        self.url = url;
        self.input = input;
    }
    
    return self;
}

- (void)main
{
    if (!self.requestMethod)
        return;
    
    
}

@end
