//
//  AKDataAgregator.h
//  AKDataSync
//
//  Created by Stanislav Pletnev on 11.06.16.
//  Copyright © 2016 Anobisoft.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AnobiKit/AKTypes.h>
#import "AKPublicProtocol.h"
#import "AKDataSyncTypes.h"

@protocol AKDataSyncContextPrivate, AKCloudManagerOwner;

@interface AKDataAgregator : AKSingleton

- (void)addWatchSynchronizableContext:(id <AKDataSyncContext>)context;
- (void)setCloudContext:(id <AKDataSyncContextPrivate, AKCloudManagerOwner>)context containerIdentifier:(NSString *)containerIdentifier databaseScope:(AKDatabaseScope)databaseScope __WATCHOS_UNAVAILABLE;
- (void)setCloudContext:(id <AKDataSyncContextPrivate, AKCloudManagerOwner>)context config:(NSString *)configName __WATCHOS_UNAVAILABLE;

+ (instancetype)defaultAgregator;

@end

