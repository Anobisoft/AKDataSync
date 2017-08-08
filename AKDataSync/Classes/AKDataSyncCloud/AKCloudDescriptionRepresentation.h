//
//  AKCloudDescriptionRepresentation.h
//  AKDataSync
//
//  Created by Stanislav Pletnev on 02.02.17.
//  Copyright © 2017 Anobisoft. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AKPublicProtocol.h"

@class AKCloudMapping;

@interface AKCloudDescriptionRepresentation : NSObject <AKDescription>

+ (instancetype)instantiateWithRecordType:(NSString *)recordType uniqueData:(NSData *)uniqueData mapping:(AKCloudMapping *)mapping;

@end
