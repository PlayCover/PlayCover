//
//  UITouch+Private.h
//  FakeTouch
//
//  Created by Watanabe Toshinori on 2/6/19.
//  Copyright © 2019 Watanabe Toshinori. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UITouch (Private)

- (void)setPhase:(UITouchPhase)touchPhase;

- (void)setTapCount:(NSUInteger)tapCount;

- (void)setWindow:(UIWindow *)window;

- (void)setView:(UIView *)view;

- (void)_setLocationInWindow:(CGPoint)location resetPrevious:(BOOL)resetPrevious;

- (void)_setIsFirstTouchForView:(BOOL)firstTouchForView;

- (void)setIsTap:(BOOL)isTap;

- (void)setTimestamp:(NSTimeInterval)timestamp;

- (void)_setHidEvent:(IOHIDEventRef)event;

- (void)setGestureView:(UIView *)view;

@end
