//
//  AKObjectRepresentation.m
//  AKDataSync
//
//  Created by Stanislav Pletnev on 11.06.16.
//  Copyright © 2016 Anobisoft.com. All rights reserved.
//

#define AKDataSync_modificationDateKey @"AKDataSync_modificationDate"
#define AKDataSync_keyedDataPropertiesKey @"AKDataSync_keyedDataProperties"

#import "AKObjectRepresentation.h"

@interface AKDescriptionRepresentation(protected)

- (instancetype)initWithDescription:(id <AKDescription>)description;

@end

@implementation AKObjectRepresentation

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    [aCoder encodeObject:_modificationDate forKey:AKDataSync_modificationDateKey];
    [aCoder encodeObject:_keyedDataProperties forKey:AKDataSync_keyedDataPropertiesKey];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        _modificationDate = [aDecoder decodeObjectForKey:AKDataSync_modificationDateKey];
        _keyedDataProperties = [aDecoder decodeObjectForKey:AKDataSync_keyedDataPropertiesKey];
    }
    return self;
}

+ (instancetype)instantiateWithMappedObject:(NSObject<AKMappedObject> *)object {
    return [[self alloc] initWithMappedObject:object];
}

- (instancetype)initWithMappedObject:(NSObject<AKMappedObject> *)object {
    if (self = [super initWithDescription:object]) {
        _modificationDate = object.modificationDate;
        NSMutableDictionary *mutableProperties = object.keyedDataProperties.mutableCopy;
        for (NSString *key in object.keyedDataProperties.allKeys)
            if ([object.keyedDataProperties[key] isKindOfClass:[NSNull class]]) [mutableProperties removeObjectForKey:key];
        _keyedDataProperties = mutableProperties.copy;
    }
    return self;
}

@end
