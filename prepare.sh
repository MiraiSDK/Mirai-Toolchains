#!/bin/sh

pushd `pwd`/`dirname $0`
SCRIPT_ROOT=`pwd`
popd

pushd ..
MIRAI_PROJECT_ROOT_PATH=`pwd`
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

export STANDALONE_TOOLCHAIN_PATH="$MIRAI_TOOLCHAIN_ANDROID_PATH/android-toolchain-arm"
export GNUSTEP_MAKE_CONFIG_PATH="$SCRIPT_ROOT/gnu-config"
export SYSROOTFLAGS_ARM="--sysroot $MIRAI_SDK_PATH"

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

#1. get Android NDK
mkdir -p $MIRAI_PRODUCTS_ANDROID_PATH
echo "$MIRAI_PRODUCTS_ANDROID_PATH"

if [ ! -d $ANDROID_NDK_PATH ]; then
	pushd $MIRAI_PRODUCTS_ANDROID_PATH
	
	echo "Missing Android NDK, will download it, if you already has NDK, please set it to environment: ANDROID_NDK_PATH"
	
	if [ ! -f android-ndk-r9b-darwin-x86_64.tar.bz2 ]; then
		echo "Downloadng Android NDK..."
		curl http://dl.google.com/android/ndk/android-ndk-r9b-darwin-x86_64.tar.bz2 -o android-ndk-r9b-darwin-x86_64.tar.bz2
	fi
	
	tar -xvyf android-ndk-r9b-darwin-x86_64.tar.bz2
	
	if [ -d $ANDROID_NDK_PATH ]; then
		rm android-ndk-r9b-darwin-x86_64.tar.bz2
	fi
	popd
fi

#get Android SDK
if [ ! -d $ANDROID_JDK_PATH ]; then
	pushd $MIRAI_PRODUCTS_ANDROID_PATH
	
	echo "Missing Android SDK, will download it, if you already has Android SDK, please set it to environment: ANDROID_JDK_PATH"
	if [ ! -f adt-bundle-mac-x86_64-20131030.zip ]; then
		echo "Downloadng Android SDK adt-bundle-mac-x86_64-20131030.zip..."
		curl http://dl.google.com/android/adt/adt-bundle-mac-x86_64-20131030.zip -o adt-bundle-mac-x86_64-20131030.zip
	fi
	
	tar -vxzf adt-bundle-mac-x86_64-20131030.zip
	if [ -d $ANDROID_JDK_PATH ]; then
		rm adt-bundle-mac-x86_64-20131030.zip
	else
		echo "Missing Android SDK folder, take a look what's extracted folder name"
		exit 1;
	fi
	
	popd
fi

#2. make standalone toolchain path
if [ ! -d $STANDALONE_TOOLCHAIN_PATH ]; then
    $ANDROID_NDK_PATH/build/tools/make-standalone-toolchain.sh --platform="android-14" --install-dir=$STANDALONE_TOOLCHAIN_PATH --arch=arm --llvm-version=3.3
	
	
	cp $ANDROID_NDK_PATH/sources/cxx-stl/gnu-libstdc++/4.8/libs/armeabi/libgnustl_shared.so $STANDALONE_TOOLCHAIN_PATH/sysroot/usr/lib/
	cp $ANDROID_NDK_PATH/toolchains/arm-linux-androideabi-4.8/prebuilt/darwin-x86_64/lib/gcc/arm-linux-androideabi/4.8/libgcc.a $STANDALONE_TOOLCHAIN_PATH/sysroot/usr/lib/
	
	pushd $STANDALONE_TOOLCHAIN_PATH/sysroot/usr/lib
	# link libcxxrt.so
	ln -sf libgnustl_shared.so libcxxrt.so
	popd
fi

echo "set PATH..."
export PATH=$PATH:$STANDALONE_TOOLCHAIN_PATH/bin # Add Android toolchain to PATH for scripting

#3. link sdk path
echo "prepare xcode sdk..."
export MIRAI_LOCAL_XCODE_SDK_PATH="$MIRAI_TOOLCHAIN_ANDROID_PATH/Android18.sdk"
if [ -d "$MIRAI_LOCAL_XCODE_SDK_PATH" ]; then
	rm -r "$MIRAI_LOCAL_XCODE_SDK_PATH"
fi

export MIRAI_SDK_PREFIX="$MIRAI_LOCAL_XCODE_SDK_PATH/usr"
cp -R "$SCRIPT_ROOT/Xcode_Integration/Xcode_SDK_Structural" "$MIRAI_LOCAL_XCODE_SDK_PATH"
ln -s  "$STANDALONE_TOOLCHAIN_PATH/sysroot/usr" "$MIRAI_SDK_PREFIX"

# xcode integration
$SCRIPT_ROOT/Xcode_Integration/install.sh

#4. build gnustep-make
buildGNUstepMake()
{
    echo "Build GNUstep Makefiles"
	pushd $SCRIPT_ROOT/gnustep-make

    if [ ! -f gnustep-make-2.6.2.tar.gz ]; then
		echo "Downloadng gnustep-make-2.6.2..."
        curl ftp://ftp.gnustep.org/pub/gnustep/core/gnustep-make-2.6.2.tar.gz > gnustep-make-2.6.2.tar.gz
    fi
    tar -xzf gnustep-make-2.6.2.tar.gz

    cp $GNUSTEP_MAKE_CONFIG_PATH/config.sub gnustep-make-2.6.2
    cp $GNUSTEP_MAKE_CONFIG_PATH/config.guess gnustep-make-2.6.2

    pushd gnustep-make-2.6.2

    patch -p1 -i ../gsmake_target.patch

    CC="$CLANG_ARM" CXX="$CLANGPP_ARM" CPPFLAGS="$SYSROOTFLAGS_ARM" CFLAGS="$SYSROOTFLAGS_ARM" AR="$AR_ARM" ./configure --prefix=$MIRAI_SDK_PREFIX --host="arm-linux-androideabi"
    checkError $? "configure gnustep-make failed"

    make install
    checkError $? "Make install gnutsep-make failed"

	popd
	
	#clean up
	rm gnustep-make-2.6.2.tar.gz
	rm -r gnustep-make-2.6.2
	popd
}

if [ ! -f $MIRAI_SDK_PREFIX/share/GNUstep/Makefiles/GNUstep.sh ]; then
	echo "build GNUstep make..."
    buildGNUstepMake
	checkError $? "build gnustep-make failed"
fi

#5. build runtime: (libobjc, libdispatch, libffi, libxml)
echo "build Runtime..."
pushd $SCRIPT_ROOT/runtime
./buildRuntime
checkError $? "Make install runtime failed"

popd

### objc runtime ready ###
echo "successful build objc runtime."

echo "start building Foundation..."

#6. iccu
if [ ! -f $MIRAI_SDK_PREFIX/lib/libicui18n.a ]; then
	pushd $SCRIPT_ROOT/icu
	./build_icu.sh
	checkError $? "Make install icu failed"
	popd
fi

#7. libiconv
if [ ! -f $MIRAI_SDK_PREFIX/lib/libiconv.a ]; then
	pushd $SCRIPT_ROOT/iconv
	./build_iconv.sh
	checkError $? "Make install iconv failed"
	popd
fi

. $MIRAI_SDK_PREFIX/share/GNUstep/Makefiles/GNUstep.sh

#8. Foundation(gnustep-base)
if [ ! -f $MIRAI_SDK_PREFIX/lib/libgnustep-base.so ]; then
	pushd $MIRAI_PROJECT_ROOT_PATH/Mirai-Foundation
	./toolchain_build.sh
	checkError $? "build gnustep-base failed"
	popd
fi

#9. Dependencies
pushd $SCRIPT_ROOT/dependencies
./build.sh
checkError $? "build dependencies failed"

popd

#10. CoreFoundation (gnustep-corebase)
if [ ! -f $MIRAI_SDK_PREFIX/lib/libgnustep-corebase.so ]; then
	pushd $MIRAI_PROJECT_ROOT_PATH/Mirai-CoreFoundation
	./toolchain_build.sh
	checkError $? "build Core Foundation failed"
	popd
fi

#11.