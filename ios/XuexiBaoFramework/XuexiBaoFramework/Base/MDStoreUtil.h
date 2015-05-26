//
//  MDStoreUtil.h
//  education
//
//  Created by Tim on 14-5-4.
//  Copyright (c) 2014年 mudi. All rights reserved.
//

#import <Foundation/Foundation.h>




// ID
NSString *IMEI();
NSString *UDID();
NSString *DeviceID();


#pragma mark --
#pragma mark Param define

#define TOPIC_TYPE_ID @"_id"
#define TOPIC_TYPE_NAME @"name"
#define TOPIC_TYPE_COUNT @"topic_count"

#define SUJECT_BIT_MASK @"subject_bit_mask"
#define SUBJECTS_LIST @"subjects_list1"
#define TOPIC_TAG_LIST @"topic_tag_list1"
#define GRADE_LIST @"grade_list"
#define TEACHER_GRADE_LIST @"teacher_grade_list"
#define AREA_LIST @"area_list"
#define CITY_LIST_FORMAT @"area_list_id_%i"

#define CACHE_UNREADCNT_MYASK @"cache_myask_unreadcnt"
#define CACHE_UNREADCNT_MYREPLY @"cache_myreply_unreadcnt"
#define CACHE_UNREADCNT_STROLL @"cache_stroll_unreadcnt"
#define CACHE_MALL_SCORE @"cache_mall_score"
#define CACHE_MALL_HASUNREAD @"cache_mall_hasunread"

#define CACHE_QUE_UNREAD_IMGIDS @"cache_que_unread_imgids"

#define CACHE_OLCONFIG_SHOWINVITE @"cache_olconfig_showinvite"
#define CACHE_OLCONFIG_SHOWPAY @"cache_olconfig_showpay"

// 本地缓存音频余额总数
#define CACHE_ACCOUNT_AUDIOBALANCE @"cache_account_audiobalance"

// Push开关本地设置
#define CACHE_PUSHSWITCH_EVENT @"operation_push_config"
#define CACHE_PUSHSWITCH_HOTTOPIC @"hottopic_push_config"
#define CACHE_PUSHSWITCH_STROLLMSG @"my_entertopic_msg_config"
#define CACHE_PUSHSWITCH_LEARNINGCHAT @"communication_msg_config"


@class MDTopicTagData;

@interface MDStoreUtil : NSObject

@property (nonatomic, strong) NSCache* queTaskCache;
@property (nonatomic, strong) NSMutableArray *subjectList;


//@property (nonatomic, strong) NSString *launchAnnounce;

// 未读题目的列表
+ (void)QueAddUnreadImgID:(NSString *)imageID;
+ (void)QueRemoveUnreadImgID:(NSString *)imageID;
+ (BOOL)IsQueReadForImgID:(NSString *)imageID;


+ (MDStoreUtil *)sharedInstance;


- (NSString *)stringForSubject:(NSInteger)subjectTag;



- (void)removeStoreForKey:(NSString *)key;

// NSUserDefaults
- (void)setObject:(id)object forKey:(NSString *)key;
- (id)getObjectForKey:(NSString *)key;

- (void)setDouble:(double)value forKey:(NSString *)key;
- (double)getDoubleForKey:(NSString *)key;

- (void)setBOOL:(BOOL)value forKey:(NSString *)key;
- (BOOL)getBOOLForKey:(NSString *)key;

- (void)setInt:(NSInteger)value forKey:(NSString *)key;
- (NSInteger)getIntForKey:(NSString *)key;

- (NSArray *)getArrayForKey:(NSString *)key;
- (NSDictionary *)getDictForKey:(NSString *)key;

- (void)saveCustomObject:(id)obj forKey:(NSString *)key;
- (id)loadCustomObjectWithKey:(NSString *)key;

// UDID
- (NSString *)keychainID;
- (void)setKeychainID:(NSString *)udid;

// 当前版本是否首次登录
- (BOOL)isCurrentVersionFirstRun;

//程序版本号的获取和设置
//-(NSInteger)storedappVersion;
@property(nonatomic,assign)NSInteger storedAppVersion;
//-(void)setStoredAppVersion:(NSInteger)ver;
+(NSInteger)plistAppVersion;
//1.x升级到2.0用户临时存储上一个版本号
@property(nonatomic,assign)NSInteger tempAppVersion;
@property(nonatomic,assign)NSInteger lastAppVersion;

+(NSString *)standardUserAgent;
//自定义http头信息
+(NSString *)userAgent;


//--Begin------------2.4版本添加新接口及数据----------------

@property   (assign, nonatomic)     BOOL                        isClosedWalletNoticeView;           //是否关闭了钱包提示条
@property   (strong, nonatomic)     NSDictionary           *    knowledgeSelectedBooksInfo;          //知识点教材选择时缓存的数据

@end




