//
//  MDQuestionData.h
//  education
//
//  Created by Tim on 14/12/18.
//  Copyright (c) 2014年 mudi. All rights reserved.
//

#import <Foundation/Foundation.h>


NSMutableArray *parseQuestionListData(NSArray *data);


@interface MDQuestionData : NSObject

+ (MDQuestionData *)dataWithDict:(NSDictionary *)data;

// 提问相关
@property (nonatomic, strong) NSNumber *rowID;
@property (nonatomic, strong) NSDate *createTime;
@property (nonatomic, strong) NSDate *updateTime;
@property (nonatomic) NSInteger searchType;
@property (nonatomic) BOOL hasAudio;
@property (nonatomic) BOOL hasNewAudio;
@property (nonatomic) BOOL hasPay;
@property (nonatomic) NSString *audioNewQuestionID;
@property (nonatomic, strong) NSString *imageID;
@property (nonatomic, strong) NSString *imageURL;
@property (nonatomic) NSInteger offerType;

// 回答相关
@property (nonatomic, strong) NSString *answerBody;
@property (nonatomic) NSInteger questionID;
@property (nonatomic) NSInteger subjectID;

@end




