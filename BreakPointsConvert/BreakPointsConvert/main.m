//
//  main.m
//  BreakPointsConvert
//
//  Created by Chen Yonghui on 3/20/14.
//  Copyright (c) 2014 sycx. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "TNBreakPoint.h"

@interface ToolMain : NSObject

@property (nonatomic, readonly, copy) NSArray *arguments;
@property (nonatomic, readonly, strong) NSString *executableName;

- (id)initWithArguments:(NSArray *)arguments;


@end
@implementation ToolMain
- (id)initWithArguments:(NSArray *)arguments;
{
    self = [super init];
    if (self) {
        _arguments = [arguments copy];
        
        _executableName = [_arguments[0] lastPathComponent];
    }
    return self;
}

- (void)main
{
    if (_arguments.count != 3) {
        [self printHelp];
        return;
    }
    

    NSString *inputPath = _arguments[1];
    if (![inputPath isAbsolutePath]) {
        inputPath = [[[NSFileManager defaultManager] currentDirectoryPath] stringByAppendingPathComponent:inputPath];
    }
    
    NSString *outputPath = _arguments[2];
    if (![outputPath isAbsolutePath]) {
        outputPath = [[[NSFileManager defaultManager] currentDirectoryPath] stringByAppendingPathComponent:outputPath];
    }
    
    NSLog(@"process input:%@ output:%@",inputPath,outputPath);
    
    //load input file
    if (![[NSFileManager defaultManager] fileExistsAtPath:inputPath]) {
        NSLog(@"[Error]input file not exist.");
        return;
    }
    
    NSError *inputLoadError = nil;
    NSString *input = [NSString stringWithContentsOfFile:inputPath encoding:NSUTF8StringEncoding error:&inputLoadError];
    if (inputLoadError) {
        NSLog(@"load input file failed: %@",inputLoadError);
        return;
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
        [breakPoints addObject:bp];
    }
    
    NSMutableArray *commands = [[breakPoints valueForKeyPath:@"gdbCommand"] mutableCopy];
    [commands removeObject:@""];
    [commands insertObject:@"set breakpoint pending on" atIndex:0];
    [commands addObject:@"b -[NSException raise]"];
    [commands addObject:@"set unwindonsignal on"];
    [commands addObject:@""];
    NSString *output = [commands componentsJoinedByString:@"\n"];

    NSError *writingError = nil;
    BOOL writeSuccess = [output writeToFile:outputPath atomically:YES encoding:NSUTF8StringEncoding error:&writingError];
    if (!writeSuccess) {
        NSLog(@"create output failed:%@",writingError);
    }
    
}

- (void)printHelp
{
    NSLog(@"usage: %@ [input file] [output file]",_executableName);
}
@end

int main(int argc, const char * argv[])
{

    @autoreleasepool {
        NSMutableArray *arguments = [NSMutableArray array];
        for (int i = 0; i<argc; i++) {
            [arguments addObject:[NSString stringWithUTF8String:argv[i]]];
        }
        
        ToolMain *main = [[ToolMain alloc] initWithArguments:arguments];
        [main main];
    }
    return 0;
}

