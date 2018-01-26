//
//  AKDescriptionRepresentation.m
//  AKDataSync
//
//  Created by Stanislav Pletnev on 11.06.16.
//  Copyright © 2016 Anobisoft. All rights reserved.
//

#import "AKDescriptionRepresentation.h"

#define AKDataSync_entityNameKey @"AKDataSync_entityName"

@interface AKReference(protected)

- (instancetype)initWithReference:(id<AKReference>)reference;

@end

@implementation AKDescriptionRepresentation

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    [aCoder encodeObject:_entityName forKey:AKDataSync_entityNameKey];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        _entityName = [aDecoder decodeObjectForKey:AKDataSync_entityNameKey];
    }
    return self;
}

+ (instancetype)instantiateWithDescription:(NSObject<AKDescription> *)description {
    return [[self alloc] initWithDescription:description];
}

- (instancetype)initWithDescription:(NSObject<AKDescription> *)description {
    if (self = [super initWithReference:description]) {
        @try {
            _entityName = description.entityName;
        } @catch (NSException *exception) {
            NSLog(@"%@", exception);
        }
    }
    return self;
}

@end
