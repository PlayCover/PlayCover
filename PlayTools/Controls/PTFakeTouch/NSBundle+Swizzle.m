//
//  NSBundle+Swizzle.m
//  PlayTools
//
//  Created by siri on 26.09.2021.
//

#import "NSBundle+Swizzle.h"
#import <objc/runtime.h>
#import "NSObject+Swizzle.h"

@implementation NSBundle (Swizzle)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [NSBundle swizzleClassMethod:@selector(bundleWithPath:) withMethod:@selector(xxx_bundleWithPath:)];
    });
}

+ (instancetype)xxx_bundleWithPath:(NSString *)path {
        if ([path isEqualToString:@"/System/Library/Frameworks/GameController.framework"]){
            return [self xxx_bundleWithPath:@"/System/iOSSupport/System/Library/Frameworks/GameController.framework"];
        }
    return [self xxx_bundleWithPath:path];
}

@end
