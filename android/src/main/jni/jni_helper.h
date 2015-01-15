#ifndef ANDROID_SRC_MAIN_JNI_JNI_HELPER_H_
#define ANDROID_SRC_MAIN_JNI_JNI_HELPER_H_

#include <stdlib.h>
#include <android/log.h>
#include <jni.h>

#include <map>
#include <string>

#define JCHECK(x, msg) \
  if (x) { \
  } else { \
    __android_log_print(ANDROID_LOG_ERROR, "xcomet_client_jni", "%s:%d: %s", __FILE__, \
                        __LINE__, msg); \
    abort(); \
  }

#define JCHECK_EXCEPTION(jni, msg) \
  if (0) {                         \
  } else {                         \
    if (jni->ExceptionCheck()) {   \
      jni->ExceptionDescribe();    \
      jni->ExceptionClear();       \
      JCHECK(0, msg);              \
    }                              \
  }

#define ARRAYSIZE(instance) \
  static_cast<int>(sizeof(instance) / sizeof(instance[0]))

inline jlong JlongFromPointer(void* ptr) {
  static_assert(sizeof(intptr_t) <= sizeof(jlong), "jlong wrong used");
  jlong ret = reinterpret_cast<intptr_t>(ptr);
  // assert(reinterpret_cast<void*>(ret) == ptr);
  return ret;
}

class JniHelper {
 public:
  JniHelper(JavaVM* jvm);
  ~JniHelper();
  jclass GetClass(const std::string& name);
  void LoadClass(JNIEnv* jni, const std::string& name);
  void FreeReferences();
  JNIEnv* GetAttachedEnv();
  void DetachCurrentEnv();

 private:
  JNIEnv* GetEnv();
  std::map<std::string, jclass> classes_;
  JavaVM* jvm_;
};

#endif  // ANDROID_SRC_MAIN_JNI_JNI_HELPER_H_
