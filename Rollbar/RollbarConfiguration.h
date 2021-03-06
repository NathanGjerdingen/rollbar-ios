//
//  RollbarConfiguration.h
//  Rollbar
//
//  Created by Sergei Bezborodko on 3/21/14.
//  Copyright (c) 2014 Rollbar, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RollbarLevel.h"

typedef NS_ENUM(NSUInteger, CaptureIpType) {
    CaptureIpFull,
    CaptureIpAnonymize,
    CaptureIpNone
};

@interface RollbarConfiguration : NSObject {
    // Stores whether this configuration is the root level
    // configuration used by the root level notifier
    BOOL isRootConfiguration;
}

+ (RollbarConfiguration*)configuration;

- (id)initWithLoadedConfiguration;

- (void)_setRoot;
- (void)save;

- (void)setReportingRate:(NSUInteger)maximumReportsPerMinute;
- (void)setRollbarLevel:(RollbarLevel)level;
- (RollbarLevel)getRollbarLevel;

- (void)setPersonId:(NSString*)personId username:(NSString*)username email:(NSString*)email;
- (void)setServerHost:(NSString *)host root:(NSString*)root branch:(NSString*)branch codeVersion:(NSString*)codeVersion;
- (void)setNotifierName:(NSString *)name version:(NSString *)version;
- (void)setCodeFramework:(NSString *)framework;

- (void)setPayloadModificationBlock:(void (^)(NSMutableDictionary*))payloadModificationBlock;
- (void)setCheckIgnoreBlock:(BOOL (^)(NSDictionary*))checkIgnoreBlock;

- (void)addScrubField:(NSString *)field;
- (void)removeScrubField:(NSString *)field;
- (void)addScrubWhitelistField:(NSString *)field;
- (void)removeScrubWhitelistField:(NSString *)field;

- (void)addTelemetryViewInputToScrub:(NSString *)input;
- (void)removeTelemetryViewInputToScrub:(NSString *)input;

- (void)setRequestId:(NSString*)requestId;
- (void)setCaptureIpType:(CaptureIpType)captureIp;

- (void)setMaximumTelemetryData:(NSInteger)maximumTelemetryData;
- (void)setCaptureLogAsTelemetryData:(BOOL)captureLog;
- (void)setCaptureConnectivityAsTelemetryData:(BOOL)captureConnectivity;

- (NSDictionary *)customData;

@property (readwrite, atomic) BOOL enabled;
@property (atomic, copy) NSString *accessToken;
@property (atomic, copy) NSString *environment;
@property (atomic, copy) NSString *endpoint;

// HTTP Proxy:
@property (readwrite, atomic) BOOL httpProxyEnabled;
@property (readwrite, atomic, copy) NSString *httpProxy;
@property (readwrite, atomic) NSNumber *httpProxyPort;

// HTTPS Proxy:
@property (readwrite, atomic) BOOL httpsProxyEnabled;
@property (readwrite, atomic, copy) NSString *httpsProxy;
@property (readwrite, atomic) NSNumber *httpsProxyPort;

@property (atomic, copy) NSString *crashLevel;
@property (atomic, copy) NSString *logLevel;
@property (readonly, atomic) NSUInteger maximumReportsPerMinute;
@property (readonly, atomic) BOOL shouldCaptureConnectivity;

@property (readonly, atomic, copy) NSString *personId;
@property (readonly, atomic, copy) NSString *personUsername;
@property (readonly, atomic, copy) NSString *personEmail;

@property (readwrite, atomic) BOOL telemetryEnabled;
@property (readwrite, atomic) BOOL scrubViewInputsTelemetry;
@property (atomic, retain) NSMutableSet *telemetryViewInputsToScrub;

// Modify payload
@property (atomic, copy) void (^payloadModification)(NSMutableDictionary *payload);

// Decides whether or not to send payload. Returns true to ignore, false to send
@property (atomic, copy) BOOL (^checkIgnore)(NSDictionary *payload);

// Fields to scrub from the payload
@property (atomic, retain) NSMutableSet *scrubFields;

// Fields to not scrub from the payload even if they mention among scrubFields:
@property (atomic, retain) NSMutableSet *scrubWhitelistFields;

/*** Optional ***/

// ID to link request between client/server
@property (atomic, copy) NSString *requestId;

@property (readonly, atomic) CaptureIpType captureIp;

// Data about the server
@property (readonly, atomic, copy) NSString *serverHost;
@property (readonly, atomic, copy) NSString *serverRoot;
@property (readonly, atomic, copy) NSString *serverBranch;
@property (readonly, atomic, copy) NSString *serverCodeVersion;

@property (readonly, atomic, copy) NSString *notifierName;
@property (readonly, atomic, copy) NSString *notifierVersion;
@property (readonly, atomic, copy) NSString *framework;

@end
