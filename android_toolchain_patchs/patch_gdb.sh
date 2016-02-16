#!/bin/bash


if [[ "$STANDALONE_TOOLCHAIN_PATH" == "" ]]; then
	echo "ERROR: unknow: STANDALONE_TOOLCHAIN_PATH"
	echo "You direct run this script? this script is called by prepare.sh"
	exit 1
fi

checkError()
{
    if [ "${1}" -ne "0" ]; then
        echo "*** Error: ${2}"
        exit ${1}
    fi
}

cleanUp()
{
	if [ "$MIRAI_CLEAN_UP" == "yes" ]; then
		#clean up
		rm -rf android_toolchain_gdb
	fi
}

build_gdb() 
{
	
	if [[ ! -d android_toolchain_gdb ]]; then
		git clone https://github.com/MiraiSDK/android_toolchain_gdb.git
	fi
	
	pushd android_toolchain_gdb/gdb-7.7

	make distclean
	rm ./config.cache
	
	GDB_TARGET=arm-linux-androideabi
	case $ABI in
		arm)
		GDB_TARGET=arm-linux-androideabi
		;;
		x86)
		GDB_TARGET=i686-pc-linux-android
		;;
		*)
		echo "Unknow GDB_TARGET"
		exit 1
	esac
	
	CFLAGS="-Wno-absolute-value" ./configure --target=$GDB_TARGET --prefix=$STANDALONE_TOOLCHAIN_PATH --program-prefix="$TOOL_PREFIX-"
	checkError $? "gdb configure failed"

	make -j4
	checkError $? "gdb make failed"

	make install
	checkError $? "gdb install failed"

	popd
}

#check version

GDB_PATHCH_LOCK_FILE="$STANDALONE_TOOLCHAIN_PATH/bin/$CROSS_GDB.patched.lock"
echo "gdb version: $GDBVERSION"
if [[ ! -f $GDB_PATHCH_LOCK_FILE ]]; then
	echo "building gdb 7.7..."
	
	build_gdb
	
	#mv $STANDALONE_TOOLCHAIN_PATH/bin/$GDB_TARGET-gdb $STANDALONE_TOOLCHAIN_PATH/bin/$CROSS_GDB
	checkError $? "gdb build failed"
	
	patch -Np0 -d $ANDROID_NDK_PATH < ./gdb_path.patch

	touch $GDB_PATHCH_LOCK_FILE
	
fi

cleanUp
