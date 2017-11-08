//
//  NSManagedObject+AKDataSync.m
//  AKDataSync
//
//  Created by Stanislav Pletnev on 21.06.16.
//  Copyright © 2016 Anobisoft.com. All rights reserved.
//

#import "NSManagedObject+AKDataSync.h"
#import "AKUUID.h"

@implementation NSManagedObject (AKDataSync)

- (NSString *)entityName {
    return [NSString stringWithString:self.entity.name];
}

+ (NSString *)entityName {
    return [NSString stringWithString:self.entity.name];
}

- (NSString *)UUIDString {
    if ([self respondsToSelector:@selector(uniqueData)]) {
        return ((NSData *)[(NSManagedObject<AKReference> *)self uniqueData]).UUIDString;
    }
    return nil;
}

+ (void)selectObjectsInContext:(NSManagedObjectContext *)context fetch:(FetchArray)fetch {
    [self selectObjectsInContext:context limit:0 fetch:fetch];
}

+ (void)selectObjectsInContext:(NSManagedObjectContext *)context limit:(NSUInteger)limit fetch:(FetchArray)fetch {
    [self selectObjectsInContext:context orderBy:nil limit:limit fetch:fetch];
}

+ (void)selectObjectsInContext:(NSManagedObjectContext *)context orderBy:(NSArray<NSSortDescriptor *> *)sortDescriptors fetch:(FetchArray)fetch {
    [self selectObjectsInContext:context orderBy:sortDescriptors limit:0 fetch:fetch];
}

+ (void)selectObjectsInContext:(NSManagedObjectContext *)context orderBy:(nullable NSArray <NSSortDescriptor *> *)sortDescriptors limit:(NSUInteger)limit fetch:(FetchArray)fetch {
    [self selectObjectsInContext:context where:nil orderBy:sortDescriptors limit:limit fetch:fetch];
}

+ (void)selectObjectsInContext:(NSManagedObjectContext *)context where:(NSPredicate *)clause fetch:(FetchArray)fetch {
    [self selectObjectsInContext:context where:clause limit:0 fetch:fetch];
}

+ (void)selectObjectsInContext:(NSManagedObjectContext *)context where:(NSPredicate *)clause limit:(NSUInteger)limit fetch:(FetchArray)fetch {
    [self selectObjectsInContext:context where:clause orderBy:nil limit:limit fetch:fetch];
}

+ (void)selectObjectsInContext:(NSManagedObjectContext *)context where:(NSPredicate *)clause orderBy:(nullable NSArray <NSSortDescriptor *> *)sortDescriptors fetch:(FetchArray)fetch {
    [self selectObjectsInContext:context where:clause orderBy:sortDescriptors limit:0 fetch:fetch];
}

+ (void)selectObjectsInContext:(NSManagedObjectContext *)context where:(NSPredicate *)clause orderBy:(nullable NSArray <NSSortDescriptor *> *)sortDescriptors limit:(NSUInteger)limit fetch:(FetchArray)fetch {
    [context performBlock:^{
        NSFetchRequest *request = [self fetchRequest];
        request.predicate = clause;
        [request setSortDescriptors:sortDescriptors];
        [request setFetchLimit:limit];
        NSError *error = nil;
        NSArray *entities = [context executeFetchRequest:request error:&error];
        if (error) NSLog(@"[ERROR] %s %@\n%@", __PRETTY_FUNCTION__, error.localizedDescription, error.userInfo);
        fetch(entities);
    }];
}

@end
