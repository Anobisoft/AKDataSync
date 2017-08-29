//
//  AKCloudRecordRepresentation.m
//  AKDataSync
//
//  Created by Stanislav Pletnev on 02.02.17.
//  Copyright © 2017 Anobisoft. All rights reserved.
//

#import "AKCloudRecordRepresentation.h"
#import <CloudKit/CloudKit.h>
#import "CKRecord+AKDataSync.h"
#import "AKCloudConfig.h"

@interface AKCloudDescriptionRepresentation(protected)

- (instancetype)initWithRecordType:(NSString *)recordType uniqueData:(NSData *)uniqueData mapping:(AKCloudMapping *)mapping config:(AKCloudConfig *)config;

@end

@implementation AKCloudRecordRepresentation {
    NSDate *_modificationDate;
    NSDictionary <NSString *, NSObject <NSCoding> *> *_keyedDataProperties;
    NSDictionary <NSString *, id<AKReference>> *_keyedReferences;
    NSDictionary <NSString *, NSSet <id<AKReference>> *> *_keyedSetsOfReferences;
}

+ (NSDictionary<NSString *,NSString *> *)entityNameByRelationKey {
    return nil;
}

- (NSDate *)modificationDate {
    return _modificationDate;
}

- (NSDictionary <NSString *, NSObject <NSCoding> *> *)keyedDataProperties {
    return _keyedDataProperties;
}

- (NSDictionary <NSString *, id<AKReference>> *)keyedReferences {
    return _keyedReferences;
}

- (NSDictionary <NSString *, NSSet <id<AKReference>> *> *)keyedSetsOfReferences {
    return _keyedSetsOfReferences;
}

+ (instancetype)instantiateWithCloudRecord:(CKRecord<AKMappedObject> *)cloudRecord mapping:(AKCloudMapping *)mapping config:(AKCloudConfig *)config{
    return [[self alloc] initWithCloudRecord:cloudRecord mapping:mapping config:config];
}

- (instancetype)initWithCloudRecord:(CKRecord<AKMappedObject> *)cloudRecord mapping:(AKCloudMapping *)mapping config:(AKCloudConfig *)config{
    if (self = [super initWithRecordType:cloudRecord.recordType uniqueData:cloudRecord.uniqueData mapping:mapping config:config]) {
        _modificationDate = cloudRecord.modificationDate;
        NSMutableDictionary <NSString *, NSObject <NSCoding> *> *tmp_keyedDataProperties = [NSMutableDictionary new];
        NSMutableDictionary <NSString *, CKReference<AKReference> *> *tmp_keyedReferences = [NSMutableDictionary new];
        NSMutableDictionary <NSString *, NSSet <CKReference<AKReference> *> *> *tmp_keyedSetsOfReferences = [NSMutableDictionary new];
        for (NSString *key in cloudRecord.allKeys) {
            if ([cloudRecord[key] isKindOfClass:[CKReference class]]) {
                CKReference<AKReference> *reference = cloudRecord[key];
                [tmp_keyedReferences setObject:reference forKey:key];
                continue;
            }
            if ([cloudRecord[key] isKindOfClass:[NSArray class]] && [((NSArray *)cloudRecord[key]).firstObject isKindOfClass:[CKReference class]]) {
                NSMutableSet <CKReference<AKReference> *> *refList = [NSMutableSet new];
                for (CKReference<AKReference> *reference in (NSArray *)cloudRecord[key]) {
                    [refList addObject:reference];
                }
                [tmp_keyedSetsOfReferences setObject:refList.copy forKey:key];
            }
            if (![key isEqualToString:config.realModificationDateFieldName]) {
                [tmp_keyedDataProperties setObject:cloudRecord[key] forKey:key];
            }
        }
        _keyedDataProperties = tmp_keyedDataProperties.copy;
        _keyedReferences = tmp_keyedReferences.copy;
        _keyedSetsOfReferences = tmp_keyedSetsOfReferences.copy;
        
//        NSLog(@"[DEBUG] _keyedDataProperties %@", _keyedDataProperties);
//        NSLog(@"[DEBUG] _keyedReferences %@", _keyedReferences);
//        NSLog(@"[DEBUG] _keyedSetsOfReferences %@", _keyedSetsOfReferences);
    }
    return self;
}


@end
