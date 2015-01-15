#include "jni_helper.h"

JniHelper::JniHelper(JavaVM* jvm)
    : jvm_(jvm) {
}

JniHelper::~JniHelper() {
  JCHECK(classes_.empty(), "Must call FreeReferences() before dtor!");
}

jclass JniHelper::GetClass(const std::string& name) {
  std::map<std::string, jclass>::iterator it = classes_.find(name);
  JCHECK(it != classes_.end(), "Could not find class");
  return it->second;
}

void JniHelper::LoadClass(JNIEnv* jni, const std::string& name) {
  jclass localRef = jni->FindClass(name.c_str());
  JCHECK_EXCEPTION(jni, "Could not load class");
  JCHECK(localRef, name.c_str());
  jclass globalRef = reinterpret_cast<jclass>(jni->NewGlobalRef(localRef));
  JCHECK_EXCEPTION(jni, "error during NewGlobalRef");
  JCHECK(globalRef, name.c_str());
  bool inserted = classes_.insert(std::make_pair(name, globalRef)).second;
  JCHECK(inserted, "Duplicate class name");
}

void JniHelper::FreeReferences() {
  JNIEnv* jni = GetAttachedEnv();
  for (std::map<std::string, jclass>::const_iterator it = classes_.begin();
       it != classes_.end(); ++it) {
    jni->DeleteGlobalRef(it->second);
  }
  classes_.clear();
  DetachCurrentEnv();
}

JNIEnv* JniHelper::GetEnv() {
  void* env;
  if (jvm_->GetEnv(&env, JNI_VERSION_1_6) != JNI_OK) {
    return static_cast<JNIEnv*>(env);
  }
  return NULL;
}

JNIEnv* JniHelper::GetAttachedEnv() {
  JNIEnv* env = GetEnv();
  if (env == NULL) {
    JCHECK(!jvm_->AttachCurrentThread(&env, NULL), "Failed to attach thread");
  }
  JCHECK(env, "AttachCurrentThread handed back NULL!");
  return static_cast<JNIEnv*>(env);
}

void JniHelper::DetachCurrentEnv() {
  jvm_->DetachCurrentThread();
}
