//
//  patch.h
//  PlayCover
//
//  Created by Александр Дорофеев on 20.11.2021.
//

#ifndef patch_h
#define patch_h

#import <Foundation/Foundation.h>
#import "headers.h"
#import "operations.h"

BOOL patch_binary_with_dylib(NSString *binaryPath, NSString *dylibName);
BOOL remove_play_tools_from(NSString *binaryPath, NSString *dylibName);

#endif /* patch_h */
