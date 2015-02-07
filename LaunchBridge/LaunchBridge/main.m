//
//  main.m
//  LaunchBridge
//
//  Created by Chen Yonghui on 3/21/14.
//  Copyright (c) 2014 sycx. All rights reserved.
//

#import <Foundation/Foundation.h>

static NSString *gShellPath = @"/bin/bash";

void cleanLog()
{
    
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:gShellPath];
    [task setArguments:@[@"-lc",@"adb logcat -c"]];
    
    [task launch];
    [task waitUntilExit];
}

NSString* searchFileInPath(NSString *file,NSString *path)
{
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:gShellPath];
    NSString *command = [NSString stringWithFormat:@"find . -name %@",file];
    [task setArguments:@[@"-lc",command]];
    [task setCurrentDirectoryPath:path];
    
    NSPipe *output = [NSPipe pipe];
    [task setStandardOutput:output];
    [task launch];
    [task waitUntilExit];
    
    NSFileHandle *read = [output fileHandleForReading];
    NSData *data = [read readDataToEndOfFile];
    NSString *o = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSArray *results = [o componentsSeparatedByString:@"\n"];
    NSLog(@"output:%@",results);
    NSString *firstMatch = [results firstObject];
    
    if ([firstMatch length]>0) {
        firstMatch = [path stringByAppendingPathComponent:firstMatch];
        
        return firstMatch;
    }
    return nil;
}

void perpareBreakpoints(NSString *targetProjectRoot, NSString *targetAndroid)
{
    // search Breakpoints_v2.xcbkptlist
    NSString *xcbptlistFile = searchFileInPath(@"Breakpoints_v2.xcbkptlist", targetProjectRoot);
    NSLog(@"xcbptlistFile:%@",xcbptlistFile);
    if (xcbptlistFile == nil) {
        xcbptlistFile = @"";
    }
    
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:gShellPath];
    
    NSString *gdbsetupFile = [targetAndroid stringByAppendingPathComponent:@"obj/local/armeabi/gdbbreakpoint.setup"];
    NSString *command = [NSString stringWithFormat:@"BreakPointsConvert %@ -o %@",xcbptlistFile,gdbsetupFile];
    
    [task setArguments:@[@"-lc",command]];
    [task launch];
    [task waitUntilExit];
    
}

void startTargetApp()
{
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:gShellPath];
    [task setArguments:@[@"-lc",@"shell am start -n org.tiny4.BasicCairo/org.tiny4.BasicCairo.MainHActivity"]];
    [task launch];
}

void degugTargetApp(NSString *targetProjectAndroidRoot)
{
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:gShellPath];
    [task setCurrentDirectoryPath:targetProjectAndroidRoot];
    [task setArguments:@[@"-lc",@"ndk-gdb --start --exec=./obj/local/armeabi/gdbbreakpoint.setup"]];
    [task launch];
}

void installTargetApp(NSString *targetProjectAndroidRoot)
{
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:gShellPath];
    [task setArguments:@[@"-lc",@"ant debug install"]];
    [task setCurrentDirectoryPath:targetProjectAndroidRoot];
    
    [task launch];
    [task waitUntilExit];

}

void forwardLog()
{
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:gShellPath];
    [task setArguments:@[@"-lc",@"adb logcat -s NSLog DEBUG"]];
    [task launch];
    [task waitUntilExit];

}

//
// usage: launchbridge project_path android_path
//
//
int main(int argc, const char * argv[])
{

    @autoreleasepool {

        if (argc < 3) {
            NSLog(@"Usage:launchbridge project_path android_path");
            return 1;
        }
        
        BOOL debugMode = YES;

        NSString *xcodeProjectPath = [NSString stringWithCString:argv[1] encoding:NSUTF8StringEncoding];
        NSString *androidProjectPath = [NSString stringWithCString:argv[2] encoding:NSUTF8StringEncoding];
        NSLog(@"project:%@\nandroid:%@",xcodeProjectPath,androidProjectPath);
        
        BOOL isArgumentsLegality = YES;
        if (![[NSFileManager defaultManager] fileExistsAtPath:xcodeProjectPath]) {
            NSLog(@"path not exist:%@",xcodeProjectPath);
            isArgumentsLegality = NO;
        }
        
        if (![[NSFileManager defaultManager] fileExistsAtPath:androidProjectPath]) {
            NSLog(@"path not exist:%@",androidProjectPath);
            isArgumentsLegality = NO;
        }
        if (!isArgumentsLegality) {
            return 1;
        }
        
        // first install android app to device
        installTargetApp(androidProjectPath);
        
        NSLog(@"===========Install Finished.===========");

        cleanLog();
        
        if (debugMode) {
            perpareBreakpoints(xcodeProjectPath,androidProjectPath);
            degugTargetApp(androidProjectPath);
        } else {
//            startTargetApp();
        }
        
        forwardLog();
    }
    return 0;
}

