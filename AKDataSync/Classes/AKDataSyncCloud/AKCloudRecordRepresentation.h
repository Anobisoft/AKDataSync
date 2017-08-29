//
//  AKCloudRecordRepresentation.h
//  AKDataSync
//
//  Created by Stanislav Pletnev on 02.02.17.
//  Copyright © 2017 Anobisoft. All rights reserved.
//

#import "AKCloudDescriptionRepresentation.h"

@class CKRecord, AKCloudMapping, AKCloudConfig;

@interface AKCloudRecordRepresentation : AKCloudDescriptionRepresentation <AKMappedObject, AKRelatableToOne, AKRelatableToMany>

+ (instancetype)instantiateWithCloudRecord:(CKRecord<AKMappedObject> *)cloudRecord mapping:(AKCloudMapping *)mapping config:(AKCloudConfig *)config;

@end
