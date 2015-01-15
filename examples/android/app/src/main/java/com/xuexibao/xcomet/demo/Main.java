/*
 * $Id: TestKeepAlive.java 216 2009-01-08 02:03:13Z jasta00 $
 */

package com.xuexibao.xcomet.demo;

import android.app.Activity;
import android.os.Bundle;
import android.view.View;
import android.view.View.OnClickListener;
import android.widget.Button;

public class Main extends Activity
{
	public static final String TAG = "Main";

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
			case R.id.ping:
                PushService.actionPing(Main.this);
				break;
			}
		}
	};

	@Override
	public void onCreate(Bundle icicle)
	{
		super.onCreate(icicle);
		setContentView(R.layout.main);

		findViewById(R.id.start).setOnClickListener(mClicked);
		findViewById(R.id.stop).setOnClickListener(mClicked);
		findViewById(R.id.ping).setOnClickListener(mClicked);
	}
}
