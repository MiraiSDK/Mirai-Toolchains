//
//  TNFileBreakpoint.h
//  BreakPointsConvert
//
//  Created by Chen Yonghui on 3/20/14.
//  Copyright (c) 2014 sycx. All rights reserved.
//

#import "TNBreakPoint.h"

@interface TNFileBreakpoint : TNBreakPoint
@property (nonatomic, strong) NSString *condition;

@property (nonatomic, strong) NSString *filePath;
@property (nonatomic, assign) NSString *timestampString;

@property (nonatomic, strong) NSString *startingColumnNumber;
@property (nonatomic, strong) NSString *endingColumnNumber;

@property (nonatomic, strong) NSString *startingLineNumber;
@property (nonatomic, strong) NSString *endingLineNumber;

@property (nonatomic, strong) NSString *landmarkName;
@property (nonatomic, strong) NSString *landmarkType;


@end
