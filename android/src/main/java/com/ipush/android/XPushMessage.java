package com.ipush.android;

import org.json.JSONObject;

public class XPushMessage {
    public static final int T_HEARTBEAT = 0;
    public static final int T_SUBSCRIBE = 1;
    public static final int T_UNSUBSCRIBE = 2;
    public static final int T_MESSAGE = 3;
    public static final int T_CHANNEL_MESSAGE = 4;
    public static final int T_ACK = 5;

    private static final String K_FROM = "f";
    private static final String K_TO = "t";
    private static final String K_BODY = "b";
    private static final String K_TYPE = "y";

    private String mFrom = "";
    private String mBody = "";
    private String mTo = "";
    private String mChannel = "";
    private int mType = 0;

    public XPushMessage() {
    }

    public void setFrom(String from) {
        mFrom = from;
    }

    public void setBody(String body) {
        mBody = body;
    }

    public void setTo(String to) {
        mTo = to;
    }

    public void setType(int type) {
        mType = type;
    }

    public String getFrom() {
        return mFrom;
    }

    public String getBody() {
        return mBody;
    }

    public String getTo() {
        return mTo;
    }

    public int getType() {
        return mType;
    }

    public static XPushMessage Parse(String raw) throws Exception {
        JSONObject json = new JSONObject(raw);
        if (!json.has(K_FROM) || !json.has(K_BODY) || !json.has(K_TYPE)) {
            throw new Exception("invalid message: " + raw);
        }
        XPushMessage msg = new XPushMessage();
        msg.setFrom(json.getString(K_FROM));
        msg.setBody(json.getString(K_BODY));
        msg.setType(json.getInt(K_TYPE));

        if (json.has(K_TO)) {
            msg.setTo(json.getString(K_TO));
        }
        return msg;
    }
}
