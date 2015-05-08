package com.xuexibao.xcomet;

import com.xuexibao.android.push.XPushManager;

public class XCometClient {
    private long mNativeHandler = 0;
    private Callback mCallback = null;

    public static interface Callback {
        void onConnect();
        void onMessage(String msg);
        void onError(String err);
        void onDisconnect();
    }

    static {
        System.loadLibrary("xcomet_client_jni");
    }

    public XCometClient(Callback cb) {
        mCallback = cb;
        mNativeHandler = create();
    }

    public void setCallback(Callback cb) {
        mCallback = cb;
    }

    public void dispose() {
        destroy();
    }

    public void connectCallback() {
        if (mCallback != null) {
            mCallback.onConnect();
        }
    }

    public void messageCallback(String msg) {
        if (mCallback != null) {
            mCallback.onMessage(msg);
        }
    }

    public void errorCallback(String err) {
        if (mCallback != null) {
            mCallback.onError(err);
        }
    }

    public void disconnectCallback() {
        if (mCallback != null) {
            mCallback.onDisconnect();
        }
    }

    public native void setHost(String host);
    public native void setPort(int port);
    public native void setUserName(String userName);
    public native void setPassword(String password);
    public native void setKeepAliveIntervalSec(int keepAlive);

    public native void destroy();
    public native int connect();
    public native int publish(String channel, String msg);
    public native int send(String to, String msg);
    public native int subscribe(String channel);
    public native int unsubscribe(String channel);
    //public native int sendHeartbeat();
    public native void close();
    public native void waitForClose();
    public native boolean isConnected();
    public native void setDebugLevel(int level);

    private native long create();
}
