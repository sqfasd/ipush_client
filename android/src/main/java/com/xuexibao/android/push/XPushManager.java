package com.xuexibao.android.push;

import android.content.Context;
import android.content.Intent;
import android.os.Handler;

import com.xuexibao.xcomet.XCometClient;

/**
 * Created by sqf on 15-5-5.
 */
public class XPushManager {
    private static final String TAG = "XPushManager";
    private static final int MAX_RETRY_COUNT = 3;

    private static XPushManager mInstance = null;

    private Context mContext = null;
    private int mRetryCount = 0;
    private Handler mReconnectHandler = null;
    private final Runnable mReconnectRunnable = new Runnable() {
        @Override
        public void run() {
            VLog.d(3, TAG, "time to retry connect, mRetryCount = " + mRetryCount);
            connect();
        }
    };

    private static enum State {
        Connected, Connecting, Disconnecting, Disconnected, Retrying
    };
    private State mState = State.Disconnected;

    private XCometClient mPushClient = null;
    private XCometClient.Callback mPushListener = new XCometClient.Callback() {

        @Override
        public void onMessage(String content) {
            VLog.d(3, TAG, "onMessage: " + content);
            Intent i = new Intent();
            i.setAction(Constants.ACTION_MESSAGE_RECEIVED);
            i.putExtra(Constants.EXTRA_MESSAGE_BODY, content);
            mContext.sendBroadcast(i);
        }

        @Override
        public void onError(String error) {
            VLog.d(3, TAG, "onError: " + error);
        }

        @Override
        public void onDisconnect() {
            VLog.d(3, TAG, "onDisconnect");
            setState(State.Disconnected);
        }

        @Override
        public void onConnect() {
            VLog.d(3, TAG, "onConnect" );
            setState(State.Connected);
        }
    };

    public static synchronized void startPush(Context context) {
        XPushConfig.setInited();
        Intent i = new Intent();
        i.setAction(Constants.ACTION_START_SERVICE);
        context.startService(i);
    }

    public static synchronized void stopPush(Context context) {
        Intent i = new Intent();
        i.setAction(Constants.ACTION_STOP_SERVICE);
        context.startService(i);
    }

    protected static synchronized void dispose() {
        if (mInstance != null) {
            mInstance.mPushClient.dispose();
            mInstance.mPushClient = null;
            mInstance = null;
        }
    }

    public static synchronized XPushManager getInstance(Context context) {
        if (mInstance == null) {
            mInstance = new XPushManager(context);
        }
        return mInstance;
    }

    private boolean isConnected() {
        return mState == State.Connected && mPushClient.isConnected();
    }

    private XPushManager(Context context) {
        mContext = context;
        if (mPushClient == null) {
            mPushClient = new XCometClient(mPushListener);
        }
    }

    public void disconnect() {
        mPushClient.close();
    }

    public synchronized void tryConnect() {
        VLog.d(3, TAG, "tryConnect(): mState = " + mState +
                ", isConnected = " + mPushClient.isConnected());
        if (isConnected()) {
            VLog.d(3, TAG, "already connected");
            return;
        }
        if (mState == State.Connecting || mState == State.Retrying) {
            VLog.d(3, TAG, "wait for connect");
            return;
        }
        mRetryCount = 0;
        connect();
    }

    private void scheduleReconnect() {
        if (++mRetryCount < MAX_RETRY_COUNT) {
            if (mReconnectHandler == null) {
                mReconnectHandler = new Handler();
            }
            mReconnectHandler.removeCallbacks(mReconnectRunnable);
            VLog.d(3, TAG, "scheduleReconnect(): scheduling reconnect in 10 seconds");
            mReconnectHandler.postDelayed(mReconnectRunnable, 10000);
        } else {
            VLog.d(3, TAG, "has exceed max retry count, will stop retry, wait for next chance");
        }
    }

    private void setState(State state) {
        VLog.d(3, TAG, "setState: " + state);
        mState = state;
    }

    private void connect() {
        VLog.d(3, TAG, "connect()");
        mPushClient.setDebugLevel(VLog.getDebugLevel());
        mPushClient.setHost(XPushConfig.getServerHost());
        mPushClient.setPort(XPushConfig.getServerPort());
        mPushClient.setUserName(XPushConfig.getAccount());
        mPushClient.setPassword(XPushConfig.getToken());
        mPushClient.setKeepAliveIntervalSec(XPushConfig.getKeepAliveIntervalSec());
        VLog.d(4, TAG, "getServerHost: " + XPushConfig.getServerHost());
        VLog.d(4, TAG, "getServerPort: " + XPushConfig.getServerPort());
        VLog.d(4, TAG, "getAccount: " + XPushConfig.getAccount());
        VLog.d(4, TAG, "getToken: " + XPushConfig.getToken());
        VLog.d(4, TAG, "getKeepAliveIntervalSec: " + XPushConfig.getKeepAliveIntervalSec());

        VLog.d(3, TAG, "before real connect");
        int ret = mPushClient.connect();
        if (ret == 0) {
            setState(State.Connecting);
            VLog.d(3, TAG, "connect success, waiting form callback");
        } else {
            VLog.d(3, TAG, "connect failed with code " + ret);
            setState(State.Retrying);
            scheduleReconnect();
        }
    }
}
