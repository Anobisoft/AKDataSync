//
//  AKDevice.m
//  AKDataSync
//
//  Created by Stanislav Pletnev on 2016-12-21
//  Copyright © 2016 Anobisoft. All rights reserved.
//

#import "AKDevice.h"
#import "NSUUID+AnobiKit.h"

@interface AKObjectRepresentation(protected)

- (instancetype)initWithMappedObject:(id <AKMappedObject>)object;

@end

@implementation AKDevice

+ (instancetype)deviceWithMappedObject:(id <AKMappedObject>)mappedObject {
    return [[self alloc] initWithMappedObject:mappedObject];
}

- (instancetype)initWithMappedObject:(id <AKMappedObject>)mappedObject {
    if (self = [super initWithMappedObject:mappedObject]) {
        
    }
    return self;
}

- (void)setUUID:(NSUUID *)UUID {
    _uniqueData = UUID.data;
}

- (void)setUUIDString:(NSString *)UUIDString {
    _uniqueData = [NSUUID UUIDWithUUIDString:UUIDString].data;
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
    return [self.class entityName];
}

@end
