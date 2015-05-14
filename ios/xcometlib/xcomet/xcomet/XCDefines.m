//
//  XCDefines.m
//  xcomet
//
//  Created by kimziv on 15/5/7.
//  Copyright (c) 2015年 kimziv. All rights reserved.
//

#import "XCDefines.h"

@implementation XCDefines

inline int hexstr2int(NSString *hexstr)
{
    if (!hexstr || hexstr.length==0) {
        return 0;
    }
    int number = (int)strtol(hexstr.UTF8String, NULL, 16);
    return number;
}
@end
