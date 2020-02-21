package com.swiftoffice.azure_notificationhubs_flutter;

import android.content.pm.ApplicationInfo;
import android.content.pm.PackageManager;
import android.os.Bundle;
import android.content.Context;

public class NotificationSettings {
    private String HubName;
    private String HubConnectionString;

    public NotificationSettings(Context context) {
        try {
            ApplicationInfo app = context.getPackageManager().getApplicationInfo(context.getPackageName(), PackageManager.GET_META_DATA);
            Bundle bundle = app.metaData;
            HubName = bundle.getString("NotificationHubName");
            HubConnectionString = bundle.getString("NotificationHubConnectionString");
        } catch(PackageManager.NameNotFoundException e) {
        }
    }

    public String getHubName() { return HubName; }
    public String getHubConnectionString() { return HubConnectionString; }

}