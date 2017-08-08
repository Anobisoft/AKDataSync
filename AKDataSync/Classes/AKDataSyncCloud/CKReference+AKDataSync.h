//
//  CKReference+AKDataSync.h
//  AKDataSync
//
//  Created by Stanislav Pletnev on 02.02.17.
//  Copyright © 2017 Anobisoft. All rights reserved.
//

#import <CloudKit/CloudKit.h>

@interface CKReference (AKDataSync)

+ (instancetype)referenceWithUniqueData:(NSData *)uniqueData;
+ (instancetype)referenceWithUUIDString:(NSString *)UUIDString;

@end
