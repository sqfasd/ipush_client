/*
 * $Id: TestKeepAlive.java 216 2009-01-08 02:03:13Z jasta00 $
 */

package com.xuexibao.xcomet.demo;

import android.app.Activity;
import android.os.Bundle;
import android.util.Log;
import android.view.View;
import android.view.View.OnClickListener;
import android.widget.Button;
import android.widget.TextView;

import com.xuexibao.android.push.XPushConfig;
import com.xuexibao.android.push.XPushManager;

public class Main extends Activity
{
	private static final String TAG = "Main";
    private static Main instance = null;

    private TextView textView = null;

    public static Main Instance() {
        return instance;
    }

    public void AppendMessage(final String msg) {
        runOnUiThread(new Runnable() {
            @Override
            public void run() {
                textView.append(msg);
            }
        });
    }

	@Override
	public void onCreate(Bundle icicle)
	{
		super.onCreate(icicle);
		setContentView(R.layout.main);
        textView = (TextView)findViewById(R.id.message_view);

        instance = this;

        XPushConfig.enableDebug();
        XPushConfig.setServerHost("182.92.113.188");
        XPushConfig.setServerPort(9000);
        XPushConfig.setAccount("android_user_2");
        XPushConfig.setToken("android_token_2");
        XPushConfig.setKeepAliveIntervalSec(30);
        XPushManager.startPush(getApplicationContext());
	}
}
