import 'dart:async';

import 'package:flutter/services.dart';

class AzureNotificationhubsFlutter {
  static const MethodChannel _channel =
      const MethodChannel('azure_notificationhubs_flutter');

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }
}
