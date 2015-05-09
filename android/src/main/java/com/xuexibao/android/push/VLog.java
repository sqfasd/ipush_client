package com.xuexibao.android.push;

import android.util.Log;

/**
 * Created by sqf on 15-5-5.
 */
final class VLog {
    public static int MIN_DEBUG_LEVEL = 0;
    public static int MAX_DEBUG_LEVEL = 7;
    public static int DEFAULT_DEBUG_LEVEL = 3;

    private static int sDebugLevel = MIN_DEBUG_LEVEL;

    public static void setDebugLevel(int level) {
        if (level < MIN_DEBUG_LEVEL) {
            sDebugLevel = MIN_DEBUG_LEVEL;
        } else if (level > MAX_DEBUG_LEVEL) {
            sDebugLevel = MAX_DEBUG_LEVEL;
        } else {
            sDebugLevel = level;
        }
    }

    public static int getDebugLevel() {
        return sDebugLevel;
    }

    public static void d(int level, final String tag, final String message) {
        if (level <= sDebugLevel) {
            Log.d(tag, message);
        }
    }

    public static void enableDebug() {
        sDebugLevel = DEFAULT_DEBUG_LEVEL;
    }
}
