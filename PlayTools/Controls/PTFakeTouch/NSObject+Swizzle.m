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


@implementation NSObject (Swizzle)

+ (void)swizzleClassMethod:(SEL)origSelector withMethod:(SEL)newSelector
{
    Class cls = [self class];
    
    Method originalMethod = class_getClassMethod(cls, origSelector);
    Method swizzledMethod = class_getClassMethod(cls, newSelector);
    
    Class metacls = objc_getMetaClass(NSStringFromClass(cls).UTF8String);
    if (class_addMethod(metacls,
                        origSelector,
                        method_getImplementation(swizzledMethod),
                        method_getTypeEncoding(swizzledMethod)) ) {
        /* swizzing super class method, added if not exist */
        class_replaceMethod(metacls,
                            newSelector,
                            method_getImplementation(originalMethod),
                            method_getTypeEncoding(originalMethod));
        
    } else {
        /* swizzleMethod maybe belong to super */
        class_replaceMethod(metacls,
                            newSelector,
                            class_replaceMethod(metacls,
                                                origSelector,
                                                method_getImplementation(swizzledMethod),
                                                method_getTypeEncoding(swizzledMethod)),
                            method_getTypeEncoding(originalMethod));
    }
}

- (void)swizzleInstanceMethod:(SEL)origSelector withMethod:(SEL)newSelector
{
    Class cls = [self class];
    /* if current class not exist selector, then get super*/
    Method originalMethod = class_getInstanceMethod(cls, origSelector);
    Method swizzledMethod = class_getInstanceMethod(cls, newSelector);
    
    /* add selector if not exist, implement append with method */
    if (class_addMethod(cls,
                        origSelector,
                        method_getImplementation(swizzledMethod),
                        method_getTypeEncoding(swizzledMethod)) ) {
        /* replace class instance method, added if selector not exist */
        /* for class cluster , it always add new selector here */
        class_replaceMethod(cls,
                            newSelector,
                            method_getImplementation(originalMethod),
                            method_getTypeEncoding(originalMethod));
        
    } else {
        /* swizzleMethod maybe belong to super */
        class_replaceMethod(cls,
                            newSelector,
                            class_replaceMethod(cls,
                                                origSelector,
                                                method_getImplementation(swizzledMethod),
                                                method_getTypeEncoding(swizzledMethod)),
                            method_getTypeEncoding(originalMethod));
    }
}


+(void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // TODO: UINSview

        if ([[PlaySettings shared] adaptiveDisplay]){
            [objc_getClass("FBSSceneSettings") swizzleInstanceMethod:@selector(frame) withMethod:@selector(hook_frame)];
            [objc_getClass("FBSSceneSettings") swizzleInstanceMethod:@selector(bounds) withMethod:@selector(hook_bounds)];
            [objc_getClass("FBSDisplayMode") swizzleInstanceMethod:@selector(size) withMethod:@selector(hook_size)];
        }

        if ([[PlaySettings shared] refreshRate] == 120){
         [objc_getClass("UnityAppController") swizzleInstanceMethod:@selector(callbackFramerateChange:) withMethod:@selector(hook_callbackFramerateChange:)];
        }

        [objc_getClass("NSMenuItem") swizzleClassMethod:@selector(enabled) withMethod:@selector(hook_enabled)];
        
        [objc_getClass("IOSViewController") swizzleInstanceMethod:@selector(prefersPointerLocked) withMethod:@selector(hook_prefersPointerLocked)];
        
        if ([[[NSBundle mainBundle] bundleIdentifier] isEqual:@"com.riotgames.league.wildrift"] || [[[NSBundle mainBundle] bundleIdentifier] isEqual:@"com.tencent.lolm"]){
            [objc_getClass("MTLRenderPipelineDescriptorInternal") swizzleInstanceMethod:@selector(validateWithDevice:error:) withMethod:@selector(hook_validateWithDevice:error:)];
            [objc_getClass("MTLRenderPipelineDescriptorInternal") swizzleInstanceMethod:@selector(depthStencilPixelformat) withMethod:@selector(hook_depthAttachmentPixelFormat)];
            [objc_getClass("MTLRenderPipelineDescriptorInternal") swizzleInstanceMethod:@selector(stencilAttachmentPixelFormat) withMethod:@selector(hook_stencilAttachmentPixelFormat)];
        }
        
        
    });
}

-(BOOL) hook_prefersPointerLocked {
    return false;
}

- (void) hook_callbackFramerateChange:(int)targetFPS {
    printf("FPS %d", targetFPS);
    [self hook_callbackFramerateChange:120];
}

- (MTLPixelFormat) hook_stencilAttachmentPixelFormat {
    return MTLPixelFormatDepth32Float;
}

- (MTLPixelFormat) hook_depthAttachmentPixelFormat {
    return MTLPixelFormatDepth32Float;
}

-(BOOL) hook_enabled {
    printf("NSMenuCall");
    return true;
}

-(BOOL)hook_validateWithDevice:(id)arg1 error:(id*)arg2 {
    return true;
}

- (CGRect) hook_frame {
    return [PlayScreen frame:[self hook_frame]];
}

- (CGRect) hook_bounds {
    return [PlayScreen bounds:[self hook_bounds]];
}

- (CGSize) hook_size {
    return [PlayScreen sizeAspectRatio:[self hook_size]];
}

bool menuWasCreated = false;

-(id)init {
    if (!menuWasCreated) {
        if ([[self class] isEqual: NSClassFromString(@"_UIMenuBuilder")]) {
            [PlayCover initMenuWithMenu: self];
            menuWasCreated = TRUE;
        }
    }
    
    return self;
}

@end
