//
//  TNBreakPoint.h
//  BreakPointsConvert
//
//  Created by Chen Yonghui on 3/20/14.
//  Copyright (c) 2014 sycx. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TNBreakPoint : NSObject
+ (NSString *)ExtensionID;
+ (void)registerClassWithExtensionID:(NSString *)extensionID;
+ (instancetype)breakPointWithProxyElement:(NSXMLElement *)element;
- (id)initWithContentElement:(NSXMLElement *)element;

@property (nonatomic, assign) BOOL shouldBeEnabled;
@property (nonatomic, assign) int ignoreCount;
@property (nonatomic, assign) int continueAfterRunningActions;

@property (nonatomic, strong) NSArray *actions;

- (NSString *)gdbCommand;

@end
