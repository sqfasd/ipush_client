//
//  MDXuexiBaoAPI.h
//  education
//
//  Created by Tim on 14-5-8.
//  Copyright (c) 2014年 mudi. All rights reserved.
//

#import <Foundation/Foundation.h>



// HTTP begin
#define OP_ACCOUNT_BIND @"/api/mobile/bind"
#define OP_LOCATION_UPLOAD @"/api/account/updateCellid"
#define OP_QUESTION_UPLOAD @"/api/question/upload"
// 发送Feedback请求
// user_id=&buz=1&userfile=
#define OP_FEEDBACK @"/api/account/question_v2"


// 学习圈帖子，每页数量
#define ARG_TCOUNT_PERPAGE @"20"

#define OP_DEVICE_BIND @"/api/device/bind"

//参数1.pushtoken 2.token
#define OP_PUSH_TOKEN_UPDATE @"/api/ios/bind"//@"/api/ios/bind_v2"


#define OP_QUE_DETAIL_GET @"/api/getQtnbyImgId"
//删除问题
#define OP_QUESTION_DELETE  @"/api/delLiveaaImageByDevId"

//根据关键字搜索题目
#define OP_QUESTION_QUERY  @"/api/getImageListByQuery"
/***** End API in v1.4 ***************/


/***** Begin API for V1.5(1.*) ***********/
#define OP_APP_ACTIVATE @"/adv/gdt/active"
/***** End API for V1.5(1.*) ***********/

/***** Begin API for V2.0 ***********/
#define OP_QUE_LIST_GET @"/api/question/list_v2"
// 获取题目详情和匹配结果
#define OP_QUESTION_ANSWERS @"/api/question/answers_v2"
//获得学科列表
#define OP_SUBJECTS_GET @"/api/dic/getSubjects"

typedef NS_ENUM(NSInteger, ParamForm) {
    ParamFormURL,
    ParamFormJson
};



// 删除题目
#define OP_QUE_DELETE               @"/api/question/delete"


// 换一题接口
#define OP_QUE_CHOOSE               @"/api/question/questionChoose"



//// 获取抢答列表
//#define OP_PREANSWER_LIST @"/api/studytopic/list"


// 上传图片的类型，服务端使用
typedef enum : NSUInteger {
    UPDIMG_TYPE_STROLL = 1,
    UPDIMG_TYPE_PORTRAIT = 2,
    UPDIMG_TYPE_PREANSWER = 3,
    UPDIMG_TYPE_CHAT = 4
} UPDIMG_TYPE;

/***** End API for V2.0 ***********/




#define HTTP_REQ_TIMEOUT 60
// HTTP end

#define PARAM_PUSH_TOKEN @"pushtoken"

#define PARAM_IMEI @"IMEI"
#define PARAM_PUID @"PUID"
#define PARAM_AID @"AID"
#define PARAM_WMAC @"WMAC"
#define PARAM_BMAC @"BMAC"
#define PARAM_MILLIS @"MILLIS"

#define PARAM_USER_ID @"user_id"
#define PARAM_DEVICE_ID @"dev_id"
#define PARAM_MOBILE @"mobile_number"
#define PARAM_MOBILE_VCODE @"verify_code"

#define PARAM_AREA_PARENTID @"parent_id"
#define PARAM_QUESTION_ID @"qid"
#define PARAM_IMAGE_ID @"image_id"

#define PARAM_GRADE @"edu_grade"
#define PARAM_GRADE_ID @"edu_grade_id"
#define PARAM_ACC_PROVINCE @"edu_province"
#define PARAM_ACC_PROVINCE_ID @"province_id"
#define PARAM_ACC_CITY @"edu_city"
#define PARAM_ACC_CITY_ID @"city_id"
#define PARAM_ACC_ID @"user_id"
#define PARAM_CONTENT @"content"


#define HTTP_HEADER_SETCOOKIR @"Set-Cookie"
#define HTTP_HEADER_COOKIR @"Cookie"

// 各省市数据Json参数
#define AREA_PARAM_ID @"_id"
#define AREA_PARAM_NAME @"name"
#define AREA_PARAM_PARENT @"parent_id"
#define AREA_PARAM_STATUS @"status"
#define AREA_PARAM_CITYARR @"city_arr"


// v2.3 与VIP相关参数

#define     PARAM_VIP_MOBILE        @"mobile"
#define     PARAM_VIP_NAME          @"name"
#define     PARAM_VIP_ORDER         @"orderno"
#define     PARAM_VIP_PSD           @"password"
#define     PARAM_VIP_PRICE         @"feePerHour"
#define     PARAM_VIP_DURATION      @"duration"
#define     PARAM_VIP_MONEY         @"money"
#define     PARAM_VIP_PLATFORM      @"platform"

#define     PARAM_VIP_FAILEDSTATUS  @"failedstatus"
#define     PARAM_VIP_FAILEDDESC    @"faileddesc"
#define     PARAM_VIP_VIP           @"vip"



@interface MDXuexiBaoAPI : NSObject

+ (MDXuexiBaoAPI *)sharedInstance;

+ (NSDateFormatter *)paramTimeFormatter;
+ (NSDateFormatter *)shortTimeFormatter;
+ (NSDateFormatter *)dateTimeFormatter;
+ (NSDateFormatter *)yearMonthTimeFormatter;
+ (NSDateFormatter *)yearMonthDayTimeFormatter;
+ (NSDateFormatter *)weekdayTimeFormatter;



/**********Begin API V2.0*****************/
// 通用接口
- (void)postForAPI:(NSString *)strURL api:(NSString *)api post:(NSDictionary *)input success:(BlockResponse)success failure:(BlockResponseFailure)failure;
- (void)postForAPI:(NSString *)strURL api:(NSString *)api post:(NSDictionary *)input paramForm:(ParamForm)paramForm success:(BlockResponse)success failure:(BlockResponseFailure)failure;
- (void)postForAPI:(NSString *)strUrl api:(NSString *)api post:(NSDictionary *)input showAlert:(BOOL)show success:(BlockResponse)success failure:(BlockResponseFailure)failure;
- (void)postForAPI:(NSString *)strURL api:(NSString *)api post:(NSDictionary *)input paramForm:(ParamForm)paramForm showAlert:(BOOL)show  success:(BlockResponse)success failure:(BlockResponseFailure)failure;
//获取学科列表
-(void)fetchSubjects:(BlockResponse)success failure:(BlockResponseFailure)failure;

//题目详情v2.0
- (void)getQuestionAnswers:(NSDictionary *)params success:(void(^)(id responseObject, BOOL cached))success failure:(BlockResponseFailure)failure;


// V1.5more App首次使用激活
- (void)activateApp:(BlockResponseOK)success failure:(BlockResponseFailure)failure;


//绑定设备
- (void)bindDevice:(NSDictionary *)params success:(BlockResponse)success failure:(BlockResponseFailure)failure;
//获得用户题目列表
- (void)getQueList:(NSDictionary *)params success:(BlockResponse)success failure:(BlockResponseFailure)failure;
//获得题目详情
- (void)getQueDetail:(NSString *)imgId success:(void(^)(id responseObject, BOOL cached))success failure:(BlockResponseFailure)failure;



// 上传题目图片
- (void)uploadSubjectPicture:(UIImage *)image success:(BlockResponse)success failure:(BlockResponseFailure)failure;
- (void)processUploading:(BlockResponse)success failure:(BlockResponseFailure)failure;
- (void)uploadBinFileWithBinPath:(NSString *)binPath andImgPath:(NSString *)imagePath success:(BlockResponse)success failure:(BlockResponseFailure)failure;
// 删除问题
- (void)deleteQuestion:(NSString *)imageId  success:(BlockResponse)success failure:(BlockResponseFailure)failure;



@end




