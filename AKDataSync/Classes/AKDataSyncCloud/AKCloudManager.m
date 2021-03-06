//
//  AKCloudManager.m
//  AKDataSyncCloud
//
//  Created by Stanislav Pletnev on 2016-12-21
//  Copyright © 2016 Anobisoft. All rights reserved.
//

#define AKCloudMaxModificationDateForEntityUDKey @"AKCloudMaxModificationDateForEntity"
#define AKCloudPreparedToCloudRecordsUDKey @"AKCloudPreparedToCloudRecords"

#import "AKCloudManager.h"
#import "AKDeviceList.h"
#import "AKPrivateProtocol.h"
#import "AKCloudConfig.h"

#import "AKCloudTransaction.h"
#import "AKCloudRecordRepresentation.h"
#import "AKCloudDescriptionRepresentation.h"
#import "AKPreparedToCloudRecords.h"

#import "CKRecord+AKDataSync.h"
#import "CKRecordID+AKDataSync.h"
#import "CKReference+AKDataSync.h"

#import <AnobiKit/AKUUID.h>
#import <AnobiKit/NSDate+AnobiKit.h>

#pragma mark -

@interface NSMapTable<KeyType, ObjectType> (ASKeyedSubscripted)
- (ObjectType)objectForKeyedSubscript:(KeyType <NSCopying>)key;
- (void)setObject:(ObjectType)obj forKeyedSubscript:(KeyType <NSCopying>)key;
@end

@implementation NSMapTable (ASKeyedSubscripted)
- (id)objectForKeyedSubscript:(id)key {
    return [self objectForKey:key];
}
- (void)setObject:(id)obj forKeyedSubscript:(id)key {
    [self setObject:obj forKey:key];
}
@end


typedef void (^FetchRecord)(__kindof CKRecord *record);
typedef void (^FetchRecordsArray)(NSArray<__kindof CKRecord *> *records);

#pragma mark -

@interface AKCloudManager() <AKCloudManager>

@property (nonatomic, strong, readonly) NSDictionary <NSString *, NSDate *> *maxCloudModificationDateForEntity;
@property (nonatomic) AKCloudState initState;
- (void)setMaxCloudModificationDate:(NSDate *)date forEntity:(NSString *)entity;

@property AKCloudConfig *config;
@property (weak) id<AKDataSyncContextPrivate, AKCloudManagerOwner> syncContext;
@property CKContainer *container;
@property CKDatabase *db;
@property AKDeviceList *deviceList;
@property AKPreparedToCloudRecords *preparedToCloudRecords;
@property BOOL smartReplicationInprogress;
@property BOOL totalReplicationInprogress;
@property NSTimer *retryToInitTimer;
@property NSTimer *resmartTimer;
@property dispatch_queue_t waitingQueue;

@end

#pragma mark -

@implementation AKCloudManager {
    NSPredicate *thisDevicePredicate;
    NSMutableSet <CKRecord *> *_recievedUpdatedRecords, *_recievedDeletionInfoRecords;
    
    dispatch_group_t primaryInitializationGroup;
    dispatch_group_t lockCloudGroup;
    
    
    
    NSString *maxCloudModificationDateForEntityUDCompositeKey, *preparedToCloudRecordsUDCompositeKey;
    
    
    
    
}

@synthesize initState = _initState;
- (void)setInitState:(AKCloudState)initState {
    _initState = initState;
    if (self.syncContext) {
        [self.syncContext cloudManager:self didChangeState:initState];
    }
}

#pragma mark - Private Properties

- (NSSet <CKRecord <AKMappedObject> *> *)recievedUpdatedRecords {
    return _recievedUpdatedRecords.copy;
}

- (NSSet <CKRecord <AKMappedObject> *> *)recievedDeletionInfoRecords {
    return _recievedDeletionInfoRecords.copy;
}

@synthesize maxCloudModificationDateForEntity = _maxCloudModificationDateForEntity;
NSMutableDictionary *maxCloudModificationDateForEntityMutable;
- (NSDictionary <NSString *, NSDate *> *)maxCloudModificationDateForEntity {
    if (!_maxCloudModificationDateForEntity) {
        _maxCloudModificationDateForEntity = [[NSUserDefaults standardUserDefaults] objectForKey:maxCloudModificationDateForEntityUDCompositeKey];
        if (!_maxCloudModificationDateForEntity) _maxCloudModificationDateForEntity = @{};
    }
    return _maxCloudModificationDateForEntity;
}
- (void)setMaxCloudModificationDate:(NSDate *)date forEntity:(NSString *)entity {
    if (date) {
        [maxCloudModificationDateForEntityMutable setObject:date forKey:entity];
    } else {
        [maxCloudModificationDateForEntityMutable removeObjectForKey:entity];
    }
    _maxCloudModificationDateForEntity = maxCloudModificationDateForEntityMutable.copy;
    [[NSUserDefaults standardUserDefaults] setObject:_maxCloudModificationDateForEntity forKey:maxCloudModificationDateForEntityUDCompositeKey];
}



#pragma mark - initialization

- (id)copy {
    return self;
}

- (id)mutableCopy {
    return self;
}

static NSMapTable<NSString *, id> *instances[4];
static NSMapTable<NSString *, id> *instancesByConfig;
+ (void)initialize {
    [super initialize];
    instances[AKDatabaseScopeDefault] = instances[AKDatabaseScopePrivate] = [NSMapTable weakToWeakObjectsMapTable];
    instances[AKDatabaseScopePublic] = [NSMapTable weakToWeakObjectsMapTable];
    instances[AKDatabaseScopeShared] = [NSMapTable weakToWeakObjectsMapTable];
    instancesByConfig = [NSMapTable strongToWeakObjectsMapTable];
}

+ (instancetype)instanceWithContainerIdentifier:(NSString *)identifier databaseScope:(AKDatabaseScope)databaseScope {
    id instance = instances[databaseScope % 4][identifier];
    if (!instance) {
        instance = [[self alloc] initWithContainerIdentifier:identifier databaseScope:databaseScope];
        instances[databaseScope % 4][identifier] = instance;
    }
    return instance;
}

- (instancetype)initWithContainerIdentifier:(NSString *)identifier databaseScope:(AKDatabaseScope)databaseScope {
    if (self = [super init]) {
        self.config = [AKCloudConfig configWithContainerIdentifier:identifier databaseScope:databaseScope];
        [self initConfiguredInstance];
    }
    return self;
}

+ (instancetype)instanceWithConfig:(NSString *)configName {
    id instance = instancesByConfig[configName];
    if (!instance) {
        instance = [[self alloc] initWithConfig:configName];
        instancesByConfig[configName] = instance;
    }
    return instance;
}

- (instancetype)initWithConfig:(NSString *)configName {
    if (self = [super init]) {
        self.config = [AKCloudConfig configWithName:configName];
        [self initConfiguredInstance];
    }
    return self;
}

- (void)initConfiguredInstance {
    primaryInitializationGroup = dispatch_group_create();
    lockCloudGroup = dispatch_group_create();
    self.waitingQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    _recievedUpdatedRecords = [NSMutableSet new];
    _recievedDeletionInfoRecords = [NSMutableSet new];
    self.deviceList = [AKDeviceList listWithConfig:self.config];
    
    NSString *predicateFormat = [NSString stringWithFormat:@"(%@ == %%@)", self.config.deviceIDFieldName];
    thisDevicePredicate = [NSPredicate predicateWithFormat:predicateFormat, self.deviceList.thisDevice.UUIDString];
    
    self.container = [CKContainer containerWithIdentifier:self.config.containerIdentifier];
    
    NSString *dbScopeString;
    switch (self.config.databaseScope) {
        case AKDatabaseScopePublic:
            self.db = self.container.publicCloudDatabase;
            dbScopeString = @"Public";
            break;
        case AKDatabaseScopeShared:
            self.db = self.container.sharedCloudDatabase;
            dbScopeString = @"Shared";
            break;
        default:            
            self.db = self.container.privateCloudDatabase;
            dbScopeString = @"Private";
            break;
    }
    _instanceIdentifier = [NSString stringWithFormat:@"%@%@-%@", NSStringFromClass(self.class), dbScopeString, self.container.containerIdentifier];
    
    maxCloudModificationDateForEntityUDCompositeKey = [NSString stringWithFormat:@"%@-%@", _instanceIdentifier, AKCloudMaxModificationDateForEntityUDKey];
    maxCloudModificationDateForEntityMutable = self.maxCloudModificationDateForEntity.mutableCopy;
    
    preparedToCloudRecordsUDCompositeKey = [NSString stringWithFormat:@"%@-%@", _instanceIdentifier, AKCloudPreparedToCloudRecordsUDKey];
    NSData *preparedToCloudRecordsData = [[NSUserDefaults standardUserDefaults] objectForKey:preparedToCloudRecordsUDCompositeKey];
    if (preparedToCloudRecordsData) self.preparedToCloudRecords = [NSKeyedUnarchiver unarchiveObjectWithData:preparedToCloudRecordsData];
    else self.preparedToCloudRecords = [AKPreparedToCloudRecords new];
    
    [self tryPerformInit];
}


@synthesize enabled = _enabled;
- (void)setEnabled:(BOOL)enabled {
    _enabled = enabled;
    if (enabled) {
        [self tryPerformInit];
        [self startSmart];
    } else {
        [self removeAllSubscriptionsCompletion:nil];
    }
}

- (void)tryPerformInit {
#ifdef DEBUG
    NSLog(@"[DEBUG] %s", __PRETTY_FUNCTION__);
#endif
    if (self.retryToInitTimer) {
        [self.retryToInitTimer invalidate];
        self.retryToInitTimer = nil;
    }
    if (self.enabled) [self performPrimaryInitCompletion:^{
        if (self.ready) {
#ifdef DEBUG
            NSLog(@"[DEBUG] %s READY!!!", __PRETTY_FUNCTION__);
#endif
            if (self.preparedToCloudRecords.accumulativeTransaction) [self performCloudUpdateWithLocalTransaction:self.preparedToCloudRecords.accumulativeTransaction];
        } else {
            if (self.retryToInitTimer) {
                [self.retryToInitTimer invalidate];
                self.retryToInitTimer = nil;
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                self.retryToInitTimer = [NSTimer scheduledTimerWithTimeInterval:self.config.initTimeout repeats:false block:^(NSTimer * _Nonnull timer) {
                    [self tryPerformInit];
                }];
            });
        }
    }];
}

- (void)performPrimaryInitCompletion:(void (^)(void))completion {
#ifdef DEBUG
    NSLog(@"[DEBUG] %s", __PRETTY_FUNCTION__);
#endif
    dispatch_group_enter(primaryInitializationGroup);
    [self.container accountStatusWithCompletionHandler:^(CKAccountStatus accountStatus, NSError * _Nullable error) {
        if (error) {
            NSLog(@"[ERROR] %@", error.localizedDescription);
        }
        self.initState = (AKCloudState)accountStatus;
        if (accountStatus == CKAccountStatusAvailable) {
            [self updateDevicesCompletion:^{
                dispatch_group_leave(self->primaryInitializationGroup);
                if (completion) completion();
            }];
        } else {
            dispatch_group_leave(self->primaryInitializationGroup);
            if (completion) completion();
        }
    }];
}

- (void)savePreparedToCloudRecords {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSUserDefaults standardUserDefaults] setObject:[NSKeyedArchiver archivedDataWithRootObject:self.preparedToCloudRecords] forKey:self->preparedToCloudRecordsUDCompositeKey];
    });    
}



#pragma mark - Devices Update

- (void)updateDevicesCompletion:(void (^)(void))completion {
#ifdef DEBUG
    NSLog(@"[DEBUG] %s", __PRETTY_FUNCTION__);
#endif
    [self enqueueUpdateWithMappedObject:self.deviceList.thisDevice successBlock:^(BOOL success) {
        if (success) {
#ifdef DEBUG
            NSLog(@"[DEBUG] enqueueUpdateThisDevice success");
#endif
            [self pushQueueWithSuccessBlock:^(BOOL success) {
                if (success) {
#ifdef DEBUG
                    NSLog(@"[DEBUG] pushDevice success");
#endif
                    self.initState = AKCloudStateThisDeviceUpdated;
                    [self loadAllDevisesCompletion:^{
                        if (completion) completion();
                    }];
                } else {
                    NSLog(@"[WARNING] pushDevice unsuccess");
                    if (completion) completion();
                }
            }];
        } else {
            NSLog(@"[WARNING] enqueueUpdateThisDevice unsuccess");
            if (completion) completion();
        }
    }];
    
}

- (void)loadAllDevisesCompletion:(void (^)(void))completion {
#ifdef DEBUG
    NSLog(@"[DEBUG] %s", __PRETTY_FUNCTION__);
#endif
    [self getAllRecordsOfEntityName:self.config.deviceRecordType fetch:^(NSArray<__kindof CKRecord *> *records) {
        if (records) {
#ifdef DEBUG
            NSLog(@"[DEBUG] %s count: %ld", __PRETTY_FUNCTION__, (long)records.count);
#endif
            for (CKRecord<AKMappedObject> *record in records) {
                AKDevice *device = [AKDevice deviceWithMappedObject:record config:self.config];
                [self.deviceList addDevice:device];
            }
            self.initState = AKCloudStateDevicesReloaded;
        } else {
//            state ^= state & AKCloudStateDevicesReloaded;
        }
        if (completion) completion();
    }];
}

- (void)reloadDevisesCompletion:(void (^)(void))completion {
#ifdef DEBUG
    NSLog(@"[DEBUG] %s", __PRETTY_FUNCTION__);
#endif
    [self getNewRecordsOfEntityName:self.config.deviceRecordType fetch:^(NSArray<__kindof CKRecord *> *records) {
        if (records) {
#ifdef DEBUG
            NSLog(@"[DEBUG] %s count: %ld", __PRETTY_FUNCTION__, (long)records.count);
#endif
            for (CKRecord<AKMappedObject> *record in records) {
                AKDevice *device = [AKDevice deviceWithMappedObject:record config:self.config];
                [self.deviceList addDevice:device];
            }
        }
        if (completion) completion();
    }];
}

#pragma mark - Subscriptions and Remote notifications

- (void)subscribeToRegisteredRecordTypes {
    [self removeAllSubscriptionsCompletion:^{
        [self saveSubscriptions];
    }];
}

- (void)removeAllSubscriptionsCompletion:(void (^)(void))completion {
#ifdef DEBUG
    NSLog(@"[DEBUG] %s", __PRETTY_FUNCTION__);
#endif
    [self.db fetchAllSubscriptionsWithCompletionHandler:^(NSArray<CKSubscription *> * _Nullable subscriptions, NSError * _Nullable error) {
        dispatch_group_t removeSubscriptionsGroup = dispatch_group_create();
        
        if (error) NSLog(@"[ERROR] fetchAllSubscriptions error: %@", error.localizedDescription);
        for (CKQuerySubscription *subscription in subscriptions) {
            dispatch_group_enter(removeSubscriptionsGroup);
            [self.db deleteSubscriptionWithID:subscription.subscriptionID completionHandler:^(NSString * _Nullable subscriptionID, NSError * _Nullable error) {
                if (error) NSLog(@"[ERROR] deleteSubscription error: %@", error.localizedDescription);
                dispatch_group_leave(removeSubscriptionsGroup);
            }];
        }
        if (completion) {
            dispatch_group_wait(removeSubscriptionsGroup, DISPATCH_TIME_FOREVER);
            completion();
        }
    }];
}

typedef void (^SaveSubscriptionCompletionHandler)(CKSubscription * _Nullable subscription, NSError * _Nullable error);
- (void)saveSubscriptions {
#ifdef DEBUG
    NSLog(@"[DEBUG] %s", __PRETTY_FUNCTION__);
#endif
    SaveSubscriptionCompletionHandler completionHandler = ^(CKSubscription * _Nullable subscription, NSError * _Nullable error) {
        if (error) {
            NSLog(@"[ERROR] Subscription failed: %@", error.localizedDescription);
        } else {
            NSLog(@"[INFO] Success subscripted: %@", subscription);
        }
    };
    for (NSString *recordType in self.mapping.allRecordTypes) {
        CKQuerySubscription *subscription = [[CKQuerySubscription alloc] initWithRecordType:recordType
                                                                                  predicate:[NSPredicate predicateWithValue:true]
                                                                                    options:+CKQuerySubscriptionOptionsFiresOnRecordCreation
                                                                                            +CKQuerySubscriptionOptionsFiresOnRecordUpdate
                                                                                            +CKQuerySubscriptionOptionsFiresOnRecordDeletion];
        subscription.notificationInfo = [CKNotificationInfo new];
        //            subscription.notificationInfo.alertBody = @"";
        subscription.notificationInfo.shouldBadge = true;
        subscription.notificationInfo.category = @"CloudKit";
        [self.db saveSubscription:subscription completionHandler:completionHandler];
    }
    CKQuerySubscription *subscription = [[CKQuerySubscription alloc] initWithRecordType:self.config.deletionInfoRecordType
                                                                              predicate:thisDevicePredicate
                                                                                options:CKQuerySubscriptionOptionsFiresOnRecordCreation+CKQuerySubscriptionOptionsFiresOnRecordUpdate];
    [self.db saveSubscription:subscription completionHandler:completionHandler];
}

- (void)acceptPushNotificationUserInfo:(NSDictionary *)userInfo {
    CKQueryNotification *notification = [CKQueryNotification notificationFromRemoteNotificationDictionary:userInfo];
    if (notification.notificationType == CKNotificationTypeQuery && notification.databaseScope == self.db.databaseScope && [notification.containerIdentifier isEqualToString:self.container.containerIdentifier]) {
#ifdef DEBUG
        NSLog(@"[DEBUG] %@ acceptPushNotification: %@", self.class, notification);
#endif
        if (notification.queryNotificationReason == CKQueryNotificationReasonRecordDeleted) {
            [self getCloudDeletionInfoCompletion:^{
                [self performMergeAndCleanupIfNeeded];
            }];
        } else {            
            [self recordByRecordID:notification.recordID fetch:^(CKRecord <AKMappedObject>*record, NSError * _Nullable error) {
                if (record) {
                    #ifdef DEBUG
                    NSLog(@"[DEBUG] found record %@", record);
                    #endif
                    NSString *entityName = self.mapping.reverseMap[record.recordType];
                    if ([record.recordType isEqualToString:self.config.deletionInfoRecordType]) {
                        [self->_recievedDeletionInfoRecords addObject:record];
                        [self.preparedToCloudRecords addRecordIDToDelete:record.recordID];
                    } else if (entityName) {
                        [self->_recievedUpdatedRecords addObject:record];
                    }
                    [self performMergeAndCleanupIfNeeded];
                } else {
                    @throw [NSException exceptionWithName:@"CKFetchRecordsOperation failed"
                                                   reason:[NSString stringWithFormat:@"Object with recordID %@ not found.", notification.recordID.recordName]
                                                 userInfo:nil];
                }
            }];
            [self smartReplication];
        }
        //*/
    } else {
        NSLog(@"[WARNING] Unacceptable notification recieved %@", notification);
    }
}



#pragma mark - AKCloudManager

- (BOOL)ready {
//    AKCloudState requiredState = AKCloudStateAccountStatusAvailable | AKCloudStateThisDeviceUpdated | AKCloudStateDevicesReloaded;
    return self.initState == AKCloudStateReady;
}

- (void)setDataSyncContext:(id<AKDataSyncContextPrivate, AKCloudManagerOwner>)context {
    self.syncContext = context;
    [self startSmart];
}

- (void)startSmart {
#ifdef DEBUG
    NSLog(@"[DEBUG] %s", __PRETTY_FUNCTION__);
#endif
    if (self.enabled) dispatch_async(self.waitingQueue, ^{
        dispatch_group_wait(self->primaryInitializationGroup, DISPATCH_TIME_FOREVER);
        if (self.ready) {
            [self subscribeToRegisteredRecordTypes];
            [self smartReplication];
        } else {
            if (self.enabled) dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.config.smartReplicationTimeout * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                if (self.enabled) [self startSmart];
            });
        }
    });
}

- (AKCloudMapping *)mapping {
    return self.syncContext.cloudMapping;
}

- (id<AKDataSyncContextPrivate, AKCloudManagerOwner>)dataSyncContext {
    return self.syncContext;
}

- (void)context:(id<AKCloudManagerOwner>)context willCommitTransaction:(id<AKRepresentableTransaction>)transaction {
#ifdef DEBUG
    NSLog(@"[DEBUG] %s", __PRETTY_FUNCTION__);
#endif
    if (self.enabled) {
        if (self.preparedToCloudRecords.accumulativeTransaction) {
            [self.preparedToCloudRecords.accumulativeTransaction mergeWithRepresentableTransaction:transaction];
            [self savePreparedToCloudRecords];
            [self performCloudUpdateWithLocalTransaction:self.preparedToCloudRecords.accumulativeTransaction];
        } else [self performCloudUpdateWithLocalTransaction:transaction];
    } else {
        if (self.preparedToCloudRecords.accumulativeTransaction) {
            [self.preparedToCloudRecords.accumulativeTransaction mergeWithRepresentableTransaction:transaction];
        } else {
            self.preparedToCloudRecords.accumulativeTransaction = [AKTransactionRepresentation instantiateWithRepresentableTransaction:transaction];
        }
        [self savePreparedToCloudRecords];
    }


}

- (void)performCloudUpdateWithLocalTransaction:(NSObject <AKRepresentableTransaction> *)transaction {
#ifdef DEBUG
    NSLog(@"[DEBUG] %s", __PRETTY_FUNCTION__);
#endif
    dispatch_async(self.waitingQueue, ^{
        dispatch_group_wait(self->primaryInitializationGroup, DISPATCH_TIME_FOREVER);
        if (self.ready) {
            dispatch_group_wait(self->lockCloudGroup, DISPATCH_TIME_FOREVER);
            dispatch_group_enter(self->lockCloudGroup);
            for (NSObject<AKMappedObject> *mappedObject in transaction.updatedObjects) {
                [self enqueueUpdateWithMappedObject:mappedObject successBlock:^(BOOL success) {
                    if (!success) {
                        [self.preparedToCloudRecords addFailedEnqueueUpdateObject:mappedObject];
                        [self savePreparedToCloudRecords];
                        NSLog(@"[WARNING] enqueueUpdateWithMappedObject unsuccess");
                    } else {
#ifdef DEBUG
                        NSLog(@"[DEBUG] enqueueUpdateWithMappedObject success");
#endif
                    }

                }];
            }
            [self reloadDevisesCompletion:^{
                for (NSObject<AKDescription> *description in transaction.deletedObjects) {
                    [self enqueueDeletionWithDescription:description];
                }
                [self pushQueueWithSuccessBlock:^(BOOL success) {
                    if (self.preparedToCloudRecords.accumulativeTransaction) self.preparedToCloudRecords.accumulativeTransaction = nil;
                    [self savePreparedToCloudRecords];
                    dispatch_group_leave(self->lockCloudGroup);
                }];
            }];
        } else {
            if (!self.preparedToCloudRecords.accumulativeTransaction) {
                self.preparedToCloudRecords.accumulativeTransaction = [AKTransactionRepresentation instantiateWithRepresentableTransaction:transaction];
                [self savePreparedToCloudRecords];
            }
            if (self.enabled) dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.config.initTimeout * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                if (self.enabled) [self performPrimaryInitCompletion:^{
                    [self performCloudUpdateWithLocalTransaction:self.preparedToCloudRecords.accumulativeTransaction];
                }];
            });
        }
    });
}



#pragma mark - Replication

- (void)smartReplication {
#ifdef DEBUG
    NSLog(@"[DEBUG] %s", __PRETTY_FUNCTION__);
#endif
    if (self.enabled) [self replicationTotal:false completion:nil];
}

- (void)totalReplication:(void (^)(void))completion {
#ifdef DEBUG
    NSLog(@"[DEBUG] %s", __PRETTY_FUNCTION__);
#endif
    if (self.enabled) [self replicationTotal:true completion:completion];
}

- (void)replicationTotal:(BOOL)total completion:(void (^)(void))completion {
    if (total) {
        if (self.totalReplicationInprogress) return ;
        else self.totalReplicationInprogress = self.smartReplicationInprogress = true;
    } else {
        if (self.smartReplicationInprogress) return ;
        else self.smartReplicationInprogress = true;
    }
    dispatch_async(self.waitingQueue, ^{
        dispatch_group_wait(self->primaryInitializationGroup, DISPATCH_TIME_FOREVER);
        if (self.ready) {
            dispatch_group_wait(self->lockCloudGroup, DISPATCH_TIME_FOREVER);
            dispatch_group_enter(self->lockCloudGroup);
            [self reloadMappedRecordsTotal:total completion:^{
                dispatch_group_leave(self->lockCloudGroup);
                self.totalReplicationInprogress = self.smartReplicationInprogress = false;
                if (completion) completion();
                [self resmart];
            }];
        } else {
            self.totalReplicationInprogress = self.smartReplicationInprogress = false;
            if (completion) completion();
            [self resmart];
        }
    });
}

- (void)resmart {
#ifdef DEBUG
    NSLog(@"[DEBUG] %s", __PRETTY_FUNCTION__);
#endif
    if (self.enabled) dispatch_async(dispatch_get_main_queue(), ^{
        if (self.resmartTimer) {
            [self.resmartTimer invalidate];
            self.resmartTimer = nil;
        }
        self.resmartTimer = [NSTimer scheduledTimerWithTimeInterval:self.config.smartReplicationTimeout repeats:false block:^(NSTimer * _Nonnull timer) {
            [self.resmartTimer invalidate];
            self.resmartTimer = nil;
            [self smartReplication];
        }];
    });
}

- (void)reloadMappedRecordsTotal:(BOOL)total completion:(void(^)(void))completion {
#ifdef DEBUG
    NSLog(@"[DEBUG] %s", __PRETTY_FUNCTION__);
#endif
    dispatch_group_t thisGroup = dispatch_group_create();
    for (NSString *entityName in self.mapping.synchronizableEntities) {
        FetchRecordsArray fetchArrayBlock = ^(NSArray<__kindof CKRecord *> *records) {
            for (CKRecord *record in records) {
                [self->_recievedUpdatedRecords addObject:record];
            }
            dispatch_group_leave(thisGroup);
        };
        dispatch_group_enter(thisGroup);
        if (total) {
            [self getAllRecordsOfEntityName:entityName fetch:fetchArrayBlock];
        } else {
            [self getNewRecordsOfEntityName:entityName fetch:fetchArrayBlock];
        }
    }
    
    dispatch_group_enter(thisGroup);
    [self getCloudDeletionInfoCompletion:^{
        dispatch_group_leave(thisGroup);
    }];
    
    dispatch_async(self.waitingQueue, ^{
        dispatch_group_wait(thisGroup, DISPATCH_TIME_FOREVER);
        [self performMergeAndCleanupIfNeeded];
        if (completion) completion();
    });
}

- (void)getCloudDeletionInfoCompletion:(void (^)(void))completion {
    [self getRecordsOfEntityName:self.config.deletionInfoRecordType withPredicate:thisDevicePredicate fetch:^(NSArray<__kindof CKRecord *> *records) {
        for (CKRecord *record in records) {
            [self->_recievedDeletionInfoRecords addObject:record];
            [self.preparedToCloudRecords addRecordIDToDelete:record.recordID]; //cleanup
        }
        if (completion) completion();
    }];
}

- (void)performMergeAndCleanupIfNeeded {
    if (_recievedUpdatedRecords.count + _recievedDeletionInfoRecords.count) {
        [self.syncContext performMergeWithTransaction:[AKCloudTransaction transactionWithUpdatedRecords:self.recievedUpdatedRecords
                                                                               deletionInfoRecords:self.recievedDeletionInfoRecords
                                                                                           mapping:self.mapping
                                                                                            config:self.config]];
        [_recievedUpdatedRecords removeAllObjects];
        [_recievedDeletionInfoRecords removeAllObjects];
    }
    if (self.preparedToCloudRecords.recordIDsToDelete) {
        [self pushQueueWithSuccessBlock:^(BOOL success) {
#ifdef DEBUG
            NSLog(@"[DEBUG] Cleanup DeletionInfo %@", success ? @"success" : @"failed");
#endif
        }];
    }
}

#pragma mark - Fetch Records

- (void)getAllRecordsOfEntityName:(NSString *)entityName fetch:(FetchRecordsArray)fetch {
#ifdef DEBUG
    NSLog(@"[DEBUG] %s %@", __PRETTY_FUNCTION__, entityName);
#endif
    [self setMaxCloudModificationDate:nil forEntity:entityName];
    [self getNewRecordsOfEntityName:entityName fetch:fetch];
}

- (void)getNewRecordsOfEntityName:(NSString *)entityName fetch:(FetchRecordsArray)fetch {
#ifdef DEBUG
    NSLog(@"[DEBUG] %s %@", __PRETTY_FUNCTION__, entityName);
#endif
    NSDate *maxCloudModificationDate = self.maxCloudModificationDateForEntity[entityName];
    
    NSPredicate *predicate = maxCloudModificationDate ? [NSPredicate predicateWithFormat:@"modificationDate >= %@", maxCloudModificationDate] : nil;
    [self getRecordsOfEntityName:entityName withPredicate:predicate fetch:^(NSArray<__kindof CKRecord *> *records) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSDate *maxDate = maxCloudModificationDate;
            BOOL changed = false;
            for (CKRecord *record in records) {
                if (!maxDate || [maxDate compare:(NSDate *)record[@"modificationDate"]] == NSOrderedAscending) {
                    maxDate = record[@"modificationDate"];
                    changed = true;
                }
            }
            if (changed) [self setMaxCloudModificationDate:[maxDate dateByAddingTimeInterval:-60.0f] forEntity:entityName];
        });
        fetch(records);
    }];
}

- (void)getRecordsOfEntityName:(NSString *)entityName withPredicate:(NSPredicate *)predicate fetch:(FetchRecordsArray)fetch {
#ifdef DEBUG
    NSLog(@"[DEBUG] getRecordsOfEntityName: %-20s withPredicate: %@", [entityName UTF8String], predicate);
#endif
    
    NSMutableArray *foundRecords = [NSMutableArray new];
    
    CKQuery *query = [[CKQuery alloc] initWithRecordType:self.mapping[entityName] predicate:predicate ?: [NSPredicate predicateWithValue:true]];
    CKQueryOperation *queryOperation = [[CKQueryOperation alloc] initWithQuery:query];
    
    __block CKQueryOperation *activeOperation = queryOperation;
    
    queryOperation.recordFetchedBlock = ^(CKRecord * _Nonnull record) {
        [foundRecords addObject:record];
    };
    queryOperation.queryCompletionBlock = ^(CKQueryCursor * _Nullable cursor, NSError * _Nullable operationError) {
        if (operationError) {
            NSLog(@"[ERROR] %@", operationError);
            fetch(nil);
        } else {
            if (cursor) {
                CKQueryOperation *fetchNext = [[CKQueryOperation alloc] initWithCursor:cursor];
                fetchNext.recordFetchedBlock = activeOperation.recordFetchedBlock;
                fetchNext.queryCompletionBlock = activeOperation.queryCompletionBlock;
                activeOperation = fetchNext;
                [self.db addOperation:fetchNext];
            } else {
                fetch(foundRecords.copy);
            }
        }
    };
    
    [self.db addOperation:queryOperation];
}


- (void)recordByRecordID:(CKRecordID *)recordID fetch:(void (^)(CKRecord<AKMappedObject> *record, NSError * _Nullable error))fetch {
#ifdef DEBUG
    NSLog(@"[DEBUG] %s", __PRETTY_FUNCTION__);
#endif
    CKFetchRecordsOperation *fetchOperation = [[CKFetchRecordsOperation alloc] initWithRecordIDs:@[recordID]];
    __block NSInteger count = 0;
    __block CKRecord<AKMappedObject> *foundRecord = nil;
    __block NSError *error = nil;
    
    [fetchOperation setPerRecordCompletionBlock:^(CKRecord * _Nullable record, CKRecordID * _Nullable recordID, NSError * _Nullable operationError) {
        if (operationError) {
            NSLog(@"[ERROR] fetchOperationError: %@", operationError);
            error = operationError;
        }
        if (record) {
            foundRecord = (CKRecord<AKMappedObject> *)record;
            count++;
        }
    }];
    
    [fetchOperation setCompletionBlock:^{
        fetch(foundRecord, error);
        if (count > 1) {
            @throw [NSException exceptionWithName:@"CKFetchRecordsOperation error" reason:[NSString stringWithFormat:@"Unique constraint violated: duplicated recordID %@", recordID.recordName] userInfo:nil];
        }
    }];
    
    fetchOperation.queuePriority = NSOperationQueuePriorityVeryHigh;
    fetchOperation.qualityOfService = NSQualityOfServiceUserInteractive;
    [self.db addOperation:fetchOperation];
}


#pragma mark - Cloud Update

- (void)enqueueUpdateWithMappedObject:(NSObject<AKMappedObject> *)syncObject successBlock:(void (^)(BOOL success))successBlock {
    if (!syncObject.uniqueData) {
        NSLog(@"[ERROR] %s syncObject.uniqueData == nil. syncObject %@", __PRETTY_FUNCTION__, syncObject);
        return;
    }
#ifdef DEBUG
//    else {
//        NSLog(@"[DEBUG] %s entity %@ UUID %@", __PRETTY_FUNCTION__, syncObject.entityName, syncObject.uniqueData.UUIDString);
//    }
#endif
    dispatch_group_enter(self.preparedToCloudRecords.lockGroup);
    CKRecordID *recordID = [CKRecordID recordIDWithUUIDString:syncObject.uniqueData.UUIDString];
    [self recordByRecordID:recordID fetch:^(CKRecord<AKMappedObject> *record, NSError * _Nullable error) {
        if (record) {
            if (record[self.config.realModificationDateFieldName] && [record[self.config.realModificationDateFieldName] compare:syncObject.modificationDate] != NSOrderedAscending) {
                NSLog(@"[WARNING] Cloud record %@ up to date %@", record.UUIDString, record[self.config.realModificationDateFieldName]);
                dispatch_group_leave(self.preparedToCloudRecords.lockGroup);
                return ; // record update no needed
            }
        } else {
            if (error.code == CKErrorUnknownItem) {
                NSLog(@"[INFO] Not found. Create new record with recordID %@", recordID.recordName);
                record = (CKRecord<AKMappedObject> *)[CKRecord recordWithRecordType:self.mapping[syncObject.entityName] recordID:recordID];
            } else {
                NSLog(@"[ERROR] recordByRecordID error: %@", error);
                
                dispatch_group_leave(self.preparedToCloudRecords.lockGroup);
                if (successBlock) successBlock(false);
                return ;
            }
        }
        record.keyedDataProperties = syncObject.keyedDataProperties;
        record[self.config.realModificationDateFieldName] = syncObject.modificationDate;
        
        if ([syncObject conformsToProtocol:@protocol(AKRelatableToOne)]) {
            NSObject <AKRelatableToOne> *relatableObject = (NSObject <AKRelatableToOne> *)syncObject;
            NSDictionary <NSString *, NSObject<AKReference> *> *keyedReferences = relatableObject.keyedReferences;
            for (NSString *relationKey in keyedReferences.allKeys) {
                [record replaceRelation:relationKey toReference:keyedReferences[relationKey]];
            }
        }
        
        if ([syncObject conformsToProtocol:@protocol(AKRelatableToMany)]) {
            NSObject <AKRelatableToMany> *relatableObject = (NSObject <AKRelatableToMany> *)syncObject;
            NSDictionary <NSString *, NSSet <NSObject<AKReference> *> *> *keyedSetsOfReferences = relatableObject.keyedSetsOfReferences;
            for (NSString *relationKey in keyedSetsOfReferences.allKeys) {
                [record replaceRelation:relationKey toSetsOfReferences:keyedSetsOfReferences[relationKey]];
            }
        }
        
        [self.preparedToCloudRecords addRecordToSave:record];
        dispatch_group_leave(self.preparedToCloudRecords.lockGroup);
        if (successBlock) successBlock(true);
    }];
}

- (void)enqueueDeletionWithDescription:(id<AKDescription>)description {
    if (!description.uniqueData) {
        NSLog(@"[ERROR] %s description.uniqueData == nil. description %@", __PRETTY_FUNCTION__, description);
        return;
    }
#ifdef DEBUG
    else NSLog(@"[DEBUG] %s %@", __PRETTY_FUNCTION__, description);
#endif
    CKRecordID *recordID = [CKRecordID recordIDWithUUIDString:description.uniqueData.UUIDString];
    [self.preparedToCloudRecords addRecordIDToDelete:recordID];
    for (AKDevice *device in self.deviceList) {
        CKRecord *deletionInfo = [CKRecord recordWithRecordType:self.config.deletionInfoRecordType];
        deletionInfo[self.config.recordTypeFieldName] = self.mapping[description.entityName];
        deletionInfo[self.config.recordIDFieldName] = description.uniqueData.UUIDString;
        deletionInfo[self.config.deviceIDFieldName] = device.UUIDString;
        [self.preparedToCloudRecords addRecordToSave:deletionInfo];
    }
}

- (void)pushQueueWithSuccessBlock:(void (^)(BOOL success))successBlock {
#ifdef DEBUG
    NSLog(@"[DEBUG] %s", __PRETTY_FUNCTION__);
#endif
    for (id<AKMappedObject> mappedObject in self.preparedToCloudRecords.failedEnqueueUpdateObjects) {
        [self enqueueUpdateWithMappedObject:mappedObject successBlock:^(BOOL success) {
            NSLog(@"[%@] retry enqueueUpdateWithMappedObject %@success", success ? @"INFO" : @"WARNING", success ? @"": @"un");
        }];
    }
    
    dispatch_async(self.waitingQueue, ^{
        dispatch_group_wait(self.preparedToCloudRecords.lockGroup, DISPATCH_TIME_FOREVER);
        CKModifyRecordsOperation *mop = [[CKModifyRecordsOperation alloc] initWithRecordsToSave:self.preparedToCloudRecords.recordsToSave
                                                                              recordIDsToDelete:self.preparedToCloudRecords.recordIDsToDelete];
        [mop setModifyRecordsCompletionBlock:^(NSArray<CKRecord *> * _Nullable savedRecords, NSArray<CKRecordID *> * _Nullable deletedRecordIDs, NSError * _Nullable operationError) {
            if (operationError) {
                NSLog(@"[ERROR] CKModifyRecordsOperation Error: %@", operationError);
            }
            if (savedRecords.count == self.preparedToCloudRecords.recordsToSave.count && deletedRecordIDs.count == self.preparedToCloudRecords.recordIDsToDelete.count) {
                [self.preparedToCloudRecords clearAll];
                [self savePreparedToCloudRecords];
                if (successBlock) successBlock(true);
            } else {
                [self.preparedToCloudRecords clearWithSavedRecords:savedRecords deletedRecordIDs:deletedRecordIDs];
                [self savePreparedToCloudRecords];
                if (self.enabled) dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.config.tryToPushTimeout * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    dispatch_async(self.waitingQueue, ^{
                        dispatch_group_wait(self.preparedToCloudRecords.lockGroup, DISPATCH_TIME_FOREVER);
                        dispatch_group_wait(self->lockCloudGroup, DISPATCH_TIME_FOREVER);
                        if (self.preparedToCloudRecords.recordsToSave.count + self.preparedToCloudRecords.recordIDsToDelete.count) {
                            dispatch_group_enter(self->lockCloudGroup);
                            [self pushQueueWithSuccessBlock:^(BOOL success) {
                                dispatch_group_leave(self->lockCloudGroup);
                            }];
                        }
                    });
                });
                if (successBlock) successBlock(false);
            }
        }];
        mop.queuePriority = NSOperationQueuePriorityVeryHigh;
        mop.qualityOfService = NSQualityOfServiceUserInteractive;
        [self.db addOperation:mop];
    });
    
}



@end
