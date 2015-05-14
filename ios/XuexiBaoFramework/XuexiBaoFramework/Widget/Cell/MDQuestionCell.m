//
//  MDQuestionCell.m
//  education
//
//  Created by kimziv on 14-5-7.
//  Copyright (c) 2014年 mudi. All rights reserved.
//

#import "MDQuestionCell.h"
#import "MDQuestionV2.h"
#import "MDQuestionData.h"



@interface MDQuestionCell ()

@property (strong, nonatomic) IBOutlet UIImageView *subjectImageView;
@property (strong, nonatomic) IBOutlet UIImageView *audioNewImgV;
@property (strong, nonatomic) IBOutlet UILabel *questionBodyLabel;
@property (strong, nonatomic) IBOutlet UILabel *knowledgePointLabel;
@property (strong, nonatomic) IBOutlet UILabel *warningStateLabel;
@property (strong, nonatomic) IBOutlet UIImageView *unreadStateImageView;
@property (strong, nonatomic) IBOutlet UILabel *timeLabel;
@property (strong, nonatomic) IBOutlet UIImageView *audioStateImgV;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *bottomLineHeightConstraint;

@property (strong, nonatomic) IBOutlet UIImageView *bgCardV;
@end



@implementation MDQuestionCell
@synthesize data=_data;
static UIColor *_DiverColor=nil;

+(void)initialize
{
    if (self==[MDQuestionCell class]) {
        _DiverColor=[UIColor colorWithHex:0xcccccc];
    }
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        //[[@"" dataUsingEncoding:NSUTF8StringEncoding] base64EncodedStringWithOptions:(NSDataBase64EncodingOptions)]
        //        [self initViews];
        
        //[self.contentView addSubview:[[NSBundle mainBundle] loadNibNamed:@"QuestionCell" owner:self options:nil].firstObject];
    }
    
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self initViews];
    }
    
    return self;
}

- (void)awakeFromNib
{
    // Initialization code
    [super awakeFromNib];
    [self initViews];
}

-(void)initViews
{
    UIView *bgV = [[UIView alloc] initWithFrame:self.frame];
    bgV.backgroundColor = [UIColor colorWithHex:0xf7f7f7];
    self.selectedBackgroundView = bgV;

    //self.contentView.backgroundColor=[UIColor clearColor];
    self.backgroundColor=[UIColor clearColor];
    self.bottomLineHeightConstraint.constant = 0.5;
}

-(void)layoutSubviews
{
    [super layoutSubviews];
}

-(void)setData:(id)d
{
    if (!d || ![d isKindOfClass:[MDQuestionData class]]) {
        return;
    }
    
    MDQuestionData *cellData = (MDQuestionData *)d;
    
    long long timestamp = cellData.createTime.timeIntervalSince1970 * 1000;
    NSString *timeText = longlong2Str(timestamp);
    self.timeLabel.text = timeText;
    
    if (cellData.searchType == 200) {
        // 请求新音频展现
        if (cellData.hasNewAudio && cellData.audioNewQuestionID && cellData.audioNewQuestionID.integerValue > 0) {
            _audioNewImgV.hidden = NO;
        }
        else {
            _audioNewImgV.hidden = YES;
        }
        
        // 音频信息展现
        _audioStateImgV.hidden = YES;
        
        // 如果有题干
        if (cellData.answerBody && cellData.answerBody.length > 0) {
            _subjectImageView.image = [UIImage imageNamed:[NSString stringWithFormat:@"%li_nor", (long)cellData.subjectID]];
            
            _questionBodyLabel.text = cellData.answerBody;
            
            _warningStateLabel.hidden = YES;

        }
        // 如果没有题干
        else {
            _subjectImageView.image = [UIImage imageNamed:@"0_nor"];
            
            _warningStateLabel.text = NSLocalizedString(@"que_tag_reg_error", "que_tag_reg_error");
            _warningStateLabel.hidden = YES;
            
            _knowledgePointLabel.hidden = YES;
            
            _questionBodyLabel.text = NSLocalizedString(@"hint_when_no_questionbody", @"");

        }

        if (cellData.subjectID >= 0) {
            _knowledgePointLabel.text = [[MDStoreUtil sharedInstance] stringForSubject:cellData.subjectID];
            _knowledgePointLabel.hidden = NO;
        }
        else {
            _knowledgePointLabel.hidden = YES;
        }
        
    } else if(cellData.searchType == 400){
        _subjectImageView.image = [UIImage imageNamed:@"0_nor"];
        
        _warningStateLabel.text = NSLocalizedString(@"que_tag_reg_error", "que_tag_reg_error");
        _warningStateLabel.hidden = YES;
        
        _knowledgePointLabel.text = @"未知";
//        _knowledgePointLabel.hidden = YES;
        
        // 新音频相关
        _audioNewImgV.hidden = YES;
        _audioStateImgV.hidden = YES;
        
        _questionBodyLabel.text = NSLocalizedString(@"hint_when_answer_not_found", @"");
        
    } else if(cellData.searchType == 500){
        _subjectImageView.image = [UIImage imageNamed:@"0_nor"];
        
        _warningStateLabel.text = NSLocalizedString(@"que_tag_reg_error", "que_tag_reg_error");
        _warningStateLabel.hidden = YES;
        
        _knowledgePointLabel.text = @"未知";
//        _knowledgePointLabel.hidden = YES;
        
        // 新音频相关
        _audioNewImgV.hidden = YES;
        _audioStateImgV.hidden = YES;
        
        _questionBodyLabel.text = NSLocalizedString(@"hint_when_answer_not_found", @"");
    }
    
    
    BOOL readStatus = [self isReadByImgId:cellData.imageID];
    if (!readStatus || (cellData.hasNewAudio && cellData.audioNewQuestionID && cellData.audioNewQuestionID.integerValue > 0)) {
        MDLog(@"imgId:%@ readStatus:%d hasNewAudio:%@ que:%@", cellData.imageID, readStatus, cellData.audioNewQuestionID, cellData.answerBody);
        _unreadStateImageView.hidden = NO;
    }else{
        _unreadStateImageView.hidden = YES;
    }
}

-(BOOL)isReadByImgId:(NSString *)imgId
{
    if (imgId && [imgId  hasPrefix:@"'"]) {
        imgId=[imgId stringByReplacingOccurrencesOfString:@"'" withString:@""];
    }
    	
    return [MDStoreUtil IsQueReadForImgID:imgId];
    
//    MDQuestionV2 *que = [[MDCoreDataUtil sharedInstance] queryQueWhidImgId:imgId];
//    if (que) {
//        return que.read_status.boolValue;
//    }else{
//        return YES;
//    }
//    return NO;
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    
    if (selected) {
        [UIView animateWithDuration:0.2 animations:^{
            self.bgCardV.alpha = 0;
        } completion:^(BOOL finished) {
            self.bgCardV.alpha = 1;
        }];
    }
//    else {
//        self.bgCardV.alpha = 1;
//    }

    // Configure the view for the selected state
}

//-(void)drawRect:(CGRect)rect
//{
//    [super drawRect:rect];
////    
////    CGContextRef c = UIGraphicsGetCurrentContext();
////    CGContextSetStrokeColorWithColor(c, _DiverColor.CGColor);
////    CGContextSetLineWidth(c, 1);
////    
////    CGFloat dash[2] = { 2.0f , 2.0f};
////    CGContextSetLineDash(c,0,dash,2.0f);
////    
////    CGContextBeginPath(c);
////    CGContextMoveToPoint(c, 12.0f, rect.size.height-0.5);
////    CGContextAddLineToPoint(c, rect.size.width-12.0f, rect.size.height-0.5);
////    CGContextStrokePath(c);
////    
//}

@end




