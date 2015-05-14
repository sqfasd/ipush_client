#!/bin/bash

readonly PROGDIR=$(readlink -m $(dirname $0))

set -x

SDK_NAME=xcomet_push_sdk
OUTPUT_DIR=build/outputs/aar
cd $OUTPUT_DIR
rm -rf tmp
mkdir -p ./tmp/$SDK_NAME
cd tmp
jar xf ../android-release.aar
cp classes.jar $SDK_NAME/libxcometclient.jar
cp -r jni/* $SDK_NAME/ 
tar zcf ${SDK_NAME}.tar.gz $SDK_NAME

echo "New sdk package: $PROGDIR/$OUTPUT_DIR/tmp/${SDK_NAME}.tar.gz"
