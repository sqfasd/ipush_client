package com.xuexibao.xcomet.demo;

import android.content.Context;

import com.xuexibao.android.push.XPushMessage;
import com.xuexibao.android.push.XPushReceiver;

/**
 * Created by sqf on 15-5-6.
 */
public class MessageReceiver extends XPushReceiver {
    @Override
    public void onPushMessage(Context context, XPushMessage msg) {
        Main.Instance().AppendMessage(msg.getBody());
    }
}
