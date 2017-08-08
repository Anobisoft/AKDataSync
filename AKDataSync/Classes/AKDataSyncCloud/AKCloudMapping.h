//
//  AKCloudMapping.h
//  AKDataSyncCloud
//
//  Created by Stanislav Pletnev on 2017-01-18
//  Copyright © 2016 Anobisoft. All rights reserved.
//

#import <Foundation/Foundation.h>

#ifndef AKCloudMapping_h
#define AKCloudMapping_h

@protocol ASKeyedSubscripted <NSObject>

- (NSString *)objectForKeyedSubscript:(NSString *)key;

@end

@interface AKCloudMapping : NSObject <ASKeyedSubscripted> //recordType by entityName

+ (instancetype)mappingWithSynchronizableEntities:(NSArray <NSString *> *)entities;
+ (instancetype)mappingWithRecordTypeKeyedByEntityNameDictionary:(NSDictionary <NSString *, NSString *> *)dictionary;

@property (nonatomic, strong, readonly) id <ASKeyedSubscripted> map; //recordType by entityName
@property (nonatomic, strong, readonly) id <ASKeyedSubscripted> reverseMap; //entityName by recordType
- (NSSet <NSString *> *)synchronizableEntities; //all cloud-synchronizable entities
- (NSSet <NSString *> *)allRecordTypes;

//mutable
- (void)mapRecordType:(NSString *)recordType withEntityName:(NSString *)entityName;
- (void)addEntity:(NSString *)entityName;
- (void)addEntities:(NSArray<NSString *> *)entities;

@end

#endif
