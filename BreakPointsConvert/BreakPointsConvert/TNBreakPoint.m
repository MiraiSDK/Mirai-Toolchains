//
//  TNBreakPoint.m
//  BreakPointsConvert
//
//  Created by Chen Yonghui on 3/20/14.
//  Copyright (c) 2014 sycx. All rights reserved.
//

#import "TNBreakPoint.h"

@implementation TNBreakPoint
+ (NSString *)ExtensionID
{
    return @"";
}

static NSMutableDictionary *bpClasses = nil;

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        bpClasses = [NSMutableDictionary dictionary];
    });    
}

+ (void)registerClassWithExtensionID:(NSString *)extensionID
{
    bpClasses[extensionID] = [self class];
}

+ (Class)classForExtensionID:(NSString *)extensionID
{
    return bpClasses[extensionID];
}

+ (instancetype)breakPointWithProxyElement:(NSXMLElement *)element
{
    NSString *BreakpointExtensionID = [[element attributeForName:@"BreakpointExtensionID"] stringValue];

    Class cl = [self classForExtensionID:BreakpointExtensionID];
    if (cl == nil) {
        NSLog(@"unsupported breakpoint ID:%@",BreakpointExtensionID);
    }
    NSXMLElement *contentElement = (NSXMLElement *)[element childAtIndex:0];
    return [[cl alloc] initWithContentElement:contentElement];
}

- (id)initWithContentElement:(NSXMLElement *)element
{
    self = [super init];
    if (self) {
        _shouldBeEnabled = [[[element attributeForName:@"shouldBeEnabled"] stringValue] boolValue];
        _ignoreCount = [[[element attributeForName:@"ignoreCount"] stringValue] intValue];
        _continueAfterRunningActions = [[[element attributeForName:@"continueAfterRunningActions"] stringValue] intValue];
        
    }
    return self;
}

- (NSString *)gdbCommand
{
    return @"";
}
@end
