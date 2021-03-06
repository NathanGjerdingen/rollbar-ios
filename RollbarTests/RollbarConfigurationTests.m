//
//  RollbarConfigurationTest.m
//  RollbarTests
//
//  Created by Ben Wong on 12/2/17.
//  Copyright © 2017 Rollbar. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "Rollbar.h"
#import "RollbarTestUtil.h"

@interface RollbarConfigurationTests : XCTestCase

@end

@implementation RollbarConfigurationTests

- (void)setUp {
    [super setUp];
    RollbarClearLogFile();
    if (!Rollbar.currentConfiguration) {
        [Rollbar initWithAccessToken:@""];
    }
}

- (void)tearDown {
    [Rollbar updateConfiguration:[RollbarConfiguration configuration] isRoot:true];
    [super tearDown];
}

- (void)testScrubWhitelistFields {
    NSString *scrubedContent = @"*****";
    NSArray *keys = @[@"client.ios.app_name", @"client.ios.ios_version", @"body.message.body"];
    
    // define scrub fields:
    for (NSString *key in keys) {
        [Rollbar.currentConfiguration addScrubField:key];
    }
    [Rollbar debug:@"test"];
    [NSThread sleepForTimeInterval:3.0f];
    
    // verify the fields were scrubbed:
    NSArray *logItems = RollbarReadLogItemFromFile();
    for (NSString *key in keys) {
        NSString *content = [logItems[0] valueForKeyPath:key];
        XCTAssertTrue([content isEqualToString:scrubedContent],
                      @"%@ is %@, should be %@",
                      key,
                      content,
                      scrubedContent
                      );
    }
    
    RollbarClearLogFile();
    [NSThread sleepForTimeInterval:3.0f];
    
    // define scrub whitelist fields (the same as the scrub fields - to counterbalance them):
    for (NSString *key in keys) {
        [Rollbar.currentConfiguration addScrubWhitelistField:key];
    }
    [Rollbar debug:@"test"];
    [NSThread sleepForTimeInterval:3.0f];
    
    // verify the fields were not scrubbed:
    logItems = RollbarReadLogItemFromFile();
    for (NSString *key in keys) {
        NSString *content = [logItems[0] valueForKeyPath:key];
        XCTAssertTrue(![content isEqualToString:scrubedContent],
                      @"%@ is %@, should not be %@",
                      key,
                      content,
                      scrubedContent
                      );
    }
}

- (void)testTelemetryEnabled {
    RollbarClearLogFile();
    [NSThread sleepForTimeInterval:3.0f];
    
    BOOL expectedFlag = NO;
    Rollbar.currentConfiguration.telemetryEnabled = expectedFlag;
    XCTAssertTrue(RollbarTelemetry.sharedInstance.enabled == expectedFlag,
                  @"RollbarTelemetry.sharedInstance.enabled is expected to be NO."
                  );
    int max = 5;
    int testCount = max;
    for (int i=0; i<testCount; i++) {
        [Rollbar recordErrorEventForLevel:RollbarDebug message:@"test"];
    }
    [Rollbar.currentConfiguration setMaximumTelemetryData:max];
    [NSThread sleepForTimeInterval:3.0f];
    NSArray *telemetryCollection = [[RollbarTelemetry sharedInstance] getAllData];
    XCTAssertTrue(telemetryCollection.count == 0,
                  @"Telemetry count is expected to be %i. Actual is %lu",
                  0,
                  telemetryCollection.count
                  );

    expectedFlag = YES;
    Rollbar.currentConfiguration.telemetryEnabled = expectedFlag;
    XCTAssertTrue(RollbarTelemetry.sharedInstance.enabled == expectedFlag,
                  @"RollbarTelemetry.sharedInstance.enabled is expected to be YES."
                  );
    for (int i=0; i<testCount; i++) {
        [Rollbar recordErrorEventForLevel:RollbarDebug message:@"test"];
    }
    [Rollbar.currentConfiguration setMaximumTelemetryData:max];
    [NSThread sleepForTimeInterval:3.0f];
    telemetryCollection = [[RollbarTelemetry sharedInstance] getAllData];
    XCTAssertTrue(telemetryCollection.count == max,
                  @"Telemetry count is expected to be %i. Actual is %lu",
                  max,
                  telemetryCollection.count
                  );
    
    [RollbarTelemetry.sharedInstance clearAllData];
}

- (void)testScrubViewInputsTelemetryConfig {

    BOOL expectedFlag = NO;
    Rollbar.currentConfiguration.scrubViewInputsTelemetry = expectedFlag;
    XCTAssertTrue(RollbarTelemetry.sharedInstance.scrubViewInputs == expectedFlag,
                  @"RollbarTelemetry.sharedInstance.scrubViewInputs is expected to be NO."
                  );
    expectedFlag = YES;
    Rollbar.currentConfiguration.scrubViewInputsTelemetry = expectedFlag;
    XCTAssertTrue(RollbarTelemetry.sharedInstance.scrubViewInputs == expectedFlag,
                  @"RollbarTelemetry.sharedInstance.scrubViewInputs is expected to be YES."
                  );
}

- (void)testViewInputTelemetrScrubFieldsConfig {

    NSString *element1 = @"password";
    NSString *element2 = @"pin";
    
    [Rollbar.currentConfiguration addTelemetryViewInputToScrub:element1];
    [Rollbar.currentConfiguration addTelemetryViewInputToScrub:element2];

    XCTAssertTrue(RollbarTelemetry.sharedInstance.viewInputsToScrub.count == 2,
                  @"RollbarTelemetry.sharedInstance.viewInputsToScrub is expected to count = 2"
                  );
    XCTAssertTrue([RollbarTelemetry.sharedInstance.viewInputsToScrub containsObject:element1],
                  @"RollbarTelemetry.sharedInstance.viewInputsToScrub is expected to conatin @%@",
                  element1
                  );
    XCTAssertTrue([RollbarTelemetry.sharedInstance.viewInputsToScrub containsObject:element2],
                  @"RollbarTelemetry.sharedInstance.viewInputsToScrub is expected to conatin @%@",
                  element2
                  );
    
    [Rollbar.currentConfiguration removeTelemetryViewInputToScrub:element1];
    [Rollbar.currentConfiguration removeTelemetryViewInputToScrub:element2];
    
    XCTAssertTrue(RollbarTelemetry.sharedInstance.viewInputsToScrub.count == 0,
                  @"RollbarTelemetry.sharedInstance.viewInputsToScrub is expected to count = 0"
                  );
}

- (void)testEnabled {
    
    RollbarClearLogFile();
    [NSThread sleepForTimeInterval:3.0f];
    
    Rollbar.currentConfiguration.enabled = NO;
    [Rollbar debug:@"Test1"];
    NSArray *logItems = RollbarReadLogItemFromFile();
    XCTAssertTrue(logItems.count == 0,
                  @"logItems count is expected to be 0. Actual value is %lu",
                  logItems.count
                  );

    Rollbar.currentConfiguration.enabled = YES;
    [Rollbar debug:@"Test2"];
    [NSThread sleepForTimeInterval:3.0f];
    logItems = RollbarReadLogItemFromFile();
    XCTAssertTrue(logItems.count == 1,
                  @"logItems count is expected to be 1. Actual value is %lu",
                  logItems.count
                  );

    Rollbar.currentConfiguration.enabled = NO;
    [Rollbar debug:@"Test3"];
    logItems = RollbarReadLogItemFromFile();
    XCTAssertTrue(logItems.count == 1,
                  @"logItems count is expected to be 1. Actual value is %lu",
                  logItems.count
                  );
    
    RollbarClearLogFile();
}

- (void)testMaximumTelemetryData {
    
    Rollbar.currentConfiguration.telemetryEnabled = YES;

    int testCount = 10;
    int max = 5;
    for (int i=0; i<testCount; i++) {
        [Rollbar recordErrorEventForLevel:RollbarDebug message:@"test"];
    }
    [Rollbar.currentConfiguration setMaximumTelemetryData:max];
    [Rollbar debug:@"Test"];
    [NSThread sleepForTimeInterval:3.0f];
    NSArray *logItems = RollbarReadLogItemFromFile();
    NSDictionary *item = logItems[0];
    NSArray *telemetryData = [item valueForKeyPath:@"body.telemetry"];
    XCTAssertTrue(telemetryData.count == max,
                  @"Telemetry item count is %lu, should be %lu",
                  telemetryData.count,
                  (long)max
                  );
}

- (void)testCheckIgnore {
    [Rollbar debug:@"Don't ignore this"];
    [NSThread sleepForTimeInterval:3.0f];
    NSArray *logItems = RollbarReadLogItemFromFile();
    XCTAssertTrue(logItems.count == 1, @"Log item count should be 1");

    [Rollbar.currentConfiguration setCheckIgnore:^BOOL(NSDictionary *payload) {
        return true;
    }];
    [Rollbar debug:@"Ignore this"];
    logItems = RollbarReadLogItemFromFile();
    XCTAssertTrue(logItems.count == 1, @"Log item count should be 1");
}

- (void)testServerData {
    NSString *host = @"testHost";
    NSString *root = @"testRoot";
    NSString *branch = @"testBranch";
    NSString *codeVersion = @"testCodeVersion";
    [Rollbar.currentConfiguration setServerHost:host
                                           root:root
                                         branch:branch
                                    codeVersion:codeVersion
     ];
    [Rollbar debug:@"test"];

    [NSThread sleepForTimeInterval:3.0f];

    NSArray *logItems = RollbarReadLogItemFromFile();
    NSDictionary *item = logItems[0];
    NSDictionary *server = item[@"server"];

    XCTAssertTrue([host isEqualToString:server[@"host"]],
                  @"host is %@, should be %@",
                  server[@"host"],
                  host
                  );
    XCTAssertTrue([root isEqualToString:server[@"root"]],
                  @"root is %@, should be %@",
                  server[@"root"],
                  root
                  );
    XCTAssertTrue([branch isEqualToString:server[@"branch"]],
                  @"branch is %@, should be %@",
                  server[@"branch"],
                  branch
                  );
    XCTAssertTrue([codeVersion isEqualToString:server[@"code_version"]],
                  @"code_version is %@, should be %@",
                  server[@"code_version"],
                  codeVersion
                  );
}

- (void)testPayloadModification {
    NSString *newMsg = @"Modified message";
    [Rollbar.currentConfiguration setPayloadModification:^(NSMutableDictionary *payload) {
        [payload setValue:newMsg forKeyPath:@"body.message.body"];
        [payload setValue:newMsg forKeyPath:@"body.message.body2"];
    }];
    [Rollbar debug:@"test"];

    [NSThread sleepForTimeInterval:3.0f];

    NSArray *logItems = RollbarReadLogItemFromFile();
    NSString *msg1 = [logItems[0] valueForKeyPath:@"body.message.body"];
    NSString *msg2 = [logItems[0] valueForKeyPath:@"body.message.body2"];

    XCTAssertTrue([msg1 isEqualToString:newMsg],
                  @"body.message.body is %@, should be %@",
                  msg1,
                  newMsg
                  );
    XCTAssertTrue([msg1 isEqualToString:newMsg],
                  @"body.message.body2 is %@, should be %@",
                  msg2,
                  newMsg
                  );
}

- (void)testScrubField {
    NSString *scrubedContent = @"*****";
    NSArray *keys = @[@"client.ios.app_name", @"client.ios.ios_version", @"body.message.body"];

    for (NSString *key in keys) {
        [Rollbar.currentConfiguration addScrubField:key];
    }
    [Rollbar debug:@"test"];

    [NSThread sleepForTimeInterval:3.0f];

    NSArray *logItems = RollbarReadLogItemFromFile();
    for (NSString *key in keys) {
        NSString *content = [logItems[0] valueForKeyPath:key];
        XCTAssertTrue([content isEqualToString:scrubedContent],
                      @"%@ is %@, should be %@",
                      key,
                      content,
                      scrubedContent
                      );
    }
}

- (void)testLogTelemetryAutoCapture {
    NSString *logMsg = @"log-message-testing";
    [[RollbarTelemetry sharedInstance] clearAllData];
    Rollbar.currentConfiguration.telemetryEnabled = YES;
    [Rollbar.currentConfiguration setCaptureLogAsTelemetryData:true];
    NSLog(logMsg);
    [Rollbar debug:@"test"];
    
    [NSThread sleepForTimeInterval:3.0f];

    NSArray *logItems = RollbarReadLogItemFromFile();
    NSArray *telemetryData = [logItems[0] valueForKeyPath:@"body.telemetry"];
    NSString *telemetryMsg = [telemetryData[0] valueForKeyPath:@"body.message"];
    XCTAssertTrue([logMsg isEqualToString:telemetryMsg],
                  @"body.telemetry[0].body.message is %@, should be %@",
                  telemetryMsg,
                  logMsg
                  );
}

@end
