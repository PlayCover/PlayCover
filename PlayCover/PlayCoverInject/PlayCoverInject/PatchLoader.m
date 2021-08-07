//
//  PatchLoader.m
//  PlayCoverInject
//
//  Created by Alex on 11.04.2021.
//

#import "PatchLoader.h"
#import <PlayCoverInject/PlayCoverInject-Swift.h>

@implementation PatchLoader

static void __attribute__((constructor)) initialize(void){
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.4 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [InputController initUI];
       });
}

@end
