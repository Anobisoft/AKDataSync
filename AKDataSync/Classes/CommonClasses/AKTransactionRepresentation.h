//
//  AKTransactionRepresentation.h
//  AKDataSync
//
//  Created by Stanislav Pletnev on 11.06.16.
//  Copyright © 2016 Anobisoft.com. All rights reserved.
//

#ifndef AKTransactionRepresentation_h
#define AKTransactionRepresentation_h

#import "AKRelatableObjectRepresentation.h"
#import "AKPrivateProtocol.h"

@interface AKTransactionRepresentation : NSObject <AKRepresentableTransaction, NSCoding>

+ (instancetype)instantiateWithRepresentableTransaction:(id <AKRepresentableTransaction>)transaction;
- (void)mergeWithRepresentableTransaction:(id <AKRepresentableTransaction>)transaction;

@end

#endif
