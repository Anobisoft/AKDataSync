//
//  AKManagedObjectContext.m
//  AKDataSync
//
//  Created by Stanislav Pletnev on 11.06.16.
//  Copyright © 2016 Anobisoft.com. All rights reserved.
//

#import "AKManagedObjectContext.h"
#import "AKRepresentableTransaction.h"
#import "AKDescriptionRepresentation.h"
#import "NSManagedObjectContext+AnobiKit.h"
#import "AKPrivateProtocol.h"
#import "NSUUID+AnobiKit.h"
#import "AKDataAgregator.h"

//#import <UIKit/UIKit.h>

#import <objc/runtime.h>

@implementation NSManagedObject(swentityName)

+ (NSString *)swentityName {
    NSString *atatentity;
    @try {
        atatentity = [self swentityName];
    } @catch (NSException *exception) {
        NSLog(@"[ERROR] %s %@", __PRETTY_FUNCTION__, exception);
    } @finally {
        if (atatentity) {
            return atatentity;
        } else {
            NSLog(@"[ERROR] %s return null. WTF?! swizzle return className: %@", __PRETTY_FUNCTION__, NSStringFromClass(self.class));
            return NSStringFromClass(self.class);
        }
    }
}

@end


@interface FoundObjectWithRelationRepresentation : NSObject

@property (nonatomic, strong) NSObject <AKRelatableToOne> *recievedRelationsToOne;
@property (nonatomic, strong) NSObject <AKRelatableToMany> *recievedRelationsToMany;
@property (nonatomic, strong) NSManagedObject <AKManagedObject> *managedObject;

@end

@implementation FoundObjectWithRelationRepresentation

@end
#if TARGET_OS_IOS
@interface AKManagedObjectContext() <AKDataSyncContextPrivate, AKCloudMappingProvider>


@end
#else
@interface AKManagedObjectContext() <AKDataSyncContextPrivate>

@end
#endif


@implementation AKManagedObjectContext {
    NSManagedObjectContext *mainContext;
    NSManagedObjectModel *managedObjectModel;
    NSPersistentStoreCoordinator *persistentStoreCoordinator;
    NSMutableArray <id <AKRepresentableTransaction>> *recievedTransactionsQueue;
    NSString *name;
    id<AKTransactionsAgregator> transactionsAgregator;
#if TARGET_OS_IOS
    AKCloudMapping *cloudMapping;
    id<AKCloudManager> ownedCloudManager;
#endif
}

+ (void)swixManagedObjectEntityNameMethod {
    Class class = [NSManagedObject class];
    
    SEL originalSelector = @selector(entityName);
    SEL swizzledSelector = @selector(swentityName);
    
    Method originalMethod = class_getClassMethod(class, originalSelector);
    Method swizzledMethod = class_getClassMethod(class, swizzledSelector);
    
    BOOL didAddMethod =
    class_addMethod(class,
                    originalSelector,
                    method_getImplementation(swizzledMethod),
                    method_getTypeEncoding(swizzledMethod));
    
    if (didAddMethod) {
        class_replaceMethod(class,
                            swizzledSelector,
                            method_getImplementation(originalMethod),
                            method_getTypeEncoding(originalMethod));
    } else {
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
}


@synthesize delegate = _delegate;

- (NSString *)contextIdentifier {
    return name;
}

- (void)setContextIdentifier:(NSString *)contextIdentifier {
    name = [NSString stringWithFormat:@"%@ %@", NSStringFromClass(self.class), contextIdentifier];
}

- (NSSet <NSManagedObject<AKMappedObject> *> *)updatedObjects {
    __block NSMutableSet <NSManagedObject<AKMappedObject> *> *result = [NSMutableSet new];;
    [self performBlockAndWait:^{
        for (NSManagedObject *obj in super.insertedObjects) {
            if ([obj conformsToProtocol:@protocol(AKMutableMappedObject)]) {
                NSManagedObject<AKMutableMappedObject> *mappedObject = (NSManagedObject<AKMutableMappedObject> *)obj;
                mappedObject.modificationDate = [NSDate date];
                [result addObject:mappedObject];
            }
        }
        for (NSManagedObject *obj in super.updatedObjects) {
            if ([obj conformsToProtocol:@protocol(AKMutableMappedObject)]) {
                NSManagedObject<AKMutableMappedObject> *mappedObject = (NSManagedObject<AKMutableMappedObject> *)obj;
                mappedObject.modificationDate = [NSDate date];
                [result addObject:mappedObject];
            }
        }
    }];
    return result.copy;
}

- (NSSet <NSObject<AKDescription> *> *)deletedObjects {
    __block NSMutableSet <NSObject<AKDescription> *> *result = [NSMutableSet new];
    [self performBlockAndWait:^{
        for (NSManagedObject *obj in super.deletedObjects) {
            if ([obj conformsToProtocol:@protocol(AKDescription)]) {
                [result addObject:[AKDescriptionRepresentation instantiateWithDescription:(NSManagedObject <AKDescription> *)obj]];
            }
        }
    }];
    return result.copy;
}

- (void)setAgregator:(id<AKTransactionsAgregator>)agregator {
    transactionsAgregator = agregator;
}

#pragma mark - cloud support
#if TARGET_OS_IOS
- (void)setCloudManager:(id<AKCloudManager>)cloudManager {
    ownedCloudManager = cloudManager;
}

- (void)initCloudWithContainerIdentifier:(NSString *)containerIdentifier databaseScope:(AKDatabaseScope)databaseScope {
    [[AKDataAgregator defaultAgregator] setCloudContext:self containerIdentifier:containerIdentifier databaseScope:databaseScope];
}

- (void)acceptPushNotificationUserInfo:(NSDictionary *)userInfo {
    if (ownedCloudManager) [ownedCloudManager acceptPushNotificationUserInfo:userInfo];
    else NSLog(@"[ERROR] owned cloud manager unordered");
}

- (void)cloudReplication {
    if (ownedCloudManager) [ownedCloudManager smartReplication];
    else NSLog(@"[ERROR] owned cloud manager unordered");
}

- (void)cloudTotalReplication {
    if (ownedCloudManager) [ownedCloudManager totalReplication];
    else NSLog(@"[ERROR] owned cloud manager unordered");
}

- (void)setCloudEnabled:(BOOL)cloudEnabled {
    if (ownedCloudManager) {
        ownedCloudManager.enabled = cloudEnabled;
        [self performTotalReplication];
    }
    else NSLog(@"[ERROR] owned cloud manager unordered");
}

- (BOOL)cloudEnabled {
    return ownedCloudManager ? ownedCloudManager.enabled : false;
}

- (AKCloudMapping *)cloudMapping {
    if (!cloudMapping) {
        cloudMapping = [AKCloudMapping new];
        for (NSEntityDescription *entity in managedObjectModel.entities) {
            if (!entity.isAbstract) {
                Class class = NSClassFromString([entity managedObjectClassName]);
                if ([class conformsToProtocol:@protocol(AKMappedObject)]) {
                    if ([class respondsToSelector:@selector(recordType)]) {
                        Class <AKMappedObject> mappedObjectClass = class;
                        NSString *recordType = [mappedObjectClass recordType];
                        if (![recordType isEqualToString:entity.name]) {
                            [cloudMapping mapRecordType:recordType withEntityName:entity.name];
                            continue;
                        }
                    }
                    [cloudMapping addEntity:entity.name];
                }
            }
        }
    }
    return cloudMapping;
}
#endif



#pragma mark - Synchronization

- (void)performTotalReplication {
    if (transactionsAgregator) [self performBlock:^{
        AKRepresentableTransaction *transaction = [AKRepresentableTransaction instantiateWithContext:self];
        NSError *error;
        if ([self save:&error]) {
            [self saveMainContext];
        } else {
            if (error) NSLog(@"[ERROR] saveContext error: %@\n%@", error.localizedDescription, error.userInfo);
        }
#if TARGET_OS_IOS
        for (NSString *entityName in self.cloudMapping.synchronizableEntities) {
            [transaction addObjects:[NSSet setWithArray:[self selectFrom:entityName]]];
        }
#else
        for (NSEntityDescription *entity in managedObjectModel.entities) {
            Class class = NSClassFromString([entity managedObjectClassName]);
            if ([class conformsToProtocol:@protocol(AKMappedObject)]) {
                [transaction addObjects:[NSSet setWithArray:[self selectFrom:entity.name]]];
            }
        }
#endif
        [transactionsAgregator willCommitTransaction:transaction];
        #if TARGET_OS_IOS
        [self cloudTotalReplication];
        #endif
    }];
}

- (void)enableWatchSynchronization {    
    [[AKDataAgregator defaultAgregator] addWatchSynchronizableContext:self];
}

+ (NSException *)incompatibleEntityExceptionWithEntityName:(NSString *)entityName entityClassName:(NSString *)entityClassName protocol:(Protocol *)protocol {
    return [NSException exceptionWithName:@"Incompatible entity class implementation"
                                   reason:[NSString stringWithFormat:@"Entity <%@> class <%@> not conformsToProtocol <%@>",
                                           entityName, entityClassName, NSStringFromProtocol(protocol)]
                                 userInfo:nil];
}

- (NSManagedObject *)insertMappedObject:(id <AKMappedObject>)recievedObject {
    NSManagedObject *object = [self insertTo:recievedObject.entityName];
    NSString *entityClassName = [[NSEntityDescription entityForName:recievedObject.entityName inManagedObjectContext:self] managedObjectClassName];
    if ([NSClassFromString(entityClassName) conformsToProtocol:@protocol(AKManagedObject)]) {
        NSManagedObject <AKManagedObject> *synchronizableObject = (NSManagedObject <AKManagedObject> *)object;
        synchronizableObject.uniqueData = recievedObject.uniqueData;
        synchronizableObject.modificationDate = recievedObject.modificationDate;
        synchronizableObject.keyedDataProperties = recievedObject.keyedDataProperties;
    } else {
        @throw [self.class incompatibleEntityExceptionWithEntityName:recievedObject.entityName entityClassName:entityClassName protocol:@protocol(AKManagedObject)];
    }
    return object;
}

- (NSManagedObject <AKFindableReference> *)objectByUniqueData:(NSData *)uniqueData entityName:(NSString *)entityName {
    NSManagedObject <AKFindableReference> *resultObject = nil;
    NSString *entityClassName = [[NSEntityDescription entityForName:entityName inManagedObjectContext:self] managedObjectClassName];
    if ([NSClassFromString(entityClassName) conformsToProtocol:@protocol(AKFindableReference)]) {
        Class <AKFindableReference> entityClass = NSClassFromString(entityClassName);
        NSArray <NSManagedObject <AKFindableReference> *> *objects = [self selectFrom:entityName
                                                                                where:[entityClass predicateWithUniqueData:uniqueData]];
        if (objects.count == 1) {
            resultObject = (NSManagedObject <AKFindableReference> *)objects.firstObject;
        } else if (objects.count) {
            resultObject = (NSManagedObject <AKFindableReference> *)objects.firstObject;
            @throw [NSException exceptionWithName:@"DataBase UNIQUE constraint violated"
                                           reason:[NSString stringWithFormat:@"Object count with UUID <%@>: %ld\n"
                                                   "Check your AKFindableReference protocol implementation for Entity <%@>",
                                                   resultObject.UUIDString, (unsigned long)objects.count,
                                                   entityName]
                                         userInfo:nil];
        }
    } else {
        @throw [self.class incompatibleEntityExceptionWithEntityName:entityName entityClassName:entityClassName protocol:@protocol(AKFindableReference)];
    }
    return resultObject;
}

- (void)objectByUniqueData:(NSData *)uniqueData entityName:(NSString *)entityName fetch:(void (^)(__kindof NSManagedObject *object))fetch {
    [self performBlock:^{
        NSManagedObject <AKFindableReference> *object;
        @try {
            object = [self objectByUniqueData:uniqueData entityName:entityName];
        } @catch (NSException *exception) {
            NSLog(@"[ERROR] %s Exception: %@", __PRETTY_FUNCTION__, exception);
        } @finally {
            fetch(object);
        }
    }];
}

- (NSManagedObject <AKFindableReference> *)objectByDescription:(id <AKDescription>)description {
    return [self objectByUniqueData:description.uniqueData entityName:description.entityName];
}

- (void)performMergeWithTransaction:(id<AKRepresentableTransaction>)transaction {
    if ([self hasChanges]) {
        [recievedTransactionsQueue addObject:transaction];
    } else {
        [self performMergeBlockWithTransaction:transaction];
        [self performSaveContextAndReloadData];
    }
}

- (void)performMergeBlockWithTransaction:(id<AKRepresentableTransaction>)transaction {
    [self performBlock:^{
        NSMutableArray <FoundObjectWithRelationRepresentation *> *foundObjectsWithRelationRepresentations = [NSMutableArray new];
        for (NSObject <AKMappedObject> *recievedMappedObject in transaction.updatedObjects) {
            @try {
                NSManagedObject <AKFindableReference> *foundObject = [self objectByDescription:recievedMappedObject];
                NSManagedObject <AKManagedObject> *managedObject;
                if (foundObject) {
                    if ([foundObject.class conformsToProtocol:@protocol(AKManagedObject)]) {
                        managedObject = (NSManagedObject <AKManagedObject> *)foundObject;
                        if ([managedObject.modificationDate compare:recievedMappedObject.modificationDate] == NSOrderedAscending) {
                            managedObject.modificationDate = recievedMappedObject.modificationDate;
                            managedObject.keyedDataProperties = recievedMappedObject.keyedDataProperties;
                        } else {
                            NSLog(@"[WARNING] %s Reject UPDATE %@ object %@: out of date", __PRETTY_FUNCTION__, recievedMappedObject.entityName, recievedMappedObject.UUIDString);
                            continue ;
                        }
                    }
                } else {
                    managedObject = (NSManagedObject <AKManagedObject> *)[self insertMappedObject:recievedMappedObject];
                }
                
                BOOL relatableToOne = [recievedMappedObject conformsToProtocol:@protocol(AKRelatableToOne)];
                BOOL relatableToMany = [recievedMappedObject conformsToProtocol:@protocol(AKRelatableToMany)];
                
                if (relatableToOne || relatableToMany) {
                    FoundObjectWithRelationRepresentation *theFoundObjectWithRelationRepresentation = [FoundObjectWithRelationRepresentation new];
                    if (relatableToOne) {
                        theFoundObjectWithRelationRepresentation.recievedRelationsToOne = (NSObject <AKRelatableToOne> *)recievedMappedObject;
                    }
                    if (relatableToMany) {
                        theFoundObjectWithRelationRepresentation.recievedRelationsToMany = (NSObject <AKRelatableToMany> *)recievedMappedObject;
                    }
                    theFoundObjectWithRelationRepresentation.managedObject = managedObject;
                    [foundObjectsWithRelationRepresentations addObject:theFoundObjectWithRelationRepresentation];
                }
                

            } @catch (NSException *exception) {
                NSLog(@"[ERROR] %s Exception: %@", __PRETTY_FUNCTION__, exception);
            }
        }
        
        for (FoundObjectWithRelationRepresentation *theFoundObjectWithRelationRepresentation in foundObjectsWithRelationRepresentations) {
            if (theFoundObjectWithRelationRepresentation.recievedRelationsToOne && [theFoundObjectWithRelationRepresentation.managedObject conformsToProtocol:@protocol(AKMutableRelatableToOne)]) {
                NSManagedObject <AKManagedObject, AKMutableRelatableToOne> *managedObjectRelatableToOne = (NSManagedObject <AKManagedObject, AKMutableRelatableToOne> *)theFoundObjectWithRelationRepresentation.managedObject;
                for (NSString *relationKey in theFoundObjectWithRelationRepresentation.recievedRelationsToOne.keyedReferences.allKeys) {
                    NSObject <AKReference> *reference = theFoundObjectWithRelationRepresentation.recievedRelationsToOne.keyedReferences[relationKey];
                    NSString *relatedEntityName = [managedObjectRelatableToOne.class entityNameByRelationKey][relationKey];
                    NSManagedObject <AKFindableReference> *relatedObject;
                    @try {
                        relatedObject = [self objectByUniqueData:reference.uniqueData entityName:relatedEntityName];
                    } @catch (NSException *exception) {
                        NSLog(@"[ERROR] %s Exception: %@", __PRETTY_FUNCTION__, exception);
                    }
                    [managedObjectRelatableToOne replaceRelation:relationKey toReference:relatedObject];
                    
                }
            }
            if (theFoundObjectWithRelationRepresentation.recievedRelationsToMany && [theFoundObjectWithRelationRepresentation.managedObject conformsToProtocol:@protocol(AKMutableRelatableToMany)]) {
                NSManagedObject <AKManagedObject, AKMutableRelatableToMany> *managedObjectRelatableToMany = (NSManagedObject <AKManagedObject, AKMutableRelatableToMany> *)theFoundObjectWithRelationRepresentation.managedObject;
                for (NSString *relationKey in theFoundObjectWithRelationRepresentation.recievedRelationsToMany.keyedSetsOfReferences.allKeys) {
                    NSSet <NSObject <AKReference> *> *setOfReferences = theFoundObjectWithRelationRepresentation.recievedRelationsToMany.keyedSetsOfReferences[relationKey];
                    NSString *relatedEntityName = [managedObjectRelatableToMany.class entityNameByRelationKey][relationKey];
                    NSMutableSet *newSet = [NSMutableSet new];
                    for (NSObject <AKReference> *reference in setOfReferences) {
                        NSManagedObject <AKFindableReference> *relatedObject;
                        @try {
                            relatedObject = [self objectByUniqueData:reference.uniqueData entityName:relatedEntityName];
                        } @catch (NSException *exception) {
                            NSLog(@"[ERROR] %s Exception: %@", __PRETTY_FUNCTION__, exception);
                        }
                        if (relatedObject) [newSet addObject:relatedObject];
                    }
                    [managedObjectRelatableToMany replaceRelation:relationKey toSetsOfReferences:newSet.copy];
                }
            }
        }
        
        for (NSObject <AKDescription> *recievedDescription in transaction.deletedObjects) {
            @try {
                NSManagedObject <AKFindableReference> *foundObject = [self objectByDescription:recievedDescription];
                if (foundObject) {
                    [self deleteObject:foundObject];
                } else {
                    NSLog(@"[WARNING] %s DELETE FROM %@ object UUID %@ not found", __PRETTY_FUNCTION__, recievedDescription.entityName, recievedDescription.UUIDString);
                }
            } @catch (NSException *exception) {
                NSLog(@"[ERROR] %s Exception: %@", __PRETTY_FUNCTION__, exception);
            }
        }
    }];
}

- (void)saveMainContext {
    dispatch_async(dispatch_get_main_queue(), ^{
#ifdef DEBUG
        NSLog(@"[DEBUG] %s", __PRETTY_FUNCTION__);
#endif
        NSError *error;
        if (![mainContext save:&error]) {
            if (error) NSLog(@"[ERROR] %s %@\n%@", __PRETTY_FUNCTION__, error.localizedDescription, error.userInfo);
        }
        
    });
}

- (void)performSaveContextAndReloadData {
    [self performBlock:^{
        [self saveAndReloadData];
    }];
}

- (void)saveAndReloadData {
    NSError *error;
    if ([self save:&error]) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(reloadData)]) {
            [self.delegate reloadData];
        }
        [self saveMainContext];
    } else {
        if (error) NSLog(@"[ERROR] %s %@\n%@", __PRETTY_FUNCTION__, error.localizedDescription, error.userInfo);
    }
}

- (void)performBlockWithSaveAndReloadData:(void (^)(void))block {
    [self performBlock:^{
        block();
        [self saveAndReloadData];
    }];
}

- (void)commit {
    if ([self hasChanges]) {        
        [self performBlock:^{
            if (transactionsAgregator) [transactionsAgregator willCommitTransaction:[AKRepresentableTransaction instantiateWithContext:self]];
            NSError *error;
            if ([self save:&error]) {
                [self saveMainContext];
            } else {
                if (error) NSLog(@"[ERROR] %s %@\n%@", __PRETTY_FUNCTION__, error.localizedDescription, error.userInfo);
            }
            [self mergeQueue];
        }];
    } else {
        [self mergeQueue];
    }
}

- (void)mergeQueue {
    [self mergeQueueCompletion:nil];
}

- (void)mergeQueueCompletion:(void (^)(void))completion {
    dispatch_group_t waitGroup;
    if (completion) waitGroup = dispatch_group_create();
    
    if (recievedTransactionsQueue.count) {
        if (completion) dispatch_group_enter(waitGroup);
        for (int i = 0; i < recievedTransactionsQueue.count; i++) {
            [self performMergeBlockWithTransaction:recievedTransactionsQueue[i]];
        }
        [self performSaveContextAndReloadData];
        [recievedTransactionsQueue removeAllObjects];
        if (completion) [self performBlock:^{
            dispatch_group_leave(waitGroup);
        }];
    }
    if (completion) dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        dispatch_group_wait(waitGroup, DISPATCH_TIME_FOREVER);
        completion();
    });
}

- (void)rollback {
    [self performBlock:^{
        [super rollback];        
    }];
    [self mergeQueue];
}


#pragma mark - initialization

- (id)copy {
    return self;
}

- (id)mutableCopy {
    return self;
}

+ (instancetype)new {
    return [self defaultContext];
}

+ (void)initialize {
    [super initialize];
    [self swixManagedObjectEntityNameMethod];
}

+ (instancetype)defaultContext {
    static dispatch_once_t pred;
    static id shared = nil;
    dispatch_once(&pred, ^{
        shared = [[self alloc] initDefaultContext];
    });
    return shared;
}

- (instancetype)initDefaultContext {
    NSURL *applicationDocumentsDirectory = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
    NSURL *storeURL = [applicationDocumentsDirectory URLByAppendingPathComponent:@"AKDefaultDataStore.sqlite"];
    if (self = [self initWithStoreURL:storeURL]) {
        self.contextIdentifier = @"Default";
    }
    return self;
}

- (instancetype)initWithStoreURL:(NSURL *)storeURL {
    return [self initWithStoreURL:storeURL modelURL:nil];
}

- (instancetype)initWithStoreURL:(NSURL *)storeURL modelURL:(NSURL *)modelURL {
    if (self = [super initWithConcurrencyType:NSPrivateQueueConcurrencyType]) {
        mainContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        NSString *idModelPart = @"DefaultModel ";
        if (modelURL) {
            idModelPart = [NSString stringWithFormat:@"Model %@ ", [modelURL.absoluteString componentsSeparatedByString:@"/"].lastObject];
            managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
        } else {
            managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:nil];
        }
        self.contextIdentifier = [NSString stringWithFormat:@"%@store %@", idModelPart, [storeURL.absoluteString componentsSeparatedByString:@"/"].lastObject];
        persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:managedObjectModel];
        NSError *error = nil;
        NSDictionary *autoMigration = @{ NSMigratePersistentStoresAutomaticallyOption : @(true),
                                         NSInferMappingModelAutomaticallyOption : @(true) };
        if (![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:autoMigration error:&error]) {
            if (error) NSLog(@"[ERROR] %s %@\n%@", __PRETTY_FUNCTION__, error.localizedDescription, error.userInfo);
        }
        [mainContext setPersistentStoreCoordinator:persistentStoreCoordinator];
        self.parentContext = mainContext;
        
        recievedTransactionsQueue = [NSMutableArray new];
    }
    return self;
}

#pragma mark - thread safe queries

- (void)deleteObject:(NSManagedObject *)object completion:(void (^)(void))completion {
    [self performBlock:^{
        [super deleteObject:object];
        completion();
    }];
}

- (void)insertTo:(NSString *)entityName fetch:(FetchObject)fetch {
    [self performBlock:^{
        NSManagedObject *object = [NSEntityDescription insertNewObjectForEntityForName:entityName inManagedObjectContext:self];
        NSString *entityClassName = [[NSEntityDescription entityForName:entityName inManagedObjectContext:self] managedObjectClassName];
        if ([NSClassFromString(entityClassName) conformsToProtocol:@protocol(AKMutableReference)]) {
            NSManagedObject <AKMutableReference> *mutableReference = (NSManagedObject <AKMutableReference> *)object;
            mutableReference.uniqueData = [[NSUUID UUID] data];
        }
        fetch(object);
    }];
}

- (void)selectFrom:(NSString *)entity fetch:(FetchArray)fetch {
    [self selectFrom:entity limit:0 fetch:fetch];
}

- (void)selectFrom:(NSString *)entity limit:(NSUInteger)limit fetch:(FetchArray)fetch {
    [self selectFrom:entity orderBy:nil limit:limit fetch:fetch];
}

- (void)selectFrom:(NSString *)entity orderBy:(nullable NSArray <NSSortDescriptor *> *)sortDescriptors fetch:(FetchArray)fetch {
    [self selectFrom:entity orderBy:sortDescriptors limit:0 fetch:fetch];
}

- (void)selectFrom:(NSString *)entity orderBy:(nullable NSArray <NSSortDescriptor *> *)sortDescriptors limit:(NSUInteger)limit fetch:(FetchArray)fetch {
    [self selectFrom:entity where:nil orderBy:sortDescriptors limit:limit fetch:fetch];
}

- (void)selectFrom:(NSString *)entity where:(NSPredicate *)clause fetch:(FetchArray)fetch {
    [self selectFrom:entity where:clause limit:0 fetch:fetch];
}

- (void)selectFrom:(NSString *)entity where:(NSPredicate *)clause limit:(NSUInteger)limit fetch:(FetchArray)fetch {
    [self selectFrom:entity where:clause orderBy:nil limit:limit fetch:fetch];
}

- (void)selectFrom:(NSString *)entity where:(NSPredicate *)clause orderBy:(nullable NSArray <NSSortDescriptor *> *)sortDescriptors fetch:(FetchArray)fetch {
    [self selectFrom:entity where:clause orderBy:sortDescriptors limit:0 fetch:fetch];
}

- (void)selectFrom:(NSString *)entity where:(NSPredicate *)clause orderBy:(nullable NSArray <NSSortDescriptor *> *)sortDescriptors limit:(NSUInteger)limit fetch:(FetchArray)fetch {
    [self performBlock:^{
        NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:entity];
        request.predicate = clause;
        [request setSortDescriptors:sortDescriptors];
        [request setFetchLimit:limit];
        NSError *error = nil;
        NSArray *entities = [self executeFetchRequest:request error:&error];
        if (error) NSLog(@"[ERROR] %s %@\n%@", __PRETTY_FUNCTION__, error.localizedDescription, error.userInfo);
        fetch(entities);
    }];
}

- (void)rollbackCompletion:(void (^)(void))completion {
    [self performBlock:^{
        [super rollback];
        completion();
    }];
    [self mergeQueue];
}


@end
