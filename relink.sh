#!/bin/sh

set -e

pushd `pwd`/`dirname $0`
SCRIPT_ROOT=`pwd`
popd

pushd ..
export MIRAI_PROJECT_ROOT_PATH=`pwd`
popd

export MIRAI_TOOLCHAIN_ANDROID_PATH="$MIRAI_PROJECT_ROOT_PATH/toolchain/android"
export MIRAI_PRODUCTS_ANDROID_PATH="$MIRAI_TOOLCHAIN_ANDROID_PATH"

if [ "$ANDROID_NDK_PATH" == "" ]; then
export ANDROID_NDK_PATH="$MIRAI_PRODUCTS_ANDROID_PATH/android-ndk-r9b" # if you already has NDK, change this to you NDK path
fi
if [ "$ANDROID_JDK_PATH" == "" ]; then
export ANDROID_JDK_PATH="$MIRAI_PRODUCTS_ANDROID_PATH/adt-bundle-mac-x86_64-20131030/sdk" # if you already has JDK, change this to you JDK path
fi

export MIRAI_SDK_PATH="/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/Android18.sdk"
export MIRAI_SDK_PREFIX="$MIRAI_SDK_PATH/usr"
export MIRAI_SDK_PKG_CONFIG_PATH="$MIRAI_SDK_PREFIX/lib/pkgconfig"

export MIRAI_LOCAL_XCODE_SDK_PATH="$MIRAI_TOOLCHAIN_ANDROID_PATH/Android18.sdk"
export MIRAI_LOCAL_XCODE_SDK_PREFIX="$MIRAI_LOCAL_XCODE_SDK_PATH/usr"

export STANDALONE_TOOLCHAIN_PATH="$MIRAI_TOOLCHAIN_ANDROID_PATH/android-toolchain-arm"
export GNUSTEP_MAKE_CONFIG_PATH="$SCRIPT_ROOT/gnu-config"
export SYSROOTFLAGS_ARM="--sysroot $MIRAI_SDK_PATH"

export PKG_CONFIG_LIBDIR=$MIRAI_SDK_PREFIX/lib/pkgconfig
export PKG_CONFIG_PATH=$PKG_CONFIG_LIBDIR

export CLANG_ARM=arm-linux-androideabi-clang
export CLANGPP_ARM=arm-linux-androideabi-clang++
export GCC_ARM=arm-linux-androideabi-gcc
export LD_ARM=arm-linux-androideabi-ld
export GXX_ARM=arm-linux-androideabi-g++
export AR_ARM=arm-linux-androideabi-ar
export RANLIB_ARM=arm-linux-androideabi-ranlib
export OBJDUMP_ARM=arm-linux-androideabi-objdump

checkError()
{
    if [ "${1}" -ne "0" ]; then
        echo "*** Error: ${2}"
        exit ${1}
    fi
}

#0. link between Xcode SDK and Mirai SDK
#	we do this at beginning because this step needs sudo privilege
#	and the whole build time is so long, we don't want waiting the script pause at mid-time, and ask your passcode
if [[ "$MIRAI_LOCAL_XCODE_SDK_PATH" == "" ]]; then
	echo "env not setted: MIRAI_LOCAL_XCODE_SDK_PATH: $MIRAI_LOCAL_XCODE_SDK_PATH"
	exit 1
fi

#link 
if [ ! -d $MIRAI_SDK_PATH ]; then
pushd /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs
echo "Attemp to Link fake sdk to Xcode..."
echo "This operation needs sudo privilege"
sudo ln -sf "$MIRAI_LOCAL_XCODE_SDK_PATH"
popd
fi



