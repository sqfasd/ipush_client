//
//  Header.m
//  XuexiBaoFramework
//
//  Created by 王俊 on 15/5/8.
//  Copyright (c) 2015年 杭州皆冠科技有限公司. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Header.h"



void ShowAlertView(NSString *title, NSString *msg, NSString *cancelTitle, id delegate)
{
    if (!msg)
        return;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:msg delegate:delegate cancelButtonTitle:cancelTitle otherButtonTitles:nil];
        [alert show];
    });
}