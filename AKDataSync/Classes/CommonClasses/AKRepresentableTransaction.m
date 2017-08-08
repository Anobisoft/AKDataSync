//
//  AKRepresentableTransaction.m
//  AKDataSync
//
//  Created by Stanislav Pletnev on 09.02.17.
//  Copyright © 2017 Anobisoft. All rights reserved.
//

#import "AKRepresentableTransaction.h"

@implementation AKRepresentableTransaction {
    NSString *_contextIdentifier;
    NSSet <NSObject <AKMappedObject> *> *_updatedObjects;
    NSSet <NSObject <AKDescription> *> *_deletedObjects;
}

- (NSString *)contextIdentifier {
    return _contextIdentifier;
}

- (NSSet <NSObject <AKMappedObject> *> *)updatedObjects {
    return _updatedObjects;
}

- (NSSet <NSObject <AKDescription> *> *)deletedObjects {
    return _deletedObjects;
}

+ (instancetype)instantiateWithContext:(id <AKRepresentableTransaction>)context {
    return [[self alloc] initWithContext:context];
}

- (instancetype)initWithContext:(id <AKRepresentableTransaction>)context {
    if (self = [super init]) {
        _contextIdentifier = context.contextIdentifier;
        _updatedObjects = context.updatedObjects.copy;
        _deletedObjects = context.deletedObjects.copy;
    }
    return self;
}

- (void)addObjects:(NSSet<NSObject<AKMappedObject> *> *)objects {
    if (!_updatedObjects) _updatedObjects = [NSSet set];
    _updatedObjects = [_updatedObjects setByAddingObjectsFromSet:objects];
}

@end
