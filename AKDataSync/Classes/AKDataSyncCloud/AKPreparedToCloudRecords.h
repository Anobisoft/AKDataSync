//
//  AKPreparedToCloudRecords.h
//  AKDataSync
//
//  Created by Stanislav Pletnev on 09.02.17.
//  Copyright © 2017 Anobisoft. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AKPublicProtocol.h"
#import "AKTransactionRepresentation.h"

@class CKRecord, CKRecordID;

@interface AKPreparedToCloudRecords : NSObject <NSSecureCoding>

@property (nonatomic, strong, readonly) NSArray<CKRecord *> *recordsToSave;
@property (nonatomic, strong, readonly) NSArray<CKRecordID *> *recordIDsToDelete;
@property (nonatomic, strong, readonly) NSArray<NSObject<AKMappedObject> *> *failedEnqueueUpdateObjects;
@property (nonatomic, strong) AKTransactionRepresentation *accumulativeTransaction;
@property (nonatomic, retain, readonly) dispatch_group_t lockGroup;

- (void)addRecordToSave:(CKRecord *)record;
- (void)addRecordIDToDelete:(CKRecordID *)recordID;
- (void)addFailedEnqueueUpdateObject:(NSObject<AKMappedObject> *)object;
- (BOOL)isEmpty;
- (void)clearAll;
- (void)clearWithSavedRecords:(NSArray<CKRecord *> *)savedRecords deletedRecordIDs:(NSArray<CKRecordID *> *)deletedRecordIDs;

@end
