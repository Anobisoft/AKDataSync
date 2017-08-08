//
//  CKRecord+AKDataSync.m
//  AKDataSync
//
//  Created by Stanislav Pletnev on 02.02.17.
//  Copyright © 2017 Anobisoft. All rights reserved.
//

#import "CKRecord+AKDataSync.h"
#import "AKCloudRecordRepresentation.h"
#import "NSUUID+AnobiKit.h"
#import "CKRecordID+AKDataSync.h"
#import "CKReference+AKDataSync.h"
#import "AKCloudInternalConst.h"

@implementation CKRecord (AKDataSync)

+ (instancetype)recordWithRecordType:(NSString *)recordType recordID:(CKRecordID *)recordID {
    return [[self alloc] initWithRecordType:recordType recordID:recordID];
}

+ (instancetype)recordWithRecordType:(NSString *)recordType {
    return [[self alloc] initWithRecordType:recordType];
}

- (id <AKDescription>)descriptionOfDeletedObjectWithMapping:(AKCloudMapping *)mapping {
    return [AKCloudDescriptionRepresentation instantiateWithRecordType:self[AKCloudDeletionInfoRecordProperty_recordType] uniqueData:[NSUUID UUIDWithUUIDString:self[AKCloudDeletionInfoRecordProperty_recordID]].data mapping:mapping];
}

- (id <AKMappedObject>)mappedObjectWithMapping:(AKCloudMapping *)mapping {
    return [AKCloudRecordRepresentation instantiateWithCloudRecord:(CKRecord<AKMappedObject> *)self mapping:mapping];
}

#pragma mark - getters

- (NSData *)uniqueData {
    return self.recordID.UUID.data;
}

- (NSString *)UUIDString {
    return self.recordID.recordName;
}

- (NSDate *)modificationDate {
    return self[AKCloudRealModificationDateProperty];
}

- (NSString *)entityName {
    @throw [NSException exceptionWithName:NSObjectInaccessibleException reason:[NSString stringWithFormat:@"[NOTICE] -[CKRecord entityName] unavailable. recordType %@ UUID %@", self.recordType, self.UUIDString] userInfo:nil];
    return nil;
}

- (NSDictionary<NSString *, NSObject <NSCoding> *> *)keyedDataProperties {
    NSMutableDictionary *tmp = [NSMutableDictionary new];
    for (NSString *key in self.allKeys) {
        [tmp setObject:self[key] forKey:key];
    }
    return tmp.copy;
}

#pragma mark - setters

- (void)setModificationDate:(NSDate *)date {
    self[AKCloudRealModificationDateProperty] = date;
}

- (void)setKeyedDataProperties:(NSDictionary <NSString *, NSObject <NSCoding> *> *)keyedDataProperties {
    for (NSString *key in keyedDataProperties.allKeys) {
        self[key] = [keyedDataProperties[key] isKindOfClass:[NSNull class]] ? nil : (__kindof id <CKRecordValue>)keyedDataProperties[key];
    }
}

- (void)replaceRelation:(NSString *)relationKey toReference:(id<AKReference>)reference {
    self[relationKey] = [CKReference referenceWithUniqueData:reference.uniqueData];
}

- (void)replaceRelation:(NSString *)relationKey toSetsOfReferences:(NSSet <id<AKReference>> *)setOfReferences {
    NSMutableArray *tmpArray = [NSMutableArray new];
    for (id<AKReference> reference in setOfReferences) {
        [tmpArray addObject:[CKReference referenceWithUniqueData:reference.uniqueData]];
    }
    self[relationKey] = tmpArray.count ? tmpArray.copy : nil;
}



@end
