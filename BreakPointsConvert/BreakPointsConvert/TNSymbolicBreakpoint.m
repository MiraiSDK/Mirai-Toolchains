//
//  TNSymbolicBreakpoint.m
//  BreakPointsConvert
//
//  Created by Chen Yonghui on 3/20/14.
//  Copyright (c) 2014 sycx. All rights reserved.
//

#import "TNSymbolicBreakpoint.h"

@implementation TNSymbolicBreakpoint
+ (NSString *)ExtensionID
{
    return @"Xcode.Breakpoint.SymbolicBreakpoint";
}

+ (void)load
{
    [self registerClassWithExtensionID:[self ExtensionID]];
}

- (id)initWithContentElement:(NSXMLElement *)element
{
    self = [super initWithContentElement:element];
    if (self) {
        _symbolName = [[element attributeForName:@"symbolName"] stringValue];
        _moduleName = [[element attributeForName:@"moduleName"] stringValue];
    }
    return self;
}

@end
