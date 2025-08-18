//
//  PlayLoader.h
//  PlayTools
//

#import <Foundation/Foundation.h>
#import "CoreGraphics/CoreGraphics.h"

#define DYLD_INTERPOSE(_replacement,_replacee) \
   __attribute__((used)) static struct{ const void* replacement; const void* replacee; } _interpose_##_replacee \
            __attribute__ ((section ("__DATA,__interpose"))) = { (const void*)(unsigned long)&_replacement, (const void*)(unsigned long)&_replacee };

@interface PlayLoader : NSObject

@end

