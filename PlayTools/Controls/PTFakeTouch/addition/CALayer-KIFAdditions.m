//
//  CALayer-KIFAdditions.m
//  Pods
//
//  Created by Radu Ciobanu on 28/01/2016.
//  Licensed to Square, Inc. under one or more contributor license agreements.
//  See the LICENSE file distributed with this work for the terms under
//  which Square, Inc. licenses this file to you.
//

#import "CALayer-KIFAdditions.h"

@implementation CALayer (KIFAdditions)

- (BOOL)hasAnimations
{
    __block BOOL result = NO;
    [self performBlockOnDescendentLayers:^(CALayer *layer, BOOL *stop) {
      // explicitly exclude _UIParallaxMotionEffect as it is used in alertviews, and we don't want every alertview to be paused)
      BOOL hasAnimation = layer.animationKeys.count != 0 && ![layer.animationKeys isEqualToArray:@[@"_UIParallaxMotionEffect"]];
      if (hasAnimation && !layer.hidden) {
          result = YES;
          if (stop != NULL) {
              *stop = YES;
          }
      }
    }];
    return result;
}

- (void)performBlockOnDescendentLayers:(void (^)(CALayer *layer, BOOL *stop))block
{
    BOOL stop = NO;
    [self performBlockOnDescendentLayers:block stop:&stop];
}

- (void)performBlockOnDescendentLayers:(void (^)(CALayer *, BOOL *))block stop:(BOOL *)stop
{
    block(self, stop);
    if (*stop) {
        return;
    }

    for (CALayer *layer in self.sublayers) {
        [layer performBlockOnDescendentLayers:block stop:stop];
        if (*stop) {
            return;
        }
    }
}

@end
