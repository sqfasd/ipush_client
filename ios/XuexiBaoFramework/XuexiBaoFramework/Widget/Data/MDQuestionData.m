//
//  MDQuestionData.m
//  education
//
//  Created by Tim on 14/12/18.
//  Copyright (c) 2014年 mudi. All rights reserved.
//

#import "MDQuestionData.h"


NSMutableArray *parseQuestionListData(NSArray *data)
{
    NSMutableArray *dataArr = [[NSMutableArray alloc] init];
    
    if (!data || ![data isKindOfClass:[NSArray class]]|| data.count <= 0) {
        return dataArr;
    }
    
    [data enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [dataArr addObject:[MDQuestionData dataWithDict:obj]];
    }];
    
    return dataArr;
}


@implementation MDQuestionData

+ (MDQuestionData *)dataWithDict:(NSDictionary *)data
{
    MDQuestionData *newData = [[MDQuestionData alloc] init];
    
    if (!data) {
        return newData;
    }
    
    // Question部分
    NSDictionary *dictQue = [data nonNullObjectForKey:@"question"];
    if (!dictQue) {
        return newData;
    }
    
    newData.rowID = [dictQue nonNullObjectForKey:@"id"];
    newData.createTime = [NSDate dateWithTimeIntervalSince1970:((NSNumber *)[dictQue nonNullObjectForKey:@"create_time"]).doubleValue / 1000];
    newData.updateTime = [NSDate dateWithTimeIntervalSince1970:((NSNumber *)[dictQue nonNullObjectForKey:@"update_time"]).doubleValue / 1000];
    newData.searchType = ((NSNumber *)[dictQue nonNullObjectForKey:@"search_type"]).integerValue;
    
    newData.imageID = [dictQue nonNullObjectForKey:@"image_id"];
    newData.imageURL = [dictQue nonNullObjectForKey:@"image_path"];

    newData.hasAudio = ((NSNumber *)[dictQue nonNullObjectForKey:@"hasAudio"]).integerValue;
    newData.hasNewAudio = ((NSNumber *)[dictQue nonNullObjectForKey:@"hasNewAudio"]).integerValue;
    if (newData.hasNewAudio) {
        // 如果有新音频，添加到未读
        [MDStoreUtil QueAddUnreadImgID:newData.imageID];
    }
    
    newData.hasPay = ((NSNumber *)[dictQue nonNullObjectForKey:@"isPay"]).integerValue;
    
    NSNumber *numQueID = [dictQue nonNullObjectForKey:@"newAudioQuestionId"];
    newData.audioNewQuestionID = numQueID ? [NSString stringWithFormat:@"%li", (long)numQueID.integerValue]: @"0";
    
    NSNumber *oT = [dictQue nonNullObjectForKey:@"audioType"];
    if (oT && [oT isKindOfClass:[NSNumber class]]) {
        newData.offerType = oT.integerValue;
    }

    
    // Answer部分
    NSArray *answers = [data nonNullObjectForKey:@"answers"];
    if (!answers || answers.count <= 0) {
        return newData;
    }
    
    NSDictionary *dictAnswer = answers.firstObject;
    if (!dictAnswer) {
        return newData;
    }

    newData.answerBody = [dictAnswer nonNullObjectForKey:@"question_body"];
    newData.questionID = ((NSNumber *)[dictAnswer nonNullObjectForKey:@"question_id"]).integerValue;
    newData.subjectID = ((NSNumber *)[dictAnswer nonNullObjectForKey:@"subject"]).integerValue;
    
    return newData;
}


- (id)init
{
    self = [super init];
    if (self) {
        _hasAudio = NO;
        _hasNewAudio = NO;
        _hasPay = NO;
    }
    
    return self;
}

@end
