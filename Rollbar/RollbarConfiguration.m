//
//  RollbarConfiguration.m
//  Rollbar
//
//  Created by Sergei Bezborodko on 3/21/14.
//  Copyright (c) 2014 Rollbar, Inc. All rights reserved.
//

#import "RollbarConfiguration.h"
#import "objc/runtime.h"
#import "NSJSONSerialization+Rollbar.h"
#import "RollbarTelemetry.h"

static NSString *NOTIFIER_NAME = @"rollbar-ios";
static NSString *NOTIFIER_VERSION = @"1.4.1";
static NSString *FRAMEWORK = @"ios";
static NSString *CONFIGURATION_FILENAME = @"rollbar.config";
static NSString *DEFAULT_ENDPOINT = @"https://api.rollbar.com/api/1/items/";

static NSString *configurationFilePath = nil;

@interface RollbarConfiguration () {
    NSMutableDictionary *customData;
}

@property (atomic, copy) NSString *personId;
@property (atomic, copy) NSString *personUsername;
@property (atomic, copy) NSString *personEmail;
@property (atomic, copy) NSString *serverHost;
@property (atomic, copy) NSString *serverRoot;
@property (atomic, copy) NSString *serverBranch;
@property (atomic, copy) NSString *serverCodeVersion;
@property (atomic, copy) NSString *notifierName;
@property (atomic, copy) NSString *notifierVersion;
@property (atomic, copy) NSString *framework;
@property (atomic) BOOL shouldCaptureConnectivity;
@property (atomic) CaptureIpType captureIp;
@property (atomic) NSUInteger maximumReportsPerMinute;

@end

@implementation RollbarConfiguration

+ (RollbarConfiguration*)configuration {
    return [[RollbarConfiguration alloc] init];
}

- (id)init {
    if (!configurationFilePath) {
        NSArray *paths =
            NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        NSString *cachesDirectory =
            [paths objectAtIndex:0];
        configurationFilePath =
            [cachesDirectory stringByAppendingPathComponent:CONFIGURATION_FILENAME];
    }

    if (self = [super init]) {
        customData = [NSMutableDictionary dictionaryWithCapacity:10];
        self.endpoint = DEFAULT_ENDPOINT;

        #ifdef DEBUG
        self.environment = @"development";
        #else
        self.environment = @"unspecified";
        #endif

        self.crashLevel = @"error";
        self.scrubFields = [NSMutableSet new];
        self.scrubWhitelistFields = [NSMutableSet new];
        self.telemetryViewInputsToScrub = [NSMutableSet new];

        self.notifierName = NOTIFIER_NAME;
        self.notifierVersion = NOTIFIER_VERSION;
        self.framework = FRAMEWORK;
        self.captureIp = CaptureIpFull;
        
        self.logLevel = @"info";

        _enabled = true;
        self.telemetryEnabled = false;
        self.maximumReportsPerMinute = 60;
        [self setCaptureLogAsTelemetryData:false];
        
        _httpProxyEnabled = NO;
        _httpProxy = @"";
        _httpProxyPort = [NSNumber numberWithInteger:0];

        _httpsProxyEnabled = NO;
        _httpsProxy = @"";
        _httpsProxyPort = [NSNumber numberWithInteger:0];

        [self save];
    }

    return self;
}

- (id)initWithLoadedConfiguration {
    self = [self init];

    NSData *data = [NSData dataWithContentsOfFile:configurationFilePath];
    if (data) {
        NSDictionary *config = [NSJSONSerialization JSONObjectWithData:data
                                                               options:0
                                                                 error:nil];

        if (!config) {
            return self;
        }

        for (NSString *propertyName in config.allKeys) {
            id value = [config objectForKey:propertyName];
            [self setValue:value forKey:propertyName];
        }
    }

    return self;
}

// Rollbar enabled flag:
@synthesize enabled = _enabled;
- (void)setEnabled:(BOOL)yesNo {
    _enabled = yesNo;
    [self save];
}
- (BOOL)enabled {
    return _enabled;
}

// HTTP Proxy settings
@synthesize  httpProxyEnabled = _httpProxyEnabled;
- (void)setHttpProxyEnabled:(BOOL)yesNo {
    _httpProxyEnabled = yesNo;
    [self save];
}
- (BOOL)httpProxyEnabled {
    return _httpProxyEnabled;
}

@synthesize  httpProxy = _httpProxy;
- (void)setHttpProxy:(NSString *)proxy {
    _httpProxy = proxy;
    [self save];
}
- (NSString *)httpProxy {
    return _httpProxy;
}

@synthesize httpProxyPort = _httpProxyPort;
- (void)setHttpProxyPort:(NSNumber *)port {
    _httpProxyPort = port;
    [self save];
}
- (NSNumber *)httpProxyPort {
    return _httpProxyPort;
}

// HTTPS Proxy settings
@synthesize httpsProxyEnabled = _httpsProxyEnabled;
- (void)setHttpsProxyEnabled:(BOOL)yesNo {
    _httpsProxyEnabled = yesNo;
    [self save];
}
- (BOOL)httpsProxyEnabled {
    return _httpsProxyEnabled;
}

@synthesize httpsProxy = _httpsProxy;
- (void)setHttpsProxy:(NSString *)proxy {
    _httpsProxy = proxy;
    [self save];
}
- (NSString *)httpsProxy {
    return _httpsProxy;
}

@synthesize httpsProxyPort = _httpsProxyPort;
- (void)setHttpsProxyPort:(NSNumber *)port {
    _httpsProxyPort = port;
    [self save];
}
- (NSNumber *)httpsProxyPort {
    return _httpsProxyPort;
}

// Telemetry enabled flag:
- (void)setTelemetryEnabled:(BOOL)yesNo {
    [RollbarTelemetry sharedInstance].enabled = yesNo;
    [self save];
}
- (BOOL)telemetryEnabled {
    return [RollbarTelemetry sharedInstance].enabled;
}

// Scrub Telemetry View Inputs:
- (void)setScrubViewInputsTelemetry:(BOOL)yesNo {
    [RollbarTelemetry sharedInstance].scrubViewInputs = yesNo;
    [self save];
}
- (BOOL)scrubViewInputsTelemetry {
    return [RollbarTelemetry sharedInstance].scrubViewInputs;
}

- (void)addTelemetryViewInputToScrub:(NSString *)input {
    [[RollbarTelemetry sharedInstance].viewInputsToScrub addObject:input];
    [self save];
}

- (void)removeTelemetryViewInputToScrub:(NSString *)input {
    [[RollbarTelemetry sharedInstance].viewInputsToScrub removeObject:input];
    [self save];
}


- (void)setRollbarLevel:(RollbarLevel)level {
    self.logLevel = RollbarStringFromLevel(level);
    
    [self save];
}

- (RollbarLevel)getRollbarLevel {
    return RollbarLevelFromString(self.logLevel);
}

- (void)setReportingRate:(NSUInteger)maximumReportsPerMinute {
    self.maximumReportsPerMinute = maximumReportsPerMinute;
    
    [self save];
}

- (void)setMaximumTelemetryData:(NSInteger)maximumTelemetryData {
    [[RollbarTelemetry sharedInstance] setDataLimit:maximumTelemetryData];
}

- (void)setPersonId:(NSString *)personId
           username:(NSString *)username
              email:(NSString *)email {
    self.personId = personId;
    self.personUsername = username;
    self.personEmail = email;

    [self save];
}

- (void)setServerHost:(NSString *)host
                 root:(NSString*)root
               branch:(NSString*)branch
          codeVersion:(NSString*)codeVersion {
    
    self.serverHost = host;
    self.serverRoot = root ?
        [root stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"/"]]
        : root;
    self.serverBranch = branch;
    self.serverCodeVersion = codeVersion;

    [self save];
}

- (void)setNotifierName:(NSString *)name
                version:(NSString *)version {
    
    self.notifierName = name ? name : NOTIFIER_NAME;
    self.notifierVersion = version ? version : NOTIFIER_VERSION;
    [self save];
}

- (void)setCodeFramework:(NSString *)framework {
    self.framework = framework ? framework : FRAMEWORK;
    [self save];
}

- (void)setPayloadModificationBlock:(void (^)(NSMutableDictionary*))payloadModificationBlock {
    self.payloadModification = payloadModificationBlock;
}

- (void)setCheckIgnoreBlock:(BOOL (^)(NSDictionary *))checkIgnoreBlock {
    self.checkIgnore = checkIgnoreBlock;
}

- (void)addScrubField:(NSString *)field {
    [self.scrubFields addObject:field];
}

- (void)removeScrubField:(NSString *)field {
    [self.scrubFields removeObject:field];
}

- (void)addScrubWhitelistField:(NSString *)field {
    [self.scrubWhitelistFields addObject:field];
}

- (void)removeScrubWhitelistField:(NSString *)field {
    [self.scrubWhitelistFields removeObject:field];
}

- (void)setCaptureLogAsTelemetryData:(BOOL)captureLog {
    [[RollbarTelemetry sharedInstance] setCaptureLog:captureLog];
}

- (void)setCaptureConnectivityAsTelemetryData:(BOOL)captureConnectivity {
    self.shouldCaptureConnectivity = captureConnectivity;
}

- (void)setCaptureIpType:(CaptureIpType)captureIp {
    self.captureIp = captureIp;
}

- (void)setValue:(id)value forUndefinedKey:(NSString *)key {
    if (value) {
        customData[key] = value;
    } else {
        [customData removeObjectForKey:key];
    }
    
    [self save];
}

- (id)valueForUndefinedKey:(NSString *)key {
    return customData[key];
}

// Add a key value observer for all properties so that this object
// is saved to disk every time a property is updated
- (void)_setRoot {
    isRootConfiguration = YES;
    
    for (NSString *propertyName in [self getProperties]) {
        if ([propertyName rangeOfString:@"person"].location == NSNotFound) {
            [self addObserver:self
                   forKeyPath:propertyName
                      options:NSKeyValueObservingOptionNew
                      context:nil];
        }
    }
}

// Convert this object's properties into json and save it to disk only if
// this is the root level configuration
- (void)save {
    if (isRootConfiguration) {
        NSMutableDictionary *config = [NSMutableDictionary dictionary];
        
        for (NSString *propertyName in [self getProperties]) {
            id value = [self valueForKey:propertyName];
            if (value) {
                [config setObject:value
                           forKey:propertyName];
            }
        }

        NSData *configJson = [NSJSONSerialization dataWithJSONObject:config
                                                             options:0
                                                               error:nil
                                                                safe:true];
        [configJson writeToFile:configurationFilePath
                     atomically:YES];
    }
}

- (void)observeValueForKeyPath:(NSString*)keyPath
                      ofObject:(id)object
                        change:(NSDictionary*)change
                       context:(void*)context {
    [self save];
}

- (NSArray*)getProperties {
    NSMutableArray *result = [NSMutableArray array];
    
    unsigned int outCount, i;
    objc_property_t *properties = class_copyPropertyList([self class], &outCount);
    
    for(i = 0; i < outCount; ++i) {
        objc_property_t property = properties[i];
        const char *propName = property_getName(property);
        if(propName) {
            NSString *propertyName = [NSString stringWithCString:propName
                                                        encoding:[NSString defaultCStringEncoding]];            
            [result addObject:propertyName];
        }
    }
    
    free(properties);
    
    [result addObjectsFromArray:customData.allKeys];
    
    return result;
}

- (NSDictionary *)customData {
    return [NSDictionary dictionaryWithDictionary:customData];
}

@end
