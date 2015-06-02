//
//  Header.h
//  XuexiBaoFramework
//
//  Created by 王俊 on 15/5/7.
//  Copyright (c) 2015年 杭州皆冠科技有限公司. All rights reserved.
//

//#ifndef XuexiBaoFramework_Header_h
//#define XuexiBaoFramework_Header_h



//Log
#if DEBUG
#define MDLog(...) NSLog(__VA_ARGS__)
//#define MDLog(...)
#else
#define MDLog(...)
#endif





//#define MD_DEBUG


#ifdef MD_DEBUG

#define MD_DOMAIN @"http://192.168.1.231:3000"

// 线上环境
#define MD_DOMAIN_PIC @"http://imgapi2.91xuexibao.com"
// 测试环境
//#define MD_DOMAIN_PIC @"http://192.168.1.230:30001"

#define MD_DOMAIN_AD @"http://adv.91xuexibao.com:3010"
#define MD_DOMAIN_MOBILE @"http://m.91xuexibao.com:3000"
#define MD_DOMAIN_PAY   @"https://pay.91xuexibao.com"
//@"https://webapi.91xuexibao.com"
#define MD_URL_FEATUREINTRO @"http://www.xuexibao.cn/app/v_2.6.html"
#define MD_URL_STATEMENT @"http://www.xuexibao.cn/html/protocol-com.html"



#else

#define MD_DOMAIN  @"http://webapi.91xuexibao.com"

#define MD_DOMAIN_HZ @"http://121.41.106.37:8080"

// 线上环境
#define MD_DOMAIN_PIC @"http://imgapi2.91xuexibao.com"
// 测试环境
//#define MD_DOMAIN_PIC @"http://192.168.1.230:30001"

#define MD_DOMAIN_AD @"http://adv.91xuexibao.com"
#define MD_DOMAIN_MOBILE @"http://m.91xuexibao.com"
#define MD_DOMAIN_PAY   @"https://pay.91xuexibao.com"
//@"https://webapi.91xuexibao.com"
#define MD_URL_FEATUREINTRO @"http://www.xuexibao.cn/app/v_2.6.html"
#define MD_URL_STATEMENT @"http://www.xuexibao.cn/html/protocol-com.html"

#endif



#define kAPI_URL @"api_url"
#define UD_PUSH_TOKEN @"udpushtoken"
#define kNTF_REQ_403 @"ntf_req_403"
#define kNTF_REQ_401 @"ntf_req_401"
#define UD_NET_LASTUSED_COOKIE @"udnetlastusedcookie"
#define UD_NET_COOKIE @"cookie"
#define UD_NET_USER_AGENT @"User-Agent"

// 渠道 Begin ****************************
#define CHANNEL_APPSTORE @""
#define CHANNEL_91_HUODONG @"ios_91_huodong"
#define CHANNEL_91_SHOUFA @"ios_91_shoufa"
#define CHANNEL_pp @"ios_pp"
#define CHANNEL_KUAIYONG_SHOUFA @"ios_kuaiyong_shoufa"
#define CHANNEL_KUAIYONG_HUODONG @"ios_kuaiyong_huodong"
#define CHANNEL_ITOOLS @"ios_itools"
#define CHANNEL_XUESHENGZHUAN @"ios_xueshengzhuan"

//XY手机助手 XYshoujizhushou
#define CHANNEL_XYSHOUJIZHUSHOU @"XYshoujizhushou"

//海马手机助手 haimashoujizhushou
#define CHANNEL_HAIMASHOUJIZHUSHOU @"haimashoujizhushou"

//葫芦App商城 huluAPPshangcheng
#define CHANNEL_HULUAPPSHANGCHENG @"huluAPPshangcheng"

//iTools助手 itoolszhushou
#define CHANNEL_ITOOLSZHUSHOU @"itoolszhushou"

//同步推助手 tongbutuizhushou
#define CHANNEL_TONGBUTUIZHUSHOU @"tbtzhushou"

//爱思助手 aisizhushou
#define CHANNEL_AISIZHUSHOU @"aisizhushou"

#define PARAM_CHANNEL CHANNEL_APPSTORE
// 渠道 End *******************************


//Question Status
typedef NS_ENUM(NSInteger, QueStatus){
    QueStatusBinCreated=1,//二值化文件创建并且保存到本地
    QueStatusUploadedFail,//上传失败
    QueStatusUploadedSuccess,//上传成功
    QueStatusReceviedNotification,//收到推送通知
    QueStatusGetAnswerFailure,//找答案失败
    QueStatusRecognitionImgFail,//图片识别失败
    QueStatusAnswerNotFound,//没有找到题目解答
    QueStatusGetAnswerSuccess//获得题目解答
};

//Read Status
typedef NS_ENUM(NSInteger, ReadStatus){
    ReadStatusNo=0,//未读
    ReadStatusYes,//已读
};


#define IS_IPHONE_4 (fabs((double)[[UIScreen mainScreen]bounds].size.height - (double)480) < DBL_EPSILON)
#define IS_IPHONE_5 (fabs((double)[[UIScreen mainScreen]bounds].size.height - (double)568) < DBL_EPSILON)
#define IS_IPHONE_6 (fabs((double)[[UIScreen mainScreen]bounds].size.height - (double)667) < DBL_EPSILON)
#define IS_IPHONE_6_PLUS (fabs((double)[[UIScreen mainScreen]bounds].size.height - (double)736) < DBL_EPSILON)


// GCD
#define dispatch_main_sync_safe(block)\
if ([NSThread isMainThread]) {\
block();\
}\
else {\
dispatch_sync(dispatch_get_main_queue(), block);\
}



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



//Cache Key
#define kCACHE_KEY_QUE_DETAIL_FORMAT @"cache_key_que_detail_%@_v2"
#define kCACHE_KEY_QUE_LIST_FORMAT @"cache_key_que_list_subject_%i_type_%i_page_%i"
//#define kCACHE_KEY_Account_Get_Timeout @"cache_key_account_get_timeout"
#define kCACHE_KEY_REPROT_TYPES_FORMAT @"cache_key_report_types_%i"
#define kCACHE_KEY_QUE_CACHE_INDEX_FORMAT @"cache_key_que_cache_index_imgid%@_v2"
#define kCACHE_KEY_QUE_CACHE_IS_ASKED_FORMAT @"cache_key_que_cache_is_asked_%@"
// V2.2 是否已经评价过
#define kCACHE_KEY_IS_INIT_PWD_FORMAT @"cache_key_is_init_pwd_%@"
#define kCACHE_KEY_AVATAR_FORMAT @"cache_key_avatar_uid_%@"



#define UD_IMEI @"udimei"
#define UD_UDTOKEN @"ududtoken"
#define UD_UDID @"ududid"
#define UD_DEVIDE_ID @"uddeviceid"


// Json
#define CLASS_NSNUMBER @"NSNumber"
#define CLASS_NSSTRING @"NSString"
#define CLASS_NSDICTIONARY @"NSDictionary"
#define CLASS_NSARRAY @"NSArray"



#define kNOTIFICATION_NAME_NoAuth @"noti_name_no_auth"
// Notification V2.0 ************************* Begin
//#define kNTF_QUE_NEW_START @"ntf_que_new_start"
//#define kNTF_QUE_NEW_UPDFAIL @"ntf_que_new_updfail"
//#define kNTF_QUE_REUPLOAD @"ntf_que_reupload"
//#define kNTF_REFRESH_QUESTIONLIST @"ntf_refresh_questionlist"

#define kNTF_REQFORHELP_OK @"ntf_reqforhelp_ok"
#define kNTF_REQFORHELP_FAIL @"ntf_reqforhelp_fail"
#define kNOTIFICATION_NAME_QuestionRead @"noti_name_question_read"
#define kNOTIFICATION_NAME_DelQuestion @"noti_name_del_question"
#define kNOTIFICATION_NAME_BIND_DEV_FINISHED @"noti_name_bind_dev_finished"
//#define kCACHE_NOPUSHREMIND_NOMORE @"cache_nopushremind_nomore"


// 路径
#define DIR_ROOT [MDFileUtil sharedInstance].documentFolder
#define DIR_DATA @"/data"
#define DIR_INFO @"/info"
#define DIR_IMGS @"/imgs"
#define DIR_CIRCLE @"/circle"

#define DIR_ORV2 @"/orv2"
#define DIR_BIV2 @"/biv2"



// NSError
#define ERROR_DOMAIN @"MDError"
#define ERROR_PARAM_INVALID 100
#define ERROR_IMAGE_BLUR 200
#define ERROR_BIN_EMPTY 300
#define ERROR_BIN_TOO_SMALL 301
#define ERROR_COREDATA 400
#define ERROR_RESPONSE_NO_DATA 500
#define ERROR_403 403  //需要重新登录
#define ERROR_401 401 //需要重新绑定


#define kTIME_INTERVAL_HALF_MINUTE    30
#define kTIME_INTERVAL_ONE_MINUTE    60
#define kTIME_INTERVAL_FIVE_MINUTES    60 * 5 //5 minutes
#define kTIME_INTERVAL_TEN_MINUTES    60 * 10 //10 minutes
#define kTIME_INTERVAL_HALF_ONE_HOUR    60 * 30 //
#define kTIME_INTERVAL_ONE_HOUR    60 * 60 //  1 hour
#define kTIME_INTERVAL_TWO_HOURS    60 * 60 * 2
#define kTIME_INTERVAL_HALF_ONE_DAY 60 * 60 * 12
#define kTIME_INTERVAL_ONE_DAY   60 * 60 * 24
#define kTIME_INTERVAL_THREE_DAY    3*60 * 60 *24
#define kTIME_INTERVAL_ONE_WEEK    60 * 60 * 24 * 7
#define kTIME_INTERVAL_INFINITE ((NSDate *)[NSDate distantFuture]).timeIntervalSince1970


// KeyChain
#define KEYCHAIN_SERVICE @"com.91xuexibao.xuexibao"
#define KEYCHAIN_USER @"user"



// 图片处理
#define IMAGE_BLUR_POINT 0.75
#define BIN_MIN_SIZE 900
#define IMAGE_MAX_PIXEL 5000000
#define MIN_PHYSICAL_RAM_SIZE 529481728 //600000000 //


// V2.*
#define COLOR_BG_COMMON [UIColor colorWithHex:0xf7f7f7]
#define kCOLOR_NAVIGATION_BAR 0xf7f7f7
#define kCOLOR_TAB_BAR 0x48c3d3
#define kCOLOR_TEXT_NORMAL_GRAY 0x999999
#define kCOLOR_BG_LIGHT_GRAY 0xf9f9f9
#define kCOLOR_AVATAR_BG_NONE 0xffffff
#define kCOLOR_AVATAR_BG_MALE 0x4bc1d2
#define kCOLOR_AVATAR_BG_FEMALE 0xf999be


#define kSEARCH_TYPE_UNSOLVED @(-1)
#define kSEARCH_TYPE_SOLVED @1



// bundle
#define XXBFRAMEWORK_BUNDLEPATH [[NSBundle mainBundle] pathForResource:@"XuexiBaoBundle" ofType:@"bundle"]
#define XXBFRAMEWORK_BUNDLE [NSBundle bundleWithPath:XXBFRAMEWORK_BUNDLEPATH]
#define LOTSTORYBOARD [UIStoryboard storyboardWithName:@"LOTStoryboard" bundle:XXBFRAMEWORK_BUNDLE]

#define XXBBUNDLEPATH @"XuexiBaoBundle.bundle/"
#define XXBRSRC_NAME(x) [NSString stringWithFormat:@"%@%@", XXBBUNDLEPATH, x]


#define UD_APP_VER @"udappver"
#define UD_TEMP_APP_VER @"temp_ud_app_ver"
#define UD_LAST_APP_VER @"ud_last_app_ver"



// 性别
typedef enum : NSUInteger {
    SEX_UNKONWN = 0,
    SEX_MALE = 1,
    SEX_FEMALE = 2
} SEX;



// Block
typedef void(^BlockUpdImgOK)(NSString *imageURL);
typedef void(^BlockUpdTopicOK)(NSString *topicID);
typedef void(^BlockListOK)(NSDictionary *data);
typedef void(^BlockResponse)(id responseObject);
typedef void(^BlockAction)();
typedef void(^BlockResponseOK)();
typedef void(^BlockResponseFailure)(NSError * error);
typedef void(^BlockCirAddNewUnreadOK)(NSManagedObjectID *objectID, BOOL needGetUserInfo);
typedef void(^BlockCompletionForInt)(NSInteger count);



//long long to str
NSString* longlong2Str(long long atime);
NSString * gen_uuid();

// Response
BOOL IsResponseOK(NSDictionary *jsonDict);
BOOL IsResponseOKNoAlert(NSDictionary *jsonDict);
CGSize textSizeForTextWithConstrain(NSString *text, UIFont *font, CGSize constrain);

// 系统StatusBar显示加载中状态
void ShowLoadingStatus(BOOL show, BOOL autoEnd);

void ShowAlertView(NSString *title, NSString *msg, NSString *cancelTitle, id delegate);


typedef void(^BlockReachable)();
typedef void(^BlockUnreachable)();
// 检测是否能够连接网络
void StartReachabilityCheck(BlockReachable reachable, BlockUnreachable unreachable);
// 检测网络连接是否发生变化（例如WIFI切换为基站信号）
void StartReachabilityInternetChange(BlockReachable reachable, BlockUnreachable unreachable);
// 检测是否有WIFI连接
void StartReachabilityForWIFI(BlockReachable reachable, BlockUnreachable unreachable);




