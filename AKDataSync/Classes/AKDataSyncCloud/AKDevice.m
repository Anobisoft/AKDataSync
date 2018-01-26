//
//  AKDevice.m
//  AKDataSync
//
//  Created by Stanislav Pletnev on 2016-12-21
//  Copyright © 2016 Anobisoft. All rights reserved.
//

#import "AKDevice.h"

@interface AKObjectRepresentation(protected)

- (instancetype)initWithMappedObject:(id<AKMappedObject>)object;

@end

@implementation AKDevice {
    __weak AKCloudConfig *_config;
}

+ (instancetype)deviceWithMappedObject:(id<AKMappedObject>)mappedObject config:(AKCloudConfig *)config {
    return [[self alloc] initWithMappedObject:mappedObject config:config];
}

- (instancetype)initWithMappedObject:(id<AKMappedObject>)mappedObject config:(AKCloudConfig *)config {
    if (self = [super initWithMappedObject:mappedObject]) {
        _config = config;
    }
    return self;
}

- (void)setUUID:(AKUUID *)UUID {
    _uniqueData = UUID.data;
}

- (void)setUUIDString:(NSString *)UUIDString {
    _uniqueData = [AKUUID UUIDWithUUIDString:UUIDString].data;
}

- (void)setUniqueData:(NSData *)uniqueData {
    _uniqueData = uniqueData;
}

- (void)setModificationDate:(NSDate *)modificationDate {
    _modificationDate = modificationDate;
}

- (void)setKeyedDataProperties:(NSDictionary<NSString *,NSObject<NSCoding> *> *)keyedDataProperties {
    _keyedDataProperties = keyedDataProperties;
}

- (NSString *)entityName {
    return _config.deviceRecordType;
}

@end
