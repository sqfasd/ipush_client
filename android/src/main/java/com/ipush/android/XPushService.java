package com.ipush.android;

import android.app.Service;
import android.content.Intent;
import android.os.IBinder;

public class XPushService extends Service {
    private static final String TAG = "XPushService";
    private boolean mIsRunning = false;
    private XPushManager mPushManager = null;

    public XPushService() {
    }

    @Override
    public IBinder onBind(Intent intent) {
        return null;
    }

    @Override
    public void onCreate() {
        super.onCreate();
    }

    @Override
    public void onDestroy() {
        super.onDestroy();
        XPushManager.dispose();
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        if (intent == null) {
            VLog.d(1, TAG, "onStartCommand(): null intent received");
            intent = new Intent();
            intent.setAction(Constants.ACTION_START_SERVICE);
        } else {
            VLog.d(1, TAG, "onStartCommand(): intent = " + intent.getAction());
        }
        VLog.d(1, TAG, "onStartCommand(): flags = " + flags + " startId = " + startId + " mIsRunning = " + mIsRunning);
        String action = intent.getAction();
        int sticky = START_STICKY;
        mIsRunning = true;
        if (action.equals(Constants.ACTION_START_SERVICE)) {
            XPushManager.getInstance(getApplicationContext()).tryConnect();
        } else if (action.equals(Constants.ACTION_STOP_SERVICE)) {
            XPushManager.dispose();
            mIsRunning = false;
            sticky = START_NOT_STICKY;
        } else if (action.equals(Constants.ACTION_RESTART_SERVICE)) {
            XPushManager.getInstance(getApplicationContext()).tryConnect();
        }
        return sticky;
    }
}
