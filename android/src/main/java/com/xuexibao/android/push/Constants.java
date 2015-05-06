package com.xuexibao.android.push;

/**
 * Created by sqf on 15-5-5.
 */
final class Constants {
    public static final String PACKAGE = "com.xuexibao.android.push";

    public static final String ACTION_START_SERVICE = PACKAGE + ".START_SERVICE";
    public static final String ACTION_STOP_SERVICE = PACKAGE + ".STOP_SERVICE";
    public static final String ACTION_RESTART_SERVICE = PACKAGE + ".RESTART_SERVICE";

    public static final String ACTION_MESSAGE_RECEIVED = PACKAGE + ".MESSAGE_RECEIVED";
    public static final String EXTRA_MESSAGE_BODY = "message_body";
}
