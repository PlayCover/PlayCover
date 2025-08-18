//
//  UITouch-KIFAdditions.m
//  KIF
//
//  Created by Eric Firestone on 5/20/11.
//  Licensed to Square, Inc. under one or more contributor license agreements.
//  See the LICENSE file distributed with this work for the terms under
//  which Square, Inc. licenses this file to you.

#import "UITouch-KIFAdditions.h"
#import <objc/runtime.h>
#import "PTFakeMetaTouch.h"

@implementation UITouch (KIFAdditions)

- (id)initAtPoint:(CGPoint)point inWindow:(UIWindow *)window onView:(UIView*)view;
{
    self = [super init];
    if (self == nil) {
        return nil;
    }
    
    // Create a fake tap touch
    [self setWindow:window]; // Wipes out some values. Needs to be first.
    
    [self _setLocationInWindow:point resetPrevious:YES];
    
    UIView *hitTestView = view;
    
    [self setView:hitTestView];
    [self setPhase:UITouchPhaseBegan];
    if (![[NSProcessInfo processInfo] isiOSAppOnMac] && ![[NSProcessInfo processInfo] isMacCatalystApp]) {
        [self _setIsTapToClick:NO];
    } else {
        [self _setIsFirstTouchForView:YES];
        [self setIsTap:NO];
    }
    [self setTimestamp: [[NSProcessInfo processInfo] systemUptime]];
    if ([self respondsToSelector:@selector(setGestureView:)]) {
        [self setGestureView:hitTestView];
    }
    
    [self kif_setHidEvent];
    return self;
}

- (id)initTouch;
{
    //DLog(@"init...touch...");
    self = [super init];
    if (self == nil) {
        return nil;
    }
    NSArray *scenes = [[[UIApplication sharedApplication] connectedScenes] allObjects];
    NSArray *windows = [[scenes objectAtIndex:0] windows];
    UIWindow *window = [windows lastObject];
    CGPoint point = CGPointMake(0, 0);
    [self setWindow:window]; // Wipes out some values.  Needs to be first.
    
    [self _setLocationInWindow:point resetPrevious:YES];
    
    UIView *hitTestView = [window hitTest:point withEvent:nil];
    
    [self setView:hitTestView];
    [self setPhase:UITouchPhaseEnded];
    //DLog(@"init...touch...setPhase 3");
    if (![[NSProcessInfo processInfo] isiOSAppOnMac] && ![[NSProcessInfo processInfo] isMacCatalystApp]) {
        [self _setIsTapToClick:NO];
    } else {
        [self _setIsFirstTouchForView:YES];
        [self setIsTap:NO];
    }
    [self setTimestamp: [[NSProcessInfo processInfo] systemUptime]];
    if ([self respondsToSelector:@selector(setGestureView:)]) {
        [self setGestureView:hitTestView];
    }
    
    [self kif_setHidEvent];
    return self;
}

//
// setLocationInWindow:
//
// Setter to allow access to the _locationInWindow member.
//
- (void)setLocationInWindow:(CGPoint)location
{
    [self setTimestamp: [[NSProcessInfo processInfo] systemUptime]];
    [self _setLocationInWindow:location resetPrevious:NO];
}

- (void)setPhaseAndUpdateTimestamp:(UITouchPhase)phase
{
    //DLog(@"setPhaseAndUpdateTimestamp : %ld",(long)phase);
    [self setTimestamp: [[NSProcessInfo processInfo] systemUptime]];
    [self setPhase:phase];
}

- (void)kif_setHidEvent {
    IOHIDEventRef event = kif_IOHIDEventWithTouches(@[self]);
    [self _setHidEvent:event];
    CFRelease(event);
}

@end
