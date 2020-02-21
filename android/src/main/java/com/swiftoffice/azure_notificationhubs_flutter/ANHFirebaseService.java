package com.swiftoffice.azure_notificationhubs_flutter;

import com.google.firebase.messaging.FirebaseMessagingService;
import com.google.firebase.messaging.RemoteMessage;

import android.graphics.BitmapFactory;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.os.Build;
import androidx.core.app.NotificationCompat;

import java.util.Date;
import java.util.Map;

import io.flutter.plugin.common.MethodChannel;

import static androidx.core.app.NotificationCompat.DEFAULT_SOUND;
import static androidx.core.app.NotificationCompat.DEFAULT_VIBRATE;
import static androidx.core.app.NotificationCompat.PRIORITY_HIGH;

public class ANHFirebaseService extends FirebaseMessagingService {
    public static final String NOTIFICATION_CHANNEL_ID = "azure_notificationhubs_flutter";
    public static final String NOTIFICATION_CHANNEL_NAME = "Azure Notification Hubs Channel";
    public static final String NOTIFICATION_CHANNEL_DESCRIPTION = "Azure Notification Hubs Channel";

    private NotificationManager mNotificationManager;
    private static Context ctx;
    private MethodChannel channel;

    @Override
    public void onMessageReceived(RemoteMessage remoteMessage) {
        Map nhObject = remoteMessage.getData();
        String nhTitle = null;
        String nhContent = "";
        if (nhObject.get("title") != null) {
            nhTitle = (String) nhObject.get("title");
        }
        if (nhObject.get("content") != null) {
            nhContent = (String) nhObject.get("content");
        }
        sendNotification(nhTitle, nhContent);
    }

    private void sendNotification(String title, String content) {
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
            NotificationCompat.Builder notificationBuilder = new NotificationCompat.Builder(
                    ctx,
                    NOTIFICATION_CHANNEL_ID)
                .setContentTitle(title)
                .setContentText(content)
                .setDefaults(DEFAULT_SOUND | DEFAULT_VIBRATE)
                .setPriority(PRIORITY_HIGH)
                .setSmallIcon(R.drawable.ic_launcher)
                .setLargeIcon(BitmapFactory.decodeResource(ctx.getResources(),
                            R.drawable.ic_launcher))
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
            NotificationManager notificationManager = context.getSystemService(NotificationManager.class);
            notificationManager.createNotificationChannel(channel);
        }
    }
}