//
//  TNFileBreakpoint.m
//  BreakPointsConvert
//
//  Created by Chen Yonghui on 3/20/14.
//  Copyright (c) 2014 sycx. All rights reserved.
//

#import "TNFileBreakpoint.h"

@implementation TNFileBreakpoint
+ (NSString *)ExtensionID
{
    return @"Xcode.Breakpoint.FileBreakpoint";
}

+ (void)load
{
    [self registerClassWithExtensionID:[self ExtensionID]];
}

- (id)initWithContentElement:(NSXMLElement *)element
{
    self = [super initWithContentElement:element];
    if (self) {
        _condition = [[element attributeForName:@"condition"] stringValue] ;
        _filePath = [[element attributeForName:@"filePath"] stringValue] ;
        _timestampString = [[element attributeForName:@"timestampString"] stringValue] ;
        
        
        _startingColumnNumber = [[element attributeForName:@"startingColumnNumber"] stringValue] ;
        _endingColumnNumber = [[element attributeForName:@"endingColumnNumber"] stringValue] ;
        _startingLineNumber = [[element attributeForName:@"startingLineNumber"] stringValue] ;
        _endingLineNumber = [[element attributeForName:@"endingLineNumber"] stringValue] ;

        
        _landmarkName = [[element attributeForName:@"landmarkName"] stringValue] ;
        _landmarkType = [[element attributeForName:@"landmarkType"] stringValue] ;

    }
    return self;
}

- (NSString *)gdbCommand
{
    NSString *fileName = [_filePath lastPathComponent];
    return [NSString stringWithFormat:@"b %@:%@",fileName,_startingLineNumber];
}
@end
