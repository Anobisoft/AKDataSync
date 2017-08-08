//
//  AKDeviceList.h
//  AKDataSync
//
//  Created by Stanislav Pletnev on 2016-12-21
//  Copyright © 2016 Anobisoft. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AKDevice.h"

@interface AKDeviceList : NSObject <NSFastEnumeration>

- (AKDevice *)thisDevice;
- (void)addDevice:(AKDevice *)device;
- (NSArray <AKDevice *> *)devices;


@end
