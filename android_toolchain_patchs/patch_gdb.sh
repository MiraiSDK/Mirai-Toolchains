#!/bin/bash


if [[ "$STANDALONE_TOOLCHAIN_PATH" == "" ]]; then
	echo "ERROR: unknow: STANDALONE_TOOLCHAIN_PATH"
	echo "You direct run this script? this script is called by prepare.sh"
	exit 1
fi

build_gdb() 
{
	
	if [[ ! -d android_toolchain_gdb ]]; then
		git clone https://github.com/MiraiSDK/android_toolchain_gdb.git
	fi
	
	pushd android_toolchain_gdb/gdb-7.7

	./configure --target=arm-linux-androideabi --prefix=$STANDALONE_TOOLCHAIN_PATH

	make -j4

	make install


	popd
	
	#clean up
	rm -rf android_toolchain_gdb
}

#check version

GDBVERSION=`$STANDALONE_TOOLCHAIN_PATH/bin/arm-linux-androideabi-gdb --version | head -n 1`
echo "gdb version: $GDBVERSION"
if [[ "$GDBVERSION" != "GNU gdb (GDB) 7.7" ]]; then
	echo "building gdb 7.7..."
	
	build_gdb
	
fi