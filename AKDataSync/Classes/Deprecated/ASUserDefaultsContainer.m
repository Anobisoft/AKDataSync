//
//  ASUserDefaultsContainer.m
//  AKDataSync
//
//  Created by Stanislav Pletnev on 11.06.16.
//  Copyright © 2016 Anobisoft.com. All rights reserved.
//

#import "ASUserDefaultsContainer.h"

#define defaultIdentifier @"Default"

@interface ASUserDefaultsContainer()
@property (nonatomic, weak) id<AKDataSyncAgregator> agregator;
@end

@implementation ASUserDefaultsContainer {
    NSMutableArray <AKSerializableObject *> *contentMutableContainer;
    NSMutableSet <AKSerializableObject *> *updatedMutableObjects;
    NSMutableSet <AKSerializableObject *> *deletedMutableObjects;
}

@synthesize content = _content;
@synthesize identifier = _identifier;
@synthesize updatedObjects = _updatedObjects;
@synthesize deletedObjects = _deletedObjects;
@synthesize delegate = _delegate;

- (void)setAgregator:(id<AKDataSyncAgregator>)agregator {
    _agregator = agregator;
}

- (NSString *)identifier {
    return _identifier;
}

- (void)setIdentifier:(NSString *)identifier {
    _identifier = [NSString stringWithFormat:@"%@_%@", NSStringFromClass(self.class), identifier];
}

- (id)copy {
    return self;
}

- (id)mutableCopy {
    return self;
}

- (id)init {
    return self;
}

+ (instancetype)alloc {
    return [self defaultConteiner];
}

+ (instancetype)new {
    return [self defaultConteiner];
}

+ (instancetype)defaultConteiner {
    static dispatch_once_t pred;
    static id shared = nil;
    dispatch_once(&pred, ^{
        shared = [[super alloc] initDefaultConteiner];
    });
    return shared;
}

- (instancetype)initDefaultConteiner {
    if (self = [super init]) {
        self.identifier = defaultIdentifier;
        [self loadDataFromStdUD];
        updatedMutableObjects = [NSMutableSet new];
        deletedMutableObjects = [NSMutableSet new];
    }
    return self;
}

- (instancetype)initWithIdentifier:(NSString *)identifier {
    if (self = [super init]) {
        self.identifier = identifier;
        [self loadDataFromStdUD];
    }
    return self;
}

+ (instancetype)instantiateWithIdentifier:(NSString *)identifier {
    return [[self alloc] initWithIdentifier:identifier];
}

- (AKSerializableObject *)insertTo:(NSString *)entityName {
    AKSerializableObject *object = [AKSerializableObject new];
    object.delegate = self;
    NSUUID *uuid = [NSUUID UUID];
    object.uniqueID = [NSKeyedArchiver archivedDataWithRootObject:uuid];
    object.entityName = entityName;
//#warning wait, lock container
    [contentMutableContainer addObject:object];
    _content = contentMutableContainer.copy;
    return object;
}


- (void)updateObject:(AKSerializableObject *)object {
    [updatedMutableObjects addObject:object];
    _updatedObjects = updatedMutableObjects.copy;
}

- (void)deleteObject:(AKSerializableObject *)object {
    if ([updatedMutableObjects containsObject:object]) {
        [updatedMutableObjects removeObject:object];
    }
    [deletedMutableObjects addObject:object];
    [contentMutableContainer removeObject:object];
    _content = contentMutableContainer.copy;
}

- (void)loadDataFromStdUD {
    NSData *tmpData = [[NSUserDefaults standardUserDefaults] objectForKey:self.identifier];
    if (tmpData) contentMutableContainer = [NSKeyedUnarchiver unarchiveObjectWithData:tmpData];
    else contentMutableContainer = [NSMutableArray new];
    _content = contentMutableContainer.copy;
}

- (void)commit {
    if (self.agregator) {
        [self.agregator willCommitContext:self];
    }
    [self saveDataToStdUD];
    [updatedMutableObjects removeAllObjects];
    [deletedMutableObjects removeAllObjects];
}

- (void)saveDataToStdUD {
    [[NSUserDefaults standardUserDefaults] setObject:[NSKeyedArchiver archivedDataWithRootObject:contentMutableContainer] forKey:self.identifier];
}



+ (int)objectIndexByUniqueID:(NSData *)uniqueID inArray:(NSArray <AKSerializableObject *> *)array {
    for (int i = 0; i < array.count; i++) {
        if ([array[i].uniqueID isEqual:uniqueID]) return i;
    }
    return -1;
}

+ (AKSerializableObject *)objectByUniqueID:(NSData *)uniqueID inSet:(NSSet <AKSerializableObject *> *)set {
    for (AKSerializableObject *obj in set) {
        if ([obj.uniqueID isEqual:uniqueID]) return obj;
    }
    return nil;
}



- (void)mergeWithRecievedContext:(AKSerializableContext *)recievedContext {
//#warning wait, lock container
    NSMutableArray <AKSerializableObject *> *commitedDB;
    NSData *tmpData = [[NSUserDefaults standardUserDefaults] objectForKey:self.identifier];
    if (tmpData) commitedDB = [NSKeyedUnarchiver unarchiveObjectWithData:tmpData];
    else commitedDB = [NSMutableArray new];
    
    for (AKSerializableObject *recievedObj in recievedContext.updatedObjects) {
        int commitedObjIndx = [self.class objectIndexByUniqueID:recievedObj.uniqueID inArray:commitedDB];
        AKSerializableObject *commitedObj = commitedObjIndx == -1 ? nil : commitedDB[commitedObjIndx];
        AKSerializableObject *contextObj = [self.class objectByUniqueID:recievedObj.uniqueID inSet:updatedMutableObjects];
        if (commitedObj) {
            if ([recievedObj.modifyDate compare:commitedObj.modifyDate] != NSOrderedAscending) {
                [commitedDB replaceObjectAtIndex:commitedObjIndx withObject:recievedObj];
            }
            if (contextObj) {
                if ([recievedObj.modifyDate compare:contextObj.modifyDate] != NSOrderedAscending) {
                    [updatedMutableObjects removeObject:contextObj];
                    [updatedMutableObjects addObject:recievedObj];
                }
            } else {
                
            }
        } else {
            [commitedDB addObject:recievedObj];
            if (contextObj) {
                NSLog(@"OMG! WTF?! updatedObj.uniqueID: %@\nexist in currentContext, recievedContext, but not exist in commitedDB", contextObj.UUIDString);
            }
        }
    }
    
    for (AKSerializableObject *recievedObj in recievedContext.deletedObjects) {
        int commitedObjIndx = [self.class objectIndexByUniqueID:recievedObj.uniqueID inArray:commitedDB];
        AKSerializableObject *commitedObj = commitedObjIndx == -1 ? nil : commitedDB[commitedObjIndx];
        AKSerializableObject *updatedObj = [self.class objectByUniqueID:recievedObj.uniqueID inSet:updatedMutableObjects];
        AKSerializableObject *deletedObj = [self.class objectByUniqueID:recievedObj.uniqueID inSet:deletedMutableObjects];
        if (commitedObj) [commitedDB removeObject:commitedObj];
        if (updatedObj) [updatedMutableObjects removeObject:updatedObj];
        if (deletedObj) [deletedMutableObjects removeObject:deletedObj];
    }
    
    contentMutableContainer = commitedDB;
    [self saveDataToStdUD];
    
    for (AKSerializableObject *updatedObj in updatedMutableObjects) {
        int commitedObjIndx = [self.class objectIndexByUniqueID:updatedObj.uniqueID inArray:commitedDB];
        if (commitedObjIndx == -1) {
            [contentMutableContainer addObject:updatedObj];
        }
        
    }
    
    _content = contentMutableContainer.copy;
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(reloadData)]) {
        [self.delegate reloadData];
    }
    
}

- (void)rollback {
    [self loadDataFromStdUD];
    [updatedMutableObjects removeAllObjects];
    [deletedMutableObjects removeAllObjects];
}





@end
