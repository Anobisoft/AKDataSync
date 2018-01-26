//
//  AKPreparedToCloudRecords.m
//  AKDataSync
//
//  Created by Stanislav Pletnev on 09.02.17.
//  Copyright © 2017 Anobisoft. All rights reserved.
//

#import "AKPreparedToCloudRecords.h"
#import <CloudKit/CloudKit.h>
#import "AKObjectRepresentation.h"
#import "CKRecord+AKDataSync.h"

@implementation NSMutableArray(removeReference)

- (void)removeReference:(NSObject<AKReference> *)reference {
    NSUInteger foundReferenceIndex;
    NSMutableArray<NSObject<AKReference> *> *references = (NSMutableArray<NSObject<AKReference> *> *)self;
    for (foundReferenceIndex = 0; foundReferenceIndex < references.count; foundReferenceIndex++) {
        if ([references[foundReferenceIndex].uniqueData isEqualToData:reference.uniqueData]) break;
    }
    if (foundReferenceIndex != references.count) [self removeObjectAtIndex:foundReferenceIndex];
}

@end

@implementation AKPreparedToCloudRecords {
    NSMutableArray <CKRecord<AKReference> *> *mutableRecordsToSave;
    NSMutableArray <CKRecordID<AKReference> *> *mutableRecordIDsToDelete;
    NSMutableArray <AKObjectRepresentation *> *failedObjectsRepresentations;
}

+ (BOOL)supportsSecureCoding {
    return true;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
//#ifdef DEBUG
//    NSLog(@"[DEBUG] %s", __PRETTY_FUNCTION__);
//#endif
    if (self = [super init]) {
        mutableRecordsToSave = [aDecoder decodeObjectForKey:@"mutableRecordsToSave"];
        mutableRecordIDsToDelete = [aDecoder decodeObjectForKey:@"mutableRecordIDsToDelete"];
        failedObjectsRepresentations = [aDecoder decodeObjectForKey:@"failedObjectsRepresentations"];
        self.accumulativeTransaction = [aDecoder decodeObjectForKey:@"accumulativeTransaction"];
        _lockGroup = dispatch_group_create();
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:mutableRecordsToSave forKey:@"mutableRecordsToSave"];
    [aCoder encodeObject:mutableRecordIDsToDelete forKey:@"mutableRecordIDsToDelete"];
    [aCoder encodeObject:failedObjectsRepresentations forKey:@"failedObjectsRepresentations"];
    [aCoder encodeObject:self.accumulativeTransaction forKey:@"accumulativeTransaction"];
}

- (instancetype)init {
//#ifdef DEBUG
//    NSLog(@"[DEBUG] %s", __PRETTY_FUNCTION__);
//#endif
    if (self = [super init]) {
        mutableRecordsToSave = [NSMutableArray new];
        mutableRecordIDsToDelete = [NSMutableArray new];
        failedObjectsRepresentations = [NSMutableArray new];
        _lockGroup = dispatch_group_create();
    }
    return self;
}


@synthesize failedEnqueueUpdateObjects = _failedEnqueueUpdateObjects;
- (NSArray<id<AKMappedObject>> *)failedEnqueueUpdateObjectsRepresentations {
    if (!_failedEnqueueUpdateObjects) _failedEnqueueUpdateObjects = failedObjectsRepresentations.copy;
    return _failedEnqueueUpdateObjects;
}
- (void)addFailedEnqueueUpdateObject:(NSObject<AKMappedObject> *)object {
    _failedEnqueueUpdateObjects = nil;
    AKObjectRepresentation *representedObject = [AKObjectRepresentation instantiateWithMappedObject:object];
    [failedObjectsRepresentations removeReference:representedObject];
    [failedObjectsRepresentations addObject:representedObject];
    #ifdef DEBUG
        NSLog(@"[DEBUG] %s count %ld", __PRETTY_FUNCTION__, (long)failedObjectsRepresentations.count);
    #endif
}


@synthesize recordsToSave = _recordsToSave;
- (NSArray<CKRecord *> *)recordsToSave {
    if (!_recordsToSave) _recordsToSave = mutableRecordsToSave.copy;
    return _recordsToSave;
}
- (void)addRecordToSave:(CKRecord<AKReference> *)record {
    _recordsToSave = nil;
    [mutableRecordsToSave removeReference:record];
    [mutableRecordsToSave addObject:record];
//#ifdef DEBUG
//    NSLog(@"[DEBUG] mutableRecordsToSave.count %ld", (unsigned long)mutableRecordsToSave.count);
//#endif
    _failedEnqueueUpdateObjects = nil;
    [failedObjectsRepresentations removeReference:record];
}


@synthesize recordIDsToDelete = _recordIDsToDelete;
- (NSArray<CKRecordID *> *)recordIDsToDelete {
    if (!_recordIDsToDelete) _recordIDsToDelete = mutableRecordIDsToDelete.copy;
    return _recordIDsToDelete;
}
- (void)addRecordIDToDelete:(CKRecordID<AKReference> *)recordID {
    _recordIDsToDelete = nil;
    [mutableRecordIDsToDelete removeReference:recordID];
    [mutableRecordIDsToDelete addObject:recordID];
//#ifdef DEBUG
//    NSLog(@"[DEBUG] mutableRecordIDsToDelete.count %ld", (unsigned long)mutableRecordIDsToDelete.count);
//#endif
}

- (BOOL)isEmpty {
    return (mutableRecordsToSave.count + mutableRecordIDsToDelete.count + failedObjectsRepresentations.count) == 0;
}

- (void)clearAll {
//#ifdef DEBUG
//    NSLog(@"[DEBUG] %s", __PRETTY_FUNCTION__);
//#endif
    _recordsToSave = @[];
    [mutableRecordsToSave removeAllObjects];
    _recordIDsToDelete = @[];
    [mutableRecordIDsToDelete removeAllObjects];
}

- (void)clearWithSavedRecords:(NSArray<CKRecord<AKReference> *> *)savedRecords deletedRecordIDs:(NSArray<CKRecordID<AKReference> *> *)deletedRecordIDs {
//#ifdef DEBUG
//    NSLog(@"[DEBUG] %s", __PRETTY_FUNCTION__);
//#endif
    _recordsToSave = nil; _recordIDsToDelete = nil;
    for (CKRecord<AKReference> *record in savedRecords) [mutableRecordsToSave removeReference:record];
    for (CKRecordID<AKReference> *recordID in deletedRecordIDs) [mutableRecordIDsToDelete removeReference:recordID];
//#ifdef DEBUG
//    NSLog(@"[DEBUG] mutableRecordsToSave.count %ld mutableRecordIDsToDelete.count %ld", (unsigned long)mutableRecordsToSave.count, (unsigned long)mutableRecordIDsToDelete.count);
//#endif
}



@end
