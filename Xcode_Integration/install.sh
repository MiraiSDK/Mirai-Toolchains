#!/bin/bash

ANDROID_CLANG_PATH=`which arm-linux-androideabi-clang`
if [[ "$ANDROID_CLANG_PATH" == "" ]]; then
	echo "can not get ANDROID_CLANG_PATH:$ANDROID_CLANG_PATH"
	exit 1
fi

# link platform
#echo "Link Android.platform to Xcode..."
#ln -s ${PRODUCT_ROOT}/Xcode/Platforms/Android.platform /Applications/Xcode.app/Contents/Developer/Platforms/Android.platform

# create Specifications
echo "Create Specifications..."
template='''
(
    {
        Identifier = org.tiny4.compilers.android.clang.3.3;
        BasedOn    = com.apple.compilers.llvm.clang.1_0;
        Name       = "Android Clang 3.3";
        Version    = "org.tiny4.compilers.android.clang.3.3";
        Vendor     = "org.tiny4";
        ExecPath   = "ANDROID_CLANG_PATH";
        Architectures = (i386);

        SupportsZeroLink              = No;
        SupportsPredictiveCompilation = No;
        SupportsHeadermaps            = Yes;
        DashIFlagAcceptsHeadermaps    = Yes;

        Options = (
        {
            Name = SDKROOT;
            Type = Path;
            CommandLineArgs = ();
        },

        );

    }
)
'''

generated=${template/ANDROID_CLANG_PATH/$ANDROID_CLANG_PATH}
mkdir -p ~/Library/Application\ Support/Developer/Shared/Xcode/Specifications/
echo "$generated" > ~/Library/Application\ Support/Developer/Shared/Xcode/Specifications/android-clang-3.3.pbcompspec


if [[ "$MIRAI_LOCAL_XCODE_SDK_PATH" == "" ]]; then
	echo "env not setted: MIRAI_LOCAL_XCODE_SDK_PATH: $MIRAI_LOCAL_XCODE_SDK_PATH"
	exit 1
fi

#link 
pushd /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs
echo "Attemp to Link fake sdk to Xcode..."
echo "This operation needs sudo privilege"
sudo ln -sf "$MIRAI_LOCAL_XCODE_SDK_PATH"
popd


