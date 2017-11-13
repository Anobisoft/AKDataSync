//
//  NSManagedObject+AKDataSync.m
//  AKDataSync
//
//  Created by Stanislav Pletnev on 21.06.16.
//  Copyright © 2016 Anobisoft. All rights reserved.
//

#import "NSManagedObject+AKDataSync.h"
#import "AKUUID.h"
#import "AKManagedObjectContext.h"

@implementation NSManagedObject (AKDataSync)

- (NSString *)entityName {
    return self.entity.name;
}

+ (NSString *)entityName {
    return self.entity.name;
}

- (NSString *)UUIDString {
    if ([self respondsToSelector:@selector(uniqueData)]) {
        return ((NSData *)[(NSManagedObject<AKReference> *)self uniqueData]).UUIDString;
    }
    return nil;
}

+ (void)fetch:(FetchArray)fetch {
    [self fetch:fetch limit:0];
}
+ (void)fetch:(FetchArray)fetch limit:(NSUInteger)limit {
    [self fetch:fetch orderBy:nil limit:limit];
}

+ (void)fetch:(FetchArray)fetch orderBy:(NSArray <NSSortDescriptor *> *)sortDescriptors {
    [self fetch:fetch orderBy:sortDescriptors limit:0];
}
+ (void)fetch:(FetchArray)fetch orderBy:(NSArray <NSSortDescriptor *> *)sortDescriptors limit:(NSUInteger)limit {
    [self fetch:fetch where:nil orderBy:sortDescriptors limit:limit];
}

+ (void)fetch:(FetchArray)fetch where:(NSPredicate *)clause {
    [self fetch:fetch where:clause limit:0];
}
+ (void)fetch:(FetchArray)fetch where:(NSPredicate *)clause limit:(NSUInteger)limit {
    [self fetch:fetch where:clause orderBy:nil limit:limit];
}
+ (void)fetch:(FetchArray)fetch where:(NSPredicate *)clause orderBy:(NSArray <NSSortDescriptor *> *)sortDescriptors {
    [self fetch:fetch where:clause orderBy:sortDescriptors limit:0];
}
+ (void)fetch:(FetchArray)fetch where:(NSPredicate *)clause orderBy:(NSArray <NSSortDescriptor *> *)sortDescriptors limit:(NSUInteger)limit {
    AKManagedObjectContext *context = [AKManagedObjectContext defaultContext];
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
