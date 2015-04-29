# xcomet_client

## Example

```
XConetClient mConnection = new XCometClient(new XCometClient.Callback() {
    @Override
    public void onConnect() {
      Log.i(TAG, "onConnect");
      Log.i(TAG, "isConnected = " + mConnection.isConnected());
    }

    @Override
    public void onMessage(String msg) {
      Log.i(TAG, "onMessage: " + msg);
    }

    @Override
    public void onError(String err) {
      Log.i(TAG, "onError: " + err);
    }

    @Override
    public void onDisconnect() {
      Log.i(TAG, "onDisconnect");
    }
});

mConnection.setHost("pushapi.91xuexibao.com");
mConnection.setPort(9000);
mConnection.setUserName("android_user_1");
mConnection.setPassword("android_password_1");
mConnection.setKeepaliveInterval(300);
mConnection.setDebugLevel(5);
int ret = mConnection.connect();
if (ret != 0) {
    Logi(TAG, "connect failed");
}
```

## 编译

使用android studio进行编译

### 库

```
android/
```

### 示例

```
examples/android
```
