// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to MDQuestionV2.m instead.

#import "_MDQuestionV2.h"

const struct MDQuestionV2Attributes MDQuestionV2Attributes = {
	.bin_path = @"bin_path",
	.create_time = @"create_time",
	.file_uuid = @"file_uuid",
	.image_id = @"image_id",
	.ori_path = @"ori_path",
	.ori_url = @"ori_url",
	.question_analysis = @"question_analysis",
	.question_answer = @"question_answer",
	.question_body = @"question_body",
	.question_body_html = @"question_body_html",
	.question_id = @"question_id",
	.question_tags = @"question_tags",
	.raw_text = @"raw_text",
	.read_status = @"read_status",
	.retry = @"retry",
	.score = @"score",
	.status = @"status",
	.subject = @"subject",
	.update_time = @"update_time",
};

@implementation MDQuestionV2ID
@end

@implementation _MDQuestionV2

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"MDQuestionV2" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"MDQuestionV2";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"MDQuestionV2" inManagedObjectContext:moc_];
}

- (MDQuestionV2ID*)objectID {
	return (MDQuestionV2ID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];

	if ([key isEqualToString:@"read_statusValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"read_status"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}
	if ([key isEqualToString:@"retryValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"retry"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}
	if ([key isEqualToString:@"scoreValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"score"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}
	if ([key isEqualToString:@"statusValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"status"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}
	if ([key isEqualToString:@"subjectValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"subject"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}

	return keyPaths;
}

@dynamic bin_path;

@dynamic create_time;

@dynamic file_uuid;

@dynamic image_id;

@dynamic ori_path;

@dynamic ori_url;

@dynamic question_analysis;

@dynamic question_answer;

@dynamic question_body;

@dynamic question_body_html;

@dynamic question_id;

@dynamic question_tags;

@dynamic raw_text;

@dynamic read_status;

- (int32_t)read_statusValue {
	NSNumber *result = [self read_status];
	return [result intValue];
}

- (void)setRead_statusValue:(int32_t)value_ {
	[self setRead_status:[NSNumber numberWithInt:value_]];
}

- (int32_t)primitiveRead_statusValue {
	NSNumber *result = [self primitiveRead_status];
	return [result intValue];
}

- (void)setPrimitiveRead_statusValue:(int32_t)value_ {
	[self setPrimitiveRead_status:[NSNumber numberWithInt:value_]];
}

@dynamic retry;

- (int16_t)retryValue {
	NSNumber *result = [self retry];
	return [result shortValue];
}

- (void)setRetryValue:(int16_t)value_ {
	[self setRetry:[NSNumber numberWithShort:value_]];
}

- (int16_t)primitiveRetryValue {
	NSNumber *result = [self primitiveRetry];
	return [result shortValue];
}

- (void)setPrimitiveRetryValue:(int16_t)value_ {
	[self setPrimitiveRetry:[NSNumber numberWithShort:value_]];
}

@dynamic score;

- (float)scoreValue {
	NSNumber *result = [self score];
	return [result floatValue];
}

- (void)setScoreValue:(float)value_ {
	[self setScore:[NSNumber numberWithFloat:value_]];
}

- (float)primitiveScoreValue {
	NSNumber *result = [self primitiveScore];
	return [result floatValue];
}

- (void)setPrimitiveScoreValue:(float)value_ {
	[self setPrimitiveScore:[NSNumber numberWithFloat:value_]];
}

@dynamic status;

- (int32_t)statusValue {
	NSNumber *result = [self status];
	return [result intValue];
}

- (void)setStatusValue:(int32_t)value_ {
	[self setStatus:[NSNumber numberWithInt:value_]];
}

- (int32_t)primitiveStatusValue {
	NSNumber *result = [self primitiveStatus];
	return [result intValue];
}

- (void)setPrimitiveStatusValue:(int32_t)value_ {
	[self setPrimitiveStatus:[NSNumber numberWithInt:value_]];
}

@dynamic subject;

- (int32_t)subjectValue {
	NSNumber *result = [self subject];
	return [result intValue];
}

- (void)setSubjectValue:(int32_t)value_ {
	[self setSubject:[NSNumber numberWithInt:value_]];
}

- (int32_t)primitiveSubjectValue {
	NSNumber *result = [self primitiveSubject];
	return [result intValue];
}

- (void)setPrimitiveSubjectValue:(int32_t)value_ {
	[self setPrimitiveSubject:[NSNumber numberWithInt:value_]];
}

@dynamic update_time;

@end

