//
//  UIEvent+Private.h
//  FakeTouch
//
//  Created by Watanabe Toshinori on 2/6/19.
//  Copyright © 2019 Watanabe Toshinori. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIEvent (Private)

- (void)_addTouch:(UITouch *)touch forDelayedDelivery:(BOOL)delayed;

- (void)_clearTouches;

@end
