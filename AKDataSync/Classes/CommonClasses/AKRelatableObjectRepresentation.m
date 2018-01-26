//
//  AKRelatableObjectRepresentation.m
//  AKDataSync
//
//  Created by Stanislav Pletnev on 20.01.17.
//  Copyright © 2017 Anobisoft. All rights reserved.
//

#define AKDataSync_keyedReferences @"AKDataSync_keyedReferences"
#define AKDataSync_keyedSetsOfReferences @"AKDataSync_keyedSetsOfReferences"

#import "AKRelatableObjectRepresentation.h"

@interface AKObjectRepresentation(protected)

- (instancetype)initWithMappedObject:(id<AKMappedObject>)object;

@end

@implementation AKRelatableObjectRepresentation

+ (NSDictionary<NSString *,NSString *> *)entityNameByRelationKey {
    return nil;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    [aCoder encodeObject:self.keyedReferences forKey:AKDataSync_keyedReferences];
    [aCoder encodeObject:self.keyedSetsOfReferences forKey:AKDataSync_keyedSetsOfReferences];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        _keyedReferences = [aDecoder decodeObjectForKey:AKDataSync_keyedReferences];
        _keyedSetsOfReferences = [aDecoder decodeObjectForKey:AKDataSync_keyedSetsOfReferences];
    }
    return self;
}

- (instancetype)initWithMappedObject:(NSObject<AKMappedObject> *)object {
    if (self = [super initWithMappedObject:object]) {
        if ([object conformsToProtocol:@protocol(AKRelatableToOne)]) {
            NSObject<AKRelatableToOne> *relatableToOneObject = (NSObject<AKRelatableToOne> *)object;
            NSMutableDictionary <NSString *, AKReference *> *tmpDict = [NSMutableDictionary new];
            NSDictionary <NSString *, NSObject<AKReference> *> *keyedReferences = relatableToOneObject.keyedReferences;
            for (NSString *relationKey in keyedReferences.allKeys) {
                [tmpDict setObject:[AKReference instantiateWithReference:keyedReferences[relationKey]] forKey:relationKey];
            }
            _keyedReferences = tmpDict.copy;
        }
        if ([object conformsToProtocol:@protocol(AKRelatableToMany)]) {
            id<AKRelatableToMany> relatableToManyObject = (NSObject<AKRelatableToMany> *)object;
            NSMutableDictionary <NSString *, NSSet <AKReference *> *> *tmpDict = [NSMutableDictionary new];
            NSDictionary <NSString *, NSSet <NSObject<AKReference> *> *> *keyedSetsOfReferences = relatableToManyObject.keyedSetsOfReferences;
            for (NSString *relationKey in keyedSetsOfReferences.allKeys) {
                NSMutableSet <AKReference *> *innerSet = [NSMutableSet new];
                for (id<AKReference> reference in keyedSetsOfReferences[relationKey]) {
                    [innerSet addObject:[AKReference instantiateWithReference:reference]];
                }
                [tmpDict setObject:innerSet.copy forKey:relationKey];
            }
            _keyedSetsOfReferences = tmpDict.copy;
        }
    }
    return self;
}

+ (instancetype)instantiateWithMappedObject:(NSObject<AKMappedObject> *)object {
    return [[self alloc] initWithMappedObject:object];
}


@end
