LOCAL_PATH := $(call my-dir)
include $(CLEAR_VARS)

#LOCAL_ARM_MODE := arm

NDK_TOOLCHAIN_VERSION = 4.8
LOCAL_CPPFLAGS := -std=c++11 -pthread -fexceptions

LOCAL_MODULE := libxcomet_client_jni
CPP_ROOT=../../../../cpp
LOCAL_SRC_FILES := \
	jni_helper.cc \
	xcomet_client_jni.cc \
	$(CPP_ROOT)/src/socketclient.cc \
	$(CPP_ROOT)/src/logging.cc \
	$(CPP_ROOT)/deps/jsoncpp/src/json_value.cpp \
	$(CPP_ROOT)/deps/jsoncpp/src/json_reader.cpp \
	$(CPP_ROOT)/deps/jsoncpp/src/json_writer.cpp

LOCAL_C_INCLUDES += \
	$(JNI_H_INCLUDE) \
	$(CPP_ROOT) \
	$(CPP_ROOT)/deps/jsoncpp/include

LOCAL_LDLIBS := -L$(SYSROOT)/usr/lib -llog
#LOCAL_STATIC_LIBRARIES := libstlport
#LOCAL_SHARED_LIBRARIES :=

include $(BUILD_SHARED_LIBRARY)
