//
//  XCDefines.h
//  xcomet
//
//  Created by kimziv on 15/5/7.
//  Copyright (c) 2015年 kimziv. All rights reserved.
//

#import <Foundation/Foundation.h>
//日志开关
#if DEBUG
//#if WB_DEBUG
#define XCLog(...) NSLog(__VA_ARGS__)
#else
#define XCLog(...)
#endif
@interface XCDefines : NSObject

@end
