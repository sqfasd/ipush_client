package com.xuexibao.android.push;

import android.content.Context;
import android.content.SharedPreferences;
import android.content.SharedPreferences.Editor;
import android.preference.PreferenceManager;
import android.util.Log;

/**
 * Created by sqf on 15-5-5.
 */

// TODO(*) use SharedPreferences to store the configs
public class XPushConfig {
    private final static String TAG = "XPushConfig";

    private static Context sContext = null;

    private static String sHost = "";
    private static int sPort = 0;
    private static String sAccount = "";
    private static String sToken = "";
    private static int DEFAULT_KEEPALIVE_INTERVAL_SEC = 60;
    private static int sKeepAliveIntervalSec = DEFAULT_KEEPALIVE_INTERVAL_SEC;
    private static boolean sInited = false;

    private static String CONFIG_DEBUG_LEVEL = Constants.PACKAGE + ".XPushConfig.debugLevel";
    private static String CONFIG_HOST = Constants.PACKAGE + ".XPushConfig.host";
    private static String CONFIG_PORT = Constants.PACKAGE + ".XPushConfig.port";
    private static String CONFIG_ACCOUNT = Constants.PACKAGE + ".XPushConfig.account";
    private static String CONFIG_TOKEN = Constants.PACKAGE + ".XPushConfig.token";
    private static String CONFIG_KEEPALIVE_INTERVAL_SEC = Constants.PACKAGE + ".XPushConfig.keepAliveIntervalSec";
    private static String CONFIG_INITED = Constants.PACKAGE + ".XPushConfig.inited";

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

    public static boolean isInited(final Context context) {
        sContext = context;
        if (!sInited) {
            LoadConfig();
        }
        return sInited;
    }

    public static void setInited(final Context context) {
        sContext = context;
        sInited = true;
        SaveConfig();
    }

    protected static void LoadConfig() {
        if (sContext == null) {
            Log.e(TAG, "LoadConfig() context not set");
        } else {
            SharedPreferences sp = PreferenceManager.getDefaultSharedPreferences(sContext);
            VLog.setDebugLevel(sp.getInt(CONFIG_DEBUG_LEVEL, 0));
            sHost = sp.getString(CONFIG_HOST, "");
            sPort = sp.getInt(CONFIG_PORT, 0);
            sAccount = sp.getString(CONFIG_ACCOUNT, "");
            sToken = sp.getString(CONFIG_TOKEN, "");
            sKeepAliveIntervalSec = sp.getInt(CONFIG_KEEPALIVE_INTERVAL_SEC, DEFAULT_KEEPALIVE_INTERVAL_SEC);
            sInited = sp.getBoolean(CONFIG_INITED, false);
        }
    }

    protected static void SaveConfig() {
        if (sContext == null) {
            Log.e(TAG, "SaveConfig() context not set");
        } else {
            Editor edit = PreferenceManager.getDefaultSharedPreferences(sContext).edit();
            edit.putInt(CONFIG_DEBUG_LEVEL, VLog.getDebugLevel());
            edit.putString(CONFIG_HOST, sHost);
            edit.putInt(CONFIG_PORT, sPort);
            edit.putString(CONFIG_ACCOUNT, sAccount);
            edit.putString(CONFIG_TOKEN, sToken);
            edit.putInt(CONFIG_KEEPALIVE_INTERVAL_SEC, sKeepAliveIntervalSec);
            edit.putBoolean(CONFIG_INITED, sInited);
            edit.commit();
        }
    }
}
