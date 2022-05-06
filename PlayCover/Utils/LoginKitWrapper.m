//
//  LoginKitWrapper.m
//  PlayCover
//
//  Created by Александр Дорофеев on 19.04.2022.
//

#import "LoginKitWrapper.h"
#import <Foundation/Foundation.h>
@implementation LoginKitWrapper
+(BOOL) setLogin:(LSSharedFileListRef) inlist path:(NSString *) path {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    return LSSharedFileListInsertItemURL(inlist, kLSSharedFileListItemLast, nil, nil, (__bridge CFURLRef _Nonnull)([NSURL fileURLWithPath:path]), nil, nil) != nil;
#pragma clang diagnostic pop
}

@end
