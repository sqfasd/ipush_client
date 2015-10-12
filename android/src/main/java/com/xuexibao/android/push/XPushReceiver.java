package com.xuexibao.android.push;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;

/**
 * Created by sqf on 15-5-6.
 */
public abstract  class XPushReceiver extends BroadcastReceiver {
    private static final String TAG = "XPushReceiver";

    @Override
    public void onReceive(Context context, Intent intent) {
        String action = intent.getAction();
        VLog.d(1, TAG, "onReceive() intent=" + action);
        if (action.equals(Constants.ACTION_MESSAGE_RECEIVED)) {
            String content = intent.getStringExtra(Constants.EXTRA_MESSAGE_BODY);
            VLog.d(3, TAG, "receive message: " + content);
            try {
                XPushMessage msg = XPushMessage.Parse(content);
                onPushMessage(context, msg);
            } catch (Exception e) {
                VLog.d(1, TAG, "parse message failed: " + e.getMessage());
            }
        } else {
            Intent i = new Intent(context, XPushService.class);
            if (XPushConfig.isInited(context)) {
                i.setAction(Constants.ACTION_START_SERVICE);
                context.startService(i);
            } else {
                VLog.d(1, TAG, "push service not inited");
            }
        }
    }

    public abstract void onPushMessage(Context context, XPushMessage msg);
}
