//
//  TNExceptionBreakpoint.h
//  BreakPointsConvert
//
//  Created by Chen Yonghui on 3/20/14.
//  Copyright (c) 2014 sycx. All rights reserved.
//

#import "TNBreakPoint.h"

@interface TNExceptionBreakpoint : TNBreakPoint
//scope:
// 0 -> all
// 1 -> Objective-C
// 2 -> C++
@property (nonatomic, assign) int scope;

// stopOnStyle
// 0 -> Break on Throw
// 1 -> Break on Catch
@property (nonatomic, assign) int stopOnStyle;

@property (nonatomic, strong) NSString *exceptionName;

@end
