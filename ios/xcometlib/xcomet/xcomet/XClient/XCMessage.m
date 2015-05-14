//
//  XCMessage.m
//  xcomet
//
//  Created by kimziv on 15/5/6.
//  Copyright (c) 2015年 kimziv. All rights reserved.
//

#import "XCMessage.h"
#define kXC_FROM            @"f"
#define kXC_TO              @"t"
#define kXC_SEQ             @"s"
#define kXC_TYPE            @"y"
#define kXC_USER            @"u"
#define kXC_CHANNEL         @"c"
#define kXC_BODY            @"b"
@interface XCMessage ()
{
   // NSMutableDictionary *_msgDic;
}
@end
@implementation XCMessage
@synthesize from=_from;
@synthesize to=_to;
@synthesize seq=_seq;
@synthesize type=_type;
@synthesize user=_user;
@synthesize channel=_channel;
@synthesize body=_body;


-(instancetype)init
{
    self=[super init];
    if (self) {
        _seq=-1;
        _type=-1;
    }
    return self;
}
//+(XCMessage *)fromPacketData:(NSData *)data
//{
//    [data rangeOfData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding] options:0 range:NSMakeRange(0, data.length)];
//}

+(XCMessage *)fromJsonData:(NSData *)data
{
    NSError *error=nil;
    id jsonObj=[NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    if (error) {
        XCLog(@"fromJsonData error:%@",error);
        return nil;
    }
    if ([NSJSONSerialization isValidJSONObject:jsonObj]) {
        NSDictionary *dic=jsonObj;
        XCMessage *msg=[[XCMessage alloc] init];
        msg.from=[dic objectForKey:kXC_FROM];
        msg.to=[dic objectForKey:kXC_TO];
        msg.seq=[[dic objectForKey:kXC_SEQ] intValue];
        msg.type=[[dic objectForKey:kXC_TYPE] integerValue];
        msg.user=[dic objectForKey:kXC_USER];
        msg.channel=[dic objectForKey:kXC_CHANNEL];
        msg.body=[dic objectForKey:kXC_BODY];
        return msg;
    }
    return nil;
}

-(NSData*)toJsonData
{
    //NSDictionary *dic=@{kXC_FROM:_from};
   
    if (_type==T_HEARTBEAT) {
        return [@" " dataUsingEncoding:NSUTF8StringEncoding];
    }else{
         NSMutableDictionary *dic=[NSMutableDictionary dictionary];
        if (_from) {
            [dic setObject:_from forKey:kXC_FROM];
        }
        if (_to) {
            [dic setObject:_to forKey:kXC_TO];
        }
        if (_seq!=-1) {
            [dic setObject:@(_seq) forKey:kXC_SEQ];
        }
        if (_type!=-1) {
            [dic setObject:@(_type) forKey:kXC_TYPE];
        }
        if (_user) {
            [dic setObject:_user forKey:kXC_USER];
        }
        if (_channel) {
            [dic setObject:_channel forKey:kXC_CHANNEL];
        }
        if (_body) {
            [dic setObject:_body forKey:kXC_BODY];
        }

        if ([NSJSONSerialization isValidJSONObject:dic]) {
            NSError *error=nil;
            NSData *data=[NSJSONSerialization dataWithJSONObject:dic options:0 error:&error];
            return data;
        }
        return nil;
    }
    
}
//static const int MAX_DATA_LEN = 20;

-(NSData *)toPacketData
{
    NSData *msgData=[self toJsonData];
    NSMutableData *packetData=[NSMutableData data];
    NSString *len=[NSString stringWithFormat:@"%lx\r\n",(unsigned long)msgData.length];
    [packetData appendData:[len dataUsingEncoding:NSUTF8StringEncoding]];
    [packetData appendData:msgData];
    [packetData appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    
    return packetData;
}

@end
