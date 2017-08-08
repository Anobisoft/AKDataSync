//
//  CKReference+AKDataSync.m
//  AKDataSync
//
//  Created by Stanislav Pletnev on 02.02.17.
//  Copyright © 2017 Anobisoft. All rights reserved.
//

#import "CKReference+AKDataSync.h"
#import "CKRecordID+AKDataSync.h"

@implementation CKReference (AKDataSync)

- (NSData *)uniqueData {
    return self.recordID.uniqueData;
}

- (NSString *)UUIDString {
    return self.recordID.recordName;
}

+ (instancetype)referenceWithUniqueData:(NSData *)uniqueData {
    return uniqueData ? [[self alloc] initWithRecordID:[CKRecordID recordIDWithUniqueData:uniqueData] action:CKReferenceActionNone] : nil;
}

+ (instancetype)referenceWithUUIDString:(NSString *)UUIDString {
    return UUIDString ? [[self alloc] initWithRecordID:[CKRecordID recordIDWithUUIDString:UUIDString] action:CKReferenceActionNone] : nil;
}

@end
