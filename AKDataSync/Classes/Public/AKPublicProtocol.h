//
//  AKPublicProtocol.h
//  AKDataSync
//
//  Created by Stanislav Pletnev on 11.06.16.
//  Copyright © 2016 Anobisoft.com. All rights reserved.
//

@protocol AKManagedObject;
@protocol AKReference, AKMutableReference, AKDescription, AKMutableDescription, AKFindableReference;
@protocol AKMappedObject, AKMutableMappedObject;
@protocol AKRelatable, AKRelatableToOne, AKMutableRelatableToOne, AKRelatableToMany, AKMutableRelatableToMany;
@protocol AKDataSyncContext, AKDataSyncContextDelegate, AKDataSyncSearchableContext;

#ifndef AKPublicProtocol_h
#define AKPublicProtocol_h

NS_ASSUME_NONNULL_BEGIN


#pragma mark - Synchronizable

@protocol AKManagedObject <AKMutableMappedObject, AKMutableReference, AKFindableReference>
@end


@protocol AKReference <NSObject>
@required
- (NSData *)uniqueData;
@optional
- (NSString *)UUIDString;
@end

@protocol AKMutableReference <AKReference>
@required
- (void)setUniqueData:(NSData *)uniqueData;
@optional
- (void)setUUIDString:(NSString *)UUIDString;
- (void)setUUID:(NSUUID *)UUID;
@end;

@protocol AKDescription <AKReference>
@required
- (NSString *)entityName;
@optional
+ (NSString *)recordType;
+ (NSString *)entityName;
@end

@protocol AKMutableDescription <AKDescription, AKMutableReference>
@end

@protocol AKFindableReference <AKReference>
@required
+ (NSString *)entityName;
+ (NSPredicate *)predicateWithUniqueData:(NSData *)uniqueData;
@end

@protocol AKMappedObject <AKDescription>
- (NSDate *)modificationDate;
- (NSDictionary <NSString *, NSObject<NSCoding> *> *)keyedDataProperties;
@end

@protocol AKMutableMappedObject <AKMappedObject>
- (void)setModificationDate:(NSDate *)modificationDate;
- (void)setKeyedDataProperties:(NSDictionary <NSString *, NSObject<NSCoding> *> *)keyedDataProperties;
@end

#pragma mark - Relationships

@protocol AKRelatable
@required
+ (NSDictionary <NSString *, NSString *> *)entityNameByRelationKey;
@end

@protocol AKRelatableToOne <AKRelatable>
@required
- (NSDictionary <NSString *, NSObject<AKReference> *> *)keyedReferences;
@end

@protocol AKMutableRelatableToOne <AKRelatableToOne>
@required
- (void)replaceRelation:(NSString *)relationKey toReference:(NSObject<AKReference> *)reference;
@end

@protocol AKRelatableToMany <AKRelatable>
@required
- (NSDictionary <NSString *, NSSet <NSObject<AKReference> *> *> *)keyedSetsOfReferences;
@end

@protocol AKMutableRelatableToMany <AKRelatableToMany>
@required
- (void)replaceRelation:(NSString *)relationKey toSetsOfReferences:(NSSet<NSObject<AKReference> *> *)setOfReferences;
@end

#pragma mark - SynchronizableContext

@protocol AKDataSyncContext <NSObject>
@required
- (void)commit;
- (void)rollbackCompletion:(nullable void (^)(void))completion;
#if TARGET_OS_IOS
- (void)acceptPushNotificationUserInfo:(NSDictionary *)userInfo;
#endif
@property (nonatomic, weak) id <AKDataSyncContextDelegate> delegate;
@end

@protocol AKDataSyncContextDelegate <NSObject>
@optional
- (void)reloadData;
- (void)iCloudNoAccount;
@end

@protocol AKDataSyncSearchableContext <NSObject>
- (id <AKFindableReference>)objectByUniqueData:(NSData *)uniqueData entityName:(NSString *)entityName;
@end



NS_ASSUME_NONNULL_END

#endif /* AKPublicProtocol_h */

