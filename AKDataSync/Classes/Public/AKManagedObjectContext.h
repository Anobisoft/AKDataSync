//
//  AKManagedObjectContext.h
//  AKDataSync
//
//  Created by Stanislav Pletnev on 11.06.16.
//  Copyright © 2016 Anobisoft.com. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "AKDataSyncTypes.h"
#import "AKPublicProtocol.h"
#import "NSManagedObject+AKDataSync.h"
#import <AnobiKit/AKTypes.h>


#define ASC ascending:true
#define DESC ascending:false

NS_ASSUME_NONNULL_BEGIN

typedef void (^FetchObject)(__kindof NSManagedObject *object);

@interface AKManagedObjectContext : NSManagedObjectContext <AKDataSyncContext>

- (instancetype)initWithConcurrencyType:(NSManagedObjectContextConcurrencyType)ct NS_UNAVAILABLE;
- (instancetype)initWithStoreURL:(NSURL *)storeURL modelURL:(nullable NSURL *)modelURL NS_DESIGNATED_INITIALIZER API_AVAILABLE(ios(9.0),watchos(2.0));
- (instancetype)initWithStoreURL:(NSURL *)storeURL;

+ (instancetype)defaultContext;
@property (nonatomic, weak) id <AKDataSyncContextDelegate> delegate;

- (void)enableCloudSyncWithContainerIdentifier:(NSString *)containerIdentifier databaseScope:(AKDatabaseScope)databaseScope __WATCHOS_UNAVAILABLE;
- (void)enableCloudSyncWithConfig:(nonnull NSString *)configName __WATCHOS_UNAVAILABLE;
@property (nonatomic, assign) BOOL cloudEnabled __WATCHOS_UNAVAILABLE;
- (void)cloudReplication __WATCHOS_UNAVAILABLE;
- (void)acceptPushNotificationUserInfo:(NSDictionary *)userInfo __WATCHOS_UNAVAILABLE;
- (void)performTotalReplication;
- (BOOL)totalReplicationInProgress;
- (void)enableWatchSynchronization;

- (id)init NS_UNAVAILABLE;
- (id)copy NS_UNAVAILABLE;
- (id)mutableCopy NS_UNAVAILABLE;

//Thread safe requests

- (void)objectByUniqueData:(NSData *)uniqueData entityName:(NSString *)entityName fetch:(FetchObject)fetch;

- (void)insertTo:(NSString *)entityName fetch:(FetchObject)fetch;
- (void)deleteObject:(NSManagedObject *)object completion:(AKBlock)completion;

- (void)selectFrom:(NSString *)entity fetch:(FetchArray)fetch;
- (void)selectFrom:(NSString *)entity limit:(NSUInteger)limit fetch:(FetchArray)fetch;
- (void)selectFrom:(NSString *)entity orderBy:(nullable NSArray <NSSortDescriptor *> *)sortDescriptors fetch:(FetchArray)fetch;
- (void)selectFrom:(NSString *)entity orderBy:(nullable NSArray <NSSortDescriptor *> *)sortDescriptors limit:(NSUInteger)limit fetch:(FetchArray)fetch;

- (void)selectFrom:(NSString *)entity where:(nullable NSPredicate *)clause fetch:(FetchArray)fetch;
- (void)selectFrom:(NSString *)entity where:(nullable NSPredicate *)clause limit:(NSUInteger)limit fetch:(FetchArray)fetch;
- (void)selectFrom:(NSString *)entity where:(nullable NSPredicate *)clause orderBy:(nullable NSArray <NSSortDescriptor *> *)sortDescriptors fetch:(FetchArray)fetch;
- (void)selectFrom:(NSString *)entity where:(nullable NSPredicate *)clause orderBy:(nullable NSArray <NSSortDescriptor *> *)sortDescriptors limit:(NSUInteger)limit fetch:(FetchArray)fetch;

NS_ASSUME_NONNULL_END


@end
