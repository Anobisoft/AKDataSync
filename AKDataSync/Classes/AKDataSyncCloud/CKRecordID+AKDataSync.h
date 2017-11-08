//
//  CKRecordID+AKDataSync.h
//  AKDataSync
//
//  Created by Stanislav Pletnev on 02.02.17.
//  Copyright © 2017 Anobisoft. All rights reserved.
//

#import <CloudKit/CloudKit.h>
#import "AKUUID.h"

@interface CKRecordID (AKDataSync)

+ (instancetype)recordIDWithUniqueData:(NSData *)uniqueData;
+ (instancetype)recordIDWithUUIDString:(NSString *)UUIDString;

- (NSString *)UUIDString;
- (AKUUID *)UUID;
- (NSData *)uniqueData;

@end
