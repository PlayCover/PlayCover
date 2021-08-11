//
//  PatchLoader.m
//  MacHelper
//

#import "MacPatchLoader.h"
#import <MacHelper/MacHelper-Swift.h>

@implementation MacPatchLoader

static void __attribute__((constructor)) initialize(void){
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [NSWindowHelper initUI];
       });
}

@end
