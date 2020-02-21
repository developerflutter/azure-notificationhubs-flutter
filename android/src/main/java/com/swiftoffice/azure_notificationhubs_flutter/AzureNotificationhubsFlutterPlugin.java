package com.swiftoffice.azure_notificationhubs_flutter;

import androidx.annotation.NonNull;
import androidx.core.app.NotificationCompat;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;

import com.google.android.gms.common.ConnectionResult;
import com.google.android.gms.common.GoogleApiAvailability;
import com.google.firebase.messaging.FirebaseMessagingService;
import com.google.firebase.messaging.RemoteMessage;

import android.app.Activity;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.graphics.BitmapFactory;
import android.os.Build;
import android.util.Log;
import android.content.Context;
import android.content.Intent;

import java.util.Date;
import java.util.Map;

import static androidx.core.app.NotificationCompat.DEFAULT_SOUND;
import static androidx.core.app.NotificationCompat.DEFAULT_VIBRATE;
import static androidx.core.app.NotificationCompat.PRIORITY_HIGH;

/** AzureNotificationhubsFlutterPlugin */
public class AzureNotificationhubsFlutterPlugin implements FlutterPlugin, MethodCallHandler, ActivityAware {

    private static Activity mainActivity;
    // private static Boolean isVisible = false;
    private static final String TAG = "ANH_FLUTTER";
    private static final int PLAY_SERVICES_RESOLUTION_REQUEST = 9000;
    private static Context applicationContext;

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
        final MethodChannel channel = new MethodChannel(binding.getFlutterEngine().getDartExecutor(), "azure_notificationhubs_flutter");
        channel.setMethodCallHandler(new AzureNotificationhubsFlutterPlugin());
        applicationContext = binding.getApplicationContext();
    }

    // This static function is optional and equivalent to onAttachedToEngine. It supports the old
    // pre-Flutter-1.12 Android projects. You are encouraged to continue supporting
    // plugin registration via this function while apps migrate to use the new Android APIs
    // post-flutter-1.12 via https://flutter.dev/go/android-project-migration.
    //
    // It is encouraged to share logic between onAttachedToEngine and registerWith to keep
    // them functionally equivalent. Only one of onAttachedToEngine or registerWith will be called
    // depending on the user's project. onAttachedToEngine or registerWith must both be defined
    // in the same class.
    public static void registerWith(Registrar registrar) {
        final MethodChannel channel = new MethodChannel(registrar.messenger(), "azure_notificationhubs_flutter");
        channel.setMethodCallHandler(new AzureNotificationhubsFlutterPlugin());
        setActivity(registrar.activity());
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
        if (call.method.equals("configure")) {
            registerWithNotificationHubs();
            ANHFirebaseService.createChannelAndHandleNotifications(applicationContext, mainActivity);
        } else {
            result.notImplemented();
        }
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {}

    private static void setActivity(Activity flutterActivity) {
        mainActivity = flutterActivity;
    }

    /**
     * Check the device to make sure it has the Google Play Services APK. If
     * it doesn't, display a dialog box that enables  users to download the APK from
     * the Google Play Store or enable it in the device's system settings.
     */

    private boolean checkPlayServices() {
        // GoogleApiAvailability apiAvailability = GoogleApiAvailability.getInstance();
        // int resultCode = apiAvailability.isGooglePlayServicesAvailable(applicationContext);
        // if (resultCode != ConnectionResult.SUCCESS) {
        //     return false;
        // }
        return true;
    }

    public void registerWithNotificationHubs() {
        if (checkPlayServices()) {
            // Start IntentService to register this application with FCM.
            if (mainActivity == null) {
                Log.d(TAG, "MAIN ACTIVITY NULL");
            } else {
                Log.d(TAG, "ALL GOOD, LETS GO!");
                Intent intent = new Intent(applicationContext, RegistrationIntentService.class);
                applicationContext.startService(intent);
            }
        }
    }

    //    ACTIVITY

    @Override
    public void onAttachedToActivity(ActivityPluginBinding binding) {
        // TODO: your plugin is now attached to an Activity
        mainActivity = binding.getActivity();
    }

    @Override
    public void onDetachedFromActivityForConfigChanges() {
        // TODO: the Activity your plugin was attached to was destroyed to change configuration.
        // This call will be followed by onReattachedToActivityForConfigChanges().
        this.mainActivity = null;
    }

    @Override
    public void onReattachedToActivityForConfigChanges(ActivityPluginBinding binding) {
        // TODO: your plugin is now attached to a new Activity after a configuration change.
        mainActivity = binding.getActivity();
    }

    @Override
    public void onDetachedFromActivity() {
        // TODO: your plugin is no longer associated with an Activity. Clean up references.
        this.mainActivity = null;
    }
}