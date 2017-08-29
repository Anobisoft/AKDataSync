//
//  AKCloudConfig.h
//  Pods
//
//  Created by Stanislav Pletnev on 28.08.17.
//
//

#import <Foundation/Foundation.h>
#import "AKDataSyncTypes.h"

@interface AKCloudConfig : NSObject

@property (readonly) NSString *containerIdentifier;
@property (readonly) AKDatabaseScope databaseScope;


@property (readonly) NSString *realModificationDateFieldName;
@property (readonly) NSString *deviceRecordType;
@property (readonly) NSString *deletionInfoRecordType;

@property (readonly) NSString *deviceIDFieldName;
@property (readonly) NSString *recordIDFieldName;
@property (readonly) NSString *recordTypeFieldName;

@property (readonly) NSTimeInterval initTimeout;
@property (readonly) NSTimeInterval tryToPushTimeout;
@property (readonly) NSTimeInterval smartReplicationTimeout;

+ (instancetype)configWithName:(NSString *)configName;
+ (instancetype)configWithContainerIdentifier:(NSString *)identifier databaseScope:(AKDatabaseScope)databaseScope;

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

@end
