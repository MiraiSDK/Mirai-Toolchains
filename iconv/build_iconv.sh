#!/bin/bash


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
		rm -r libiconv-1.14
		rm libiconv-1.14.tar.gz
	fi
}

buildLibiconv()
{
	
	if [ ! -d libiconv-1.14 ]; then
		if [ ! -f libiconv-1.14.tar.gz ]; then
			echo "Downloading libiconv-1.14.tar.gz..."
			curl -O http://ftp.gnu.org/pub/gnu/libiconv/libiconv-1.14.tar.gz
		fi
		tar -xvf libiconv-1.14.tar.gz
	fi
	pushd libiconv-1.14
	
	#patch config
	cp $GNUSTEP_MAKE_CONFIG_PATH/config.sub build-aux/config.sub
	cp $GNUSTEP_MAKE_CONFIG_PATH/config.sub libcharset/build-aux/config.sub
	cp $GNUSTEP_MAKE_CONFIG_PATH/config.guess build-aux/config.guess
	cp $GNUSTEP_MAKE_CONFIG_PATH/config.guess libcharset/build-aux/config.guess
	
	gl_cv_header_working_stdint_h=yes CC=arm-linux-androideabi-clang CXX=arm-linux-androideabi-clang++ AR=arm-linux-androideabi-ar \
	CFLAGS="$ARCHFLAGS" CXXFLAGS="$ARCHFLAGS" ./configure --host=arm-linux-androideabi --prefix="$MIRAI_SDK_PREFIX" --enable-static=yes --enable-shared=no
	checkError $? "configure libiconv failed"
	
	make -j4
    checkError $? "make libiconv failed"
	
	make install
	
	popd
	
}

buildLibiconv
cleanUp
