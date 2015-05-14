// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to MDQuestionV2.h instead.

#import <CoreData/CoreData.h>

extern const struct MDQuestionV2Attributes {
	__unsafe_unretained NSString *bin_path;
	__unsafe_unretained NSString *create_time;
	__unsafe_unretained NSString *file_uuid;
	__unsafe_unretained NSString *image_id;
	__unsafe_unretained NSString *ori_path;
	__unsafe_unretained NSString *ori_url;
	__unsafe_unretained NSString *question_analysis;
	__unsafe_unretained NSString *question_answer;
	__unsafe_unretained NSString *question_body;
	__unsafe_unretained NSString *question_body_html;
	__unsafe_unretained NSString *question_id;
	__unsafe_unretained NSString *question_tags;
	__unsafe_unretained NSString *raw_text;
	__unsafe_unretained NSString *read_status;
	__unsafe_unretained NSString *retry;
	__unsafe_unretained NSString *score;
	__unsafe_unretained NSString *status;
	__unsafe_unretained NSString *subject;
	__unsafe_unretained NSString *update_time;
} MDQuestionV2Attributes;

@interface MDQuestionV2ID : NSManagedObjectID {}
@end

@interface _MDQuestionV2 : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
@property (nonatomic, readonly, strong) MDQuestionV2ID* objectID;

@property (nonatomic, strong) NSString* bin_path;

//- (BOOL)validateBin_path:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSDate* create_time;

//- (BOOL)validateCreate_time:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSString* file_uuid;

//- (BOOL)validateFile_uuid:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSString* image_id;

//- (BOOL)validateImage_id:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSString* ori_path;

//- (BOOL)validateOri_path:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSString* ori_url;

//- (BOOL)validateOri_url:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSString* question_analysis;

//- (BOOL)validateQuestion_analysis:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSString* question_answer;

//- (BOOL)validateQuestion_answer:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSString* question_body;

//- (BOOL)validateQuestion_body:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSString* question_body_html;

//- (BOOL)validateQuestion_body_html:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSString* question_id;

//- (BOOL)validateQuestion_id:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSString* question_tags;

//- (BOOL)validateQuestion_tags:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSString* raw_text;

//- (BOOL)validateRaw_text:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSNumber* read_status;

@property (atomic) int32_t read_statusValue;
- (int32_t)read_statusValue;
- (void)setRead_statusValue:(int32_t)value_;

//- (BOOL)validateRead_status:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSNumber* retry;

@property (atomic) int16_t retryValue;
- (int16_t)retryValue;
- (void)setRetryValue:(int16_t)value_;

//- (BOOL)validateRetry:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSNumber* score;

@property (atomic) float scoreValue;
- (float)scoreValue;
- (void)setScoreValue:(float)value_;

//- (BOOL)validateScore:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSNumber* status;

@property (atomic) int32_t statusValue;
- (int32_t)statusValue;
- (void)setStatusValue:(int32_t)value_;

//- (BOOL)validateStatus:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSNumber* subject;

@property (atomic) int32_t subjectValue;
- (int32_t)subjectValue;
- (void)setSubjectValue:(int32_t)value_;

//- (BOOL)validateSubject:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSDate* update_time;

//- (BOOL)validateUpdate_time:(id*)value_ error:(NSError**)error_;

@end

@interface _MDQuestionV2 (CoreDataGeneratedPrimitiveAccessors)

- (NSString*)primitiveBin_path;
- (void)setPrimitiveBin_path:(NSString*)value;

- (NSDate*)primitiveCreate_time;
- (void)setPrimitiveCreate_time:(NSDate*)value;

- (NSString*)primitiveFile_uuid;
- (void)setPrimitiveFile_uuid:(NSString*)value;

- (NSString*)primitiveImage_id;
- (void)setPrimitiveImage_id:(NSString*)value;

- (NSString*)primitiveOri_path;
- (void)setPrimitiveOri_path:(NSString*)value;

- (NSString*)primitiveOri_url;
- (void)setPrimitiveOri_url:(NSString*)value;

- (NSString*)primitiveQuestion_analysis;
- (void)setPrimitiveQuestion_analysis:(NSString*)value;

- (NSString*)primitiveQuestion_answer;
- (void)setPrimitiveQuestion_answer:(NSString*)value;

- (NSString*)primitiveQuestion_body;
- (void)setPrimitiveQuestion_body:(NSString*)value;

- (NSString*)primitiveQuestion_body_html;
- (void)setPrimitiveQuestion_body_html:(NSString*)value;

- (NSString*)primitiveQuestion_id;
- (void)setPrimitiveQuestion_id:(NSString*)value;

- (NSString*)primitiveQuestion_tags;
- (void)setPrimitiveQuestion_tags:(NSString*)value;

- (NSString*)primitiveRaw_text;
- (void)setPrimitiveRaw_text:(NSString*)value;

- (NSNumber*)primitiveRead_status;
- (void)setPrimitiveRead_status:(NSNumber*)value;

- (int32_t)primitiveRead_statusValue;
- (void)setPrimitiveRead_statusValue:(int32_t)value_;

- (NSNumber*)primitiveRetry;
- (void)setPrimitiveRetry:(NSNumber*)value;

- (int16_t)primitiveRetryValue;
- (void)setPrimitiveRetryValue:(int16_t)value_;

- (NSNumber*)primitiveScore;
- (void)setPrimitiveScore:(NSNumber*)value;

- (float)primitiveScoreValue;
- (void)setPrimitiveScoreValue:(float)value_;

- (NSNumber*)primitiveStatus;
- (void)setPrimitiveStatus:(NSNumber*)value;

- (int32_t)primitiveStatusValue;
- (void)setPrimitiveStatusValue:(int32_t)value_;

- (NSNumber*)primitiveSubject;
- (void)setPrimitiveSubject:(NSNumber*)value;

- (int32_t)primitiveSubjectValue;
- (void)setPrimitiveSubjectValue:(int32_t)value_;

- (NSDate*)primitiveUpdate_time;
- (void)setPrimitiveUpdate_time:(NSDate*)value;

@end
