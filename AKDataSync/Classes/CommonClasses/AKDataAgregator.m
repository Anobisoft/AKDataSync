//
//  AKDataAgregator.m
//  AKDataSync
//
//  Created by Stanislav Pletnev on 11.06.16.
//  Copyright © 2016 Anobisoft. All rights reserved.
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
}

+ (instancetype)defaultAgregator {
	return [self shared];
}

- (instancetype)init {
    if (self = [super init]) {
        self.watchConnector = (id<AKWatchConnector>)AKWatchConnector.shared;
        [self.watchConnector setAgregator:self];
        watchContextSet = [NSMutableSet new];
//#warning UNCOMPLETED reload "replication needed" status
    }
    return self;
}

- (void)context:(id<AKCloudManagerOwner>)context willCommitTransaction:(id<AKRepresentableTransaction>)transaction {
    if ([watchContextSet containsObject:(id<AKDataSyncContextPrivate>)transaction]) {
        AKTransactionRepresentation *transactionRepresentation = [AKTransactionRepresentation instantiateWithRepresentableTransaction:transaction];
        if (_watchConnector) {
            if (_watchConnector.ready) {
                [_watchConnector sendTransaction:transactionRepresentation];
            } else {
                NSLog(@"[WARNING] %s : watchConnector is not ready", __PRETTY_FUNCTION__);
            }
        }
    }
    
    if (context.cloudManager) [context.cloudManager context:context willCommitTransaction:transaction];

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
- (void)setCloudContext:(id<AKDataSyncContextPrivate, AKCloudManagerOwner>)context containerIdentifier:(NSString *)containerIdentifier databaseScope:(AKDatabaseScope)databaseScope {
    id<AKCloudManager> cloudManager = (id<AKCloudManager>)[AKCloudManager instanceWithContainerIdentifier:containerIdentifier databaseScope:databaseScope];
    [context setAgregator:self];
    [context setCloudManager:cloudManager];
    [cloudManager setDataSyncContext:context];
}

- (void)setCloudContext:(id<AKDataSyncContextPrivate, AKCloudManagerOwner>)context config:(NSString *)configName {
    id<AKCloudManager> cloudManager = (id<AKCloudManager>)[AKCloudManager instanceWithConfig:configName];
    [context setAgregator:self];
    [context setCloudManager:cloudManager];
    [cloudManager setDataSyncContext:context];
}
#endif


@end
