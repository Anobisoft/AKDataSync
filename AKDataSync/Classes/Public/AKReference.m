//
//  AKReference.m
//  AKDataSync
//
//  Created by Stanislav Pletnev on 23.01.17.
//  Copyright © 2017 Anobisoft. All rights reserved.
//

#import "AKReference.h"
#import "AKPublicProtocol.h"
#import "AKUUID.h"

#define AKDataSync_uniqueDataKey @"AKDataSync_uniqueData"

@implementation AKReference {
    NSString *uuidString;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:_uniqueData forKey:AKDataSync_uniqueDataKey];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        _uniqueData = [aDecoder decodeObjectForKey:AKDataSync_uniqueDataKey];
    }
    return self;
}

+ (instancetype)null {
    return [[self alloc] init];
}

+ (instancetype)instantiateWithReference:(NSObject<AKReference> *)reference {
    return [[self alloc] initWithReference:reference];
}

- (instancetype)initWithReference:(NSObject<AKReference> *)reference {
    if (self = [super init]) {
        _uniqueData = reference.uniqueData;
    }
    return self;
}

- (NSString *)UUIDString {
    if (!uuidString) uuidString = _uniqueData.UUIDString;
    return uuidString;
}


@end
