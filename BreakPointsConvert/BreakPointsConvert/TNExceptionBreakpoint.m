//
//  TNExceptionBreakpoint.m
//  BreakPointsConvert
//
//  Created by Chen Yonghui on 3/20/14.
//  Copyright (c) 2014 sycx. All rights reserved.
//

#import "TNExceptionBreakpoint.h"

@implementation TNExceptionBreakpoint
+ (NSString *)ExtensionID
{
    return @"Xcode.Breakpoint.ExceptionBreakpoint";
}

+ (void)load
{
    [self registerClassWithExtensionID:[self ExtensionID]];
}

- (id)initWithContentElement:(NSXMLElement *)element
{
    self = [super initWithContentElement:element];
    if (self) {
        _scope = [[[element attributeForName:@"scope"] stringValue] intValue];
        _stopOnStyle = [[[element attributeForName:@"stopOnStyle"] stringValue] intValue];
    }
    return self;
}
@end
