//
//  NSObject+PrivateSwizzle.h
//  PlayTools
//
//  Created by siri on 06.10.2021.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSObject (Swizzle)

+ (void)swizzleClassMethod:(SEL)origSelector withMethod:(SEL)newSelector;
- (void)swizzleInstanceMethod:(SEL)origSelector withMethod:(SEL)newSelector;
- (void)isMethodExists:(SEL)origSelector;

@end

NS_ASSUME_NONNULL_END
