//
//  ASUserDefaultsContainer.h
//  AKDataSync
//
//  Created by Stanislav Pletnev on 11.06.16.
//  Copyright © 2016 Anobisoft.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AKSerializableObject.h"
#import "AKSerializableContext.h"

@protocol ASSyncDelegate <NSObject>
@optional
- (void)reloadData;
@end

@interface ASUserDefaultsContainer : NSObject <ASynchronizableObjectDelegate, ASynchronizableContext>

+ (instancetype)defaultConteiner;
+ (instancetype)instantiateWithIdentifier:(NSString *)identifier;

@property (nonatomic, strong, readonly) NSArray <AKSerializableObject *> *content;

- (AKSerializableObject *)insertTo:(NSString *)entityName;
- (void)deleteObject:(AKSerializableObject *)object;

- (id)init NS_UNAVAILABLE;
- (id)copy NS_UNAVAILABLE;
- (id)mutableCopy NS_UNAVAILABLE;

@end
