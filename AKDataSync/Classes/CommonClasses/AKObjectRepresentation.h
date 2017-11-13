//
//  AKObjectRepresentation.h
//  AKDataSync
//
//  Created by Stanislav Pletnev on 11.06.16.
//  Copyright © 2016 Anobisoft. All rights reserved.
//

#ifndef AKObjectRepresentation_h
#define AKObjectRepresentation_h

#import <Foundation/Foundation.h>
#import "AKDescriptionRepresentation.h"

@interface AKObjectRepresentation : AKDescriptionRepresentation <AKMappedObject> {
    @protected
    NSDate *_modificationDate;
    NSDictionary <NSString *, NSObject<NSCoding> *> *_keyedDataProperties;
}

+ (instancetype)instantiateWithMappedObject:(NSObject<AKMappedObject> *)object;

@property (nonatomic, strong, readonly) NSDate *modificationDate;
@property (nonatomic, strong, readonly) NSDictionary <NSString *, NSObject<NSCoding> *> *keyedDataProperties;

@end

#endif
