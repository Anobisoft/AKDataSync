//
//  AKCloudTransaction.m
//  AKDataSync
//
//  Created by Stanislav Pletnev on 26.01.17.
//  Copyright © 2017 Anobisoft. All rights reserved.
//

#import "AKCloudTransaction.h"
#import "AKCloudRecordRepresentation.h"
#import "CKRecord+AKDataSync.h"

@implementation AKCloudTransaction {
    NSSet <NSObject<AKMappedObject> *> *_updatedObjects;
    NSSet <NSObject<AKDescription> *> *_deletedDescriptions;
}

+ (instancetype)transactionWithUpdatedRecords:(NSSet <CKRecord<AKMappedObject> *> *)updatedRecords deletionInfoRecords:(NSSet <CKRecord *> *)deletionInfoRecords mapping:(AKCloudMapping *)mapping {
    return [[self alloc] initWithUpdatedRecords:updatedRecords deletionInfoRecords:deletionInfoRecords mapping:mapping];
}

- (instancetype)initWithUpdatedRecords:(NSSet <CKRecord<AKMappedObject> *> *)updatedRecords deletionInfoRecords:(NSSet <CKRecord *> *)deletionInfoRecords mapping:(AKCloudMapping *)mapping {
    if (self = [super init]) {
        NSMutableSet *tmpSet;
        if (updatedRecords.count) {
            tmpSet = [NSMutableSet new];
            for (CKRecord<AKMappedObject> *record in updatedRecords) {
                [tmpSet addObject:[record mappedObjectWithMapping:mapping]];
            }
            _updatedObjects = tmpSet.copy;
        } else _updatedObjects = nil;
        if (deletionInfoRecords.count) {
            tmpSet = [NSMutableSet new];
            for (CKRecord *record in deletionInfoRecords) {
                [tmpSet addObject:[record descriptionOfDeletedObjectWithMapping:mapping]];
            }
            _deletedDescriptions = tmpSet.copy;
        } else _deletedDescriptions = nil;

    }
    return self;
}

- (NSSet <id <AKMappedObject>> *)updatedObjects {
    return _updatedObjects;
}

- (NSSet <id <AKDescription>> *)deletedObjects {
    return _deletedDescriptions;
}

- (NSString *)contextIdentifier {
    return nil;
}


@end
