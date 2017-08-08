//
//  AKRepresentableTransaction.h
//  AKDataSync
//
//  Created by Stanislav Pletnev on 09.02.17.
//  Copyright © 2017 Anobisoft. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AKPrivateProtocol.h"

@interface AKRepresentableTransaction : NSObject <AKRepresentableTransaction>

+ (instancetype)instantiateWithContext:(id <AKRepresentableTransaction>)context;
- (void)addObjects:(NSSet<NSObject<AKMappedObject> *> *)objects;
- (instancetype)init NS_UNAVAILABLE;

@end
