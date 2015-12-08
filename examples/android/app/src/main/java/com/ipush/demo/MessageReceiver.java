package com.ipush.demo;

import android.content.Context;
import android.util.Log;

import com.ipush.android.XPushMessage;
import com.ipush.android.XPushReceiver;
import com.ipush.demo.Main;

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
