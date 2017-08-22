//
//  AKDataAgregator.h
//  AKDataSync
//
//  Created by Stanislav Pletnev on 11.06.16.
//  Copyright © 2016 Anobisoft.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AKPublicProtocol.h"
#import "AKDataSyncTypes.h"

@protocol AKDataSyncContextPrivate, AKCloudMappingProvider;

@interface AKDataAgregator : NSObject

- (void)addWatchSynchronizableContext:(id <AKDataSyncContext>)context;
- (void)setCloudContext:(id <AKDataSyncContextPrivate, AKCloudMappingProvider>)context containerIdentifier:(NSString *)containerIdentifier databaseScope:(AKDatabaseScope)databaseScope __WATCHOS_UNAVAILABLE;

- (instancetype)init NS_UNAVAILABLE;
- (id)copy NS_UNAVAILABLE;
- (id)mutableCopy NS_UNAVAILABLE;

+ (instancetype)defaultAgregator;

@end

