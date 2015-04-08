/*
 * $Id: PushService.java 219 2009-01-09 00:48:56Z jasta00 $
 */

package com.xuexibao.xcomet.demo;

import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.InetSocketAddress;
import java.net.Socket;
import java.util.Date;

import android.app.AlarmManager;
import android.app.Notification;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.app.Service;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.SharedPreferences;
import android.net.ConnectivityManager;
import android.net.NetworkInfo;
import android.os.IBinder;
import android.util.Log;
import com.liveaa.net.XCometClient;

public class PushService extends Service
{
	public static final String TAG = "PushService";

	private static final String HOST = "scomet.91xuexibao.com";
	private static final int PORT = 9000;

	private static final String ACTION_START = "com.xuexibao.xcomet.demo.START";
	private static final String ACTION_STOP = "com.xuexibao.xcomet.demo.STOP";
	private static final String ACTION_KEEPALIVE = "com.xuexibao.xcomet.demo.KEEP_ALIVE";
	private static final String ACTION_RECONNECT = "com.xuexibao.xcomet.demo.RECONNECT";

	private ConnectivityManager mConnMan;
	private NotificationManager mNotifMan;

	private boolean mStarted;
    private XCometClient mConnection;

	private static final long KEEP_ALIVE_INTERVAL = 1000 * 30;

	private static final long INITIAL_RETRY_INTERVAL = 1000 * 10;
	private static final long MAXIMUM_RETRY_INTERVAL = 1000 * 60 * 30;

	private SharedPreferences mPrefs;

	private static final int NOTIF_CONNECTED = 0;
	
	private static final String PREF_STARTED = "isStarted";

	public static void actionStart(Context ctx)
	{
		Intent i = new Intent(ctx, PushService.class);
		i.setAction(ACTION_START);
		ctx.startService(i);
	}

	public static void actionStop(Context ctx)
	{
		Intent i = new Intent(ctx, PushService.class);
		i.setAction(ACTION_STOP);
		ctx.startService(i);
	}
	
	public static void actionPing(Context ctx)
	{
		Intent i = new Intent(ctx, PushService.class);
		i.setAction(ACTION_KEEPALIVE);
		ctx.startService(i);
	}

	@Override
	public void onCreate()
	{
		super.onCreate();

		mPrefs = getSharedPreferences(TAG, MODE_PRIVATE);
		
		mConnMan =
		  (ConnectivityManager)getSystemService(CONNECTIVITY_SERVICE);

		mNotifMan =
		  (NotificationManager)getSystemService(NOTIFICATION_SERVICE);
	
		/* If our process was reaped by the system for any reason we need
		 * to restore our state with merely a call to onCreate.  We record
		 * the last "started" value and restore it here if necessary. */
		//handleCrashedService();
	}
	
	private void handleCrashedService()
	{
		if (wasStarted() == true)
		{
			/* We probably didn't get a chance to clean up gracefully, so do
			 * it now. */
			hideNotification();			
			// stopKeepAlives();

			/* Formally start and attempt connection. */
			start();
		}
	}
	
	@Override
	public void onDestroy()
	{
		log("Service destroyed (started=" + mStarted + ")");

		if (mStarted == true)
			stop();
	}

	private void log(String message)
	{
		Log.i(TAG, message);
	}
	
	private boolean wasStarted()
	{
		return mPrefs.getBoolean(PREF_STARTED, false);
	}

	private void setStarted(boolean started)
	{
		mPrefs.edit().putBoolean(PREF_STARTED, started).commit();
		mStarted = started;
	}

	@Override
	public int onStartCommand(Intent intent, int flags, int startId)
	{
		log("Service started with intent=" + intent);
		if (intent.getAction().equals(ACTION_STOP) == true) {
			stop();
			stopSelf();
		} else if (intent.getAction().equals(ACTION_START) == true) {
            start();
        } else if (intent.getAction().equals(ACTION_KEEPALIVE) == true) {
            keepAlive();
        } else if (intent.getAction().equals(ACTION_RECONNECT) == true) {
            reconnectIfNecessary();
        }
        return START_STICKY;
	}

    private void keepAlive() {
    }

    private void newConnection() {
        mConnection = new XCometClient(new XCometClient.Callback() {
            @Override
            public void onConnect() {
                Log.i(TAG, "onConnect");
                Log.i(TAG, "isConnected = " + mConnection.isConnected());
                setStarted(true);
            }

            @Override
            public void onMessage(String msg) {
                Log.i(TAG, "onMessage: " + msg);
                Main.Instance().AppendMessage(msg);
            }

            @Override
            public void onError(String err) {
                Log.i(TAG, "onError: " + err);
            }

            @Override
            public void onDisconnect() {
                Log.i(TAG, "onDisconnect");
                setStarted(false);
            }
        });
        mConnection.setHost(HOST);
        mConnection.setPort(PORT);
        mConnection.setUserName("android_user_1");
        mConnection.setPassword("android_password_1");
        mConnection.setKeepaliveInterval(10);
    }
	@Override
	public IBinder onBind(Intent intent)
	{
		return null;
	}

	private synchronized void start()
	{
		if (mStarted == true)
		{
			Log.w(TAG, "Attempt to start connection that is already active");
			return;
		}

		setStarted(true);

		registerReceiver(mConnectivityChanged,
		  new IntentFilter(ConnectivityManager.CONNECTIVITY_ACTION));

		log("Connecting...");
        newConnection();

        new Thread(new Runnable() {
            @Override
            public void run() {
                int ret = mConnection.connect();
                Log.i(TAG, "connect ret = " + ret);
            }
        });
        //startKeepAlives();
	}

	private synchronized void stop()
	{
        //stopKeepAlives();
		if (mStarted == false)
		{
			Log.w(TAG, "Attempt to stop connection not active.");
			return;
		}

		setStarted(false);

		unregisterReceiver(mConnectivityChanged);		
		// cancelReconnect();

		if (mConnection != null)
		{
			// mConnection.abort();
            mConnection.dispose();
			mConnection = null;
		}
	}

	private void startKeepAlives()
	{
		Intent i = new Intent();
		i.setClass(this, PushService.class);
		i.setAction(ACTION_KEEPALIVE);
		PendingIntent pi = PendingIntent.getService(this, 0, i, 0);
		AlarmManager alarmMgr = (AlarmManager)getSystemService(ALARM_SERVICE);
		alarmMgr.setRepeating(AlarmManager.RTC_WAKEUP,
		  System.currentTimeMillis() + KEEP_ALIVE_INTERVAL,
		  KEEP_ALIVE_INTERVAL, pi);
	}

	private void stopKeepAlives()
	{
		Intent i = new Intent();
		i.setClass(this, PushService.class);
		i.setAction(ACTION_KEEPALIVE);
		PendingIntent pi = PendingIntent.getService(this, 0, i, 0);
		AlarmManager alarmMgr = (AlarmManager)getSystemService(ALARM_SERVICE);
		alarmMgr.cancel(pi);
	}

	public void scheduleReconnect(long startTime)
	{
		long interval =
		  mPrefs.getLong("retryInterval", INITIAL_RETRY_INTERVAL);

		long now = System.currentTimeMillis();
		long elapsed = now - startTime;

		if (elapsed < interval)
			interval = Math.min(interval * 4, MAXIMUM_RETRY_INTERVAL);
		else
			interval = INITIAL_RETRY_INTERVAL;

		log("Rescheduling connection in " + interval + "ms.");

		mPrefs.edit().putLong("retryInterval", interval).commit();

		Intent i = new Intent();
		i.setClass(this, PushService.class);
		i.setAction(ACTION_RECONNECT);
		PendingIntent pi = PendingIntent.getService(this, 0, i, 0);
		AlarmManager alarmMgr = (AlarmManager)getSystemService(ALARM_SERVICE);
		alarmMgr.set(AlarmManager.RTC_WAKEUP, now + interval, pi);
	}
	
	public void cancelReconnect()
	{
		Intent i = new Intent();
		i.setClass(this, PushService.class);
		i.setAction(ACTION_RECONNECT);
		PendingIntent pi = PendingIntent.getService(this, 0, i, 0);
		AlarmManager alarmMgr = (AlarmManager)getSystemService(ALARM_SERVICE);
		alarmMgr.cancel(pi);
	}

	private synchronized void reconnectIfNecessary()
	{
		if (mStarted == true && mConnection == null)
		{
			log("Reconnecting...");

            newConnection();
		}
        mConnection.connect();
	}

	private BroadcastReceiver mConnectivityChanged = new BroadcastReceiver()
	{
		@Override
		public void onReceive(Context context, Intent intent)
		{
			NetworkInfo info = (NetworkInfo)intent.getParcelableExtra
			  (ConnectivityManager.EXTRA_NETWORK_INFO);
			
			boolean hasConnectivity = (info != null && info.isConnected()) 
			  ? true : false;

			log("Connecting changed: connected=" + hasConnectivity);

			if (hasConnectivity)
				reconnectIfNecessary();
		}
	};
	
	private void showNotification()
	{
        /*
		Notification n = new Notification();
		
		n.flags = Notification.FLAG_NO_CLEAR |
		  Notification.FLAG_ONGOING_EVENT;

		n.icon = R.drawable.connected_notify;
		n.when = System.currentTimeMillis();

		PendingIntent pi = PendingIntent.getActivity(this, 0,
		  new Intent(this, Main.class), 0);

		n.setLatestEventInfo(this, "KeepAlive connected",
		  "Connected to " + HOST + ":" + PORT, pi);

		mNotifMan.notify(NOTIF_CONNECTED, n);
		*/
	}
	
	private void hideNotification()
	{
		mNotifMan.cancel(NOTIF_CONNECTED);
	}
}
