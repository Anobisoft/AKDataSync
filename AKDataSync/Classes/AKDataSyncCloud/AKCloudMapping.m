//
//  AKCloudMapping.m
//  AKDataSyncCloud
//
//  Created by Stanislav Pletnev on 2017-01-18
//  Copyright © 2016 Anobisoft. All rights reserved.
//

#import "AKCloudMapping.h"

@interface AKMap : NSObject <ASKeyedSubscripted>

- (void)mapObject:(NSString *)object withKey:(NSString *)key;
- (NSDictionary *)dictionary;

@end

@implementation AKMap {
    NSMutableDictionary *map;
}

- (instancetype)init {
    if (self = [super init]) {
        map = [NSMutableDictionary new];
    }
    return self;
}

- (NSString *)objectForKeyedSubscript:(NSString *)key {
    return map[key] ?: key;
}

- (void)mapObject:(NSString *)object withKey:(NSString *)key {
    [map setObject:object forKey:key];
}

- (NSDictionary *)dictionary {
    return map.copy;
}

@end

@implementation AKCloudMapping {
    NSMutableSet *_entities;
    NSMutableSet *_recordTypes;
    AKMap *_map, *_reverseMap;
}

- (NSString *)objectForKeyedSubscript:(NSString *)key {
    return self.map[key];
}

- (instancetype)init {
    if (self = [super init]) {
        _entities = [NSMutableSet new];
        _recordTypes = [NSMutableSet new];
        [self emptyMap];
    }
    return self;
}

- (void)emptyMap {
    _map = [AKMap new];
    _reverseMap = [AKMap new];
}

+ (instancetype)mappingWithSynchronizableEntities:(NSArray <NSString *> *)entities {
    return [[self alloc] initWithArray:entities];
}


- (instancetype)initWithArray:(NSArray <NSString *> *)array {
    if (self = [super init]) {
        _entities = [NSMutableSet setWithArray:array];
        _recordTypes = _entities.mutableCopy;
        [self emptyMap];
    }
    return self;
}

+ (instancetype)mappingWithRecordTypeKeyedByEntityNameDictionary:(NSDictionary <NSString *, NSString *> *)dictionary {
    return [[self alloc] initWithDictionary:dictionary];
}

- (instancetype)initWithDictionary:(NSDictionary <NSString *, NSString *> *)dictionary {
    if (self = [self init]) {
        for (NSString *entityName in dictionary.allKeys) {
            [self mapRecordType:dictionary[entityName] withEntityName:entityName];
        }
    }
    return self;
}

- (void)mapRecordType:(NSString *)recordType withEntityName:(NSString *)entityName {
    [_map mapObject:recordType withKey:entityName];
    if ([_reverseMap[recordType] isEqualToString:recordType]) [_reverseMap mapObject:entityName withKey:recordType];
    else @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:recordType userInfo:nil];
    [_entities addObject:entityName];
    [_recordTypes addObject:recordType];
}

- (void)addEntity:(NSString *)entityName {
    [_entities addObject:entityName];
    [_recordTypes addObject:self.map[entityName]];
}

- (void)addEntities:(NSArray<NSString *> *)entities {
    [_entities addObjectsFromArray:entities];
    for (NSString *entityName in entities) {
        [_recordTypes addObject:self.map[entityName]];
    }
}

- (NSSet<NSString *> *)synchronizableEntities {
    return _entities.copy;
}

- (NSSet<NSString *> *)allRecordTypes {
    return _recordTypes.copy;
}



@end
