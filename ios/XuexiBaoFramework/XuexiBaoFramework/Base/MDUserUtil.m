//
//  MDUserUtil.m
//  education
//
//  Created by Tim on 14-5-27.
//  Copyright (c) 2014年 mudi. All rights reserved.
//

#import "MDUserUtil.h"
#import "UIAlertView+Blocks.h"
#import "MDXuexiBaoOperationMgr.h"



@interface MDUserUtil ()

{
    BOOL isDoingTopicSync;
    NSLock *_lockUpdLocalTopic;
}

@property (nonatomic, strong) NSMutableArray *postTopicArray;

// 学习圈：读取数据库，将所有待上传帖子同步到服务端
- (void)syncLocalTopicsData;

@end



@implementation MDUserUtil
@synthesize token=_token;
@synthesize phoneNo = _phoneNo;
@synthesize grade = _grade;
@synthesize school =_school;
@synthesize gender =_gender;
@synthesize avatarUrl=_avatarUrl;
@synthesize userID = _userID;
@synthesize nickName=_nickName;
@synthesize userRootDir=_userRootDir;
@synthesize userInfoDir=_userInfoDir;
@synthesize userCircleDir=_userCircleDir;
@synthesize imgsDir=_imgsDir;
@synthesize  genderText=_genderText;
@synthesize  province=_province;
@synthesize  city=_city;
@synthesize provinceId=_provinceId;
@synthesize cityId=_cityId;
@synthesize countyName=_countyName;
@synthesize countyId=_countyId;
@synthesize schoolName=_schoolName;
@synthesize schoolId=_schoolId;

@synthesize deviceBind=_deviceBind;
@synthesize gradeId=_gradeId;
@synthesize login=_login;
@synthesize questionCnt=_questionCnt;
@synthesize topicCnt=_topicCnt;
@synthesize acceptCnt=_acceptCnt;
@synthesize inviteCode=_inviteCode;
@synthesize invitedCode=_invitedCode;
@synthesize lastPhoneNO=_lastPhoneNO;
@synthesize pushToken =_pushToken;
@synthesize newUser=_newUser;
@synthesize score=_score;
@synthesize goldCoins=_goldCoins;
@synthesize isVIP=_isVIP;

+ (MDUserUtil *)sharedInstance
{
    static MDUserUtil *sharedUser = nil;
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        sharedUser = [[self alloc] init];
    });
    
    return sharedUser;
}

- (id)init
{
    self = [super init];
    if (self) {
        isDoingTopicSync = NO;
        _isVIP = NO;
        _lockUpdLocalTopic = [[NSLock alloc] init];
    }
    
    return self;
}


#pragma mark Properties

- (NSMutableArray *)postTopicArray
{
    if (!_postTopicArray) {
        _postTopicArray = [[NSMutableArray alloc] init];
    }
    
    return _postTopicArray;
}

-(NSString *)token
{
    _token=[[MDStoreUtil sharedInstance] getObjectForKey:UD_UDTOKEN];
    return _token;
}

-(void)setToken:(NSString *)token
{
    [[MDStoreUtil sharedInstance] setObject:token forKey:UD_UDTOKEN];
    _token=token;
}



- (BOOL)isCompletedInfo
{
    BOOL isCompleted = NO;
    if(self.avatarUrl.length > 0 && self.nickName.length > 0 && self.gender && self.gender.intValue != -1 && self.gradeId && self.gradeId.intValue != -1 && self.provinceId && self.provinceId.intValue != -1 && self.schoolId && self.schoolId.integerValue != -1){
        isCompleted = YES;
    }
    return isCompleted;
}

//通用图片目录
-(NSString *)imgsDir
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *imgsPath=[MDFileUtil.documentFolder stringByAppendingPathComponent:DIR_IMGS];
    BOOL isDir;
    NSError *error;
    if ([fileManager fileExistsAtPath:imgsPath isDirectory:&isDir]) {
        if (!isDir) {
            if (![fileManager removeItemAtPath:imgsPath error:&error]) {
                MDLog(@"remove user rubish file fail:%@",error.description);
            }
        }else{
            return imgsPath;
        }
    }
    if (![fileManager createDirectoryAtPath:imgsPath withIntermediateDirectories:YES attributes:nil error:&error]) {
        MDLog(@"create user root dir fail:%@",error.description);
        return nil;
    }
    return imgsPath;
}


-(NSString *)genderText
{
    NSNumber *gender=[self gender];
    if (gender) {
        if ([gender isEqual:@(SEX_MALE)]) {
            return NSLocalizedString(@"gender_male", @"gender_male");
        }else if([gender isEqual:@(SEX_FEMALE)]){
            return NSLocalizedString(@"gender_female", @"gender_male");
        }
    }
    return @"";
}

-(BOOL)isUserInit
{
    return (self.nickName!=nil);
}

-(void)resetAccount
{
    self.userID=nil;
    self.phoneNo = self.grade = nil;
    self.nickName=nil;
    self.school=nil;
    self.avatarUrl=nil;
    self.gender=nil;
    self.grade=nil;
    self.gradeId=nil;
    self.avatarUrl=nil;
    self.invitedCode=nil;
    self.inviteCode=nil;
    self.questionCnt=nil;
    self.topicCnt=nil;
    self.acceptCnt=nil;
    self.login=NO;
    self.province = nil;
    self.city=nil;
    self.score = nil;
    self.goldCoins=nil;
    self.provinceId=nil;
    self.cityId=nil;
    self.deviceBind=NO;

    _teacherSearchHis = nil;

    //pushToken;
}


// 激活App时，同步服务端操作
- (void)synchronizeWhileStartup
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // 1. 拉取问题列表需要的数据
        
        // 4. 开启重传“失败题目”的任务
        [[MDXuexiBaoOperationMgr sharedInstance] checkAndSyncUpdFailSubjects:NO];
    });
    
    UIApplication* application = [UIApplication sharedApplication];
    [application setApplicationIconBadgeNumber:0];
    [application cancelAllLocalNotifications];
}


// 清除缓存
- (void)clearCache
{
    __weak id weakSelf = self;
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"alert_title", @"") message:NSLocalizedString(@"alert_clearcache_remind", @"") delegate:nil cancelButtonTitle:NSLocalizedString(@"Cancel", @"") otherButtonTitles:NSLocalizedString(@"Continue", @""), nil];

    [alert showWithHandler:^(UIAlertView *alertView, NSInteger buttonIndex) {
        if (buttonIndex == 1) {
            [weakSelf internalClearCache];
        }
    }];
}

//清除本地学校信息
+ (void)clearSchoolData
{
    [MDUserUtil sharedInstance].schoolName = @"";
    [MDUserUtil sharedInstance].schoolId = @(-1);
    [MDUserUtil sharedInstance].countyName = @"";
    [MDUserUtil sharedInstance].countyId = @(-1);
}

- (void)internalClearCache
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        MDLog(@"internalClearCache begin");
        NSFileManager *fileMgr = [NSFileManager defaultManager];
        NSInteger totalSize = 0;
        
        NSError *error = nil;
        NSArray *fileArray = [fileMgr contentsOfDirectoryAtPath:self.imgsDir error:&error];

        
        dispatch_async(dispatch_get_main_queue(), ^{
           [SVProgressHUD showMDBusying];
        });
        
        for (int i = 0; i < fileArray.count; i++) {
            NSString *fullPath = [self.imgsDir stringByAppendingPathComponent:[fileArray objectAtIndex:i]];
            MDLog(@"fullPath: %@", fullPath);
            BOOL isDir;
            if ([fileMgr fileExistsAtPath:fullPath isDirectory:&isDir] && !isDir) {
                NSDictionary *fileAttributeDic = [fileMgr attributesOfItemAtPath:fullPath error:&error];
                if (!fileAttributeDic) {
                    MDLog(@"%@ fileAttr invalid: %@", fullPath, error);
                    continue;
                }
                
                totalSize += fileAttributeDic.fileSize;
                [fileMgr removeItemAtPath:fullPath error:&error];
            }
        }
        
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [SVProgressHUD dismiss];
            
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"alert_title", @"") message:[NSString stringWithFormat:NSLocalizedString(@"alert_clearcache_result", @""), totalSize / (CGFloat)(1024 * 1024)] delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"") otherButtonTitles:nil];
            [alert show];
        });
        
        MDLog(@"internalClearCache end totalSize:%ld", (long)totalSize);
    });
}


+(BOOL)isMe:(NSString *)otherUserId
{
    NSString *myUserId=[self sharedInstance].userID;
    if (otherUserId && myUserId) {
        return [otherUserId isEqualToString:myUserId];
    }
    return NO;
}

@end








