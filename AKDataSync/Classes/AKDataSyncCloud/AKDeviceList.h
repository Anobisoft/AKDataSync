//
//  AKDeviceList.h
//  AKDataSync
//
//  Created by Stanislav Pletnev on 2016-12-21
//  Copyright © 2016 Anobisoft. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AnobiKit/AKTypes.h>
#import "AKDevice.h"

@class AKCloudConfig;

@interface AKDeviceList : NSObject <NSFastEnumeration, DisableNSInit>

- (AKDevice *)thisDevice;
- (void)addDevice:(AKDevice *)device;
- (NSArray<AKDevice *> *)devices;
+ (instancetype)listWithConfig:(AKCloudConfig *)config;

@end
