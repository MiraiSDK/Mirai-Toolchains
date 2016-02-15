#!/bin/sh

PREFIX=$MIRAI_SDK_PREFIX

CAIRO_VERSION=1.14.6

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
		rm -r cairo-$CAIRO_VERSION
		rm cairo-$CAIRO_VERSION.tar.xz
	
	fi
}

# 1. Pixman
buildCPUFeature()
{
	if [ ! -f $MIRAI_SDK_PREFIX/lib/cpufeatures.a ]; then
		pushd $ANDROID_NDK_PATH/sources/android/cpufeatures
		export CFLAGS="$ARCHFLAGS"
		$CROSS_CLANG -c -o cpu-features.o cpu-features.c
		$CROSS_AR rcs cpufeatures.a cpu-features.o
		mv cpufeatures.a $MIRAI_SDK_PREFIX/lib/
		rm cpu-features.o
		popd
	fi

}

buildPixman()
{
	buildCPUFeature
	
	if [ ! -d pixman-0.34.0 ]; then
		if [ ! -f pixman-0.34.0.tar.gz ]; then
			echo "Download pixman..."
			# curl -O http://cairographics.org/releases/pixman-0.32.4.tar.gz
			curl -O http://cairographics.org/releases/pixman-0.34.0.tar.gz
			checkError $? "Download pixman failed"
		fi
		tar -xvf pixman-0.34.0.tar.gz
	fi

	pushd pixman-0.34.0

	CPUFEATURES_INCLUDE=$ANDROID_NDK_PATH/sources/android/cpufeatures
	FLAGS="$ARCHFLAGS --sysroot $MIRAI_SDK_PATH -I$CPUFEATURES_INCLUDE -DPIXMAN_NO_TLS"

	CC="$CROSS_CLANG" CXX="$CROSS_CLANGPP" AR="$CROSS_AR" RANLIB="$CROSS_RANLIB" CPPFLAGS="$FLAGS" \
	CFLAGS="$FLAGS" LDFLAGS="$ARCHLDFLAGS -l$MIRAI_SDK_PREFIX/lib/cpufeatures.a" \
	PNG_CFLAGS="-I$MIRAI_SDK_PREFIX/include" PNG_LIBS="-L$MIRAI_SDK_PREFIX/lib -lpng" \
	./configure --host=$HOSTEABI --prefix=$PREFIX
	checkError $? "Configure pixman failed"
	
	make -j4
	checkError $? "Make pixman failed"
	
	make install
	checkError $? "Install pixman failed"

	popd	
}


#3. 
buildCairo()
{
	
	if [ ! -d cairo-$CAIRO_VERSION ]; then
		if [ ! -f cairo-$CAIRO_VERSION.tar.xz ]; then
			curl -O http://cairographics.org/releases/cairo-$CAIRO_VERSION.tar.xz
			checkError $? "Download cairo failed"
		fi
		tar -xJf cairo-$CAIRO_VERSION.tar.xz
		
		pushd cairo-$CAIRO_VERSION
		patch -p0 -i ../cairo_util_trace_lconv.patch
		popd
	fi

	# compile
	pushd cairo-$CAIRO_VERSION
	export PKG_CONFIG_LIBDIR="$MIRAI_SDK_PREFIX/lib/pkgconfig:$MIRAI_SDK_PREFIX/share/pkgconfig"
	export PKG_CONFIG_PATH=$PKG_CONFIG_LIBDIR
	ARMCFLAGS="$ARCHFLAGS -DANDROID --sysroot $MIRAI_SDK_PATH -g"
	
	CC=$CROSS_CLANG CXX=$CROSS_CLANGPP AR=$CROSS_AR \
	CPPFLAGS="$ARMCFLAGS" CFLAGS="$ARMCFLAGS" ./configure --host=$HOSTEABI \
	--prefix=$PREFIX --enable-xlib=no --enable-xcb=no --enable-glesv2
	checkError $? "Configure cairo failed"

	make -j4
	checkError $? "Make cairo failed"

	make install
	checkError $? "Install cairo failed"

	popd
}


buildPixman
checkError $? "Build pixman failed"

buildCairo
checkError $? "Build cairo failed"

#we enable cairo glesv2, needs let pkgconfig know where is glesv2
#otherwise anything depends cairo will failed.
if [ ! -f $MIRAI_SDK_PREFIX/lib/pkgconfig/glesv2.pc ]; then
	cp glesv2.pc $MIRAI_SDK_PREFIX/lib/pkgconfig/glesv2.pc
fi

cleanUp
