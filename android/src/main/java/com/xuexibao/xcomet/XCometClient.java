package com.xuexibao.xcomet;

public class XCometClient {
  private String mHost = null;
  private int mPort = -1;
  private String mUserName = null;
  private String mPassword = null;
  private XCometCallback mCallback = null;
  private bool mIsConnected = false;

  public static interface XCometCallback {
    void onConnect();
    void onMessage(String msg);
    void onError(XCometError err);
    void onDisconnect();
  }

  public XCometClient() {
  }

  public void setHost(String host) {mHost = host;}
  public void setPort(int port) {mPort = port;}
  public void setUserName(String userName) {mUserName = userName;}
  public void setPassword(String password) {mPassword = password;}
  public void setCallback(XCometCallback cb) {mCallback = cb;}

  public void connect() {
    // CHECK(mHost != null && mPort =! -1 && mUserName != null && mPassword != null && mCallback != null);
  }

  public isConnected() {
    return mIsConnected;
  }

  public int publish(String msg) {
  }

  public int close() {
  }

}
