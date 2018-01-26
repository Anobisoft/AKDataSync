//
//  NSManagedObject+AKDataSync.h
//  AKDataSync
//
//  Created by Stanislav Pletnev on 21.06.16.
//  Copyright © 2016 Anobisoft. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "AKPublicProtocol.h"

typedef void (^FetchArrayBlock)(NSArray<__kindof NSManagedObject *> *objects);

@interface NSManagedObject (AKDataSync)

- (NSString *)entityName;
+ (NSString *)entityName;

+ (void)fetch:(FetchArrayBlock)fetch;
+ (void)fetch:(FetchArrayBlock)fetch limit:(NSUInteger)limit;
+ (void)fetch:(FetchArrayBlock)fetch orderBy:(NSArray<NSSortDescriptor *> *)sortDescriptors ;
+ (void)fetch:(FetchArrayBlock)fetch orderBy:(NSArray<NSSortDescriptor *> *)sortDescriptors limit:(NSUInteger)limit;

+ (void)fetch:(FetchArrayBlock)fetch where:(NSPredicate *)clause;
+ (void)fetch:(FetchArrayBlock)fetch where:(NSPredicate *)clause limit:(NSUInteger)limit;
+ (void)fetch:(FetchArrayBlock)fetch where:(NSPredicate *)clause orderBy:(NSArray<NSSortDescriptor *> *)sortDescriptors;
+ (void)fetch:(FetchArrayBlock)fetch where:(NSPredicate *)clause orderBy:(NSArray<NSSortDescriptor *> *)sortDescriptors limit:(NSUInteger)limit;

@end
