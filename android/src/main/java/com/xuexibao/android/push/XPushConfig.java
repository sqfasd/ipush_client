package com.xuexibao.android.push;

/**
 * Created by sqf on 15-5-5.
 */

// TODO(*) use SharedPreferences to store the configs
public class XPushConfig {
    private static String sHost = "";
    private static int sPort = 0;
    private static String sAccount = "";
    private static String sToken = "";
    private static int DEFAULT_KEEPALIVE_INTERVAL_SEC = 60;
    private static int sKeepAliveIntervalSec = DEFAULT_KEEPALIVE_INTERVAL_SEC;
    private static boolean sInited = false;

    public static void enableDebug() {
        VLog.enableDebug();
    }
    public static void setDebugLevel(int level) {
        VLog.setDebugLevel(level);
    }

    public static void setServerHost(final String host) {
        sHost = host;
    }

    public static String getServerHost() {
        return sHost;
    }

    public static void setServerPort(int port) {
        sPort = port;
    }

    public static int getServerPort() {
        return sPort;
    }

    public static void setAccount(final String account) {
        sAccount = account;
    }

    public static String getAccount() {
        return sAccount;
    }

    public static void setToken(final String token) {
        sToken = token;
    }

    public static String getToken() {
        return sToken;
    }

    public static void setKeepAliveIntervalSec(int keepAlive) {
        sKeepAliveIntervalSec = keepAlive;
    }

    public static int getKeepAliveIntervalSec() {
        return sKeepAliveIntervalSec;
    }

    public static boolean isInited() {
        return sInited;
    }

    public static void setInited() {
        sInited = true;
    }
}
