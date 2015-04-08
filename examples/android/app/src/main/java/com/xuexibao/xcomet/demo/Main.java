/*
 * $Id: TestKeepAlive.java 216 2009-01-08 02:03:13Z jasta00 $
 */

package com.xuexibao.xcomet.demo;

import android.app.Activity;
import android.os.Bundle;
import android.view.View;
import android.view.View.OnClickListener;
import android.widget.Button;
import android.widget.TextView;

public class Main extends Activity
{
	private static final String TAG = "Main";
    private static Main instance = null;

    private TextView textView = null;

	private final OnClickListener mClicked = new OnClickListener()
	{
		public void onClick(View v)
		{
			switch (v.getId())
			{
			case R.id.start:
				PushService.actionStart(Main.this);
				break;
			case R.id.stop:
                PushService.actionStop(Main.this);
				break;
			}
		}
	};

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

		findViewById(R.id.start).setOnClickListener(mClicked);
		findViewById(R.id.stop).setOnClickListener(mClicked);
        textView = (TextView)findViewById(R.id.message_view);

        instance = this;
	}
}
