//
//  TNIDETestFailureBreakpoint.m
//  BreakPointsConvert
//
//  Created by Chen Yonghui on 3/20/14.
//  Copyright (c) 2014 sycx. All rights reserved.
//

#import "TNIDETestFailureBreakpoint.h"

@implementation TNIDETestFailureBreakpoint
+ (NSString *)ExtensionID
{
    return @"Xcode.Breakpoint.IDETestFailureBreakpoint";
}

+ (void)load
{
    [self registerClassWithExtensionID:[self ExtensionID]];
}

- (id)initWithContentElement:(NSXMLElement *)element
{
    self = [super initWithContentElement:element];
    if (self) {
        _breakpointStackSelectionBehavior = [[element attributeForName:@"breakpointStackSelectionBehavior"] stringValue];        
    }
    return self;
}
@end
