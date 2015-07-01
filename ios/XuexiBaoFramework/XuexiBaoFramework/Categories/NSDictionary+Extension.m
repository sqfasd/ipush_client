//
//  NSDictionary+Util.m
//  JuGeiLi
//
//  Created by kimziv on 13-10-2.
//  Copyright (c) 2013年 kimziv. All rights reserved.
//

#import "NSDictionary+Extension.h"

@implementation NSDictionary (Util)
- (id)nonNullObjectForKey:(id)key {
    
    id object;
    object = self[key];
    
    if (object == [NSNull null]) {
        return nil;
    }
    
    return object;
}

- (id)nonNullValueForKeyPath:(NSString *)keyPath {
    
    id object;
    
    object = [self valueForKeyPath:keyPath];
    
    if (object == [NSNull null]) {
        return nil;
    }
    
    return object;
}

- (id)nonNullValueForKey:(NSString *)key {
    
    id object;
    
    object = [self valueForKey:key];
    
    if (object == [NSNull null]) {
        return nil;
    }
    
    return object;
}

- (id)valueForCaseInsensitiveKey:(NSString *)caseInsensitiveKey {
    
    __block id object = nil;
    
    [self
     enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
         if ([key isKindOfClass:[NSString class]]) {
             if ([(NSString *)key caseInsensitiveCompare:caseInsensitiveKey] == NSOrderedSame) {
                 object = obj;
                 
                 *stop = YES;
             }
         }
     }];
    
    return object;
}

- (float)floatForKey:(NSString *)key {
    NSNumber *number = self[key];
    return [number floatValue];
}

- (CGSize)sizeForKey:(NSString *)key {
    NSValue *value = self[key];
    return [value CGSizeValue];
}

- (NSDictionary *)dictionaryByMappingDictionary:(NSDictionary *)map {
    NSMutableDictionary *mappedDictionary = [NSMutableDictionary dictionary];
    
    [[self allKeys] enumerateObjectsUsingBlock:^(id keyForMappedDictionary, NSUInteger idx, BOOL *stop) {
        id mappedKey = map[keyForMappedDictionary];
        
        mappedDictionary[(nil == mappedKey ? keyForMappedDictionary : mappedKey)] = self[keyForMappedDictionary];
    }];
    
    return [NSDictionary dictionaryWithDictionary:mappedDictionary];
}

-(id)keyForObject:(id)obj
{
    __block id key=nil;
    [self enumerateKeysAndObjectsUsingBlock:^(id aKey, id aObj, BOOL *stop) {
        if (aObj==obj) {
             key=aKey;
            *stop=YES;
        }
    }];
    return key;
}

@end


@implementation NSMutableDictionary (Util)

- (void)setFloat:(CGFloat)value forKey:(NSString *)key {
    NSNumber *wrapped = @(value);
    [self setValue:wrapped forKey:key];
}

- (void)setSize:(CGSize)value forKey:(NSString *)key {
    NSValue *wrapped = [NSValue valueWithCGSize:value];
    [self setValue:wrapped forKey:key];
}

@end


