//
//  AKCloudInternalConst.h
//  AKDataSync
//
//  Created by Stanislav Pletnev on 02.02.17.
//  Copyright © 2017 Anobisoft. All rights reserved.
//

#ifndef AKCloudInternalConst_h
#define AKCloudInternalConst_h

#define AKCloudMaxModificationDateForEntityUDKey @"AKCloudMaxModificationDateForEntity"
#define AKCloudPreparedToCloudRecordsUDKey @"AKCloudPreparedToCloudRecords"

#define AKCloudDevicesInfoRecordType @"AKDevice"

#define AKCloudDeletionInfoRecordType @"AKDeletionInfo"
#define AKCloudDeletionInfoRecordProperty_recordType @"AKDI_recordType"
#define AKCloudDeletionInfoRecordProperty_recordID @"AKDI_recordID"
#define AKCloudDeletionInfoRecordProperty_deviceID @"AKDI_deviceID"

#define AKCloudRealModificationDateProperty @"realModificationDate"

#define AKCloudInitTimeout 60
#define AKCloudTryToPushTimeout 60
#define AKCloudSmartReplicationTimeout 60

#endif /* AKCloudInternalConst_h */
