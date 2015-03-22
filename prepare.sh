#!/bin/sh

set -e

## To avoid permission issues, user should not run this script as root
if [[ $EUID -eq 0 ]]; then
	echo "This script must not be run as root" 1>&2
	exit 1
fi

pushd `pwd`/`dirname $0`
SCRIPT_ROOT=`pwd`
popd

pushd $SCRIPT_ROOT/..
export MIRAI_PROJECT_ROOT_PATH=`pwd`
popd

##should clean up
export MIRAI_CLEAN_UP="no"

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
export ARCHFLAGS="-march=armv7-a -mfloat-abi=softfp -mfpu=vfpv3-d16"
export ARCHLDFLAGS="-march=armv7-a -Wl,--fix-cortex-a8"


#### check tools required ###

function checkToolExists
{
	echo "check: $1"
	set +e
	TOOL_PATH=`which $1`
	set -e
	if [[ "$TOOL_PATH" == "" ]]; then
		echo "ERROR: the tool $1 that required is not existed, please install it"
		exit 1
	fi
}
cleanUp()
{
	if [ "$MIRAI_CLEAN_UP" == "yes" ]; then
		#clean up ndk 
		pushd $MIRAI_PRODUCTS_ANDROID_PATH
			if [ -d $ANDROID_NDK_PATH ]; then
				rm android-ndk-r9b-darwin-x86_64.tar.bz2
			fi
		popd
		
		#clean up jdk
		pushd $MIRAI_PRODUCTS_ANDROID_PATH
			rm adt-bundle-mac-x86_64-20131030.zip
		popd
		
		#clean up
		cleanupGNUstepMake
	fi
}

## check aclocal 
checkToolExists "aclocal"

## check ant
checkToolExists "ant"

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

#1. get Android NDK
mkdir -p $MIRAI_PRODUCTS_ANDROID_PATH
echo "$MIRAI_PRODUCTS_ANDROID_PATH"

if [ ! -d $ANDROID_NDK_PATH ]; then
	pushd $MIRAI_PRODUCTS_ANDROID_PATH
	
	echo "Missing Android NDK, will download it, if you already has NDK, please set it to environment: ANDROID_NDK_PATH"
	
	if [ ! -f android-ndk-r9b-darwin-x86_64.tar.bz2 ]; then
		echo "Downloadng Android NDK..."
		curl -O http://dl.google.com/android/ndk/android-ndk-r9b-darwin-x86_64.tar.bz2
	fi
	
	tar -xvyf android-ndk-r9b-darwin-x86_64.tar.bz2
	
	#patch 
	pushd $ANDROID_NDK_PATH
		patch -p0 < $SCRIPT_ROOT/android_toolchain_patchs/ndk-gdb.patch
	popd
	
	
	popd
fi

#get Android SDK
if [ ! -d $ANDROID_JDK_PATH ]; then
	pushd $MIRAI_PRODUCTS_ANDROID_PATH
	
	echo "Missing Android SDK, will download it, if you already has Android SDK, please set it to environment: ANDROID_JDK_PATH"
	if [ ! -f adt-bundle-mac-x86_64-20131030.zip ]; then
		echo "Downloadng Android SDK adt-bundle-mac-x86_64-20131030.zip..."
		curl -O http://dl.google.com/android/adt/adt-bundle-mac-x86_64-20131030.zip
	fi
	
	tar -vxzf adt-bundle-mac-x86_64-20131030.zip
	if [ ! -d $ANDROID_JDK_PATH ]; then
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

	popd
fi

echo "set PATH..."
export PATH=$PATH:$STANDALONE_TOOLCHAIN_PATH/bin # Add Android toolchain to PATH for scripting

#3. link sdk path
echo "prepare xcode sdk..."

# remove sdk floder if exist?
#if [ -d "$MIRAI_LOCAL_XCODE_SDK_PATH" ]; then
#	rm -r "$MIRAI_LOCAL_XCODE_SDK_PATH"
#fi

#patch gdb.
pushd $SCRIPT_ROOT/android_toolchain_patchs
./patch_gdb.sh
popd

# copy Xcode SDK directory structural
cp -R "$SCRIPT_ROOT/Xcode_Integration/Xcode_SDK_Structural" "$MIRAI_LOCAL_XCODE_SDK_PATH"

# link  between android-toolchain an mirai-toolchiain
ln -sfh  "$STANDALONE_TOOLCHAIN_PATH/sysroot/usr" "$MIRAI_LOCAL_XCODE_SDK_PREFIX"

# xcode integration
$SCRIPT_ROOT/Xcode_Integration/install.sh

# helper tools
pushd BreakPointsConvert
xcodebuild
rm -rf build
popd

pushd LaunchBridge
xcodebuild
rm -rf build
popd

#4. build gnustep-make
buildGNUstepMake()
{
    echo "Build GNUstep Makefiles"
	pushd $SCRIPT_ROOT/gnustep-make

    if [ ! -f gnustep-make-2.6.2.tar.gz ]; then
		echo "Downloadng gnustep-make-2.6.2..."
        curl -O ftp://ftp.gnustep.org/pub/gnustep/core/gnustep-make-2.6.2.tar.gz
		checkError $? "Download gnustep-make failed"
		
    fi
    tar -xzf gnustep-make-2.6.2.tar.gz
	checkError $? "extract gnustep-make failed"
	

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
	# we don't remove downloaded file here, because we needs re-build after objc built.
	rm -r gnustep-make-2.6.2
	popd
}

cleanupGNUstepMake()
{
	pushd $SCRIPT_ROOT/gnustep-make
	
	#clean up
	rm gnustep-make-2.6.2.tar.gz
	
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

#6. rebuild gnustep-make
if grep USE_OBJC_EXCEPTIONS $MIRAI_SDK_PREFIX/share/GNUstep/Makefiles/config.make | grep no; then
buildGNUstepMake
fi

echo "start building Foundation..."

#7. iccu
if [ ! -f $MIRAI_SDK_PREFIX/lib/libicui18n.a ]; then
	pushd $SCRIPT_ROOT/icu
	./build_icu.sh
	checkError $? "Make install icu failed"
	popd
fi

#8. libiconv
if [ ! -f $MIRAI_SDK_PREFIX/lib/libiconv.a ]; then
	pushd $SCRIPT_ROOT/iconv
	./build_iconv.sh
	checkError $? "Make install iconv failed"
	popd
fi

. $MIRAI_SDK_PREFIX/share/GNUstep/Makefiles/GNUstep.sh

#9. Foundation(gnustep-base)
if [ ! -f $MIRAI_SDK_PREFIX/lib/libgnustep-base.so ]; then
	pushd $MIRAI_PROJECT_ROOT_PATH/Mirai-Foundation
	./toolchain_build.sh
	checkError $? "build gnustep-base failed"
	popd
fi

#10. Dependencies (png, jpeg, tiff, expat, freetype, fontconfig, lcms)
pushd $SCRIPT_ROOT/dependencies
./build.sh
checkError $? "build dependencies failed"

popd

#11. CoreFoundation (gnustep-corebase)
if [ ! -f $MIRAI_SDK_PREFIX/lib/libgnustep-corebase.so ]; then
	pushd $MIRAI_PROJECT_ROOT_PATH/Mirai-CoreFoundation
	./toolchain_build.sh
	checkError $? "build Core Foundation failed"
	popd
fi

#12. patch
pushd $SCRIPT_ROOT/Xcode_Integration/toolchainPatchs
./patchToolchainLd
popd

#13. makeup fake Frameworks folders
mkdir -p $MIRAI_SDK_PATH/System/Library/Frameworks
pushd $MIRAI_SDK_PATH/System/Library/Frameworks
	mkdir -p CoreFoundation.framework Foundation.framework GNUstepBase.framework

	pushd CoreFoundation.framework
	ln -sf $MIRAI_SDK_PREFIX/include/CoreFoundation Headers
	popd
	
	pushd Foundation.framework  
	ln -sf $MIRAI_SDK_PREFIX/include/Foundation Headers
	popd
	
	pushd GNUstepBase.framework
	ln -sf $MIRAI_SDK_PREFIX/include/GNUstepBase Headers
	popd
	
popd

#####################
### Core Graphics ###
#####################
#14. cairo
if [ ! -f $MIRAI_SDK_PREFIX/lib/libcairo.a ]; then
	pushd $SCRIPT_ROOT/cairo
	./buildCairo.sh
	checkError $? "build cairo failed"
	popd
fi

#15. Core Graphics (opal)
if [ ! -f $MIRAI_SDK_PREFIX/lib/libCoreGraphics.so ]; then
	echo "build CoreGraphics..."
	pushd $MIRAI_PROJECT_ROOT_PATH/Mirai-CoreGraphics
	xcodebuild -target CoreGraphics-Android
	checkError $? "build CoreGraphics failed"
	
	#clean up
	rm -r build
	popd
fi

#################
### Core Text ###
#################

#16.Core Text
if [ ! -f $MIRAI_SDK_PREFIX/lib/libCoreText.so ]; then
	pushd $MIRAI_PROJECT_ROOT_PATH/Mirai-CoreText
	./toolchain_build.sh
	checkError $? "build CoreText failed"
	popd
fi

#17. OpenGL ES
if [ ! -f $MIRAI_SDK_PREFIX/lib/libOpenGLES.so ]; then
	pushd $MIRAI_PROJECT_ROOT_PATH/Mirai-OpenGLES
	xcodebuild -target OpenGLES-Android
	checkError $? "build OpenGLES failed"
	
	#clean up
	rm -r build
	popd
fi

#18. QuartzCore
if [ ! -f $MIRAI_SDK_PREFIX/lib/libQuartzCore.so ]; then
	pushd $MIRAI_PROJECT_ROOT_PATH/Mirai-QuartzCore
	xcodebuild -target GSQuartzCore-Android
	checkError $? "build QuartzCore failed"
	
	#clean up
	rm -r build
	popd
fi

#############
### UIKit ###
#############

#19. create a empty availability
if [ ! -f $MIRAI_SDK_PREFIX/include/Availability.h ]; then
	touch $MIRAI_SDK_PREFIX/include/Availability.h
fi

#20. TNJavaHelper
if [ ! -f $MIRAI_SDK_PREFIX/lib/libTNJavaHelper.so ]; then
	pushd $MIRAI_PROJECT_ROOT_PATH/Mirai-UIKit/TNJavaHelper
	xcodebuild -target TNJavaHelper-Android
	checkError $? "build JavaHelper failed"
	
	#clean up
	rm -r build
	popd
fi

#21. UIKit
if [ ! -f $MIRAI_SDK_PREFIX/lib/libUIKit.so ]; then
	pushd $MIRAI_PROJECT_ROOT_PATH/Mirai-UIKit
	xcodebuild -target UIKit
	checkError $? "build UIKit failed"
	
	#clean up
	rm -r build
	popd
fi

#22. MediaPlayer
if [ ! -f $MIRAI_SDK_PREFIX/lib/libMediaPlayer.so ]; then
	pushd $MIRAI_PROJECT_ROOT_PATH/Mirai-MediaPlayer
	xcodebuild -target MediaPlayer-Android
	checkError $? "build MediaPlayer failed"
	
	#clean up
	rm -r build
	popd
fi

#Print Successful Message
echo ""
echo ""
echo "###################### Build Successful ######################"
echo "Some useful information:"
echo ""
echo "  MIRAI_SDK_PATH: 	$MIRAI_SDK_PATH"
echo "ANDROID_NDK_PATH: 	$ANDROID_NDK_PATH"
echo "ANDROID_JDK_PATH: 	$ANDROID_JDK_PATH"
echo ""
echo "To use android toolchain in shell, add below path to your PATH env"
echo ""
echo "	$ANDROID_JDK_PATH/tools"
echo "	$ANDROID_JDK_PATH/platform-tools"
echo "	$ANDROID_NDK_PATH"
echo "	$STANDALONE_TOOLCHAIN_PATH/bin"
echo ""

