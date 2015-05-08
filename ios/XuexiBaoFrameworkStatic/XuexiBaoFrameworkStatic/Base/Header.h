//
//  Header.h
//  XuexiBaoFramework
//
//  Created by 王俊 on 15/5/7.
//  Copyright (c) 2015年 杭州皆冠科技有限公司. All rights reserved.
//

#ifndef XuexiBaoFramework_Header_h
#define XuexiBaoFramework_Header_h



//Log
#if DEBUG
#define MDLog(...) NSLog(__VA_ARGS__)
//#define MDLog(...)
#else
#define MDLog(...)
#endif


#define IS_IPHONE_4 (fabs((double)[[UIScreen mainScreen]bounds].size.height - (double)480) < DBL_EPSILON)
#define IS_IPHONE_5 (fabs((double)[[UIScreen mainScreen]bounds].size.height - (double)568) < DBL_EPSILON)
#define IS_IPHONE_6 (fabs((double)[[UIScreen mainScreen]bounds].size.height - (double)667) < DBL_EPSILON)
#define IS_IPHONE_6_PLUS (fabs((double)[[UIScreen mainScreen]bounds].size.height - (double)736) < DBL_EPSILON)


// iOS系统
#define IOS_VERSION [[[UIDevice currentDevice] systemVersion] floatValue]
#define IS_IOS7_AND_UP (IOS_VERSION >= 7.0)
#define IS_IOS8_AND_UP (IOS_VERSION >= 8.0)



#define SCREEN_HEIGHT [[UIScreen mainScreen] bounds].size.height
#define SCREEN_WIDTH [[UIScreen mainScreen] bounds].size.width
#define SCREEN_RECT CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)


// Color
#define color_with_rgb(r,g,b)       [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:1]
#define COLOR_TEXT_DISABLED         [UIColor colorWithRed:204.0/255 green:204.0/255 blue:204.0/255 alpha:1]
#define COLOR_THEME_MAIN            [UIColor colorWithRed:75.0/255 green:193.0/255 blue:210.0/255 alpha:1]
#define COLOR_BACKGROUND_DARK       [UIColor colorWithRed:51.0/255 green:51.0/255 blue:51.0/255 alpha:1]
#define COLOR_NAVIGATIONBAR         color_with_rgb(0,145,255)
#define COLOR_NAV_TITLE             color_with_rgb(255,255,255)
#define COLOR_BLANK_BACKGROUND      color_with_rgb(247,247,247)
#define COLOR_THEME_BLUE            color_with_rgb(0,145,255)
#define COLOR_THEME_RED             color_with_rgb(248,97,97)
#define COLOR_THEME_CONTENT         color_with_rgb(119,119,119)
#define COLOR_THEME_LIGHTCONTENT    color_with_rgb(174,174,174)
#define COLOR_THEME_GREEN           color_with_rgb(102,194,28)
#define COLOR_SEPARATOR_COLOR       color_with_rgb(235,235,235)




#define EVENT_SUB_CAM_OPEN @"Sub_Cam_Open"
#define EVENT_SUB_CAM_CANCEL @"Sub_Cam_Cancel"
#define EVENT_SUB_CAM_OK @"Sub_Cam_OK"
#define EVENT_SUB_CAM_SELPHOTO @"Sub_Cam_SelPhoto"
#define EVENT_SUB_EDIT_OK @"Sub_Edit_OK"
#define EVENT_SUB_EDIT_CANCLE @"Sub_Edit_Cancle"

#define EVENT_SUB_RESULT_OK @"Sub_Result_OK"    // 返回答案（2.3开始不维护该值）
#define EVENT_SUB_RESULT_ACTIVEPUSH @"Sub_Result_ActivePush"    // 正在运行App


void ShowAlertView(NSString *title, NSString *msg, NSString *cancelTitle, id delegate);


#endif
