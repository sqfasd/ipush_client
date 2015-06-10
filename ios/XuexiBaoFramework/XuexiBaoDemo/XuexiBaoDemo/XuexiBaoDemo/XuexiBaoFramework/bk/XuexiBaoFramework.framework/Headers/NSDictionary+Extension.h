//
//  NSDictionary+Util.h
//  JuGeiLi
//
//  Created by kimziv on 13-10-2.
//  Copyright (c) 2013年 kimziv. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDictionary (Util)
- (id)nonNullObjectForKey:(id)key;
- (id)nonNullValueForKeyPath:(NSString *)keyPath;
- (id)nonNullValueForKey:(NSString *)key;

- (id)valueForCaseInsensitiveKey:(NSString *)caseInsensitiveKey;

- (float)floatForKey:(NSString *)key;
- (CGSize)sizeForKey:(NSString *)key;

/**
 Returns a new dictionary that contains all objects from the receiving dictionary but replaces any
 keys found to match a key in a given "map" dictionary with the objects of those matched keys.
 objectForKey: is called on "map" dictionary for each key in the receiving dictionary, and if an
 object is associated with that key, that object is then used as the new key for the receiving
 dictionary's object in the new dictionary.
 
 @param map A dictionary containing objects that may be used as keys.
 */
- (NSDictionary *)dictionaryByMappingDictionary:(NSDictionary *)map;

-(id)keyForObject:(id)obj;
  
@end

@interface NSMutableDictionary (Util)

- (void)setFloat:(CGFloat)value forKey:(NSString *)key;
- (void)setSize:(CGSize)value forKey:(NSString *)key;

@end
