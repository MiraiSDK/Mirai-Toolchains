#!/bin/bash

if [ ! -d jni ]; then
	git clone https://github.com/langresser/libiconv-1.14-android.git jni
	patch -p1 -i static_library.patch
fi

ndk-build

cp obj/local/armeabi/libiconv.a $MIRAI_SDK_PREFIX/lib/

#clean-up
rm -r obj
rm -rf jni