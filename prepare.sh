#!/bin/sh

set -e

printUsage()
{
	echo "Usage: prepare.sh [options]
	
Options:
	-a <ABI>: build with abi, which is one of values:[arm x86]; default value is arm
	-j <JDK_PATH>: PATH of JDK
	-n <NDK_PATH>: PATH of NDK
	-k : keep downloaded files.
	-h : show this help infomation
	-f : force rebuild cocoa frameworks
	"
}

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

################ parser options ################

OPTION_ABI=arm
OPTION_KEEP_FILES=no
OPTION_NDK_PATH=""
OPTION_JDK_PATH=""
OPTION_REBUILD_COCOA=no

while getopts 'a:fjnkh' opt ; do
	 case $opt in
		 a) OPTION_ABI=$OPTARG ;;
		 f) OPTION_REBUILD_COCOA=yes ;;
		 k) OPTION_KEEP_FILES=yes ;;
		 n) OPTION_NDK_PATH=$OPTARG ;;
		 j) OPTION_JDK_PATH=$OPTARG ;;
		 h) printUsage; exit 0 ;;
		 *) echo "unknow opt:$opt"
		 	printUsage
		 	exit 1
		 	;;
	 esac
done

################ env setting ################

##-k: should clean up
export MIRAI_CLEAN_UP="yes"
if [ $OPTION_KEEP_FILES != no ]; then
	MIRAI_CLEAN_UP="no"
fi

## ABI setting
export ABI=$OPTION_ABI

case $ABI in
	arm)
		export ARCH_PREFIX=arm
		export TOOL_PREFIX=$ARCH_PREFIX-linux-androideabi
		export ABILIBNAME=armeabi
		export ARCHFLAGS="-march=armv7-a -mfloat-abi=softfp -mfpu=vfpv3-d16"
		export ARCHLDFLAGS="-march=armv7-a -Wl,--fix-cortex-a8"
		export HOSTEABI="$ARCH_PREFIX-linux-androideabi"
		export TARGETEABI="$ARCH_PREFIX-linux-androideabi"
		
		;;
	x86)
		export ARCH_PREFIX=i686
		export TOOL_PREFIX=$ARCH_PREFIX-linux-android
		export ABILIBNAME=x86
		export ARCHFLAGS=""
		export ARCHLDFLAGS=""
		export HOSTEABI="$ARCH_PREFIX-linux-android"
		export TARGETEABI="$ARCH_PREFIX-linux-android"
		
		;;
	*)
		echo "Unknow ABI:$ABI";
		exit 1
esac

export CROSS_CLANG=$TOOL_PREFIX-clang
export CROSS_CLANGPP=$TOOL_PREFIX-clang++
export CROSS_GCC=$TOOL_PREFIX-gcc
export CROSS_LD=$TOOL_PREFIX-ld
export CROSS_GXX=$TOOL_PREFIX-g++
export CROSS_AR=$TOOL_PREFIX-ar
export CROSS_RANLIB=$TOOL_PREFIX-ranlib
export CROSS_OBJDUMP=$TOOL_PREFIX-objdump
export CROSS_GDB=$TOOL_PREFIX-gdb

## NDK and JDK PATH
export MIRAI_TOOLCHAIN_ANDROID_PATH="$MIRAI_PROJECT_ROOT_PATH/toolchain/android"
export MIRAI_PRODUCTS_ANDROID_PATH="$MIRAI_TOOLCHAIN_ANDROID_PATH"

if [ "$OPTION_NDK_PATH" != "" ]; then
	export ANDROID_NDK_PATH=$OPTION_NDK_PATH
fi

if [ "$OPTION_JDK_PATH" != "" ]; then
	export ANDROID_JDK_PATH=$OPTION_JDK_PATH
fi

if [ "$ANDROID_NDK_PATH" == "" ]; then
export ANDROID_NDK_PATH="$MIRAI_PRODUCTS_ANDROID_PATH/android-ndk-r10e"
fi
if [ "$ANDROID_JDK_PATH" == "" ]; then
export ANDROID_JDK_PATH="$MIRAI_PRODUCTS_ANDROID_PATH/android-sdk-macosx"
fi

### folder setting
export MIRAI_SDK_PATH="/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/Android18.sdk"
export MIRAI_SDK_PREFIX="$MIRAI_SDK_PATH/usr"
export MIRAI_SDK_PKG_CONFIG_PATH="$MIRAI_SDK_PREFIX/lib/pkgconfig"

export MIRAI_LOCAL_XCODE_SDK_PATH="$MIRAI_TOOLCHAIN_ANDROID_PATH/Android18.sdk"
export MIRAI_LOCAL_XCODE_SDK_PATH_ARCH="$MIRAI_TOOLCHAIN_ANDROID_PATH/Android18-$ABI.sdk"
export MIRAI_LOCAL_XCODE_SDK_PREFIX="$MIRAI_LOCAL_XCODE_SDK_PATH/usr"

export STANDALONE_TOOLCHAIN_PATH="$MIRAI_TOOLCHAIN_ANDROID_PATH/android-toolchain-$ABI"
export GNUSTEP_MAKE_CONFIG_PATH="$SCRIPT_ROOT/gnu-config"

export PKG_CONFIG_LIBDIR=$MIRAI_SDK_PREFIX/lib/pkgconfig
export PKG_CONFIG_PATH=$PKG_CONFIG_LIBDIR

export SYSROOTFLAGS="--sysroot $MIRAI_SDK_PATH"

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

## check aclocal 
checkToolExists "aclocal"

## check ant
checkToolExists "ant"

## function to check error
checkError()
{
    if [ "${1}" -ne "0" ]; then
        echo "*** Error: ${2}"
        exit ${1}
    fi
}

## function to cleanup files
cleanUp()
{
	if [ "$MIRAI_CLEAN_UP" == "yes" ]; then
		#clean up ndk 
		pushd $MIRAI_PRODUCTS_ANDROID_PATH
			if [ -d $ANDROID_NDK_PATH ]; then
				rm android-ndk-r10e-darwin-x86_64.bin
			fi
		popd
		
		#clean up jdk
		pushd $MIRAI_PRODUCTS_ANDROID_PATH
			rm android-sdk_r24.4.1-macosx.zip
		popd
		
		#clean up
		cleanupGNUstepMake
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

	if [[ `uname -s` != "Darwin" ]]; then
		echo "Mac OS X is the only supported system"
		exit 1
	fi

	
	if [ ! -f android-ndk-r10e-darwin-x86_64.bin ]; then
		echo "Downloadng Android NDK..."
		echo "Getting http://dl.google.com/android/ndk/android-ndk-r10e-darwin-x86_64.bin"
		curl -O http://dl.google.com/android/ndk/android-ndk-r10e-darwin-x86_64.bin
		checkError $? "Download ndk failed.."
		chmod a+x android-ndk-r10e-darwin-x86_64.bin
	fi
	
	./android-ndk-r10e-darwin-x86_64.bin
	
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
	if [ ! -f android-sdk_r24.4.1-macosx.zip ]; then
		echo "Downloadng Android SDK ..."
		echo "Getting android-sdk_r24.4.1-macosx.zip"
		curl -O http://dl.google.com/android/android-sdk_r24.4.1-macosx.zip
		checkError $? "Download Android SDK failed.."
	fi
	
	tar -vxzf android-sdk_r24.4.1-macosx.zip
	if [ ! -d $ANDROID_JDK_PATH ]; then
		echo "Missing Android SDK folder, take a look what's extracted folder name"
		exit 1;
	fi
	
	popd
fi

##TODO: rebuild clang

#2. make standalone toolchain path
if [ ! -d $STANDALONE_TOOLCHAIN_PATH ]; then
    $ANDROID_NDK_PATH/build/tools/make-standalone-toolchain.sh --platform="android-14" --install-dir=$STANDALONE_TOOLCHAIN_PATH --arch=$ABI --llvm-version=3.6
	
	
	cp $ANDROID_NDK_PATH/sources/cxx-stl/gnu-libstdc++/4.8/libs/$ABILIBNAME/libgnustl_shared.so $STANDALONE_TOOLCHAIN_PATH/sysroot/usr/lib/
	#cp $ANDROID_NDK_PATH/toolchains/$API-4.8/prebuilt/darwin-x86_64/lib/gcc/$TOOL_PREFIX/4.8/libgcc.a $STANDALONE_TOOLCHAIN_PATH/sysroot/usr/lib/
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
cp -R "$SCRIPT_ROOT/Xcode_Integration/Xcode_SDK_Structural/" "$MIRAI_LOCAL_XCODE_SDK_PATH_ARCH"
rm -r $MIRAI_LOCAL_XCODE_SDK_PATH
ln -sf $MIRAI_LOCAL_XCODE_SDK_PATH_ARCH $MIRAI_LOCAL_XCODE_SDK_PATH

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

    CC="$CROSS_CLANG" CXX="$CROSS_CLANGPP" CPPFLAGS="$SYSROOTFLAGS" CFLAGS="$SYSROOTFLAGS" ./configure --prefix=$MIRAI_SDK_PREFIX --host="$HOSTEABI"
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
if [ ! -f $MIRAI_SDK_PREFIX/lib/libFoundation.so ] || 
	[ "$OPTION_REBUILD_COCOA" == "yes" ]; then
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
if [ ! -f $MIRAI_SDK_PREFIX/lib/libCoreFoundation.so ] || 
	[ "$OPTION_REBUILD_COCOA" == "yes" ]; then
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
if [ ! -f $MIRAI_SDK_PREFIX/lib/libCoreGraphics.so ] || 
	[ "$OPTION_REBUILD_COCOA" == "yes" ]; then
	pushd $MIRAI_PROJECT_ROOT_PATH/Mirai-CoreGraphics
	./toolchain_build.sh
	checkError $? "build CoreGraphics failed"
	popd
fi

#################
### Core Text ###
#################

#16.Core Text
if [ ! -f $MIRAI_SDK_PREFIX/lib/libCoreText.so ] || 
	[ "$OPTION_REBUILD_COCOA" == "yes" ]; then
	pushd $MIRAI_PROJECT_ROOT_PATH/Mirai-CoreText
	./toolchain_build.sh
	checkError $? "build CoreText failed"
	popd
fi

#17. OpenGL ES
if [ ! -f $MIRAI_SDK_PREFIX/lib/libOpenGLES.so ] || 
	[ "$OPTION_REBUILD_COCOA" == "yes" ]; then
	pushd $MIRAI_PROJECT_ROOT_PATH/Mirai-OpenGLES
	./toolchain_build.sh
	checkError $? "build OpenGLES failed"
	popd
fi

#18. QuartzCore
if [ ! -f $MIRAI_SDK_PREFIX/lib/libQuartzCore.so ] || 
	[ "$OPTION_REBUILD_COCOA" == "yes" ]; then
	pushd $MIRAI_PROJECT_ROOT_PATH/Mirai-QuartzCore
	./toolchain_build.sh
	checkError $? "build QuartzCore failed"
	popd
fi

#############
### UIKit ###
#############

#19. create a empty availability
#20. TNJavaHelper
#21. UIKit
if [ ! -f $MIRAI_SDK_PREFIX/lib/libUIKit.so ] || 
	[ "$OPTION_REBUILD_COCOA" == "yes" ]; then
	pushd $MIRAI_PROJECT_ROOT_PATH/Mirai-UIKit
	./toolchain_build.sh
	checkError $? "build UIKit failed"
	popd
fi

#22. MediaPlayer
if [ ! -f $MIRAI_SDK_PREFIX/lib/libMediaPlayer.so ] || 
	[ "$OPTION_REBUILD_COCOA" == "yes" ]; then
	pushd $MIRAI_PROJECT_ROOT_PATH/Mirai-MediaPlayer
	./toolchain_build.sh
	checkError $? "build MediaPlayer failed"
	popd
fi

if [ ! -f $MIRAI_SDK_PREFIX/lib/libAVFoundation.so ] || 
	[ "$OPTION_REBUILD_COCOA" == "yes" ]; then
	pushd $MIRAI_PROJECT_ROOT_PATH/Mirai-AVFoundation
	./toolchain_build.sh
	checkError $? "build AVFoundation failed"
	popd
fi

if [ ! -f $MIRAI_SDK_PREFIX/lib/libCommonCrypto.so ] || 
	[ "$OPTION_REBUILD_COCOA" == "yes" ]; then
	pushd $MIRAI_PROJECT_ROOT_PATH/Mirai-CommonCrypto
	./toolchain_build.sh
	checkError $? "build CommonCrypto failed"
	popd
fi

if [ ! -f $MIRAI_SDK_PREFIX/lib/libImageIO.so ] || 
	[ "$OPTION_REBUILD_COCOA" == "yes" ]; then
	pushd $MIRAI_PROJECT_ROOT_PATH/Mirai-ImageIO
	./toolchain_build.sh
	checkError $? "build ImageIO failed"
	popd
fi

if [ ! -f $MIRAI_SDK_PREFIX/lib/libSecurity.so ] || 
	[ "$OPTION_REBUILD_COCOA" == "yes" ]; then
	pushd $MIRAI_PROJECT_ROOT_PATH/Mirai-Security
	./toolchain_build.sh
	checkError $? "build Security failed"
	popd
fi

if [ ! -f $MIRAI_SDK_PREFIX/lib/libSystemConfiguration.so ] || 
	[ "$OPTION_REBUILD_COCOA" == "yes" ]; then
	pushd $MIRAI_PROJECT_ROOT_PATH/Mirai-SystemConfiguration
	./toolchain_build.sh
	checkError $? "build SystemConfiguration failed"
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

