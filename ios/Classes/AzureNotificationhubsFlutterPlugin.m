#import "AzureNotificationhubsFlutterPlugin.h"
#import "Constants.h"

@implementation AzureNotificationhubsFlutterPlugin {
  FlutterMethodChannel *_channel;
  NSDictionary *_launchNotification;
  BOOL _resumingFromBackground;
}

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  FlutterMethodChannel* channel = [FlutterMethodChannel
      methodChannelWithName:@"azure_notificationhubs_flutter"
            binaryMessenger:[registrar messenger]];
  AzureNotificationhubsFlutterPlugin* instance = [[AzureNotificationhubsFlutterPlugin alloc] initWithChannel:channel];
  [registrar addApplicationDelegate:instance];
  [registrar addMethodCallDelegate:instance channel:channel];
}

- (instancetype)initWithChannel:(FlutterMethodChannel *)channel {
  self = [super init];
  if (self) {
    _channel = channel;
    _resumingFromBackground = NO;
  }
  return self;
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
  if ([@"configure" isEqualToString:call.method]) {
    [self handleRegister];
    if (_launchNotification != nil) {
      [_channel invokeMethod:@"onLaunch" arguments:_launchNotification];
    }
    result(nil);
  } else {
    result(FlutterMethodNotImplemented);
  }
}

////////////////////////////////////////////////////////////////////////////////
//
// UIApplicationDelegate methods
//
////////////////////////////////////////////////////////////////////////////////

//
// Tells the delegate that the launch process is almost done and the app is almost ready to run.
//
// https://developer.apple.com/documentation/uikit/uiapplicationdelegate/1622921-application?language=objc
//
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    //
    // It is important to always set the UNUserNotificationCenterDelegate when the app launches. Otherwise the app
    // may miss some notifications.
    //
    [[UNUserNotificationCenter currentNotificationCenter] setDelegate:self];
    if (launchOptions != nil) {
        _launchNotification = launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey];
    }
    // Check if user tapped on notification to launch app
//    NSDictionary *notification = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
//    if (notification) {
//        NSLog(@"app received notification from remote%@",notification);
//        [_channel invokeMethod:@"onLaunch" arguments:notification];
//    }
    return YES;
}

//
// Tells the app that a remote notification arrived that indicates there is data to be fetched.
//
// https://developer.apple.com/documentation/uikit/uiapplicationdelegate/1623013-application?language=objc
//
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult result))completionHandler {
    NSLog(@"Received remote (silent) notification");
    [self logNotificationDetails:userInfo];
    
    //
    // Let the system know the silent notification has been processed.
    //
    if (_resumingFromBackground) {
      [_channel invokeMethod:@"onResume" arguments:userInfo];
    } else {
      [_channel invokeMethod:@"onMessage" arguments:userInfo];
    }
  
    completionHandler(UIBackgroundFetchResultNoData);
}

//
// Tells the delegate that the app successfully registered with Apple Push Notification service (APNs).
//
// https://developer.apple.com/documentation/uikit/uiapplicationdelegate/1622958-application?language=objc
//
- (void) application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    NSString *token = [self stringWithDeviceToken:deviceToken];

    // Load and parse stored tags
    // NSString *unparsedTags = [[NSUserDefaults standardUserDefaults] valueForKey:NHUserDefaultTags];
    // if (unparsedTags.length > 0) {
    //     NSArray *tagsArray = [unparsedTags componentsSeparatedByString: @","];
    //     [tags addObjectsFromArray:tagsArray];
    // }

    // Add device to tags
    NSString *deviceTag = [@"device:" stringByAppendingString:token];
    NSArray *tags = @[deviceTag];
    NSLog(@"didRegisterForRemoteNotifications: %@", token);
    //
    // Register the device with the Notification Hub.
    // If the device has not already been registered, this will create the registration.
    // If the device has already been registered, this will update the existing registration.
    //
    SBNotificationHub* hub = [self getNotificationHub];
    [hub registerNativeWithDeviceToken:deviceToken tags:tags completion:^(NSError* error) {
        if (error != nil) {
            NSLog(@"Error registering for notifications: %@", error);
        } else {
          NSDictionary *args = [[NSDictionary alloc] initWithObjectsAndKeys:deviceTag, @"token", nil];
          [self->_channel invokeMethod:@"onToken" arguments:args];
        }
    }];
}

////////////////////////////////////////////////////////////////////////////////
//
// UNUserNotificationCenterDelegate methods
//
////////////////////////////////////////////////////////////////////////////////

//
// Asks the delegate how to handle a notification that arrived while the app was running in the foreground.
//
// https://developer.apple.com/documentation/usernotifications/unusernotificationcenterdelegate/1649518-usernotificationcenter?language=objc
//
- (void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions options))completionHandler {
    NSLog(@"Received notification while the application is in the foreground");
    //
    // The system calls this delegate method when the app is in the foreground. This allows the app to handle the notification
    // itself (and potentially modify the default system behavior).
    //
    
    //
    // Handle the notification by displaying custom UI.
    //
    [self showNotification:notification.request.content.userInfo];
    
    //
    // Use 'options' to specify which default behaviors to enable.
    // https://developer.apple.com/documentation/usernotifications/unnotificationpresentationoptions?language=objc
    // - UNAuthorizationOptionBadge: Apply the notification's badge value to the app’s icon.
    // - UNAuthorizationOptionSound: Play the sound associated with the notification.
    // - UNAuthorizationOptionAlert: Display the alert using the content provided by the notification.
    //
    // In this case, do not pass UNAuthorizationOptionAlert because the notification was handled by the app.
    //
    if (_resumingFromBackground) {
      [_channel invokeMethod:@"onResume" arguments:notification.request.content.userInfo];
    } else {
      [_channel invokeMethod:@"onMessage" arguments:notification.request.content.userInfo];
    }
    completionHandler(UNAuthorizationOptionBadge | UNAuthorizationOptionSound);
}

//
// Asks the delegate to process the user's response to a delivered notification.
//
// https://developer.apple.com/documentation/usernotifications/unusernotificationcenterdelegate/1649501-usernotificationcenter?language=objc
//
- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void(^)(void))completionHandler {
    NSLog(@"Received notification while the application is in the background");
    //
    // The system calls this delegate method when the user taps or responds to the system notification.
    //
    
    //
    // Handle the notification response by displaying custom UI
    //
    [self showNotification:response.notification.request.content.userInfo];
    
    //
    // Let the system know the response has been processed.
    //
    if (_resumingFromBackground) {
      [_channel invokeMethod:@"onResume" arguments:response.notification.request.content.userInfo];
    } else {
      [_channel invokeMethod:@"onMessage" arguments:response.notification.request.content.userInfo];
    }
    completionHandler();
}

////////////////////////////////////////////////////////////////////////////////
//
// App logic and helpers
//
////////////////////////////////////////////////////////////////////////////////

- (SBNotificationHub *)getNotificationHub {
    NSString *hubName = [[NSBundle mainBundle] objectForInfoDictionaryKey:NHInfoHubName];
    NSString *connectionString = [[NSBundle mainBundle] objectForInfoDictionaryKey:NHInfoConnectionString];
    
    return [[SBNotificationHub alloc] initWithConnectionString:connectionString notificationHubPath:hubName];
}

- (void)handleRegister {
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];

    UNAuthorizationOptions options =  UNAuthorizationOptionAlert | UNAuthorizationOptionSound | UNAuthorizationOptionBadge;
    [center requestAuthorizationWithOptions:(options) completionHandler:^(BOOL granted, NSError * _Nullable error) {
        if (error != nil) {
            NSLog(@"Error requesting for authorization: %@", error);
        }
    }];
    [[UIApplication sharedApplication] registerForRemoteNotifications];
}

- (void)handleUnregister {
    //
    // Unregister the device with the Notification Hub.
    //
    SBNotificationHub *hub = [self getNotificationHub];
    [hub unregisterNativeWithCompletion:^(NSError* error) {
        if (error != nil) {
            NSLog(@"Error unregistering for push: %@", error);
        } else {
            // [self showAlert:@"Unregistered" withTitle:@"Registration Status"];
        }
    }];
}

- (void)logNotificationDetails:(NSDictionary *)userInfo {
    if (userInfo != nil) {
        UIApplicationState state = [UIApplication sharedApplication].applicationState;
        BOOL background = state != UIApplicationStateActive;
        NSLog(@"Received %@notification: \n%@", background ? @"(background) " : @"", userInfo);
    }
}

- (void)showNotification:(NSDictionary *)userInfo {
    [self logNotificationDetails:userInfo];
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
  _resumingFromBackground = YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
  _resumingFromBackground = NO;
  // Clears push notifications from the notification center, with the
  // side effect of resetting the badge count. We need to clear notifications
  // because otherwise the user could tap notifications in the notification
  // center while the app is in the foreground, and we wouldn't be able to
  // distinguish that case from the case where a message came in and the
  // user dismissed the notification center without tapping anything.
  // TODO(goderbauer): Revisit this behavior once we provide an API for managing
  // the badge number, or if we add support for running Dart in the background.
  // Setting badgeNumber to 0 is a no-op (= notifications will not be cleared)
  // if it is already 0,
  // therefore the next line is setting it to 1 first before clearing it again
  // to remove all
  // notifications.
  application.applicationIconBadgeNumber = 1;
  application.applicationIconBadgeNumber = 0;
}

- (NSString *)stringWithDeviceToken:(NSData *)deviceToken {
    const char *data = [deviceToken bytes];
    NSMutableString *token = [NSMutableString string];

    for (NSUInteger i = 0; i < [deviceToken length]; i++) {
        [token appendFormat:@"%02.2hhX", data[i]];
    }

    return [token copy];
}

@end
