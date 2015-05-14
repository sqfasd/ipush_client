//
//  MDUserUtil.h
//  education
//
//  Created by Tim on 14-5-27.
//  Copyright (c) 2014年 mudi. All rights reserved.
//

#import <Foundation/Foundation.h>



// 通知：个人信息已经更新
#define NTF_ACCINFO_UPDATED @"ntfaccinfoupdated"


@class MDTopicData;
@class MDCirUnreadMsgData;

@interface MDUserUtil : NSObject

+ (MDUserUtil *)sharedInstance;

@property (nonatomic, strong) NSString *token;
@property (nonatomic, strong) NSString *phoneNo;
@property (nonatomic, strong) NSNumber *gradeId;
@property (nonatomic, strong) NSString *grade;
@property (nonatomic, strong) NSString *school;
@property (nonatomic, strong) NSNumber *score;
@property (nonatomic, strong) NSNumber *goldCoins;
@property (nonatomic, strong) NSNumber *gender;
@property (nonatomic, strong) NSString *avatarUrl;
@property (nonatomic, strong) NSString *userID;
@property (nonatomic, strong) NSString *nickName;
@property (nonatomic, strong) NSString *province;
@property (nonatomic, strong) NSString *city;
@property (nonatomic, strong) NSNumber *provinceId;
@property (nonatomic, strong) NSNumber *cityId;
@property (nonatomic, strong) NSString *countyName;
@property (nonatomic, strong) NSNumber *countyId;
@property (nonatomic, strong) NSString *schoolName;
@property (nonatomic, strong) NSNumber *schoolId;

@property (nonatomic, strong) NSNumber *questionCnt;
@property (nonatomic, strong) NSNumber *topicCnt;
@property (nonatomic, strong) NSNumber *acceptCnt;
@property (nonatomic, strong) NSString *inviteCode;
@property (nonatomic, strong) NSString *invitedCode;
@property (nonatomic, strong) NSString *pushToken;
@property (nonatomic, assign, getter=isDeviceBind) BOOL deviceBind;
//@property (nonatomic, assign, getter=isMobileBind) BOOL mobileBind;
@property (nonatomic, assign, getter=isLogin) BOOL login;
@property (nonatomic, strong) NSString *lastPhoneNO;
@property (nonatomic, assign, getter=isNewUser) BOOL  newUser;
@property (nonatomic, assign) BOOL  isVIP;
@property (nonatomic, assign) BOOL  isCompletedInfo;            //用户资料是否填写完成

//通用图片目录
@property (nonatomic, strong,readonly) NSString *imgsDir;
//用户根目录
@property (nonatomic, strong,readonly) NSString *userRootDir;
//用户个人信息相关目录
@property (nonatomic, strong,readonly) NSString *userInfoDir;
//用户学习圈图片目录
@property (nonatomic, strong,readonly) NSString *userCircleDir;
@property (nonatomic, strong,readonly) NSString *genderText;

// 推荐名师搜索记录
@property (nonatomic, strong) NSMutableArray *teacherSearchHis;
- (NSMutableArray *)updateSearchHisFor:(NSString *)search;
- (void)clearSearchHis;


//是否初始化用户数据
-(BOOL)isUserInit;
-(void)resetAccount;//清除用户数据
- (void)logoff;
//- (BOOL)hasLogin;
- (void)login:(NSString *)phoneNo;

//判断用户是否登录
-(BOOL)isLogin;

// 学习圈：将待上传帖子内容添加到数据库中，并尝试开始上传操作
- (void)addUploadTopicData:(MDTopicData *)topicData;

// V1.3 学习圈：收到本账户的未读消息
- (void)processNewUnreadMsg:(MDCirUnreadMsgData *)unreadData;
// V1.4 学习圈：在线“未读消息”列表
- (void)processNewUnreadMsgArray:(NSArray *)unreadMsgs;

// 学习圈：获取用户信息
- (void)fetchOtherUserInfoWith:(MDCirUnreadMsgData *)unreadData;

//默认头像
-(UIImage *)defaultAvatarForGender:(NSNumber *)gender;
//默认头像
-(UIImage *)defaultAvatar;
// 性别Icon
- (UIImage *)genderIcon;
// 性别Icon
- (UIImage *)genderIconForGender:(NSNumber *)gender;

// 用现成的ImageURL创建帖子
- (void)createTopicWithImgURL:(NSDictionary *)input withTopicData:(MDTopicData *)topicData;

// V1.4
// 激活App时，同步服务端操作
- (void)synchronizeWhileStartup;
// 拉取学习圈“未读消息”列表数据
- (void)synchronizeAllUnreadMsgs;
// 收到一条“消息中心”Push
- (void)receiveMsgCenterPush;
// 清除缓存
- (void)clearCache;
//根据用户判断是否是自己
+(BOOL)isMe:(NSString *)otherUserId;

//清除本地学校信息
+ (void)clearSchoolData;


// V2.4 同步本地未完成上传的记录
- (void)syncLocalIAPRecords:(BlockResponseOK)done;


// V2.0
// 获取指定类型的未读消息
- (void)getMessageUnreadCountFor:(NSInteger)msgType success:(void(^)(NSInteger count))success failure:(BlockResponseFailure)failure;

// 获取积分兑礼品积分数
- (void)getMallScoreInfo:(void(^)(NSInteger))success failure:(BlockResponseFailure)failure;

@end




