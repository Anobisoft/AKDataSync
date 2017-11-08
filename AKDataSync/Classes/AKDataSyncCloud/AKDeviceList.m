//
//  AKDeviceList.m
//  AKDataSync
//
//  Created by Stanislav Pletnev on 2016-12-21
//  Copyright © 2016 Anobisoft. All rights reserved.
//

#import "AKDeviceList.h"
#import <UIKit/UIKit.h>
#import <sys/utsname.h>
#import "AKUUID.h"
#import <Security/Security.h>

NSString* machine()
{
    struct utsname systemInfo;
    uname(&systemInfo);
    return [NSString stringWithCString:systemInfo.machine
                              encoding:NSUTF8StringEncoding];
}

@implementation AKDeviceList {
    NSMutableDictionary *mutableStore;
    AKDevice *thisDevice;
}

static NSString *thisDeviceVersion;

+ (void)initialize {
    [super initialize];
    thisDeviceVersion = [@{@"iPod5,1"    : @"iPod Touch 5",
                           @"iPod7,1"    : @"iPod Touch 6",
                           @"iPhone3,1"  : @"iPhone 4",
                           @"iPhone3,2"  : @"iPhone 4",
                           @"iPhone3,3"  : @"iPhone 4",
                           @"iPhone4,1"  : @"iPhone 4s",
                           @"iPhone5,1"  : @"iPhone 5",
                           @"iPhone5,2"  : @"iPhone 5",
                           @"iPhone5,3"  : @"iPhone 5c",
                           @"iPhone5,4"  : @"iPhone 5c",
                           @"iPhone6,1"  : @"iPhone 5s",
                           @"iPhone6,2"  : @"iPhone 5s",
                           @"iPhone7,2"  : @"iPhone 6",
                           @"iPhone7,1"  : @"iPhone 6 Plus",
                           @"iPhone8,1"  : @"iPhone 6s",
                           @"iPhone8,2"  : @"iPhone 6s Plus",
                           @"iPhone9,1"  : @"iPhone 7",
                           @"iPhone9,3"  : @"iPhone 7",
                           @"iPhone9,2"  : @"iPhone 7 Plus",
                           @"iPhone9,4"  : @"iPhone 7 Plus",
                           @"iPhone8,4"  : @"iPhone SE",
                           @"iPad2,1"    : @"iPad 2",
                           @"iPad2,2"    : @"iPad 2",
                           @"iPad2,3"    : @"iPad 2",
                           @"iPad2,4"    : @"iPad 2",
                           @"iPad3,1"    : @"iPad 3",
                           @"iPad3,2"    : @"iPad 3",
                           @"iPad3,3"    : @"iPad 3",
                           @"iPad3,4"    : @"iPad 4",
                           @"iPad3,5"    : @"iPad 4",
                           @"iPad3,6"    : @"iPad 4",
                           @"iPad4,1"    : @"iPad Air",
                           @"iPad4,2"    : @"iPad Air",
                           @"iPad4,3"    : @"iPad Air",
                           @"iPad5,3"    : @"iPad Air 2",
                           @"iPad5,4"    : @"iPad Air 2",
                           @"iPad2,5"    : @"iPad Mini",
                           @"iPad2,6"    : @"iPad Mini",
                           @"iPad2,7"    : @"iPad Mini",
                           @"iPad4,4"    : @"iPad Mini 2",
                           @"iPad4,5"    : @"iPad Mini 2",
                           @"iPad4,6"    : @"iPad Mini 2",
                           @"iPad4,7"    : @"iPad Mini 3",
                           @"iPad4,8"    : @"iPad Mini 3",
                           @"iPad4,9"    : @"iPad Mini 3",
                           @"iPad5,1"    : @"iPad Mini 4",
                           @"iPad5,2"    : @"iPad Mini 4",
                           @"iPad6,3"    : @"iPad Pro",
                           @"iPad6,4"    : @"iPad Pro",
                           @"iPad6,7"    : @"iPad Pro",
                           @"iPad6,8"    : @"iPad Pro",
                           @"AppleTV5,3" : @"Apple TV",
                           @"i386"       : @"Simulator",
                           @"x86_64"     : @"Simulator",
                           } objectForKey: machine()];

}

- (NSString *)uniqueDeviceIdentifier {
    static NSString *uniqueDeviceIdentifier = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSMutableDictionary *keychainItem = [NSMutableDictionary dictionaryWithDictionary:
                                             @{(__bridge id)kSecClass : (__bridge id)kSecClassInternetPassword,
                                               (__bridge id)kSecAttrAccessible : (__bridge id)kSecAttrAccessibleWhenUnlocked,
                                               (__bridge id)kSecAttrServer : [NSBundle mainBundle].bundleIdentifier,
                                               (__bridge id)kSecAttrAccount : @"UniqueDeviceIdentifier",
                                               (__bridge id)kSecReturnData : (__bridge id)kCFBooleanTrue,
                                               (__bridge id)kSecReturnAttributes : (__bridge id)kCFBooleanTrue
                                               }];
        
        CFDictionaryRef result = nil;
        OSStatus sts = SecItemCopyMatching((__bridge CFDictionaryRef)keychainItem, (CFTypeRef *)&result);
        
        if (sts) NSLog(@"[WARNING] Load UniqueDeviceIdentifier Error: %d", (int)sts);
        
        if (sts == noErr) {
            NSDictionary *resultDict = (__bridge_transfer NSDictionary *)result;
            NSData *pswd = resultDict[(__bridge id)kSecValueData];
            uniqueDeviceIdentifier = [[NSString alloc] initWithData:pswd encoding:NSUTF8StringEncoding];
        } else {
            uniqueDeviceIdentifier = [UIDevice currentDevice].identifierForVendor.UUIDString;
#ifdef DEBUG
            NSLog(@"[DEBUG] Save new UniqueDeviceIdentifier %@", uniqueDeviceIdentifier);
#endif
            keychainItem[(__bridge id)kSecValueData] = [uniqueDeviceIdentifier dataUsingEncoding:NSUTF8StringEncoding];
            OSStatus sts = SecItemAdd((__bridge CFDictionaryRef)keychainItem, NULL);
            if (sts) NSLog(@"[ERROR] Save UniqueDeviceIdentifier Error: %d", (int)sts);
        }
    });

    return uniqueDeviceIdentifier;
}

+ (instancetype)listWithConfig:(AKCloudConfig *)config {
    return [[self alloc] initWithConfig:config];
}

- (instancetype)initWithConfig:(AKCloudConfig *)config {
    if (self = [super init]) {
        mutableStore = [NSMutableDictionary new];
        thisDevice = [AKDevice deviceWithMappedObject:nil config:config];
        thisDevice.UUIDString = [self uniqueDeviceIdentifier];
    }
    return self;
}

- (void)updateThisDeviceInfo {
    NSString *system = [NSString stringWithFormat:@"%@ %@", [[UIDevice currentDevice] systemName], [[UIDevice currentDevice] systemVersion]];
    thisDevice.keyedDataProperties = @{ @"name"    : [[UIDevice currentDevice] name],
                                        @"model"   : [[UIDevice currentDevice] model],
                                        @"version" : thisDeviceVersion,
                                        @"system"  : system,
                                        };
    thisDevice.modificationDate = [NSDate date];
}

- (AKDevice *)thisDevice {
    [self updateThisDeviceInfo];
    return thisDevice;
}

- (void)addDevice:(AKDevice *)device {
    if (device && ![device.uniqueData isEqualToData:thisDevice.uniqueData]) {
        [mutableStore setObject:device forKey:device.UUIDString];
    }
}

- (NSArray<AKDevice *> *)devices {
    return mutableStore.allValues;
}

//- (AKDevice *)deviceForUniqueID:(NSData *)uniqueID {
//    return [mutableStore objectForKey:uniqueID];
//}

#pragma mark - Enumeration

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id _Nullable __unsafe_unretained [])buffer count:(NSUInteger)len {
    return [mutableStore.allValues countByEnumeratingWithState:state objects:buffer count:len];
}

- (NSEnumerator *)objectEnumerator {
    return mutableStore.objectEnumerator;
}

- (NSArray *)allKeys {
    return mutableStore.allKeys;
}

- (NSArray *)allValues {
    return mutableStore.allValues;
}

- (NSUInteger)count {
    return mutableStore.count;
}

- (NSArray *)allKeysForObject:(id)anObject {
    return [mutableStore allKeysForObject:anObject];
}



@end
