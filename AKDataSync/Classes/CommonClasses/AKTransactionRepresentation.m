//
//  AKTransactionRepresentation.m
//  AKDataSync
//
//  Created by Stanislav Pletnev on 11.06.16.
//  Copyright © 2016 Anobisoft. All rights reserved.
//

#define AKDataSync_contextIdentifierKey @"AKDataSync_contextIdentifier"
#define AKDataSync_updatedObjectsKey @"AKDataSync_updatedObjects"
#define AKDataSync_deletedObjectsKey @"AKDataSync_deletedObjects"

#import "AKTransactionRepresentation.h"
#import "AKPrivateProtocol.h"

@interface AKTransactionRepresentation()

@property (nonatomic, strong, readonly) NSSet <NSObject<AKMappedObject> *> *updatedObjects;
@property (nonatomic, strong, readonly) NSSet <NSObject<AKDescription> *> *deletedObjects;
@property (nonatomic, strong, readonly) NSString *contextIdentifier;

@end

@implementation AKTransactionRepresentation

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:_contextIdentifier forKey:AKDataSync_contextIdentifierKey];
    [aCoder encodeObject:_updatedObjects forKey:AKDataSync_updatedObjectsKey];
    [aCoder encodeObject:_deletedObjects forKey:AKDataSync_deletedObjectsKey];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        _contextIdentifier = [aDecoder decodeObjectForKey:AKDataSync_contextIdentifierKey];
        _updatedObjects = [aDecoder decodeObjectForKey:AKDataSync_updatedObjectsKey];
        _deletedObjects = [aDecoder decodeObjectForKey:AKDataSync_deletedObjectsKey];
    }
    return self;
}

- (instancetype)init {
    if (self = [super init]) {
        _contextIdentifier = [NSUUID UUID].UUIDString;
    }
    return self;
}

+ (instancetype)instantiateWithRepresentableTransaction:(id<AKRepresentableTransaction>)transaction {
    return [[self alloc] initWithRepresentableTransaction:transaction];
}

- (instancetype)initWithRepresentableTransaction:(id<AKRepresentableTransaction>)transaction {
    if (self = [super init]) {
        _contextIdentifier = transaction.contextIdentifier;
        NSSet <NSObject<AKMappedObject> *> *updatedObjects = transaction.updatedObjects;
        if (updatedObjects.count) {
            NSMutableSet <AKRelatableObjectRepresentation *> *tmpUSet = [NSMutableSet new];
            for (NSObject<AKMappedObject> *updatedObject in updatedObjects) {
                [tmpUSet addObject:[AKRelatableObjectRepresentation instantiateWithMappedObject:updatedObject]];
            }
            _updatedObjects = tmpUSet.copy;
        } else {
            _updatedObjects = nil;
        }
        
        NSSet <NSObject<AKDescription> *> *deletedObjects = transaction.deletedObjects;
        if (deletedObjects.count) {
            NSMutableSet <AKDescriptionRepresentation *> *tmpSet = [NSMutableSet new];
            for (NSObject<AKDescription> *description in deletedObjects) {
                [tmpSet addObject:[AKDescriptionRepresentation instantiateWithDescription:description]];
            }
            _deletedObjects = tmpSet.copy;
        } else {
            _deletedObjects = nil;
        }
    }
    return (_deletedObjects || _updatedObjects) ? self : nil;
}

- (void)mergeWithRepresentableTransaction:(id<AKRepresentableTransaction>)transaction {
    if ([self.contextIdentifier isEqualToString:transaction.contextIdentifier]) {
        NSSet <NSObject<AKMappedObject> *> *updatedObjects = transaction.updatedObjects;
        if (updatedObjects.count) {
            NSMutableSet <AKRelatableObjectRepresentation *> *tmpUSet = _updatedObjects.mutableCopy;
            for (NSObject<AKMappedObject> *updatedObject in updatedObjects) {
                AKRelatableObjectRepresentation *existedRepresentation = nil;
                for (AKRelatableObjectRepresentation *enumerObj in tmpUSet)
                    if ([updatedObject.uniqueData isEqualToData:enumerObj.uniqueData]) existedRepresentation = enumerObj;
                if (existedRepresentation) [tmpUSet removeObject:existedRepresentation];
                [tmpUSet addObject:[AKRelatableObjectRepresentation instantiateWithMappedObject:updatedObject]];
            }
            _updatedObjects = tmpUSet.copy;
        }
        
        NSSet <NSObject<AKDescription> *> *deletedObjects = transaction.deletedObjects;
        if (deletedObjects.count) {
            NSMutableSet <AKDescriptionRepresentation *> *tmpSet = _deletedObjects.mutableCopy;
            for (NSObject<AKDescription> *description in deletedObjects) {
                AKDescriptionRepresentation *existedRepresentation = nil;
                for (AKDescriptionRepresentation *enumerObj in tmpSet)
                    if ([description.uniqueData isEqualToData:enumerObj.uniqueData]) existedRepresentation = enumerObj;
                if (existedRepresentation) [tmpSet removeObject:existedRepresentation];
                [tmpSet addObject:[AKDescriptionRepresentation instantiateWithDescription:description]];
            }
            _deletedObjects = tmpSet.copy;
        }
    } else {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"invalid contextIdentifier" userInfo:nil];
    }
}

@end
