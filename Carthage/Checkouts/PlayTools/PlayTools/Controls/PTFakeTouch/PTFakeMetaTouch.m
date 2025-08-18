//
//  PTFakeMetaTouch.m
//  PTFakeTouch
//
//  Created by PugaTang on 16/4/20.
//  Copyright © 2016年 PugaTang. All rights reserved.
//

#import "PTFakeMetaTouch.h"
#import "UITouch-KIFAdditions.h"
#import "UIApplication+Private.h"
#import "UIEvent+Private.h"
#import "CoreFoundation/CFRunLoop.h"
#import <stdatomic.h>
#include <dlfcn.h>
#include <string.h>

static NSMutableArray *livingTouchAry;
atomic_ullong reusageMask = ATOMIC_VAR_INIT(0);
static CFRunLoopSourceRef source;

NSLock *lock;

void eventSendCallback(void* info) {
    UIEvent *event = [[UIApplication sharedApplication] _touchesEvent];
    [event _clearTouches];
    // Step1: copy touches and record began touches and mark recyclable touches
    NSMutableArray *begunTouchAry = [[NSMutableArray alloc] init];
    [lock lock];
    [livingTouchAry enumerateObjectsUsingBlock:^(UITouch *aTouch, NSUInteger idx, BOOL *stop) {
        switch (aTouch.phase) {
            case UITouchPhaseEnded:
            case UITouchPhaseCancelled:
                // set this bit to 1
                atomic_fetch_or(&reusageMask, 1ull<<idx);
                break;
            case UITouchPhaseBegan:
                [begunTouchAry addObject:aTouch];
                break;
            default:
                break;
        }
        [event _addTouch:aTouch forDelayedDelivery:NO];
    }];
    [lock unlock];

    // Step2: send event
    [[UIApplication sharedApplication] sendEvent:event];

    // Step 3: change "began" touches to "moved"
    // Do not let a "began" appear twice on a point
    for (UITouch *touch in begunTouchAry) {
        // Double check "began", because phase may have changed
        @synchronized (touch) {
            // Check condition needs to be synchronized too,
            // otherwise phase might also change after condition met
            if ([touch phase] == UITouchPhaseBegan) {
                [touch setPhaseAndUpdateTimestamp:UITouchPhaseMoved];
            }
        }
    }
}

@implementation PTFakeMetaTouch

+ (void)load {
    livingTouchAry = [[NSMutableArray alloc] init];
    CFRunLoopSourceContext context;
    memset(&context, 0, sizeof(CFRunLoopSourceContext));
    context.perform = eventSendCallback;
    lock = [[NSLock alloc] init];
    // content of context is copied
    source = CFRunLoopSourceCreate(NULL, -2, &context);
    CFRunLoopRef loop = CFRunLoopGetMain();
    CFRunLoopAddSource(loop, source, kCFRunLoopCommonModes);
}

+ (NSInteger)fakeTouchId: (NSInteger)pointId AtPoint: (CGPoint)point withTouchPhase: (UITouchPhase)phase inWindow: (UIWindow*)window onView:(UIView*)view {
    UITouch* touch = NULL;
    // respect the semantics of touch phase, allocate new touch on touch began.
    if(phase == UITouchPhaseBegan) {
        touch = [[UITouch alloc] initAtPoint:point inWindow:window onView:view];
        // Find and clear any 1 bit if possible
        if(atomic_load(&reusageMask) == 0){
            pointId = [livingTouchAry count];
            [lock lock];
        }else{
            // reuse previous ID
            pointId = 0;
            // It is guanranteed other thread only "set" but not "clear" bit
            // So this is safe even if mask changes around here
            while( !(atomic_load(&reusageMask) & (1ull<<pointId)) ){
                pointId++;
            }
            // issue: this could fail if not atomic
            // How:
            // 1. Other thread read
            // 2. This thread read and write
            // 3. Other thread write
            [lock lock];
            atomic_fetch_and(&reusageMask, ~(1ull<<pointId));
            // These must be locked together, because otherwise
            // After we occupy this id, other thread may release it again,
            // before we actually replace the UITouch
        }
        [livingTouchAry setObject:touch atIndexedSubscript:pointId];
        [lock unlock];
    } else {
        touch = [livingTouchAry objectAtIndex:pointId];
        if(touch.phase == UITouchPhaseBegan && phase == UITouchPhaseMoved) {
            // previous touch began event not yet captured by runloop. Ignore this move
            return pointId;
        }
        @synchronized (touch) {
            [touch setLocationInWindow:point];
            [touch setPhaseAndUpdateTimestamp:phase];
        }
    }
    CFRunLoopSourceSignal(source);
    // Check on actual phase of touch
    if([touch phase] == UITouchPhaseEnded || [touch phase] == UITouchPhaseCancelled) {
        pointId = -1;
    }
    return pointId;
}
@end
