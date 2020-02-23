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

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  [[UNUserNotificationCenter currentNotificationCenter] setDelegate:self];
  if (launchOptions != nil) {
      _launchNotification = launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey];
  }
  return YES;
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult result))completionHandler {
  NSLog(@"Received remote (silent) notification");
  if (_resumingFromBackground) {
    [_channel invokeMethod:@"onResume" arguments:userInfo];
  } else {
    [_channel invokeMethod:@"onMessage" arguments:userInfo];
  }
  completionHandler(UIBackgroundFetchResultNoData);
}

- (void) application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
  NSString *token = [self stringWithDeviceToken:deviceToken];
  NSString *deviceTag = [@"device:" stringByAppendingString:token];
  NSArray *tags = @[deviceTag];
  SBNotificationHub* hub = [self getNotificationHub];
  [hub registerNativeWithDeviceToken:deviceToken tags:tags completion:^(NSError* error) {
    if (error != nil) {
        NSLog(@"Error registering for notifications: %@", error);
    } else {
      [self->_channel invokeMethod:@"onToken" arguments:deviceTag];
    }
  }];
}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions options))completionHandler {
  if (_resumingFromBackground) {
    [_channel invokeMethod:@"onResume" arguments:notification.request.content.userInfo];
  } else {
    [_channel invokeMethod:@"onMessage" arguments:notification.request.content.userInfo];
  }
  completionHandler(UNAuthorizationOptionBadge | UNAuthorizationOptionSound);
}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void(^)(void))completionHandler {
  if (_resumingFromBackground) {
    [_channel invokeMethod:@"onResume" arguments:response.notification.request.content.userInfo];
  } else {
    [_channel invokeMethod:@"onMessage" arguments:response.notification.request.content.userInfo];
  }
  completionHandler();
}

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
  SBNotificationHub *hub = [self getNotificationHub];
  [hub unregisterNativeWithCompletion:^(NSError* error) {
    if (error != nil) {
      NSLog(@"Error unregistering for push: %@", error);
    }
  }];
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
  _resumingFromBackground = YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
  _resumingFromBackground = NO;
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
