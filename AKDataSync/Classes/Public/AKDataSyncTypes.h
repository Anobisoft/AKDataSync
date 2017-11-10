//
//  AKDataSyncTypes.h
//  Pods
//
//  Created by Stanislav Pletnev on 22.08.17.
//
//

#ifndef AKDataSyncTypes_h
#define AKDataSyncTypes_h

#import <AnobiKit/AKTypes.h>

typedef NS_ENUM(NSUInteger, AKCloudState) {
    /* An error occurred when getting the account status, consult the corresponding NSError */
    AKCloudStateCouldNotDetermine = 0,
    /* The iCloud account credentials are available for this application */
    AKCloudStateAccountStatusAvailable = 1,
    /* Parental Controls / Device Management has denied access to iCloud account credentials */
    AKCloudStateAccountStatusRestricted = 2,
    /* No iCloud account is logged in on this device */
    AKCloudStateAccountStatusNoAccount = 3,
    AKCloudStateThisDeviceUpdated = 4,
    AKCloudStateDevicesReloaded = 5,
    AKCloudStateReady = 5,
};

typedef NS_ENUM(NSInteger, AKDatabaseScope) {
    AKDatabaseScopeDefault = 0,
    AKDatabaseScopePublic,
    AKDatabaseScopePrivate,
    AKDatabaseScopeShared,
};

#endif /* AKDataSyncTypes_h */
