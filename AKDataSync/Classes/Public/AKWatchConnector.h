//
//  AKWatchConnector.h
//  AKDataSync
//
//  Created by Stanislav Pletnev on 11.06.16.
//  Copyright © 2016 Anobisoft. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WatchConnectivity/WatchConnectivity.h>
#import <AnobiKit/AKTypes.h>


@protocol AKWatchConnectorDelegate;

#ifndef AKWatchConnector_h
#define AKWatchConnector_h

NS_ASSUME_NONNULL_BEGIN

@interface AKWatchConnector : AKSingleton <WCSessionDelegate> {
    @protected BOOL sessionActivated;
}

@property (nonatomic, weak, nullable) id <AKWatchConnectorDelegate> delegate;
@property (nonatomic, assign, readonly) BOOL ready;

@end

@protocol AKWatchConnectorDelegate <NSObject>
@required


@optional
- (void)watchConnector:(AKWatchConnector *)connector statusChanged:(BOOL)ready __WATCHOS_UNAVAILABLE;

/** ------------------------- Interactive Messaging ------------------------- */

- (void)sessionReachabilityDidChange:(BOOL)reachable;

- (void)watchConnector:(AKWatchConnector *)connector didReceiveMessage:(NSDictionary<NSString *, id> *)message;
- (void)watchConnector:(AKWatchConnector *)connector didReceiveMessage:(NSDictionary<NSString *, id> *)message replyHandler:(void(^)(NSDictionary<NSString *, id> *replyMessage))replyHandler;
- (void)watchConnector:(AKWatchConnector *)connector didReceiveMessageData:(NSData *)messageData;
- (void)watchConnector:(AKWatchConnector *)connector didReceiveMessageData:(NSData *)messageData replyHandler:(void(^)(NSData *replyMessageData))replyHandler;

/** -------------------------- Background Transfers ------------------------- */
- (void)watchConnector:(AKWatchConnector *)connector didReceiveApplicationContext:(NSDictionary<NSString *, id> *)applicationContext;
- (void)watchConnector:(AKWatchConnector *)connector didFinishUserInfoTransfer:(WCSessionUserInfoTransfer *)userInfoTransfer error:(nullable NSError *)error;
- (void)watchConnector:(AKWatchConnector *)connector didReceiveUserInfo:(NSDictionary<NSString *, id> *)userInfo;
- (void)watchConnector:(AKWatchConnector *)connector didFinishFileTransfer:(WCSessionFileTransfer *)fileTransfer error:(nullable NSError *)error;
- (void)watchConnector:(AKWatchConnector *)connector didReceiveFile:(WCSessionFile *)file;

NS_ASSUME_NONNULL_END

@end

#endif
