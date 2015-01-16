package com.xuexibao.xcomet;

import android.util.Log;

public class XCometClient {
  private long mNativeHandler = 0;
  private XCometCallback mCallback = null;

  public static interface XCometCallback {
    void onConnect();
    void onMessage(String msg);
    void onError(String err);
    void onDisconnect();
  }

   static {
     System.loadLibrary("xcomet_client_jni");
   }

  public XCometClient(XCometCallback cb) {
    mCallback = cb;
    mNativeHandler = create();
  }

  public void dispose() {
    destroy();
  }

  public void connectCallback() {
    mCallback.onConnect();
  }

  public void messageCallback(String msg) {
    mCallback.onMessage(msg);
  }

  public void errorCallback(String err) {
    mCallback.onError(err);
  }

  public void disconnectCallback() {
    mCallback.onDisconnect();
  }

  public native void setHost(String host);
  public native void setPort(int port);
  public native void setUserName(String userName);
  public native void setPassword(String password);

  public native void destroy();
  public native int connect();
  public native int publish(String channel, String msg);
  public native int send(String user, String msg);
  public native int subscribe(String channel);
  public native int unsubscribe(String channel);
  public native int sendHeartbeat();
  public native void close();
  public native void waitForClose();

  private native long create();
}
