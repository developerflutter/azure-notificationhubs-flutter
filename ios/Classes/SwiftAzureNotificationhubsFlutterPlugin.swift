import Flutter
import UIKit

public class SwiftAzureNotificationhubsFlutterPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "azure_notificationhubs_flutter", binaryMessenger: registrar.messenger())
    let instance = SwiftAzureNotificationhubsFlutterPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    result("iOS " + UIDevice.current.systemVersion)
  }
}
