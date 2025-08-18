//
//  NSObject+PrivateSwizzle.m
//  PlayTools
//
//  Created by siri on 06.10.2021.
//

#import "NSObject+Swizzle.h"
#import <objc/runtime.h>
#import "CoreGraphics/CoreGraphics.h"
#import "UIKit/UIKit.h"
#import <PlayTools/PlayTools-Swift.h>
#import "PTFakeMetaTouch.h"
#import <VideoSubscriberAccount/VideoSubscriberAccount.h>

__attribute__((visibility("hidden")))
@interface PTSwizzleLoader : NSObject
@end

@implementation NSObject (Swizzle)

- (void) swizzleInstanceMethod:(SEL)origSelector withMethod:(SEL)newSelector
{
    Class cls = [self class];
    // If current class doesn't exist selector, then get super
    Method originalMethod = class_getInstanceMethod(cls, origSelector);
    Method swizzledMethod = class_getInstanceMethod(cls, newSelector);
    
    // Add selector if it doesn't exist, implement append with method
    if (class_addMethod(cls,
                        origSelector,
                        method_getImplementation(swizzledMethod),
                        method_getTypeEncoding(swizzledMethod)) ) {
        // Replace class instance method, added if selector not exist
        // For class cluster, it always adds new selector here
        class_replaceMethod(cls,
                            newSelector,
                            method_getImplementation(originalMethod),
                            method_getTypeEncoding(originalMethod));
        
    } else {
        // SwizzleMethod maybe belongs to super
        class_replaceMethod(cls,
                            newSelector,
                            class_replaceMethod(cls,
                                                origSelector,
                                                method_getImplementation(swizzledMethod),
                                                method_getTypeEncoding(swizzledMethod)),
                            method_getTypeEncoding(originalMethod));
    }
}

- (void) swizzleExchangeMethod:(SEL)origSelector withMethod:(SEL)newSelector
{
    Class cls = [self class];
    // If current class doesn't exist selector, then get super
    Method originalMethod = class_getInstanceMethod(cls, origSelector);
    Method swizzledMethod = class_getInstanceMethod(cls, newSelector);
    
    method_exchangeImplementations(originalMethod, swizzledMethod);
}

- (BOOL) hook_prefersPointerLocked {
    return false;
}

- (CGRect) hook_frameDefault {
    return [PlayScreen frameDefault:[self hook_frameDefault]];
}

- (CGRect) hook_boundsDefault {
    return [PlayScreen boundsDefault:[self hook_boundsDefault]];
}

- (CGRect) hook_nativeBoundsDefault {
    return [PlayScreen nativeBoundsDefault:[self hook_nativeBoundsDefault]];
}

- (CGSize) hook_sizeDelfault {
    return [PlayScreen sizeAspectRatioDefault:[self hook_sizeDelfault]];
}


- (CGRect) hook_frame {
    return [PlayScreen frame:[self hook_frame]];
}

- (CGRect) hook_bounds {
    return [PlayScreen bounds:[self hook_bounds]];
}

- (CGRect) hook_nativeBounds {
    return [PlayScreen nativeBounds:[self hook_nativeBounds]];
}

- (CGSize) hook_size {
    return [PlayScreen sizeAspectRatio:[self hook_size]];
}



- (long long) hook_orientation {
    return 0;
}

- (double) hook_nativeScale {
    return [[PlaySettings shared] customScaler];
}

- (double) hook_scale {
    // Return rounded value of [[PlaySettings shared] customScaler]
    // Even though it is a double return, this will only accept .0 value or apps will crash
    return round([[PlaySettings shared] customScaler]);
}

- (double) get_default_height {
    return [[UIScreen mainScreen] bounds].size.height;
    
}
- (double) get_default_width {
    return [[UIScreen mainScreen] bounds].size.width;
    
}

- (void) hook_setCurrentSubscription:(VSSubscription *)currentSubscription {
    // do nothing
}

// Hook for UIUserInterfaceIdiom

// - (long long) hook_userInterfaceIdiom {
//     return UIUserInterfaceIdiomPad;
// }

bool menuWasCreated = false;
- (id) initWithRootMenuHook:(id)rootMenu {
    self = [self initWithRootMenuHook:rootMenu];
    if (!menuWasCreated) {
        [PlayCover initMenuWithMenu: self];
        menuWasCreated = TRUE;
    }
    return self;
}

@end

/*
 This class only exists to apply swizzles from the +load of a class that won't have any categories/extensions. The reason
 for not doing this in a C module initializer is that obj-c initialization happens before any __attribute__((constructor))
 is called. This way we can guarantee the hooks will be applied before [PlayCover launch] is called (in PlayLoader.m).
 
 Side note:
 While adding method replacements to NSObject does work, I'm not certain this doesn't (or won't) have any side effects. The
 way Apple does method swizzling internally is by creating a category of the swizzled class and adding the replacements there.
 This keeps all those replacements "local" to that class. Example:
 
 '''
 @interface FBSSceneSettings (Swizzle)
 -(CGRect) hook_frame {
    ...
 }
 @end
 
 Somewhere else:
 swizzle(FBSSceneSettings.class, @selector(frame), @selector(hook_frame);
 '''
 
 However, doing this would require generating @interface declarations (either with class-dump or by hand) which would add a lot
 of code and complexity. I'm not sure this trade-off is "worth it", at least at the time of writing.
 */

@implementation PTSwizzleLoader
+ (void)load {
    // This might need refactor soon
    if(@available(iOS 16.3, *)) {
        if ([[PlaySettings shared] adaptiveDisplay]) {
            // This is an experimental fix
            if ([[PlaySettings shared] inverseScreenValues]) {
                // This lines set External Scene settings and other IOS10 Runtime services by swizzling
                // In Sonoma 14.1 betas, frame method seems to be moved to FBSSceneSettingsCore
                if(@available(iOS 17.1, *))
                    [objc_getClass("FBSSceneSettingsCore") swizzleExchangeMethod:@selector(frame) withMethod:@selector(hook_frameDefault)];
                else
                    [objc_getClass("FBSSceneSettings") swizzleInstanceMethod:@selector(frame) withMethod:@selector(hook_frameDefault)];
                [objc_getClass("FBSSceneSettings") swizzleInstanceMethod:@selector(bounds) withMethod:@selector(hook_boundsDefault)];
                [objc_getClass("FBSDisplayMode") swizzleInstanceMethod:@selector(size) withMethod:@selector(hook_sizeDelfault)];
                
                // Fixes Apple mess at MacOS 13.2
                [objc_getClass("UIDevice") swizzleInstanceMethod:@selector(orientation) withMethod:@selector(hook_orientation)];
                [objc_getClass("UIScreen") swizzleInstanceMethod:@selector(nativeBounds) withMethod:@selector(hook_nativeBoundsDefault)];
                [objc_getClass("UIScreen") swizzleInstanceMethod:@selector(nativeScale) withMethod:@selector(hook_nativeScale)];
                [objc_getClass("UIScreen") swizzleInstanceMethod:@selector(scale) withMethod:@selector(hook_scale)];
            } else {
                // This acutally runs when adaptiveDisplay is normally triggered
                if(@available(iOS 17.1, *))
                    [objc_getClass("FBSSceneSettingsCore") swizzleExchangeMethod:@selector(frame) withMethod:@selector(hook_frame)];
                else
                    [objc_getClass("FBSSceneSettings") swizzleInstanceMethod:@selector(frame) withMethod:@selector(hook_frame)];
                [objc_getClass("FBSSceneSettings") swizzleInstanceMethod:@selector(bounds) withMethod:@selector(hook_bounds)];
                [objc_getClass("FBSDisplayMode") swizzleInstanceMethod:@selector(size) withMethod:@selector(hook_size)];
                
                [objc_getClass("UIDevice") swizzleInstanceMethod:@selector(orientation) withMethod:@selector(hook_orientation)];
                [objc_getClass("UIScreen") swizzleInstanceMethod:@selector(nativeBounds) withMethod:@selector(hook_nativeBounds)];
                [objc_getClass("UIScreen") swizzleInstanceMethod:@selector(nativeScale) withMethod:@selector(hook_nativeScale)];
                [objc_getClass("UIScreen") swizzleInstanceMethod:@selector(scale) withMethod:@selector(hook_scale)];   
            }
        }
        else {
            if ([[PlaySettings shared] windowFixMethod] == 1) {
                // do nothing:tm:
            }
            else {
                CGFloat newValueW = (CGFloat) [self get_default_width];
                [[PlaySettings shared] setValue:@(newValueW) forKey:@"windowSizeWidth"];
                
                CGFloat newValueH = (CGFloat)[self get_default_height];
                [[PlaySettings shared] setValue:@(newValueH) forKey:@"windowSizeHeight"];
                if (![[PlaySettings shared] inverseScreenValues]) {
                    if(@available(iOS 17.1, *))
                        [objc_getClass("FBSSceneSettingsCore") swizzleExchangeMethod:@selector(frame) withMethod:@selector(hook_frameDefault)];
                    else
                        [objc_getClass("FBSSceneSettings") swizzleInstanceMethod:@selector(frame) withMethod:@selector(hook_frameDefault)];
                    [objc_getClass("FBSSceneSettings") swizzleInstanceMethod:@selector(bounds) withMethod:@selector(hook_boundsDefault)];
                    [objc_getClass("FBSDisplayMode") swizzleInstanceMethod:@selector(size) withMethod:@selector(hook_sizeDelfault)];
                }
                [objc_getClass("UIDevice") swizzleInstanceMethod:@selector(orientation) withMethod:@selector(hook_orientation)];
                [objc_getClass("UIScreen") swizzleInstanceMethod:@selector(nativeBounds) withMethod:@selector(hook_nativeBoundsDefault)];
                
                [objc_getClass("UIScreen") swizzleInstanceMethod:@selector(nativeScale) withMethod:@selector(hook_nativeScale)];
                [objc_getClass("UIScreen") swizzleInstanceMethod:@selector(scale) withMethod:@selector(hook_scale)];
            }
        }
    } 
    else {
        if ([[PlaySettings shared] adaptiveDisplay]) {
                if(@available(iOS 17.1, *))
                    [objc_getClass("FBSSceneSettingsCore") swizzleExchangeMethod:@selector(frame) withMethod:@selector(hook_frame)];
                else
                    [objc_getClass("FBSSceneSettings") swizzleInstanceMethod:@selector(frame) withMethod:@selector(hook_frame)];
                [objc_getClass("FBSSceneSettings") swizzleInstanceMethod:@selector(bounds) withMethod:@selector(hook_bounds)];
                [objc_getClass("FBSDisplayMode") swizzleInstanceMethod:@selector(size) withMethod:@selector(hook_size)];
            }
    }
    
    [objc_getClass("_UIMenuBuilder") swizzleInstanceMethod:sel_getUid("initWithRootMenu:") withMethod:@selector(initWithRootMenuHook:)];
    [objc_getClass("IOSViewController") swizzleInstanceMethod:@selector(prefersPointerLocked) withMethod:@selector(hook_prefersPointerLocked)];
    // Set idiom to iPad
    // [objc_getClass("UIDevice") swizzleInstanceMethod:@selector(userInterfaceIdiom) withMethod:@selector(hook_userInterfaceIdiom)];
    // [objc_getClass("UITraitCollection") swizzleInstanceMethod:@selector(userInterfaceIdiom) withMethod:@selector(hook_userInterfaceIdiom)];

    [objc_getClass("VSSubscriptionRegistrationCenter") swizzleInstanceMethod:@selector(setCurrentSubscription:) withMethod:@selector(hook_setCurrentSubscription:)];
}

@end
