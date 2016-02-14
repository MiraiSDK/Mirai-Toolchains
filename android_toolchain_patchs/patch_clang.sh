#!/bin/sh

checkError()
{
    if [ "${1}" -ne "0" ]; then
        echo "*** Error: ${2}"
        exit ${1}
    fi
}

pushd `pwd`/`dirname $0`
SCRIPT_ROOT=`pwd`
popd


PATCH_USE_PREBUILD=no

PATCH_LOCK_FILE="$ANDROID_NDK_PATH/toolchains/llvm-3.6/prebuilt/darwin-x86_64/bin/clang.patched.lock"
if [[ -f $PATCH_LOCK_FILE ]]; then
	echo "clang already patched. skip.."
	exit 0
fi

if [[ "$PATCH_USE_PREBUILD" == "yes" ]]; then
	cp "$ANDROID_NDK_PATH/toolchains/llvm-3.6/prebuilt/darwin-x86_64/bin/clang" "$ANDROID_NDK_PATH/toolchains/llvm-3.6/prebuilt/darwin-x86_64/bin/clang.origin"
	cp "$SCRIPT_ROOT/clang/prebuilt/darwin-x86_64/bin/clang" "$ANDROID_NDK_PATH/toolchains/llvm-3.6/prebuilt/darwin-x86_64/bin/clang"
else
	##build from source
	pushd $ANDROID_NDK_PATH
		if [[ ! -d src ]]; then
			./build/tools/download-toolchain-sources.sh --git-date=2015-05-05 src #ndk r10e released on 2015-05-05
			checkError $? "Download ndk toolchain source failed.."

			patch -d src/llvm-3.6/clang/ -p0 < $SCRIPT_ROOT/ObjCGNU.patch
			checkError $? "patch clang failed.."
		fi
		
		CC=clang ./build/tools/build-llvm.sh $(pwd)/src $(pwd) llvm-3.6 --try-64
		checkError $? "re-build llvm failed.."
	popd
fi

touch $PATCH_LOCK_FILE