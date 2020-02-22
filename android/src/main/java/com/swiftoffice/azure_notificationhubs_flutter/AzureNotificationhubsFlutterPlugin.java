package com.swiftoffice.azure_notificationhubs_flutter;

import androidx.annotation.NonNull;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import android.content.Context;
import android.content.Intent;

public class AzureNotificationhubsFlutterPlugin implements FlutterPlugin, MethodCallHandler {

    private static Context applicationContext;

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
        final MethodChannel channel = new MethodChannel(binding.getFlutterEngine().getDartExecutor(), "azure_notificationhubs_flutter");
        channel.setMethodCallHandler(new AzureNotificationhubsFlutterPlugin());
        applicationContext = binding.getApplicationContext();
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
        if (call.method.equals("configure")) {
            registerWithNotificationHubs();
            NotificationService.createChannelAndHandleNotifications(applicationContext);
        } else {
            result.notImplemented();
        }
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {}

    public void registerWithNotificationHubs() {
        Intent intent = new Intent(applicationContext, RegistrationIntentService.class);
        applicationContext.startService(intent);
    }


//    This static function is optional and equivalent to onAttachedToEngine. It supports the old
//    pre-Flutter-1.12 Android projects. You are encouraged to continue supporting
//    plugin registration via this function while apps migrate to use the new Android APIs
//    post-flutter-1.12 via https://flutter.dev/go/android-project-migration.
//
//    It is encouraged to share logic between onAttachedToEngine and registerWith to keep
//    them functionally equivalent. Only one of onAttachedToEngine or registerWith will be called
//    depending on the user's project. onAttachedToEngine or registerWith must both be defined
//    in the same class.
//    public static void registerWith(Registrar registrar) {
//        final MethodChannel channel = new MethodChannel(registrar.messenger(), "azure_notificationhubs_flutter");
//        channel.setMethodCallHandler(new AzureNotificationhubsFlutterPlugin());
//    }

}