//
//  AKReference.h
//  AKDataSync
//
//  Created by Stanislav Pletnev on 23.01.17.
//  Copyright © 2017 Anobisoft. All rights reserved.
//

#ifndef AKReference_h
#define AKReference_h

#import <Foundation/Foundation.h>
#import "AKPublicProtocol.h"

@interface AKReference : NSObject <AKReference, NSCoding> {
    @protected
    NSData *_uniqueData;
}

+ (instancetype)null;
+ (instancetype)instantiateWithReference:(NSObject<AKReference> *)reference;
- (NSString *)UUIDString;

@property (nonatomic, strong, readonly) NSData *uniqueData;

@end

#endif
