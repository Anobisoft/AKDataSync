//
//  AKCloudConfig.m
//  AKDataSync
//
//  Created by Stanislav Pletnev on 28.08.17.
//  Copyright © 2017 Anobisoft. All rights reserved.
//

#import "AKCloudConfig.h"
#import <AnobiKit/AKConfigManager.h>

#pragma mark - DefaultConfigValues
#define AKCloudRealModificationDateFieldNameDefaultValue @"AK_realModificationDate"
#define AKCloudDeviceRecordTypeDefaultValue @"AKDevice"
#define AKCloudDeletionInfoRecordTypeDefaultValue @"AKDeletionInfo"

#pragma mark -
#define AKCloudDeletionInfo_deviceIDFieldNameDefaultValue @"AK_deviceID"
#define AKCloudDeletionInfo_recordIDFieldNameDefaultValue @"AK_recordID"
#define AKCloudDeletionInfo_recordTypeFieldNameDefaultValue @"AK_recordType"

#pragma mark -
#define AKCloudTimeoutDefaultValue 60


@implementation AKCloudConfig {
    
}

static NSMutableDictionary<NSString *, id> *instances[4];
static NSMutableDictionary<NSString *, id> *instancesByName;
static NSDictionary<NSString *, NSNumber *> *keyedAKDatabaseScope;
+ (void)initialize {
    [super initialize];
    instances[AKDatabaseScopeDefault] = instances[AKDatabaseScopePrivate] = [NSMutableDictionary new];
    instances[AKDatabaseScopePublic] = [NSMutableDictionary new];
    instances[AKDatabaseScopeShared] = [NSMutableDictionary new];
    instancesByName = [NSMutableDictionary new];
    keyedAKDatabaseScope = @{
							 AKDatabaseScopePrivateKey : @(AKDatabaseScopePrivate),
							 AKDatabaseScopePublicKey : @(AKDatabaseScopePublic),
                             AKDatabaseScopeSharedKey : @(AKDatabaseScopeShared),
                             };
}

- (id)copy {
    return self;
}

- (id)mutableCopy {
    return self;
}

@synthesize containerIdentifier = _containerIdentifier;
@synthesize databaseScope = _databaseScope;

@synthesize realModificationDateFieldName = _realModificationDateFieldName;
@synthesize deviceRecordType = _deviceRecordType;
@synthesize deletionInfoRecordType = _deletionInfoRecordType;

@synthesize deviceIDFieldName = _deviceIDFieldName;
@synthesize recordIDFieldName = _recordIDFieldName;
@synthesize recordTypeFieldName = _recordTypeFieldName;

@synthesize initTimeout = _initTimeout;
@synthesize tryToPushTimeout = _tryToPushTimeout;
@synthesize smartReplicationTimeout = _smartReplicationTimeout;


+ (instancetype)configWithName:(NSString *)configName {
    id instance = instancesByName[configName ?: @"AKDataSyncDefaultKey"];
    if (!instance) {
        instance = [[self alloc] initWithName:configName];
        instancesByName[configName ?: @"AKDataSyncDefaultKey"] = instance;
    }
    return instance;
}


- (instancetype)initWithName:(NSString *)configName {
    if (self = [super init]) {
        NSDictionary *configDictionary = nil;
        if (configName) {
            configDictionary = [AKConfigManager manager][configName];
        }
        if (!configDictionary) {
            configDictionary = [AKConfigManager manager][@"AKDataSync"];
        }
        
        _containerIdentifier = configDictionary[AKCloudContainerCFGKey] ?: [NSString stringWithFormat:@"iCloud.%@", [NSBundle mainBundle].bundleIdentifier];
        
        NSNumber *numberTmp = keyedAKDatabaseScope[configDictionary[AKCloudDatabaseScopeCFGKey]];
        if (numberTmp)
            _databaseScope = numberTmp.integerValue;
        else
            _databaseScope = AKDatabaseScopePrivate;

        
        _realModificationDateFieldName = configDictionary[AKCloudRealModificationDateFieldNameCFGKey] ?: AKCloudRealModificationDateFieldNameDefaultValue;
        _deviceRecordType = configDictionary[AKCloudDeviceRecordTypeCFGKey] ?: AKCloudDeviceRecordTypeDefaultValue;
        _deletionInfoRecordType = configDictionary[AKCloudDeletionInfoRecordTypeCFGKey] ?: AKCloudDeletionInfoRecordTypeDefaultValue;

        _deviceIDFieldName = configDictionary[AKCloudDeletionInfo_deviceIDFieldNameCFGKey] ?: AKCloudDeletionInfo_deviceIDFieldNameDefaultValue;
        _recordIDFieldName = configDictionary[AKCloudDeletionInfo_recordIDFieldNameCFGKey] ?: AKCloudDeletionInfo_recordIDFieldNameDefaultValue;
        _recordTypeFieldName = configDictionary[AKCloudDeletionInfo_recordTypeFieldNameCFGKey] ?: AKCloudDeletionInfo_recordTypeFieldNameDefaultValue;
        
        numberTmp = configDictionary[AKCloudInitTimeoutCFGKey];
        _initTimeout = numberTmp.doubleValue ?: AKCloudTimeoutDefaultValue;
        numberTmp = configDictionary[AKCloudTryToPushTimeoutCFGKey];
        _tryToPushTimeout = numberTmp.doubleValue ?: AKCloudTimeoutDefaultValue;
        numberTmp = configDictionary[AKCloudSmartReplicationTimeoutCFGKey];
        _smartReplicationTimeout = numberTmp.doubleValue ?: AKCloudTimeoutDefaultValue;

        
    }
    return self;
}

+ (instancetype)configWithContainerIdentifier:(NSString *)identifier databaseScope:(AKDatabaseScope)databaseScope {
    id instance = instances[databaseScope % 4][identifier];
    if (!instance) {
        instance = [[self alloc] initWithContainerIdentifier:identifier databaseScope:databaseScope];
        instances[databaseScope % 4][identifier] = instance;
    }
    return instance;
}



- (instancetype)initWithContainerIdentifier:(NSString *)identifier databaseScope:(AKDatabaseScope)databaseScope {
    if (self = [self initWithName:nil]) {
        _containerIdentifier = identifier;
        _databaseScope = databaseScope;
    }
    return self;
}




@end
