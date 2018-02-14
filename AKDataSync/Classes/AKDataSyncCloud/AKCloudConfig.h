//
//  AKCloudConfig.h
//  AKDataSync
//
//  Created by Stanislav Pletnev on 28.08.17.
//  Copyright © 2017 Anobisoft. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AKDataSyncTypes.h"

#pragma mark -
#define AKCloudContainerCFGKey @"AKCloudContainer"
#define AKCloudDatabaseScopeCFGKey @"AKCloudDatabaseScope"

#define AKDatabaseScopePublicKey @"PUBLIC"
#define AKDatabaseScopePrivateKey @"PRIVATE"
#define AKDatabaseScopeSharedKey @"SHARED"

#pragma mark -
#define AKCloudRealModificationDateFieldNameCFGKey @"AKCloudRealModificationDateFieldName"
#define AKCloudDeviceRecordTypeCFGKey @"AKCloudDeviceRecordType"
#define AKCloudDeletionInfoRecordTypeCFGKey @"AKCloudDeletionInfoRecordType"

#pragma mark -
#define AKCloudDeletionInfo_deviceIDFieldNameCFGKey @"AKCloudDeletionInfo_deviceIDFieldName"
#define AKCloudDeletionInfo_recordIDFieldNameCFGKey @"AKCloudDeletionInfo_recordIDFieldName"
#define AKCloudDeletionInfo_recordTypeFieldNameCFGKey @"AKCloudDeletionInfo_recordTypeFieldName"

#pragma mark -
#define AKCloudInitTimeoutCFGKey @"AKCloudInitTimeout"
#define AKCloudTryToPushTimeoutCFGKey @"AKCloudTryToPushTimeout"
#define AKCloudSmartReplicationTimeoutCFGKey @"AKCloudSmartReplicationTimeout"


@interface AKCloudConfig : NSObject <DisableNSInit>

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

@end
