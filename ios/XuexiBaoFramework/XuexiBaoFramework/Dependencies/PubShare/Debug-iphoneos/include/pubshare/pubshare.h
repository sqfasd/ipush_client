//
//  pubshare.h
//  pubshare
//
//  Created by Tim on 14-6-24.
//  Copyright (c) 2014年 xuexibao. All rights reserved.
//





#define IS_IPHONE_4 (fabs((double)[[UIScreen mainScreen]bounds].size.height - (double)480) < DBL_EPSILON)
#define IS_IPHONE_5 (fabs((double)[[UIScreen mainScreen]bounds].size.height - (double)568) < DBL_EPSILON)
#define IS_IPHONE_6 (fabs((double)[[UIScreen mainScreen]bounds].size.height - (double)667) < DBL_EPSILON)
#define IS_IPHONE_6_PLUS (fabs((double)[[UIScreen mainScreen]bounds].size.height - (double)736) < DBL_EPSILON)

#define SCREEN_isHigherThaniPhone4 ((isPad_AllTargetMode_SC && [[UIScreen mainScreen] applicationFrame].size.height <= 960 ? NO : ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? ([[UIScreen mainScreen] currentMode].size.height > 960 ? YES : NO) : NO)))
#define DEVICE_ORIENTATION [[UIDevice currentDevice] orientation]

#define SCREEN_HEIGHT [[UIScreen mainScreen] bounds].size.height
#define SCREEN_WIDTH [[UIScreen mainScreen] bounds].size.width
#define SCREEN_RECT CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)





#define COLOR_NAVIGATIONBAR         color_with_rgb(0,145,255)
#define COLOR_NAV_TITLE             color_with_rgb(255,255,255)
#define COLOR_BLANK_BACKGROUND      color_with_rgb(247,247,247)
#define COLOR_THEME_BLUE            color_with_rgb(0,145,255)
#define COLOR_THEME_RED             color_with_rgb(248,97,97)
#define COLOR_THEME_CONTENT         color_with_rgb(119,119,119)
#define COLOR_THEME_LIGHTCONTENT    color_with_rgb(174,174,174)
#define COLOR_THEME_GREEN           color_with_rgb(102,194,28)
#define COLOR_SEPARATOR_COLOR       color_with_rgb(235,235,235)

#define COLOR_SELECTEDBTN_BACKGROUND      color_with_rgb(244,244,244)
#define COLOR_SEPARATOR_COLOR       color_with_rgb(235,235,235)




//Log
#if DEBUG
#define MDLog(...) NSLog(__VA_ARGS__)
//#define MDLog(...)
#else
#define MDLog(...)
#endif


char *encryptForContent(const char *content, size_t contentSize);


