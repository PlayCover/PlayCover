//
//  UITouch-KIFAdditions.h
//  KIF
//
//  Created by Eric Firestone on 5/20/11.
//  Licensed to Square, Inc. under one or more contributor license agreements.
//  See the LICENSE file distributed with this work for the terms under
//  which Square, Inc. licenses this file to you.

#import <UIKit/UIKit.h>
#import "IOHIDEvent+KIF.h"
#import "UITouch+Private.h"

@interface UITouch (KIFAdditions)

- (id)initAtPoint:(CGPoint)point inWindow:(UIWindow *)window onView:(UIView*)view;
- (id)initTouch;

- (void)setLocationInWindow:(CGPoint)location;
- (void)setPhaseAndUpdateTimestamp:(UITouchPhase)phase;

@end
