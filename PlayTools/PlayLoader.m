//
//  PlayLoader.m
//  PlayTools
//
#import "PlayLoader.h"
#import <PlayTools/PlayTools-Swift.h>
#include <dlfcn.h>
#include <stdio.h>
#include <unistd.h>
#import "NSObject+Swizzle.h"
#include <sys/types.h>
#include <sys/sysctl.h>
#include <stdio.h>
#include "sandbox.h"
#include <unistd.h>
#import <sys/utsname.h>
#import <sys/stat.h>

#define SYSTEM_INFO_PATH "/System/Library/CoreServices/SystemVersion.plist"
#define IOS_SYSTEM_INFO_PATH "/System/Library/CoreServices/iOSSystemVersion.plist"

#define CS_OPS_STATUS 0    /* return status */
#define CS_OPS_ENTITLEMENTS_BLOB 7    /* get entitlements blob */
#define CS_OPS_IDENTITY 11    /* get codesign identity */

int dyld_get_active_platform();

int my_dyld_get_active_platform()
{
    return 2;
}

extern void* dyld_get_base_platform(void* platform);

void* my_dyld_get_base_platform(void* platform)
{
    return 2;
}

static bool isGenshin = false;

extern int csops(pid_t pid, unsigned int ops, void *useraddr, size_t usersize);

int my_csops(pid_t pid, uint32_t ops, user_addr_t useraddr, user_size_t usersize){
    if (isGenshin) {
        if (ops == CS_OPS_STATUS || ops == CS_OPS_IDENTITY) {
            printf("Hooked CSOPS %d \n", ops);
            return 0;
        }
    }
  
    return csops(pid, ops, useraddr, usersize);
}

DYLD_INTERPOSE(my_csops, csops)
DYLD_INTERPOSE(my_dyld_get_active_platform, dyld_get_active_platform)
DYLD_INTERPOSE(my_dyld_get_base_platform, dyld_get_base_platform)


@implementation PlayLoader

static void __attribute__((constructor)) initialize(void){
    NSString* bundleId = [[NSBundle mainBundle] bundleIdentifier];
    isGenshin = [bundleId isEqual:@"com.miHoYo.GenshinImpact"] || [bundleId isEqual:@"com.miHoYo.Yuanshen"];
    [PlayCover launch];
}


@end
