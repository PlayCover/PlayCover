//
//  BatteryLevel.h
//  PlayTools
//
//  Created by Edoardo C. on 07/08/24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSObject (SwizzleBattery)

- (void)swizzleInstanceMethod:(SEL)origSelector withMethod:(SEL)newSelector;

@end

NS_ASSUME_NONNULL_END
