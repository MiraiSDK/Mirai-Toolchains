#!/bin/sh

PREFIX=$MIRAI_SDK_PREFIX

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
		#clean up pixman
		rm -r pixman-0.32.4
		rm pixman-0.32.4.tar.gz
	
		#clean up cairo
		rm -r cairo-1.12.14
		rm cairo-1.12.14.tar.xz
	
	fi
}

# 1. Pixman
buildCPUFeature()
{
	if [ ! -f $MIRAI_SDK_PREFIX/lib/cpufeatures.a ]; then
		pushd $ANDROID_NDK_PATH/sources/android/cpufeatures
		export CFLAGS="$ARCHFLAGS"
		$CLANG_ARM -c -o cpu-features.o cpu-features.c
		$AR_ARM rcs cpufeatures.a cpu-features.o
		mv cpufeatures.a $MIRAI_SDK_PREFIX/lib/
		rm cpu-features.o
		popd
	fi

}

buildPixman()
{
	buildCPUFeature
	
	if [ ! -d pixman-0.32.4 ]; then
		if [ ! -f pixman-0.32.4.tar.gz ]; then
			echo "Download pixman..."
			curl -O http://cairographics.org/releases/pixman-0.32.4.tar.gz
		fi
		tar -xvf pixman-0.32.4.tar.gz
	fi

	pushd pixman-0.32.4

	CPUFEATURES_INCLUDE=$ANDROID_NDK_PATH/sources/android/cpufeatures
	FLAGS="$ARCHFLAGS --sysroot $MIRAI_SDK_PATH -I$CPUFEATURES_INCLUDE -DPIXMAN_NO_TLS"

	CC="$CLANG_ARM" CXX="$CLANGPP_ARM" AR="$AR_ARM" RANLIB="$RANLIB_ARM" CPPFLAGS="$FLAGS" \
	CFLAGS="$FLAGS" LDFLAGS="$ARCHLDFLAGS -l$MIRAI_SDK_PREFIX/lib/cpufeatures.a" \
	PNG_CFLAGS="-I$MIRAI_SDK_PREFIX/include" PNG_LIBS="-L$MIRAI_SDK_PREFIX/lib -lpng" \
	./configure --host=arm-linux-androideabi --prefix=$PREFIX
	
	make -j4
	checkError $? "Make pixman failed"
	
	make install

	popd	
}


#3. 
buildCairo()
{
	if [ ! -d cairo-1.12.14 ]; then
		if [ ! -f cairo-1.12.14.tar.xz ]; then
			curl -O http://cairographics.org/releases/cairo-1.12.14.tar.xz
		fi
		tar -xJf cairo-1.12.14.tar.xz
		
		pushd cairo-1.12.14
		patch -p1 -i ../cairo_android_lconv.patch
		popd
	fi

	# compile
	pushd cairo-1.12.14
	export PKG_CONFIG_LIBDIR="$MIRAI_SDK_PREFIX/lib/pkgconfig:$MIRAI_SDK_PREFIX/share/pkgconfig"
	export PKG_CONFIG_PATH=$PKG_CONFIG_LIBDIR
	ARMCFLAGS="$ARCHFLAGS -DANDROID --sysroot $MIRAI_SDK_PATH -g"
	
	CC=arm-linux-androideabi-clang CXX=arm-linux-androideabi-clang++ AR=arm-linux-androideabi-ar \
	CPPFLAGS="$ARMCFLAGS" CFLAGS="$ARMCFLAGS" ./configure --host=arm-linux-androideabi \
	--prefix=$PREFIX --enable-xlib=no --enable-xcb=no --enable-glesv2
	
	make -j4
	make install

	popd
}


buildPixman
checkError $? "Make pixman failed"

buildCairo
checkError $? "Make cairo failed"

#we enable cairo glesv2, needs let pkgconfig know where is glesv2
#otherwise anything depends cairo will failed.
if [ ! -f $MIRAI_SDK_PREFIX/lib/pkgconfig/glesv2.pc ]; then
	cp glesv2.pc $MIRAI_SDK_PREFIX/lib/pkgconfig/glesv2.pc
fi

cleanUp
