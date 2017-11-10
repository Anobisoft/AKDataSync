//
//  AKCloudManager.h
//  AKDataSyncCloud
//
//  Created by Stanislav Pletnev on 2016-12-21
//  Copyright © 2016 Anobisoft. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AKCloudMapping.h"
#import "AKDataSyncTypes.h"



NS_ASSUME_NONNULL_BEGIN

@interface AKCloudManager : NSObject <DisableNSInit>

@property (nonatomic, strong, readonly) NSString *instanceIdentifier;

//unique instance for identifier+databaseScope. AKDatabaseScopePrivate - default scope
+ (instancetype)instanceWithContainerIdentifier:(NSString *)identifier databaseScope:(AKDatabaseScope)databaseScope;
+ (instancetype)instanceWithConfig:(NSString *)configName;

@end

NS_ASSUME_NONNULL_END
