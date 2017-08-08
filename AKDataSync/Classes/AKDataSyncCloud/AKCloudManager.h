//
//  AKCloudManager.h
//  AKDataSyncCloud
//
//  Created by Stanislav Pletnev on 2016-12-21
//  Copyright © 2016 Anobisoft. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AKCloudMapping.h"
#import "AKPublicProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface AKCloudManager : NSObject

@property (nonatomic, strong, readonly) NSString *instanceIdentifier;

+ (instancetype)instanceWithContainerIdentifier:(NSString *)identifier databaseScope:(AKDatabaseScope)databaseScope; //unique for identifier+databaseScope. AKDatabaseScopePrivate - default scope
- (void)totalReplication;
- (void)smartReplication;


+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;


@end

NS_ASSUME_NONNULL_END
