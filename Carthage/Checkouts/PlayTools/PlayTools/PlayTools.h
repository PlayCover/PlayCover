//
//  PlayTools.h
//  PlayTools
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

//! Project version number for PlayTools.
FOUNDATION_EXPORT double PlayToolsVersionNumber;

//! Project version string for PlayTools.
FOUNDATION_EXPORT const unsigned char PlayToolsVersionString[];

#import "PTFakeMetaTouch.h"
#import "IOHIDEvent+KIF.h"
#import "UIApplication+Private.h"
#import "UIEvent+Private.h"
#import "UITouch+Private.h"

// This is the function that CFRunLoop calls to serve main dispatch queue
// Used by PlayInput to manually drain the queue
extern void _dispatch_main_queue_callback_4CF(void *);
