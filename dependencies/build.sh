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
		#clean up libpng
		rm libpng-$LIB_PNG_VERSION.tar.gz
		rm -r libpng-$LIB_PNG_VERSION
	
		#clean up libjpeg
		rm libjpeg-turbo-1.3.0.tar.gz
		rm -r libjpeg-turbo-1.3.0
	
		#clean up tiff
		rm tiff-4.0.3.tar.gz
		rm -r tiff-4.0.3
		
		#clean up freetype
		rm freetype-2.5.1.tar.gz
		rm -rf freetype-2.5.1
		
		#clean up fontconfig
		rm -rf fontconfig
	
		#clean up expat
		rm expat-2.1.0.tar.gz
		rm -r expat-2.1.0
	
		#clean up lcms
		rm lcms-1.19.tar.gz
		rm -r lcms-1.19
	fi
}

buildLibPNG()
{
	
	if [ ! -d libpng ]; then
		git clone https://github.com/MiraiSDK/libpng.git
		pushd libpng
		git checkout tags/v1.6.16
		./autogen.sh
		popd
	fi

	pushd libpng

	FLAGS="$ARCHFLAGS --sysroot $MIRAI_SDK_PATH"

	CC=$CROSS_CLANG CXX=$CROSS_CLANGPP AR=$CROSS_AR CPPFLAGS="$FLAGS" CFLAGS="$FLAGS" \
		./configure --host=$HOSTEABI --prefix=$PREFIX
	checkError $? "Configure libpng failed"
	
	make -j4
	checkError $? "Make libpng failed"

	make install
	checkError $? "Install libpng failed"

	make clean
	
	popd	
}

buildLibJPEG()
{
	if [ ! -d libjpeg-turbo-1.3.0 ]; then
		if [ ! -f libjpeg-turbo-1.3.0.tar.gz ]; then
			echo "Download libjpeg-turbo..."
			curl -O http://heanet.dl.sourceforge.net/project/libjpeg-turbo/1.3.0/libjpeg-turbo-1.3.0.tar.gz
		fi
		tar -xvf libjpeg-turbo-1.3.0.tar.gz
		
		cp $GNUSTEP_MAKE_CONFIG_PATH/config.sub libjpeg-turbo-1.3.0/config.sub
		cp $GNUSTEP_MAKE_CONFIG_PATH/config.guess libjpeg-turbo-1.3.0/config.guess
	fi

	pushd libjpeg-turbo-1.3.0

	CC=$CROSS_CLANG CXX=$CROSS_CLANGPP AR=$CROSS_AR RANLIB=$CROSS_RANLIB \
	CFLAGS="$ARCHFLAGS" CPPFLAGS="$ARCHFLAGS" ./configure --host=$HOSTEABI --prefix=$PREFIX
	checkError $? "Configure libjpeg failed"
	
	make -j4
	checkError $? "Make libjpeg failed"
	
	make install
	checkError $? "Install libjpeg failed"
	
	make clean
	
	popd
}

buildLibTIFF()
{
	if [ ! -d tiff-4.0.3 ]; then
		if [ ! -f tiff-4.0.3.tar.gz ]; then
			echo "Download tiff..."
			curl -O http://download.osgeo.org/libtiff/tiff-4.0.3.tar.gz
		fi
		tar -xvf tiff-4.0.3.tar.gz
		cp $GNUSTEP_MAKE_CONFIG_PATH/config.sub tiff-4.0.3/config/config.sub
		cp $GNUSTEP_MAKE_CONFIG_PATH/config.guess tiff-4.0.3/config/config.guess
	fi

	pushd tiff-4.0.3

	CC=$CROSS_CLANG CXX=$CROSS_CLANGPP AR=$CROSS_AR RANLIB=$CROSS_RANLIB \
	CFLAGS="$CFLAGS $ARCHFLAGS" CPPFLAGS="$CPPFLAGS $ARCHFLAGS" ./configure --host=$HOSTEABI --prefix=$PREFIX --enable-shared=no
	checkError $? "Configure libtiff failed"
	
	make -j4
	checkError $? "Make libtiff failed"
	
	make install
	checkError $? "Install libtiff failed"

	make clean
	
	popd
}

buildFreetype()
{
	if [ ! -d freetype-2.5.1 ]; then
		if [ ! -f freetype-2.5.1.tar.gz ]; then
			curl -O http://ftp.twaren.net/Unix/NonGNU//freetype/freetype-2.5.1.tar.gz
		fi
		tar -xvf freetype-2.5.1.tar.gz
	fi

	pushd freetype-2.5.1
	
	LIBPNG_CFLAGS="-I$PREFIX/include/libpng16" LIBPNG_LIBS="-L$PREFIX/lib -lpng16" \
	CFLAGS="$ARCHFLAGS" CPPFLAGS="$ARCHFLAGS" ./configure --host=$HOSTEABI --prefix=$PREFIX --without-zlib
	checkError $? "Configure freetype failed"
	
	make -j4
	checkError $? "Make freetype failed"
	
	make install
	checkError $? "Install freetype failed"
	
	make clean

	popd	
}

buildFontconfig()
{
	if [ ! -d fontconfig ]; then
		git clone git://anongit.freedesktop.org/fontconfig
		
		pushd fontconfig
			git checkout tags/2.11.92
			
			patch -p1 -i ../fontconfig_android_lconv.patch
			patch -p1 -i ../fontconfig_autogen.patch
			
			./autogen.sh
		popd
	fi

	pushd fontconfig

	export PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig"
	CC=$CROSS_CLANG CXX=$CROSS_CLANGPP AR=$CROSS_AR RANLIB=$CROSS_RANLIB CFLAGS="$ARCHFLAGS -DANDROID" CPPFLAGS="$ARCHFLAGS -DANDROID"  ./configure --host=$HOSTEABI --prefix=$PREFIX  --with-default-fonts="/data/local/tmp/fonts" --enable-static=yes #--with-cache-dir="/sdcard/.fccache"
	checkError $? "configure fontconfig failed"
	make -j4
	checkError $? "Make fontconfig failed"
	
	make install
	checkError $? "install fontconfig failed"
	
	make clean

	popd
}

buildExpat()
{
	if [ ! -d expat-2.1.0 ]; then
		if [ ! -f expat-2.1.0.tar.gz ]; then
			curl -O http://heanet.dl.sourceforge.net/project/expat/expat/2.1.0/expat-2.1.0.tar.gz
		fi
		
		tar -xvf expat-2.1.0.tar.gz
	fi

	pushd expat-2.1.0

	CC=$CROSS_CLANG CXX=$CROSS_CLANGPP AR=$CROSS_AR RANLIB=$CROSS_RANLIB \
	CFLAGS="$ARCHFLAGS" CPPFLAGS="$ARCHFLAGS" ./configure --host=$HOSTEABI --prefix=$PREFIX 
	checkError $? "Configure expat failed"
	
	make -j4
	checkError $? "Make expat failed"
	
	make install
	checkError $? "Install expat failed"
	
	make clean

	popd
}

buildLCMS()
{
	if [ ! -d lcms-1.19 ]; then
		if [ ! -f lcms-1.19.tar.gz ]; then
			curl -O http://heanet.dl.sourceforge.net/project/lcms/lcms/1.19/lcms-1.19.tar.gz
		fi
		
		tar -xvf lcms-1.19.tar.gz

		cp $GNUSTEP_MAKE_CONFIG_PATH/config.sub lcms-1.19/config.sub
		cp $GNUSTEP_MAKE_CONFIG_PATH/config.guess lcms-1.19/config.guess
		
		pushd lcms-1.19
		patch -p1 -i ../lcms_android_swab.patch
		popd
	fi

	pushd lcms-1.19

	export CFLAGS="$ARCHFLAGS -DANDROID"
	CC=$CROSS_CLANG CXX=$CROSS_CLANGPP AR=$CROSS_AR RANLIB=$CROSS_RANLIB \
	CPPFLAGS="$ARCHFLAGS" ./configure --host=$HOSTEABI --prefix=$PREFIX 
	checkError $? "Configure lcms failed"
	
	make -j4
	checkError $? "Make lcms failed"
	
	make install
	checkError $? "Install lcms failed"

	make clean

	popd
}

if [ ! -f $MIRAI_SDK_PREFIX/lib/libpng.a ]; then
buildLibPNG
checkError $? "Make libpng failed"
fi

if [ ! -f $MIRAI_SDK_PREFIX/lib/libjpeg.a ]; then
buildLibJPEG
checkError $? "Make libjpeg failed"
fi

if [ ! -f $MIRAI_SDK_PREFIX/lib/libtiff.a ]; then
buildLibTIFF
checkError $? "Make libtiff failed"
fi

if [ ! -f $MIRAI_SDK_PREFIX/lib/libexpat.a ]; then
buildExpat
checkError $? "Make expat failed"
fi

if [ ! -f $MIRAI_SDK_PREFIX/lib/libfreetype.a ]; then
buildFreetype
checkError $? "Make freetype failed"
fi

if [ ! -f $MIRAI_SDK_PREFIX/lib/libfontconfig.a ]; then
buildFontconfig
checkError $? "Make fontconfig failed"
fi

if [ ! -f $MIRAI_SDK_PREFIX/lib/liblcms.a ]; then
buildLCMS
checkError $? "Make lcms failed"
fi

cleanUp


