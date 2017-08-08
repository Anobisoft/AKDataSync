//
//  AKCloudTransaction.h
//  AKDataSync
//
//  Created by Stanislav Pletnev on 26.01.17.
//  Copyright © 2017 Anobisoft. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AKPrivateProtocol.h"

@class CKRecord;

@interface AKCloudTransaction : NSObject <AKRepresentableTransaction>

+ (instancetype)transactionWithUpdatedRecords:(NSSet <CKRecord<AKMappedObject> *> *)updatedRecords deletionInfoRecords:(NSSet <CKRecord *> *)deletionInfoRecords mapping:(AKCloudMapping *)mapping;

@end
