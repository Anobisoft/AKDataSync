//
//  AKRelatableObjectRepresentation.h
//  AKDataSync
//
//  Created by Stanislav Pletnev on 20.01.17.
//  Copyright © 2017 Anobisoft. All rights reserved.
//

#ifndef AKRelatableObjectRepresentation_h
#define AKRelatableObjectRepresentation_h

#import <Foundation/Foundation.h>
#import "AKObjectRepresentation.h"

@interface AKRelatableObjectRepresentation : AKObjectRepresentation <AKRelatableToOne, AKRelatableToMany>

@property (nonatomic, strong, readonly) NSDictionary <NSString *, AKReference *> *keyedReferences;
@property (nonatomic, strong, readonly) NSDictionary <NSString *, NSSet <AKReference *> *> *keyedSetsOfReferences;

@end

#endif
