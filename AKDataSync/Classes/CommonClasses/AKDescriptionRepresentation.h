//
//  AKDescriptionRepresentation.h
//  AKDataSync
//
//  Created by Stanislav Pletnev on 11.06.16.
//  Copyright © 2016 Anobisoft. All rights reserved.
//

#ifndef AKDescriptionRepresentation_h
#define AKDescriptionRepresentation_h

#import <Foundation/Foundation.h>
#import "AKReference.h"

@interface AKDescriptionRepresentation : AKReference <AKDescription>

+ (instancetype)instantiateWithDescription:(NSObject<AKDescription> *)description;

@property (nonatomic, strong, readonly) NSString *entityName;

@end

#endif
