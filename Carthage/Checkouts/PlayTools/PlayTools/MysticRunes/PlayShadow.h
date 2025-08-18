//
//  PlayShadow.h
//  PlayTools
//
//  Created by Venti on 08/03/2023.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSObject (ShadowSwizzle)

- (void)swizzleInstanceMethod:(SEL)origSelector withMethod:(SEL)newSelector;
+ (void)swizzleClassMethod: (SEL)origSelector withMethod: (SEL)newSelector

@end
NS_ASSUME_NONNULL_END
