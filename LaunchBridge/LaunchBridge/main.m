//
//  main.m
//  LaunchBridge
//
//  Created by Chen Yonghui on 3/21/14.
//  Copyright (c) 2014 sycx. All rights reserved.
//

#import <Foundation/Foundation.h>

void cleanLog(NSString *adbPath)
{
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:adbPath];
    [task setArguments:@[@"logcat",@"-c"]];
    
    [task launch];
    [task waitUntilExit];
}

void perpareBreakpoints(NSString *toolPath, NSString *targetProjectRoot, NSString *targetAndroid)
{
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:toolPath];
    NSString *xcbptlistFile = [targetProjectRoot stringByAppendingPathComponent:@"BasicCairo.xcodeproj/xcuserdata/chyhfj.xcuserdatad/xcdebugger/Breakpoints_v2.xcbkptlist"];
    NSString *gdbsetupFile = [targetAndroid stringByAppendingPathComponent:@"obj/local/armeabi/gdbbreakpoint.setup"];
    
    [task setArguments:@[xcbptlistFile,gdbsetupFile]];
    [task launch];
    [task waitUntilExit];
}

void startTargetApp(NSString *adbPath)
{
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:adbPath];
    [task setArguments:@[@"shell",@"am",@"start",@"-n",@"org.tiny4.BasicCairo/org.tiny4.BasicCairo.MainHActivity"]];
    [task launch];
}

void degugTargetApp(NSString *gdbPath,NSString *adbPath,NSString *targetProjectAndroidRoot)
{
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:gdbPath];
    [task setCurrentDirectoryPath:targetProjectAndroidRoot];
    [task setArguments:@[@"--start",@"--exec=./obj/local/armeabi/gdbbreakpoint.setup",[NSString stringWithFormat:@"--adb=%@",adbPath]]];
    [task launch];
}

void installTargetApp(NSString *antPath,NSString *targetProjectAndroidRoot)
{
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:antPath];
    [task setArguments:@[@"debug",@"install"]];
    [task setCurrentDirectoryPath:targetProjectAndroidRoot];
    
    [task launch];
    [task waitUntilExit];

}

void forwardLog(NSString *adbPath)
{
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:adbPath];
    [task setArguments:@[@"logcat"]];
    [task launch];
    [task waitUntilExit];

}

int main(int argc, const char * argv[])
{

    @autoreleasepool {
        
        NSString *adbPath = @"/Users/chyhfj/.SDK/Android/jdk/platform-tools/adb";
        NSString *targetProjectRoot = @"/Users/chyhfj/Development/MiraSDK/DemoProject/BasicQuartzCore";
        NSString *targetProjectAndroidRoot = @"/Users/chyhfj/Development/MiraSDK/DemoProject/BasicQuartzCore/BasicCairo-android";
        NSString *convertToolPath = @"/Users/chyhfj/Development/MiraSDK/DemoProject/BasicQuartzCore/BasicCairo-android/BreakPointsConvert";
        NSString *gdbPath = @"/Users/chyhfj/.SDK/Android/android-ndk-r9/ndk-gdb";
        NSString *antPath = @"/usr/local/bin/ant";
        installTargetApp(antPath,targetProjectAndroidRoot);
        NSLog(@"===========Install Finished.===========");

        cleanLog(adbPath);
        perpareBreakpoints(convertToolPath,targetProjectRoot,targetProjectAndroidRoot);
        startTargetApp(adbPath);
//        degugTargetApp(gdbPath,adbPath, targetProjectAndroidRoot);
        forwardLog(adbPath);

        
    }
    return 0;
}

