//
//  XClientOption.h
//  xcomet
//
//  Created by kimziv on 15/5/7.
//  Copyright (c) 2015年 kimziv. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface XClientOption : NSObject
@property(nonatomic, strong)NSString *host;
@property(nonatomic,assign)NSInteger port;
@property(nonatomic, strong)NSString *userName;
@property(nonatomic, strong)NSString *password;
@end
