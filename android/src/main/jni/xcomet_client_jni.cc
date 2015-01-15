#include <stdint.h>
#include <stdlib.h>
#include <jni.h>
#include <android/log.h>

#include "src/logging.h"
#include "src/socketclient.h"

#include "jni_helper.h"

using namespace xcomet;

#define JOWW(rettype, name) extern "C" rettype JNIEXPORT JNICALL Java_com_xuexibao_xcomet_##name

static const char* XCOMETCLIENT_CLASS_NAME = "com/xuexibao/xcomet/XCometClient";
static JniHelper* g_jni_helper_ = NULL;
static jobject g_self_global_ref_;

static jclass GetClass() {
  return g_jni_helper_->GetClass(XCOMETCLIENT_CLASS_NAME);
}

static void AndroidLogFunc(int level, const char* str) {
  int android_log_level = ANDROID_LOG_VERBOSE;
  if (level == LOG_WARNING) {
    android_log_level = ANDROID_LOG_WARN;
  } else if (level == LOG_ERROR || level == LOG_ERROR_REPORT) {
    android_log_level = ANDROID_LOG_ERROR;
  } else if (level == LOG_FATAL) {
    android_log_level = ANDROID_LOG_FATAL;
  }
  __android_log_write(android_log_level, "xcomet_client_jni", str);
}

extern "C" jint JNIEXPORT JNICALL JNI_OnLoad(JavaVM *jvm, void *reserved) {
  SimpleLogger::SetPrintFunc(AndroidLogFunc);
  SimpleLogger::SetLogLevel(LOG_INFO);
  SimpleLogger::SetLogVerboseLevel(3);  //TODO release should be 1
  LOG(INFO) << "jni onload";
  g_jni_helper_ = new JniHelper(jvm);
  JNIEnv* env = g_jni_helper_->GetAttachedEnv();
  g_jni_helper_->LoadClass(env, XCOMETCLIENT_CLASS_NAME);
  return JNI_VERSION_1_6;
}

extern "C" void JNIEXPORT JNICALL JNI_OnUnLoad(JavaVM *jvm, void *reserved) {
  g_jni_helper_->FreeReferences();
  delete g_jni_helper_;
  LOG(INFO) << "jni onunload";
}

static SocketClient* GetSocketClient(JNIEnv* env, jobject self) {
  jclass cls = env->GetObjectClass(self);
  jfieldID native_handler = env->GetFieldID(cls, "mNativeHandler", "J");
  jlong j_ptr = env->GetLongField(self, native_handler);
  return reinterpret_cast<SocketClient*>(j_ptr);
}

JOWW(jlong, XCometClient_create)(JNIEnv* env, jobject self) {
  ClientOption option;
  SocketClient* client = new SocketClient(option);
  g_self_global_ref_ = static_cast<jobject>(env->NewGlobalRef(self));
  client->SetConnectCallback([]() {
    LOG(INFO) << "connected";
    JNIEnv* jni= g_jni_helper_->GetAttachedEnv();
    jclass cls = GetClass();
    jmethodID callback = jni->GetMethodID(cls,"connectCallback","()V");
    jni->CallVoidMethod(g_self_global_ref_, callback);
  });
  client->SetDisconnectCallback([]() {
    LOG(INFO) << "disconnected";
    JNIEnv* jni= g_jni_helper_->GetAttachedEnv();
    jclass cls = GetClass();
    jmethodID callback = jni->GetMethodID(cls,"disconnectCallback","()V");
    jni->CallVoidMethod(g_self_global_ref_, callback);
  });
  client->SetMessageCallback([](const std::string& msg) {
    LOG(INFO) << "receive message: " << msg;
    JNIEnv* jni= g_jni_helper_->GetAttachedEnv();
    jclass cls = GetClass();
    jmethodID callback = jni->GetMethodID(cls,
                                          "messageCallback",
                                          "(Ljava/lang/String;)V");
    jstring jstr = jni->NewStringUTF(msg.c_str());
    jni->CallVoidMethod(g_self_global_ref_, callback, jstr);
  });
  client->SetErrorCallback([](const std::string& error) {
    LOG(INFO) << ": " << error;
    JNIEnv* jni= g_jni_helper_->GetAttachedEnv();
    jclass cls = GetClass();
    jmethodID callback = jni->GetMethodID(cls,
                                          "errorCallback",
                                          "(Ljava/lang/String;)V");
    jstring jstr = jni->NewStringUTF(error.c_str());
    jni->CallVoidMethod(g_self_global_ref_, callback, jstr);
  });
  return JlongFromPointer(client);
}

JOWW(void, XCometClient_destroy)(JNIEnv* env, jobject self) {
  SocketClient* client = GetSocketClient(env, self);
  delete client;
}

JOWW(void, XCometClient_setHost)(JNIEnv* env, jobject self, jstring host) {
  SocketClient* client = GetSocketClient(env, self);
  client->SetHost(env->GetStringUTFChars(host, NULL));
}

JOWW(void, XCometClient_setPort)(JNIEnv* env, jobject self, jint port) {
  SocketClient* client = GetSocketClient(env, self);
  client->SetPort(port);
}

JOWW(void, XCometClient_setUserName)(JNIEnv* env, jobject self,
                                     jstring username) {
  SocketClient* client = GetSocketClient(env, self);
  client->SetUserName(env->GetStringUTFChars(username, NULL));
}

JOWW(void, XCometClient_setPassword)(JNIEnv* env, jobject self,
                                     jstring password) {
  SocketClient* client = GetSocketClient(env, self);
  client->SetPassword(env->GetStringUTFChars(password, NULL));
}

JOWW(int, XCometClient_connect)(JNIEnv* env, jobject self) {
  SocketClient* client = GetSocketClient(env, self);
  return client->Connect();
}

JOWW(int, XCometClient_publish)(JNIEnv* env, jobject self,
                                jstring channel, jstring msg) {
  SocketClient* client = GetSocketClient(env, self);
  return client->Publish(env->GetStringUTFChars(channel, NULL),
                         env->GetStringUTFChars(msg, NULL));
}

JOWW(int, XCometClient_send)(JNIEnv* env, jobject self,
                             jstring user, jstring msg) {
  SocketClient* client = GetSocketClient(env, self);
  return client->Send(env->GetStringUTFChars(user, NULL),
                      env->GetStringUTFChars(msg, NULL));
}

JOWW(int, XCometClient_subscribe)(JNIEnv* env, jobject self, jstring channel) {
  SocketClient* client = GetSocketClient(env, self);
  return client->Subscribe(env->GetStringUTFChars(channel, NULL));
}

JOWW(int, XCometClient_unsubscribe)(JNIEnv* env, jobject self,
                                    jstring channel) {
  SocketClient* client = GetSocketClient(env, self);
  return client->Unsubscribe(env->GetStringUTFChars(channel, NULL));
}

JOWW(int, XCometClient_sendHeartbeat)(JNIEnv* env, jobject self) {
  SocketClient* client = GetSocketClient(env, self);
  return client->SendHeartbeat();
}

JOWW(void, XCometClient_close)(JNIEnv* env, jobject self) {
  SocketClient* client = GetSocketClient(env, self);
  client->Close();
}

JOWW(void, XCometClient_waitForClose)(JNIEnv* env, jobject self) {
  SocketClient* client = GetSocketClient(env, self);
  client->WaitForClose();
}
