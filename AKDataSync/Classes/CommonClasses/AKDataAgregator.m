//
//  AKDataAgregator.m
//  AKDataSync
//
//  Created by Stanislav Pletnev on 11.06.16.
//  Copyright © 2016 Anobisoft.com. All rights reserved.
//

#import "AKDataAgregator.h"
#import "AKPrivateProtocol.h"
#import "AKWatchConnector.h"
#import "AKTransactionRepresentation.h"

#import "AKCloudManager.h"

@interface AKDataAgregator() <AKWatchTransactionsAgregator, AKTransactionsAgregator>
@property (nonatomic, weak) id<AKWatchConnector> watchConnector;
@end

@implementation AKDataAgregator {
    NSMutableSet <id<AKDataSyncContextPrivate>> *watchContextSet;
#if TARGET_OS_IOS
    NSMutableDictionary <NSString *, id<AKCloudManager>> *cloudManagers[4];
#endif
}

+ (instancetype)new {
    return [self defaultAgregator];
}

- (id)copy {
    return self;
}

- (id)mutableCopy {
    return self;
}

+ (instancetype)defaultAgregator {
    static dispatch_once_t pred;
    static id shared = nil;
    dispatch_once(&pred, ^{
        shared = [[self alloc] initUniqueInstance];
    });
    return shared;
}

- (instancetype)initUniqueInstance {
    if (self = [super init]) {
        self.watchConnector = (id<AKWatchConnector>)AKWatchConnector.sharedInstance;
        [self.watchConnector setAgregator:self];
        watchContextSet = [NSMutableSet new];
//#warning UNCOMPLETED reload "replication needed" status
#if TARGET_OS_IOS
        cloudManagers[AKDatabaseScopeDefault] = cloudManagers[AKDatabaseScopePrivate] = [NSMutableDictionary new];
        cloudManagers[AKDatabaseScopePublic] = [NSMutableDictionary new];
        cloudManagers[AKDatabaseScopeShared] = nil;
#endif
    }
    return self;
}

- (void)willCommitTransaction:(id <AKRepresentableTransaction>)transaction {
    if ([watchContextSet containsObject:(id <AKDataSyncContextPrivate>)transaction]) {
        AKTransactionRepresentation *transactionRepresentation = [AKTransactionRepresentation instantiateWithRepresentableTransaction:transaction];
        if (_watchConnector) {
            if (_watchConnector.ready) {
                [_watchConnector sendTransaction:transactionRepresentation];
            } else {
                NSLog(@"[WARNING] %s : watchConnector is not ready", __PRETTY_FUNCTION__);
            }
        }
    }
#if TARGET_OS_IOS
    for (int i = 0; i < 4; i++) {
        id<AKCloudManager> cloudManager = cloudManagers[i][transaction.contextIdentifier];
        if (cloudManager) {
            [cloudManager willCommitTransaction:transaction];
        }
    }
#endif
}

- (void)watchConnectorGetReady:(id<AKWatchConnector>)connector {
//#warning UNCOMPLETED Start full replication if connector ready and replication needed.
}

- (void)watchConnector:(AKWatchConnector *)connector didRecieveTransaction:(id<AKRepresentableTransaction>)transaction {
#ifdef DEBUG
    NSLog(@"[DEBUG] %s : <%@>", __PRETTY_FUNCTION__, transaction.contextIdentifier);
#endif
    for (id<AKDataSyncContextPrivate> cc in watchContextSet) {
        if ([cc.contextIdentifier isEqualToString:transaction.contextIdentifier]) {
            [cc performMergeWithTransaction:transaction];
            return ;
        }
    }
    NSLog(@"[ERROR] %s : context <%@> not found", __PRETTY_FUNCTION__, transaction.contextIdentifier);
}

- (void)addWatchSynchronizableContext:(id<AKDataSyncContextPrivate>)context {
    [watchContextSet addObject:context];
    [context setAgregator:self];
//#warning UNCOMPLETED Start full replication if connector ready and replication needed.
}

#if TARGET_OS_IOS
- (void)setCloudContext:(id <AKDataSyncContextPrivate, AKCloudMappingProvider>)context containerIdentifier:(NSString *)containerIdentifier databaseScope:(AKDatabaseScope)databaseScope {
    id<AKCloudManager> cloudManager = cloudManagers[databaseScope][context.contextIdentifier];
    if (!cloudManager) {
        cloudManager = (id<AKCloudManager>)[AKCloudManager instanceWithContainerIdentifier:containerIdentifier databaseScope:databaseScope];
        cloudManagers[databaseScope][context.contextIdentifier] = cloudManager;
    }
    [context setAgregator:self];
    [context setCloudManager:cloudManager];
    [cloudManager setDataSyncContext:context];
}
#endif


@end
