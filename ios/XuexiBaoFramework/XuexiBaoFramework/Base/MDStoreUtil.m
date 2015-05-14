//
//  MDStoreUtil.m
//  education
//
//  Created by Tim on 14-5-4.
//  Copyright (c) 2014年 mudi. All rights reserved.
//

#import "MDStoreUtil.h"
#import <Security/Security.h>
#include <sys/socket.h> // Per msqr
#include <sys/sysctl.h>
#include <net/if.h>
#include <net/if_dl.h>
#import <AdSupport/AdSupport.h>
#import "SSKeyChain.h"
#import "UIDevice+Extension.h"
#import "EGOCache.h"
#import "pubshare.h"
#import "MDNetworking.h"


NSString *IMEI()
{
    NSString *imei = [[MDStoreUtil sharedInstance] getObjectForKey:UD_IMEI];
    if (!imei || imei.length <= 0) {
        // 如果是iOS7之前的系统，获取MAC地址
        if (IOS_VERSION < 7.0) {
            int                 mib[6];
            size_t              len;
            char                *buf;
            unsigned char       *ptr;
            struct if_msghdr    *ifm;
            struct sockaddr_dl  *sdl;
            
            mib[0] = CTL_NET;
            mib[1] = AF_ROUTE;
            mib[2] = 0;
            mib[3] = AF_LINK;
            mib[4] = NET_RT_IFLIST;
            
            if ((mib[5] = if_nametoindex("en0")) == 0) {
                printf("Error: if_nametoindex error\n");
                return NULL;
            }
            
            if (sysctl(mib, 6, NULL, &len, NULL, 0) < 0) {
                printf("Error: sysctl, take 1\n");
                return NULL;
            }
            
            if ((buf = malloc(len)) == NULL) {
                printf("Could not allocate memory. error!\n");
                return NULL;
            }
            
            if (sysctl(mib, 6, buf, &len, NULL, 0) < 0) {
                printf("Error: sysctl, take 2");
                free(buf);
                return NULL;
            }
            
            ifm = (struct if_msghdr *)buf;
            sdl = (struct sockaddr_dl *)(ifm + 1);
            ptr = (unsigned char *)LLADDR(sdl);
            imei = [NSString stringWithFormat:@"%02X:%02X:%02X:%02X:%02X:%02X",
                         *ptr, *(ptr+1), *(ptr+2), *(ptr+3), *(ptr+4), *(ptr+5)];
            free(buf);
        }
        // 如果是iOS7之后的系统，获取IDFA
        else {
            imei = [[[ASIdentifierManager sharedManager] advertisingIdentifier] UUIDString];
        }
        
        [[MDStoreUtil sharedInstance] setObject:imei forKey:UD_IMEI];
    }
    
    return imei;
}

NSString *UDID()
{
    NSString *strUDID = [[MDStoreUtil sharedInstance] keychainID];

    if (!strUDID) {
        strUDID = gen_uuid();
        [[MDStoreUtil sharedInstance] setKeychainID:strUDID];
    }
    
    return strUDID;
}

NSString *DeviceID()
{
    NSString *result = [[MDStoreUtil sharedInstance] getObjectForKey:UD_DEVIDE_ID];
    if (!result || result.length < 5) {
        NSString *imei = UDID();
        if (!imei)
            return nil;
        
        NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:imei, PARAM_IMEI, @"", PARAM_PUID, @"", PARAM_AID, @"", PARAM_WMAC, @"", PARAM_BMAC, [NSString stringWithFormat:@"%lld", (long long)[NSDate date].timeIntervalSince1970 * 1000], PARAM_MILLIS, nil];
        
        NSError *error = nil;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:params options:0 error:&error];
        
        
        NSString *strJson = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
//        char *encrypedChar = encryptForContent(jsonChar, strlen(jsonChar));
        char *encrypedChar = encryptForContent(strJson.UTF8String, strJson.length);
        result = [NSString stringWithUTF8String:encrypedChar];
        
        MDLog(@"jsonData enChar:%s\nencharlen: %lu\nresult0:%@", encrypedChar, strlen(encrypedChar), result);

        

//        NSData *rsaPost = [[MDXuexiBaoAPI sharedInstance] RSAEncrypotoData:[[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding]];
//        result = [rsaPost base64Encoding];
//        MDLog(@"imei:%@\nrsaImei length:%d\nbase64Str:%@", params, rsaPost.length, result);
        
        
        
        [[MDStoreUtil sharedInstance] setObject:result forKey:UD_DEVIDE_ID];
    }

    return result;
}



@interface MDStoreUtil ()

@end


@implementation MDStoreUtil

@synthesize subjectList=_subjectList;
@synthesize queTaskCache=_queTaskCache;
@synthesize storedAppVersion=_storedAppVersion;
@synthesize lastAppVersion=_lastAppVersion;
@synthesize tempAppVersion=_tempAppVersion;
@synthesize isClosedWalletNoticeView=_isClosedWalletNoticeView;
@synthesize knowledgeSelectedBooksInfo=_knowledgeSelectedBooksInfo;

+ (MDStoreUtil *)sharedInstance
{
    static MDStoreUtil *sharedStoreUtil = nil;
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        sharedStoreUtil = [[self alloc] init];
    });
    
    return sharedStoreUtil;
}

- (id)init
{
    self = [super init];
    if (self) {

    }
    
    return self;
}


// UDID
- (NSString *)keychainID
{
    return [SSKeychain passwordForService:KEYCHAIN_SERVICE account:KEYCHAIN_USER];
}

- (void)setKeychainID:(NSString *)udid
{
    [SSKeychain setPassword:udid forService:KEYCHAIN_SERVICE account:KEYCHAIN_USER];
}


- (NSString *)stringForSubject:(NSInteger)subjectTag
{
    NSString *result = @"";
    
    for (NSDictionary *subject in self.subjectList) {
        NSNumber *tag = [subject nonNullObjectForKey:@"subjectId"];
        if (tag && tag.integerValue == subjectTag) {
            result = [subject nonNullObjectForKey:@"name"];
            break;
        }
    }
    
    return result;
}

#pragma mark Properties
-(NSMutableArray *)subjectList
{
    NSArray *subs = (NSArray *)[[EGOCache globalCache] objectForKey:SUBJECTS_LIST];
    
    if (subs && subs.count>0) {
        _subjectList = [subs mutableCopy];
    }
    else {
        _subjectList = [NSMutableArray array];
    }
    
    return _subjectList;
}



#pragma mark General Operations
// 未读题目的列表
+ (void)QueAddUnreadImgID:(NSString *)imageID
{
    if (!imageID || ![imageID isKindOfClass:[NSString class]]|| imageID.length <= 0)
        return;
    
    NSMutableDictionary *dictData = nil;
    NSDictionary *cacheUnreadQues = (NSDictionary *)[[EGOCache globalCache] objectForKey:CACHE_QUE_UNREAD_IMGIDS];
    
    if (!cacheUnreadQues) {
        dictData = [[NSMutableDictionary alloc] init];
    }
    else {
        dictData = [[NSMutableDictionary alloc] initWithDictionary:cacheUnreadQues];
    }
    
    [dictData setObject:imageID forKey:imageID];
    
    [[EGOCache globalCache] setObject:[dictData copy] forKey:CACHE_QUE_UNREAD_IMGIDS withTimeoutInterval:kTIME_INTERVAL_INFINITE];
}

+ (void)QueRemoveUnreadImgID:(NSString *)imageID
{
    if (!imageID || ![imageID isKindOfClass:[NSString class]] || imageID.length <= 0)
        return;
    
    NSMutableDictionary *dictData = nil;
    NSDictionary *cacheUnreadQues = (NSDictionary *)[[EGOCache globalCache] objectForKey:CACHE_QUE_UNREAD_IMGIDS];
    
    if (!cacheUnreadQues || cacheUnreadQues.count <= 0)
        return;

    dictData = [[NSMutableDictionary alloc] init];
    for (NSString *key in [cacheUnreadQues allKeys]) {
        if ([key isEqualToString:imageID])
            continue;
        
        [dictData setObject:key forKey:key];
    }
    
    [[EGOCache globalCache] setObject:[dictData copy] forKey:CACHE_QUE_UNREAD_IMGIDS withTimeoutInterval:kTIME_INTERVAL_INFINITE];
}

+ (BOOL)IsQueReadForImgID:(NSString *)imageID
{
    NSDictionary *cacheUnreadQues = (NSDictionary *)[[EGOCache globalCache] objectForKey:CACHE_QUE_UNREAD_IMGIDS];
    
    if (!cacheUnreadQues || cacheUnreadQues.count <= 0)
        return YES;
    
    for (NSString *key in [cacheUnreadQues allKeys]) {
        if ([imageID isEqualToString:key]) {
            return NO;
        }
    }
    
    return YES;
}

- (void)setObject:(id)object forKey:(NSString *)key
{
//    if (!object || !key || [key length] <= 0)
//        return;
    if (!key || [key length] <= 0)//fix bug
        return;
    
    [[NSUserDefaults standardUserDefaults] setObject:object forKey:key];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (id)getObjectForKey:(NSString *)key
{
    if (!key || [key length] <= 0)
        return nil;
    
    return [[NSUserDefaults standardUserDefaults] objectForKey:key];
}

- (void)setBOOL:(BOOL)value forKey:(NSString *)key
{
    [[NSUserDefaults standardUserDefaults] setBool:value forKey:key];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (BOOL)getBOOLForKey:(NSString *)key
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:key];
}

- (void)setDouble:(double)value forKey:(NSString *)key
{
    if (!key || [key length] <= 0) {
        return;
    }
    
    [[NSUserDefaults standardUserDefaults] setDouble:value forKey:key];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (double)getDoubleForKey:(NSString *)key
{
    if (!key || [key length] <= 0) {
        return 0;
    }
    return [[NSUserDefaults standardUserDefaults] doubleForKey:key];
}

- (void)setInt:(NSInteger)value forKey:(NSString *)key
{
    if (!key || [key length] <= 0) {
        return;
    }
    
    [[NSUserDefaults standardUserDefaults] setInteger:value forKey:key];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSInteger)getIntForKey:(NSString *)key
{
    if (!key || [key length] <= 0) {
        return 0;
    }
    return [[NSUserDefaults standardUserDefaults] integerForKey:key];
}

- (NSArray *)getArrayForKey:(NSString *)key
{
    if (!key || [key length] <= 0)
        return nil;
    
    return [[NSUserDefaults standardUserDefaults] arrayForKey:key];
}

- (NSDictionary *)getDictForKey:(NSString *)key
{
    if (!key || [key length] <= 0)
        return nil;
    
    return [[NSUserDefaults standardUserDefaults] dictionaryForKey:key];
}

- (void)removeStoreForKey:(NSString *)key
{
    if (!key || [key length] <= 0)
        return ;
    
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:key];
}

- (void)saveCustomObject:(id)obj forKey:(NSString *)key
{
    NSData *myEncodedObject = [NSKeyedArchiver archivedDataWithRootObject:obj];
    [[NSUserDefaults standardUserDefaults] setObject:myEncodedObject forKey:key];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (id)loadCustomObjectWithKey:(NSString *)key
{
    NSData *myEncodedObject = [[NSUserDefaults standardUserDefaults] objectForKey:key];
    return [NSKeyedUnarchiver unarchiveObjectWithData: myEncodedObject];
}

#pragma mark Settings

//当前版本是否首次登录
- (BOOL)isCurrentVersionFirstRun
{
    NSString * buildVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleVersionKey];
    NSString * version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    
    NSString * key = [NSString stringWithFormat:@"%@_%@",buildVersion,version];
    BOOL isCurVerFirstRun = [self getBOOLForKey:key];
    
    if (!isCurVerFirstRun) {
        [self setBOOL:YES forKey:key];
        
        return YES;
    }
    
    return NO;    
}

-(NSInteger)storedAppVersion
{
   _storedAppVersion =  [self getIntForKey:UD_APP_VER];
    return _storedAppVersion;
}

-(void)setStoredAppVersion:(NSInteger)ver
{
    [self setInt:ver forKey:UD_APP_VER];
    _storedAppVersion=ver;
}

+(NSInteger)plistAppVersion
{
    NSDictionary *infoDic=[[NSBundle mainBundle] infoDictionary];
    NSString *ver=[infoDic objectForKey:@"CFBundleShortVersionString"];
    return ver.integerValue;
}

-(NSInteger)tempAppVersion
{
    _tempAppVersion = [self getIntForKey:UD_TEMP_APP_VER];
    return _tempAppVersion;
}

-(void)setTempAppVersion:(NSInteger)tempAppVersion
{
    [self setInt:tempAppVersion forKey:UD_TEMP_APP_VER];
    _tempAppVersion=tempAppVersion;
}

-(NSInteger)lastAppVersion
{
    _lastAppVersion =  [self getIntForKey:UD_LAST_APP_VER];
    return _lastAppVersion;
}

-(void)setLastAppVersion:(NSInteger)lastAppVersion
{
    [self setInt:lastAppVersion forKey:UD_LAST_APP_VER];
    _lastAppVersion=lastAppVersion;
}

+(NSString *)userAgent
{
    NSString *model=[[UIDevice currentDevice] platform];
    NSString *systemName=[UIDevice currentDevice].systemName;
    NSString *systemVersion=[UIDevice currentDevice].systemVersion;
    NSString *appName=[[NSBundle mainBundle].infoDictionary objectForKey:@"CFBundleDisplayName"];
    NSString *appVersion=[[NSBundle mainBundle].infoDictionary objectForKey:@"CFBundleVersion"];
    NSError *error=nil;
    NSData *jsonData= [NSJSONSerialization dataWithJSONObject:@{@"dev_model":model?model:@"",@"sys_name":systemName?systemName:@"",@"sys_ver":systemVersion?systemVersion:@"",@"app_name":appName?appName:@"",@"app_ver":appVersion?appVersion:@"",@"version":@"1"} options:0 error:&error];
    if (error) {
        MDLog(@"error:%@",error.description);
    }
    NSString *agent =[[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding]; //[NSString stringWithFormat:@"{sys_name:%@,sys_ver:%@;app_name:%@;app_ver:%@}",systemName,systemVersion,appName,appVersion];
    MDLog(@"user_agent:%@",agent);
    return agent;
}

+(NSString *)standardUserAgent
{
    NSString *agentFormat=@"XueXiBao/%@ (%@ %@; %@) Build/%@";
    NSString *model=[[UIDevice currentDevice] platform];
    NSString *systemName=[UIDevice currentDevice].systemName;
    NSString *systemVersion=[UIDevice currentDevice].systemVersion;
    //NSString *appName=[[NSBundle mainBundle].infoDictionary objectForKey:@"CFBundleDisplayName"];
    NSString *appVersion=[[NSBundle mainBundle].infoDictionary objectForKey:@"CFBundleVersion"];
    NSString *appBuild=[[NSBundle mainBundle].infoDictionary objectForKey:@"CFBundleShortVersionString"];
    NSString *agent=[NSString stringWithFormat:agentFormat,appVersion,systemName,systemVersion,model,appBuild];
    MDLog(@"User-Agent:%@",agent);
    return agent;
}


-(NSCache *)queTaskCache
{
    if (!_queTaskCache) {
        _queTaskCache=[[NSCache alloc] init];
        [_queTaskCache setCountLimit:10];
    }
    return _queTaskCache;
}

@end





