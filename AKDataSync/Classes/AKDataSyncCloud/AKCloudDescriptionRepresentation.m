//
//  AKCloudDescriptionRepresentation.m
//  AKDataSync
//
//  Created by Stanislav Pletnev on 02.02.17.
//  Copyright © 2017 Anobisoft. All rights reserved.
//

#import "AKCloudDescriptionRepresentation.h"
#import "NSUUID+AnobiKit.h"
#import "AKCloudMapping.h"

@implementation AKCloudDescriptionRepresentation {
    NSString *_entityName, *_uuidString;
    NSData *_uniqueData;
}

- (NSString *)entityName {
    return _entityName;
}

- (NSData *)uniqueData {
    return _uniqueData;
}

- (NSString *)UUIDString {
    if (!_uuidString) _uuidString = _uniqueData.UUIDString;
    return _uuidString;
}

+ (instancetype)instantiateWithRecordType:(NSString *)recordType uniqueData:(NSData *)uniqueData mapping:(AKCloudMapping *)mapping {
    return [[self alloc] initWithRecordType:recordType uniqueData:uniqueData mapping:mapping];
}

- (instancetype)initWithRecordType:(NSString *)recordType uniqueData:(NSData *)uniqueData mapping:(AKCloudMapping *)mapping {
    if (self = [super init]) {
        _entityName = mapping.reverseMap[recordType];
        _uniqueData = uniqueData;
    }
    return self;
}



@end
