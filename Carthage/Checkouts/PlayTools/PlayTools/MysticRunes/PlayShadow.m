//
//  PlayShadow.m
//  PlayTools
//
//  Created by Venti on 08/03/2023.
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <PlayTools/PlayTools-Swift.h>

__attribute__((visibility("hidden")))
@interface PlayShadowLoader : NSObject
@end

@implementation NSObject (ShadowSwizzle)

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

+ (void) swizzleClassMethod:(SEL)origSelector withMethod:(SEL)newSelector {
    Class cls = object_getClass((id)self);
    Method originalMethod = class_getClassMethod(cls, origSelector);
    Method swizzledMethod = class_getClassMethod(cls, newSelector);

    if (class_addMethod(cls,
                        origSelector,
                        method_getImplementation(swizzledMethod),
                        method_getTypeEncoding(swizzledMethod)) ) {
        class_replaceMethod(cls,
                            newSelector,
                            method_getImplementation(originalMethod),
                            method_getTypeEncoding(originalMethod));
    } else {
        class_replaceMethod(cls,
                            newSelector,
                            class_replaceMethod(cls,
                                                origSelector,
                                                method_getImplementation(swizzledMethod),
                                                method_getTypeEncoding(swizzledMethod)),
                            method_getTypeEncoding(originalMethod));
    }
}

// Instance methods

- (NSInteger) pm_hook_deviceType {
    return 1;
}

- (bool) pm_return_false {
    // NSLog(@"PC-DEBUG: [PlayMask] Jailbreak Detection Attempted");
    return false;
}

- (bool) pm_return_true {
    // NSLog(@"PC-DEBUG: [PlayMask] Jailbreak Detection Attempted");
    return true;
}

- (BOOL) pm_return_yes {
    // NSLog(@"PC-DEBUG: [PlayMask] Jailbreak Detection Attempted");
    return YES;
}

- (BOOL) pm_return_no {
    // NSLog(@"PC-DEBUG: [PlayMask] Jailbreak Detection Attempted");
    return NO;
}

- (int) pm_return_0 {
    // NSLog(@"PC-DEBUG: [PlayMask] Jailbreak Detection Attempted");
    return 0;
}

- (int) pm_return_1 {
    // NSLog(@"PC-DEBUG: [PlayMask] Jailbreak Detection Attempted");
    return 1;
}

- (NSString *) pm_return_empty {
    // NSLog(@"PC-DEBUG: [PlayMask] Jailbreak Detection Attempted");
    return @"";
}

- (NSDictionary *) pm_return_empty_dictionary {
    // NSLog(@"PC-DEBUG: [PlayMask] Jailbreak Detection Attempted");
    return @{};
}

// Class methods

+ (void) pm_return_2_with_completion_handler:(void (^)(NSInteger))completionHandler {
    // NSLog(@"PC-DEBUG: [PlayMask] Jailbreak Detection Attempted");
    completionHandler(2);
}

+ (NSInteger) pm_return_2 {
    // NSLog(@"PC-DEBUG: [PlayMask] Jailbreak Detection Attempted");
    return 2;
}

+ (bool) pm_clsm_return_false {
    // NSLog(@"PC-DEBUG: [PlayMask] Jailbreak Detection Attempted");
    return false;
}

+ (bool) pm_clsm_return_true {
    // NSLog(@"PC-DEBUG: [PlayMask] Jailbreak Detection Attempted");
    return true;
}

+ (BOOL) pm_clsm_return_yes {
    // NSLog(@"PC-DEBUG: [PlayMask] Jailbreak Detection Attempted");
    return YES;
}

+ (BOOL) pm_clsm_return_no {
    // NSLog(@"PC-DEBUG: [PlayMask] Jailbreak Detection Attempted");
    return NO;
}

+ (int) pm_clsm_do_nothing_with_callback:(void (^)(int))callback {
    // NSLog(@"PC-DEBUG: [PlayMask] Jailbreak Detection Attempted");
    return 0;
}

@end

@implementation PlayShadowLoader

+ (void) load {
    [self debugLogger:@"PlayShadow is now loading"];
    // Gate this behind an environment variable
    if ([[NSProcessInfo processInfo].environment[@"USE_EXTRA_ANTIJB"] isEqualToString:@"1"]) {
        [self loadJailbreakBypass];
    }
    // if ([[PlaySettings shared] bypass]) [self loadEnvironmentBypass]; # disabled as it might be too powerful

    // Swizzle ATTrackingManager
    [objc_getClass("ATTrackingManager") swizzleClassMethod:@selector(requestTrackingAuthorizationWithCompletionHandler:) withMethod:@selector(pm_return_2_with_completion_handler:)];
    [objc_getClass("ATTrackingManager") swizzleClassMethod:@selector(trackingAuthorizationStatus) withMethod:@selector(pm_return_2)];

    // canResizeToFitContent
    // [objc_getClass("UIWindow") swizzleInstanceMethod:@selector(canResizeToFitContent) withMethod:@selector(pm_return_true)];
}

+ (void) loadJailbreakBypass {
    [self debugLogger:@"Jailbreak bypass loading"];
    // Swizzle NSProcessInfo to troll every app that tries to detect macCatalyst
    // [objc_getClass("NSProcessInfo") swizzleInstanceMethod:@selector(isMacCatalystApp) withMethod:@selector(pm_return_false)];
    // [objc_getClass("NSProcessInfo") swizzleInstanceMethod:@selector(isiOSAppOnMac) withMethod:@selector(pm_return_true)];

    // Some device info class
    [objc_getClass("UIDevice") swizzleInstanceMethod:@selector(platform) withMethod:@selector(pm_return_empty)];
    [objc_getClass("UIDevice") swizzleInstanceMethod:@selector(hwModel) withMethod:@selector(pm_return_empty)];
    [objc_getClass("RNDeviceInfo") swizzleInstanceMethod:@selector(getDeviceType) withMethod:@selector(pm_hook_deviceType)];
        
    // Class: UIDevice
    [objc_getClass("UIDevice") swizzleClassMethod:@selector(isJailbroken) withMethod:@selector(pm_clsm_return_no)];
    [objc_getClass("UIDevice") swizzleInstanceMethod:@selector(isJailBreak) withMethod:@selector(pm_return_no)];
    [objc_getClass("UIDevice") swizzleInstanceMethod:@selector(isJailBroken) withMethod:@selector(pm_return_no)];

    // Class: JailbreakDetectionVC
    [objc_getClass("JailbreakDetectionVC") swizzleInstanceMethod:@selector(isJailbroken) withMethod:@selector(pm_return_no)];

    // Class: DTTJailbreakDetection
    [objc_getClass("DTTJailbreakDetection") swizzleClassMethod:@selector(isJailbroken) withMethod:@selector(pm_clsm_return_no)];

    // Class: ANSMetadata
    [objc_getClass("ANSMetadata") swizzleInstanceMethod:@selector(computeIsJailbroken) withMethod:@selector(pm_return_no)];
    [objc_getClass("ANSMetadata") swizzleInstanceMethod:@selector(isJailbroken) withMethod:@selector(pm_return_no)];

    // Class: AppsFlyerUtils
    [objc_getClass("AppsFlyerUtils") swizzleClassMethod:@selector(isJailBreakon) withMethod:@selector(pm_clsm_return_no)];
    [objc_getClass("AppsFlyerUtils") swizzleClassMethod:@selector(isJailbroken) withMethod:@selector(pm_clsm_return_no)];
    [objc_getClass("AppsFlyerUtils") swizzleClassMethod:@selector(isJailbrokenWithSkipAdvancedJailbreakValidation:) withMethod:@selector(pm_clsm_return_false)];

    // Class: jailBreak
    [objc_getClass("jailBreak") swizzleClassMethod:@selector(isJailBreak) withMethod:@selector(pm_clsm_return_false)];

    // Class: GBDeviceInfo
    [objc_getClass("GBDeviceInfo") swizzleInstanceMethod:@selector(isJailbroken) withMethod:@selector(pm_return_no)];

    // Class: CMARAppRestrictionsDelegate
    [objc_getClass("CMARAppRestrictionsDelegate") swizzleInstanceMethod:@selector(isDeviceNonCompliant) withMethod:@selector(pm_return_false)];

    // Class: ADYSecurityChecks
    [objc_getClass("ADYSecurityChecks") swizzleClassMethod:@selector(isDeviceJailbroken) withMethod:@selector(pm_clsm_return_false)];

    // Class: UBReportMetadataDevice
    [objc_getClass("UBReportMetadataDevice") swizzleInstanceMethod:@selector(is_rooted) withMethod:@selector(pm_return_null)];

    // Class: UtilitySystem
    [objc_getClass("UtilitySystem") swizzleClassMethod:@selector(isJailbreak) withMethod:@selector(pm_clsm_return_false)];

    // Class: GemaltoConfiguration
    [objc_getClass("GemaltoConfiguration") swizzleClassMethod:@selector(isJailbreak) withMethod:@selector(pm_clsm_return_false)];

    // Class: CPWRDeviceInfo
    [objc_getClass("CPWRDeviceInfo") swizzleInstanceMethod:@selector(isJailbroken) withMethod:@selector(pm_return_false)];

    // Class: CPWRSessionInfo
    [objc_getClass("CPWRSessionInfo") swizzleInstanceMethod:@selector(isJailbroken) withMethod:@selector(pm_return_false)];

    // Class: KSSystemInfo
    [objc_getClass("KSSystemInfo") swizzleClassMethod:@selector(isJailbroken) withMethod:@selector(pm_clsm_return_false)];

    // Class: EMDSKPPConfiguration
    [objc_getClass("EMDSKPPConfiguration") swizzleInstanceMethod:@selector(jailBroken) withMethod:@selector(pm_return_false)];

    // Class: EnrollParameters
    [objc_getClass("EnrollParameters") swizzleInstanceMethod:@selector(jailbroken) withMethod:@selector(pm_return_null)];

    // Class: EMDskppConfigurationBuilder
    [objc_getClass("EMDskppConfigurationBuilder") swizzleInstanceMethod:@selector(jailbreakStatus) withMethod:@selector(pm_return_false)];

    // Class: FCRSystemMetadata
    [objc_getClass("FCRSystemMetadata") swizzleInstanceMethod:@selector(isJailbroken) withMethod:@selector(pm_return_false)];

    // Class: v_VDMap
    [objc_getClass("v_VDMap") swizzleInstanceMethod:@selector(isJailbrokenDetected) withMethod:@selector(pm_return_false)];
    [objc_getClass("v_VDMap") swizzleInstanceMethod:@selector(isJailBrokenDetectedByVOS) withMethod:@selector(pm_return_false)];
    [objc_getClass("v_VDMap") swizzleInstanceMethod:@selector(isDFPHookedDetecedByVOS) withMethod:@selector(pm_return_false)];
    [objc_getClass("v_VDMap") swizzleInstanceMethod:@selector(isCodeInjectionDetectedByVOS) withMethod:@selector(pm_return_false)];
    [objc_getClass("v_VDMap") swizzleInstanceMethod:@selector(isDebuggerCheckDetectedByVOS) withMethod:@selector(pm_return_false)];
    [objc_getClass("v_VDMap") swizzleInstanceMethod:@selector(isAppSignerCheckDetectedByVOS) withMethod:@selector(pm_return_false)];
    [objc_getClass("v_VDMap") swizzleInstanceMethod:@selector(v_checkAModified) withMethod:@selector(pm_return_false)];
    [objc_getClass("v_VDMap") swizzleInstanceMethod:@selector(isRuntimeTamperingDetected) withMethod:@selector(pm_return_false)];

    // Class: SDMUtils
    [objc_getClass("SDMUtils") swizzleInstanceMethod:@selector(isJailBroken) withMethod:@selector(pm_return_no)];

    // Class: OneSignalJailbreakDetection
    [objc_getClass("OneSignalJailbreakDetection") swizzleClassMethod:@selector(isJailbroken) withMethod:@selector(pm_clsm_return_no)];

    // Class: DigiPassHandler
    [objc_getClass("DigiPassHandler") swizzleInstanceMethod:@selector(rootedDeviceTestResult) withMethod:@selector(pm_return_no)];

    // Class: AWMyDeviceGeneralInfo
    [objc_getClass("AWMyDeviceGeneralInfo") swizzleInstanceMethod:@selector(isCompliant) withMethod:@selector(pm_return_true)];

    // Class: DTXSessionInfo
    [objc_getClass("DTXSessionInfo") swizzleInstanceMethod:@selector(isJailbroken) withMethod:@selector(pm_return_false)];

    // Class: DTXDeviceInfo
    [objc_getClass("DTXDeviceInfo") swizzleInstanceMethod:@selector(isJailbroken) withMethod:@selector(pm_return_false)];

    // Class: JailbreakDetection
    [objc_getClass("JailbreakDetection") swizzleInstanceMethod:@selector(jailbroken) withMethod:@selector(pm_return_false)];

    // Class: jailBrokenJudge
    [objc_getClass("jailBrokenJudge") swizzleInstanceMethod:@selector(isJailBreak) withMethod:@selector(pm_return_false)];
    [objc_getClass("jailBrokenJudge") swizzleInstanceMethod:@selector(isCydiaJailBreak) withMethod:@selector(pm_return_false)];
    [objc_getClass("jailBrokenJudge") swizzleInstanceMethod:@selector(isApplicationsJailBreak) withMethod:@selector(pm_return_false)];
    [objc_getClass("jailBrokenJudge") swizzleInstanceMethod:@selector(ischeckCydiaJailBreak) withMethod:@selector(pm_return_false)];
    [objc_getClass("jailBrokenJudge") swizzleInstanceMethod:@selector(isPathJailBreak) withMethod:@selector(pm_return_false)];
    [objc_getClass("jailBrokenJudge") swizzleInstanceMethod:@selector(boolIsjailbreak) withMethod:@selector(pm_return_false)];

    // Class: FBAdBotDetector
    [objc_getClass("FBAdBotDetector") swizzleInstanceMethod:@selector(isJailBrokenDevice) withMethod:@selector(pm_return_false)];

    // Class: TNGDeviceTool
    [objc_getClass("TNGDeviceTool") swizzleClassMethod:@selector(isJailBreak) withMethod:@selector(pm_clsm_return_false)];
    [objc_getClass("TNGDeviceTool") swizzleClassMethod:@selector(isJailBreak_file) withMethod:@selector(pm_clsm_return_false)];
    [objc_getClass("TNGDeviceTool") swizzleClassMethod:@selector(isJailBreak_cydia) withMethod:@selector(pm_clsm_return_false)];
    [objc_getClass("TNGDeviceTool") swizzleClassMethod:@selector(isJailBreak_appList) withMethod:@selector(pm_clsm_return_false)];
    [objc_getClass("TNGDeviceTool") swizzleClassMethod:@selector(isJailBreak_env) withMethod:@selector(pm_clsm_return_false)];

    // Class: DTDeviceInfo
    [objc_getClass("DTDeviceInfo") swizzleClassMethod:@selector(isJailbreak) withMethod:@selector(pm_clsm_return_false)];

    // Class: SecVIDeviceUtil
    [objc_getClass("SecVIDeviceUtil") swizzleClassMethod:@selector(isJailbreak) withMethod:@selector(pm_clsm_return_false)];

    // Class: RVPBridgeExtension4Jailbroken
    [objc_getClass("RVPBridgeExtension4Jailbroken") swizzleInstanceMethod:@selector(isJailbroken) withMethod:@selector(pm_return_false)];

    // Class: ZDetection
    [objc_getClass("ZDetection") swizzleClassMethod:@selector(isRootedOrJailbroken) withMethod:@selector(pm_clsm_return_false)];
}

+ (void) loadEnvironmentBypass {
    [self debugLogger:@"Environment bypass loading"];
    // Completely nuke everything in the environment variables
    [objc_getClass("NSProcessInfo") swizzleInstanceMethod:@selector(environment) withMethod:@selector(pm_return_empty_dictionary)];
}

+ (void) debugLogger: (NSString *) message {
    NSLog(@"PC-DEBUG: %@", message);
}

@end
