package com.xuexibao.xcomet.demo;

import android.content.Context;
import android.util.Log;

import com.xuexibao.android.push.XPushMessage;
import com.xuexibao.android.push.XPushReceiver;

/**
 * Created by sqf on 15-5-6.
 */
public class MessageReceiver extends XPushReceiver {
    @Override
    public void onPushMessage(Context context, XPushMessage msg) {
        Log.d("MessageReceiver", "from="+msg.getFrom());
        Log.d("MessageReceiver", "body="+msg.getBody());
        Main.Instance().AppendMessage(msg.getBody());
    }
}
