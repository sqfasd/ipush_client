//
//  Header.m
//  XuexiBaoFramework
//
//  Created by 王俊 on 15/5/8.
//  Copyright (c) 2015年 杭州皆冠科技有限公司. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Header.h"
#import "Reachability.h"



NSString* longlong2Str(long long atime)
{
    NSDate *date_l = [NSDate dateWithTimeIntervalSince1970:atime / 1000.0];
    
    NSString *str_l = [MDXuexiBaoAPI .paramTimeFormatter stringFromDate:date_l];
    
    return str_l;
}

// 系统StatusBar显示加载中状态
void ShowLoadingStatus(BOOL show, BOOL autoEnd)
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:show];
        
        if (show && autoEnd) {
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC));
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
            });
        }
    });
}

void ShowAlertView(NSString *title, NSString *msg, NSString *cancelTitle, id delegate)
{
    if (!msg)
        return;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:msg delegate:delegate cancelButtonTitle:cancelTitle otherButtonTitles:nil];
        [alert show];
    });
}

NSString * gen_uuid()
{
    CFUUIDRef uuid_ref = CFUUIDCreate(NULL);
    CFStringRef uuid_string_ref= CFUUIDCreateString(NULL, uuid_ref);
    
    CFRelease(uuid_ref);
    NSString *uuid = [NSString stringWithString:(__bridge NSString*)uuid_string_ref];
    
    CFRelease(uuid_string_ref);
    return uuid;
}

id JsonValue(id value, NSString *defaultClass)
{
    if (!value) {
        if (!defaultClass || [defaultClass length] <= 0)
            return nil;
        
        return [[NSClassFromString(defaultClass) alloc] init];
    }
    
    if ([value isKindOfClass:[NSNumber class]] && [defaultClass isEqualToString:CLASS_NSSTRING]) {
        return [[NSString alloc] initWithFormat:@"%ld", (long)((NSNumber *)value).integerValue];
    }
    
    if ([value isKindOfClass:[NSString class]] && [defaultClass isEqualToString:CLASS_NSNUMBER]) {
        return [NSNumber numberWithInteger:((NSString *)value).integerValue];
    }
    
    if ([value isKindOfClass:[NSNull class]] || ![value isKindOfClass:[NSClassFromString(defaultClass) class]])
        return [[NSClassFromString(defaultClass) alloc] init];
    
    return value;
}

BOOL IsResponseOK(NSDictionary *jsonDict)
{
    if (!jsonDict ||  ![jsonDict isKindOfClass:[NSDictionary class]] || jsonDict.count <= 0) {
#ifdef MD_DEBUG
        [SVProgressHUD showStatus:NSLocalizedString(@"response_no_data", @"")];
#endif
        return NO;
    }
    
    BOOL result = NO;
    NSNumber *status = JsonValue([jsonDict objectForKey:@"status"], CLASS_NSNUMBER);
    if (status.integerValue == 0) {
        result = YES;
    }else if(status.integerValue == -5 || status.integerValue == -2){
        
        NSString *msg=[jsonDict nonNullObjectForKey:@"msg"];
        if (msg && msg.length>0) {
            [SVProgressHUD showStatus:[jsonDict nonNullObjectForKey:@"msg"]]; // did by snmhm1991
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kNOTIFICATION_NAME_NoAuth object:nil userInfo:nil];
    }else if(status.integerValue==-3)
    {
        [SVProgressHUD dismiss];
        [[NSNotificationCenter defaultCenter] postNotificationName:kNOTIFICATION_NAME_NoAuth object:nil userInfo:nil];
    }else{
        NSString *msg=[jsonDict nonNullObjectForKey:@"msg"];
        if (msg && msg.length>0) {
            [SVProgressHUD showStatus:[jsonDict nonNullObjectForKey:@"msg"]]; // did by snmhm1991
        }
    }
    
    return result;
}

BOOL IsResponseOKNoAlert(NSDictionary *jsonDict)
{
    if (!jsonDict ||  ![jsonDict isKindOfClass:[NSDictionary class]] || jsonDict.count <= 0) {
#ifdef MD_DEBUG
        [SVProgressHUD showStatus:NSLocalizedString(@"response_no_data", @"")];
#endif
        return NO;
    }
    
    BOOL result = NO;
    NSNumber *status = JsonValue([jsonDict objectForKey:@"status"], CLASS_NSNUMBER);
    if (status.integerValue == 0) {
        result = YES;
    }
    else if(status.integerValue == -5 || status.integerValue == -2){
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kNOTIFICATION_NAME_NoAuth object:nil userInfo:nil];
    }else if(status.integerValue==-3)
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:kNOTIFICATION_NAME_NoAuth object:nil userInfo:nil];
    }
    else{
        NSString *msg=[jsonDict nonNullObjectForKey:@"msg"];
        if (msg && msg.length>0) {
            
        }
    }
    
    return result;
}


CGSize textSizeForTextWithConstrain(NSString *text, UIFont *font, CGSize constrain)
{
    CGSize textSize = CGSizeZero;
    if (!text || text.length <= 0 || !font)
        return textSize;
    
    NSDictionary *attributes = [NSDictionary dictionaryWithObject:font forKey:NSFontAttributeName];
    
    NSAttributedString *attributedText =
    [[NSAttributedString alloc]
     initWithString:text
     attributes:attributes];
    
    CGRect rect = [attributedText boundingRectWithSize:constrain
                                               options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading
                                               context:nil];
    
    return rect.size;
}


// 检测是否能够连接网络
void StartReachabilityCheck(BlockReachable reachable, BlockUnreachable unreachable)
{
    Reachability *reach = [Reachability reachabilityWithHostname:@"www.baidu.com"];
    if (NotReachable == reach.currentReachabilityStatus) {
        if (unreachable) {
            MDLog(@"Reachability www.baidu.com unreachable");
            unreachable();
        }
    }
    else {
        if (reachable) {
            MDLog(@"Reachability www.baidu.com reachable");
            reachable();
        }
    }
}

void StartReachabilityInternetChange(BlockReachable reachable, BlockUnreachable unreachable) {
    Reachability *reach = [Reachability reachabilityForInternetConnection];
    if (reachable) {
        reach.reachableBlock = ^(Reachability *reach) {
            MDLog(@"Reachability internet reachable");
            reachable();
        };
    }
    
    if (unreachable) {
        reach.unreachableBlock = ^(Reachability *reach) {
            MDLog(@"Reachability unreachable");
            unreachable();
        };
    }
    
    [reach startNotifier];
}

// 检测是否有WIFI连接
void StartReachabilityForWIFI(BlockReachable reachable, BlockUnreachable unreachable) {
    Reachability *reach = [Reachability reachabilityWithHostname:@"www.baidu.com"];
    if (ReachableViaWiFi == reach.currentReachabilityStatus) {
        if (reachable) {
            MDLog(@"Reachability www.baidu.com wifi reachable");
            reachable();
        }
    }
    else {
        if (unreachable) {
            MDLog(@"Reachability www.baidu.com wifi unreachable");
            unreachable();
        }
    }
    
    [reach startNotifier];
}

