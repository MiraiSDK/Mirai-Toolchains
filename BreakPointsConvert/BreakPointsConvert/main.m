//
//  main.m
//  BreakPointsConvert
//
//  Created by Chen Yonghui on 3/20/14.
//  Copyright (c) 2014 sycx. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <getopt.h>

#import "TNBreakPoint.h"

//
// BreakPointsConvert input [-o output]
//
//
struct globalArgs_t {
    const char *outFileName;    /* -o option */
    int verbosity;              /* -v option */
    const char *inputFileName;

} globalArgs;

static const char *optString = "o:vh?";

static struct option long_options[] =
{
    {"verbose", no_argument,        NULL,  'v'},
    {"output",  required_argument,  NULL,  'o'},
    {"help",    no_argument,        NULL,  'h'},
    {NULL,      no_argument,        NULL,   0 }
};

void display_usage()
{
    printf("usage: BreakPointsConvert [input file] [-o outputfile]\n");
}

NSArray *breakpointsFromPath(NSString *path)
{
    if (!path) {
        return @[];
    }
    
    NSString *absolutePath = path;
    if (![path isAbsolutePath]) {
        absolutePath = [[[NSFileManager defaultManager] currentDirectoryPath] stringByAppendingPathComponent:path];
    }
    
    //load input file
    if (![[NSFileManager defaultManager] fileExistsAtPath:absolutePath]) {
        return @[];
    }
    
    NSError *inputLoadError = nil;
    NSString *input = [NSString stringWithContentsOfFile:absolutePath encoding:NSUTF8StringEncoding error:&inputLoadError];
    if (inputLoadError) {
        NSLog(@"load input file failed: %@",inputLoadError);
        return @[];
    }
    
    NSError *xmlLoadingError = nil;
    NSXMLDocument *document = [[NSXMLDocument alloc] initWithXMLString:input options:0 error:&xmlLoadingError];
    
    NSXMLElement *rootElement = document.rootElement;
    
    NSString *type = [[rootElement attributeForName:@"type"] stringValue];
    NSString *version = [[rootElement attributeForName:@"version"] stringValue];
    NSXMLElement *breakpoints = (NSXMLElement *)[rootElement childAtIndex:0];
    
    NSMutableArray *breakPoints = [NSMutableArray array];
    for (NSXMLElement *breakpointProxy in breakpoints.children) {
        TNBreakPoint* bp = [TNBreakPoint breakPointWithProxyElement:breakpointProxy];
        if (bp) {
            [breakPoints addObject:bp];
        }
    }
    
    return breakPoints;
}

int main(int argc, const char * argv[])
{
    globalArgs.verbosity = 0;
    globalArgs.outFileName = NULL;
    
    int c;
    while (1) {
        int option_index = 0;
        
        c = getopt_long(argc, argv, optString, long_options, &option_index);
        
        if (c== -1) {
            break;
        }
        
        switch (c) {
            case 0:
                
                break;
            case 'o':
                globalArgs.outFileName = optarg;
                break;
            case 'v':
                globalArgs.verbosity++;
                break;
            case 'h':
            case '?':
                display_usage();
                return 0;
                break;
            default:
                break;
        }
    }
    
    globalArgs.inputFileName = *(argv + optind);
    
    if (globalArgs.verbosity) {
        printf("input file:%s",globalArgs.inputFileName);
    }
    
    @autoreleasepool {
        
        NSString *inputPath;
        if (globalArgs.inputFileName) {
            inputPath = [NSString stringWithUTF8String:globalArgs.inputFileName];
        }
        
        
        NSString *outputPath;
        if (globalArgs.outFileName) {
            outputPath = [NSString stringWithUTF8String:globalArgs.outFileName];
            
            if (![outputPath isAbsolutePath]) {
                outputPath = [[[NSFileManager defaultManager] currentDirectoryPath] stringByAppendingPathComponent:outputPath];
            }
        }
        
        if (globalArgs.verbosity) {
            NSLog(@"process input:%@ output:%@",inputPath,outputPath);
        }
        
        
        NSArray *breakPoints = breakpointsFromPath(inputPath);
        
        NSMutableArray *commands = [[breakPoints valueForKeyPath:@"gdbCommand"] mutableCopy];
        [commands removeObject:@""];
        [commands insertObject:@"set breakpoint pending on" atIndex:0];
        [commands addObject:@"b -[NSException raise]"];
        [commands addObject:@"set unwindonsignal on"];
        [commands insertObject:@"set pagination off" atIndex:0];
        [commands addObject:@"c"];
        [commands addObject:@""];
        NSString *output = [commands componentsJoinedByString:@"\n"];
        
        if (outputPath) {
            NSError *writingError = nil;
            BOOL writeSuccess = [output writeToFile:outputPath atomically:YES encoding:NSUTF8StringEncoding error:&writingError];
            if (!writeSuccess) {
                NSLog(@"create output failed:%@",writingError);
            }
        } else {
            printf("%s",output.UTF8String);
        }

    }
    
    return 0;
}

