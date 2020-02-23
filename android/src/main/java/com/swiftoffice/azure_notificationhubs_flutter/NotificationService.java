package com.swiftoffice.azure_notificationhubs_flutter;

import com.google.firebase.messaging.FirebaseMessagingService;
import com.google.firebase.messaging.RemoteMessage;

import androidx.annotation.NonNull;
import android.R;
import android.content.res.Resources;
import android.graphics.BitmapFactory;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.graphics.drawable.Drawable;
import android.os.Build;

import androidx.core.app.NotificationCompat;
import androidx.localbroadcastmanager.content.LocalBroadcastManager;

import java.util.Date;
import java.util.HashMap;
import java.util.Map;

import static androidx.core.app.NotificationCompat.DEFAULT_ALL;
import static androidx.core.app.NotificationCompat.DEFAULT_SOUND;
import static androidx.core.app.NotificationCompat.DEFAULT_VIBRATE;
import static androidx.core.app.NotificationCompat.PRIORITY_HIGH;

public class NotificationService extends FirebaseMessagingService {
    public static final String NOTIFICATION_CHANNEL_ID = "azure_notificationhubs_flutter";
    public static final String NOTIFICATION_CHANNEL_NAME = "Azure Notification Hubs Channel";
    public static final String NOTIFICATION_CHANNEL_DESCRIPTION = "Azure Notification Hubs Channel";

    public static final String ACTION_REMOTE_MESSAGE =
            "com.swiftoffice.azure_notificationhubs_flutter.NOTIFICATION";
    public static final String ACTION_TOKEN = "com.swiftoffice.azure_notificationhubs_flutter.TOKEN";
    public static final String EXTRA_REMOTE_MESSAGE =
            "com.swiftoffice.azure_notificationhubs_flutter.NOTIFICATION_DATA";
    public static final String EXTRA_TOKEN = "com.swiftoffice.azure_notificationhubs_flutter.TOKEN_DATA";

    private NotificationManager mNotificationManager;
    private static Context ctx;

    @Override
    public void onMessageReceived(RemoteMessage message) {
        Map<String, Object> content = parseRemoteMessage(message);
        Intent intent = new Intent(ACTION_REMOTE_MESSAGE);
        intent.putExtra(EXTRA_REMOTE_MESSAGE, message);
        LocalBroadcastManager.getInstance(this).sendBroadcast(intent);
        sendNotification(content);
    }

    private void sendNotification(Map<String, Object> content) {
        ctx = getApplicationContext();
        Class mainActivity;
        try {
            String packageName = ctx.getPackageName();
            Intent launchIntent = ctx.getPackageManager().getLaunchIntentForPackage(packageName);
            String activityName = launchIntent.getComponent().getClassName();
            mainActivity = Class.forName(activityName);
            Intent intent = new Intent(ctx, mainActivity);
            intent.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP);
            mNotificationManager = (NotificationManager) ctx.getSystemService(Context.NOTIFICATION_SERVICE);
            PendingIntent contentIntent = PendingIntent.getActivity(ctx, 0,
                intent, PendingIntent.FLAG_ONE_SHOT);
            Resources resources = ctx.getPackageManager().getResourcesForApplication(packageName);
            int resId = resources.getIdentifier("ic_launcher", "mipmap", packageName);
            Drawable icon = resources.getDrawable(resId);
            NotificationCompat.Builder notificationBuilder = new NotificationCompat.Builder(
                    ctx,
                    NOTIFICATION_CHANNEL_ID)
                .setContentTitle(((Map) content.get("data")).get("title").toString())
                .setContentText(((Map) content.get("data")).get("body").toString())
                .setDefaults(DEFAULT_SOUND | DEFAULT_VIBRATE | DEFAULT_ALL)
                .setPriority(PRIORITY_HIGH)
                .setSmallIcon(R.drawable.ic_menu_manage)
                .setLargeIcon(BitmapFactory.decodeResource(resources, resId))
                .setContentIntent(contentIntent)
                .setBadgeIconType(NotificationCompat.BADGE_ICON_SMALL)
                .setAutoCancel(true);
            int m = (int)((new Date().getTime() / 1000L) % Integer.MAX_VALUE);
            mNotificationManager.notify(m, notificationBuilder.build());
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    public static void createChannelAndHandleNotifications(Context context) {
        ctx = context;
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            NotificationChannel channel = new NotificationChannel(
                NOTIFICATION_CHANNEL_ID,
                NOTIFICATION_CHANNEL_NAME,
                NotificationManager.IMPORTANCE_HIGH);
            channel.setDescription(NOTIFICATION_CHANNEL_DESCRIPTION);
            channel.enableVibration(true);
            NotificationManager notificationManager = context.getSystemService(NotificationManager.class);
            notificationManager.createNotificationChannel(channel);
        }
    }

    @NonNull
    public static Map<String, Object> parseRemoteMessage(RemoteMessage message) {
        Map<String, Object> content = new HashMap<>();
        content.put("data", message.getData());
        return content;
    }
}