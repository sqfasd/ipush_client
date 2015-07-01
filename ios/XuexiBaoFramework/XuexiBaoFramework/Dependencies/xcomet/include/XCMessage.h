//
//  XCMessage.h
//  xcomet
//
//  Created by kimziv on 15/5/6.
//  Copyright (c) 2015年 kimziv. All rights reserved.
//

#import <Foundation/Foundation.h>
enum MType {
    T_HEARTBEAT,
    T_SUBSCRIBE,
    T_UNSUBSCRIBE,
    T_MESSAGE,
    T_CHANNEL_MESSAGE,
    T_ACK,
};
@interface XCMessage : NSObject

@property(nonatomic, strong)NSString *from;
@property(nonatomic, strong)NSString *to;
@property(nonatomic, assign)UInt32 seq;
@property(nonatomic, assign)NSInteger type;
@property(nonatomic, strong)NSString *user;
@property(nonatomic, strong)NSString *channel;
@property(nonatomic, strong)NSString *body;

+(XCMessage *)fromJsonData:(NSData *)data;
-(NSData*)toJsonData;
-(NSData *)toPacketData;
@end
