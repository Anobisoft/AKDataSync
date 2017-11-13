//
//  NSManagedObject+AKDataSync.h
//  AKDataSync
//
//  Created by Stanislav Pletnev on 21.06.16.
//  Copyright © 2016 Anobisoft. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "AKPublicProtocol.h"

typedef void (^FetchArray)(NSArray <__kindof NSManagedObject *> *objects);

@interface NSManagedObject (AKDataSync)

- (NSString *)entityName;
+ (NSString *)entityName;

+ (void)fetch:(FetchArray)fetch;
+ (void)fetch:(FetchArray)fetch limit:(NSUInteger)limit;
+ (void)fetch:(FetchArray)fetch orderBy:(NSArray <NSSortDescriptor *> *)sortDescriptors ;
+ (void)fetch:(FetchArray)fetch orderBy:(NSArray <NSSortDescriptor *> *)sortDescriptors limit:(NSUInteger)limit;

+ (void)fetch:(FetchArray)fetch where:(NSPredicate *)clause;
+ (void)fetch:(FetchArray)fetch where:(NSPredicate *)clause limit:(NSUInteger)limit;
+ (void)fetch:(FetchArray)fetch where:(NSPredicate *)clause orderBy:(NSArray <NSSortDescriptor *> *)sortDescriptors;
+ (void)fetch:(FetchArray)fetch where:(NSPredicate *)clause orderBy:(NSArray <NSSortDescriptor *> *)sortDescriptors limit:(NSUInteger)limit;

@end
