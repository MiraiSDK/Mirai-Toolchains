#!/bin/sh
# scripts references from http://thebugfreeblog.blogspot.jp/2013/05/cross-building-icu-for-applications-on.html

pushd `pwd`/`dirname $0`
SCRIPT_ROOT=`pwd`
popd

ICU_PREFIX=$MIRAI_SDK_PREFIX

pushd $SCRIPT_ROOT

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
		echo "Clean..."
		rm -rf build_icu_osx
		rm -rf build_icu_android
		rm -r icu
	fi
}

# 1.download icu
downloadICU()
{
	if [ ! -d icu ]; then
		echo "Downloding icu from SVN..."
		svn export http://source.icu-project.org/repos/icu/icu/tags/release-52-1/ icu
	
		checkError $? "Download icu failed"
	fi
}

#2. build build target, assume is OSX
buildOSXVersion()
{
	echo "Build osx target..."
	if [ ! -d build_icu_osx ]; then
		mkdir $SCRIPT_ROOT/build_icu_osx

		pushd $SCRIPT_ROOT/build_icu_osx

		export CPPFLAGS="-DU_USING_ICU_NAMESPACE=0 -fno-short-enums \
		-DU_HAVE_NL_LANGINFO_CODESET=0 -D__STDC_INT64__ -DU_TIMEZONE=1 \
		-DUCONFIG_NO_LEGACY_CONVERSION=1 -DUCONFIG_NO_TRANSLITERATION=0"

		../icu/source/runConfigureICU MacOSX --prefix=$PWD/icu_build --enable-extras=no --enable-strict=no -enable-static -enable-shared --enable-tests=no --enable-samples=no --enable-dyload=no --enable-debug
		make -j4
		checkError $? "Make osx version failed"
		make install
	    checkError $? "install osx version failed"
	
		popd	
	fi

}

#3. build host target
buildAndroidVersion()
{
	echo "build android target..."
	
	if [ -d $SCRIPT_ROOT/build_icu_android ]; then
		rm -rf $SCRIPT_ROOT/build_icu_android
	fi
	
	mkdir $SCRIPT_ROOT/build_icu_android
	pushd $SCRIPT_ROOT/build_icu_android

	export HOST_ICU=$SCRIPT_ROOT/build_icu_android
	export ICU_CROSS_BUILD=$SCRIPT_ROOT/build_icu_osx
	
	#
	# -DU_TIMEZONE=1
	# -DUCONFIG_NO_REGULAR_EXPRESSIONS=0
	# -DUCONFIG_NO_FORMATTING=0
	#
	# Knowing gnustep-corebase required features
	# required BREAK_ITERATION (-DUCONFIG_NO_BREAK_ITERATION = 0)
	# required COLLATION (-DUCONFIG_NO_COLLATION=0)
	#
	export CPPFLAGS="$ARCHFLAGS -I$MIRAI_SDK_PREFIX/include/ \
	-fno-short-wchar -DU_USING_ICU_NAMESPACE=0 -fno-short-enums \
	-DU_HAVE_NL_LANGINFO_CODESET=0 -D__STDC_INT64__ -DU_TIMEZONE=1 \
	-DUCONFIG_NO_LEGACY_CONVERSION=1 -DUCONFIG_NO_TRANSLITERATION=0"
	export LDFLAGS="$ARCHLDFLAGS -lc -lgnustl_shared -Wl,-rpath-link=$MIRAI_SDK_PREFIX/lib/"

	../icu/source/configure --with-cross-build=$ICU_CROSS_BUILD \
	--enable-extras=no --enable-strict=no -enable-static --disable-shared \
	--enable-tests=no --enable-samples=no --enable-dyload=no \
	--host=$HOSTEABI --prefix=$ICU_PREFIX --enable-debug
	make -j4
	checkError $? "Make android version failed"
	make install 
	checkError $? "install android version failed"

	popd
}

downloadICU
checkError $? "Download icu failed"

buildOSXVersion
checkError $? "Make install osx version failed"

buildAndroidVersion
checkError $? "Make install android version failed"

cleanUp

popd
