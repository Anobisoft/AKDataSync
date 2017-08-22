//
//  NSManagedObject+AKDataSync.h
//  AKDataSync
//
//  Created by Stanislav Pletnev on 21.06.16.
//  Copyright © 2016 Anobisoft.com. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "AKPublicProtocol.h"

typedef void (^FetchArray)(NSArray <__kindof NSManagedObject *> *objects);

@interface NSManagedObject (AKDataSync)

- (NSString *)entityName;
+ (NSString *)entityName;

+ (void)selectObjectsInContext:(NSManagedObjectContext *)context fetch:(FetchArray)fetch;
+ (void)selectObjectsInContext:(NSManagedObjectContext *)context limit:(NSUInteger)limit fetch:(FetchArray)fetch;
+ (void)selectObjectsInContext:(NSManagedObjectContext *)context orderBy:(NSArray <NSSortDescriptor *> *)sortDescriptors fetch:(FetchArray)fetch;
+ (void)selectObjectsInContext:(NSManagedObjectContext *)context orderBy:(NSArray <NSSortDescriptor *> *)sortDescriptors limit:(NSUInteger)limit fetch:(FetchArray)fetch;

+ (void)selectObjectsInContext:(NSManagedObjectContext *)context where:(NSPredicate *)clause fetch:(FetchArray)fetch;
+ (void)selectObjectsInContext:(NSManagedObjectContext *)context where:(NSPredicate *)clause limit:(NSUInteger)limit fetch:(FetchArray)fetch;
+ (void)selectObjectsInContext:(NSManagedObjectContext *)context where:(NSPredicate *)clause orderBy:(NSArray <NSSortDescriptor *> *)sortDescriptors fetch:(FetchArray)fetch;
+ (void)selectObjectsInContext:(NSManagedObjectContext *)context where:(NSPredicate *)clause orderBy:(NSArray <NSSortDescriptor *> *)sortDescriptors limit:(NSUInteger)limit fetch:(FetchArray)fetch;

@end
