//
//  TNOpenGLErrorBreakpoint.h
//  BreakPointsConvert
//
//  Created by Chen Yonghui on 3/20/14.
//  Copyright (c) 2014 sycx. All rights reserved.
//

#import "TNBreakPoint.h"

@interface TNOpenGLErrorBreakpoint : TNBreakPoint
@property (nonatomic, strong) NSString *breakpointStackSelectionBehavior;
@property (nonatomic, strong) NSString *symbolName;
@property (nonatomic, strong) NSString *moduleName;


@end
