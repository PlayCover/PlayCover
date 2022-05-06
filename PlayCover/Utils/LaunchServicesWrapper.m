//
//  LaunchServicesWrapper.m
//  PlayCover
//
//  Created by Александр Дорофеев on 23.02.2022.
//

#import <ApplicationServices/ApplicationServices.h>
#import "LaunchServicesWrapper.h"

@implementation LaunchServicesWrapper

+ (NSString *)UTIforFileExtension:(NSString *)extension
{
  return (NSString *)CFBridgingRelease(
    UTTypeCreatePreferredIdentifierForTag(
      kUTTagClassFilenameExtension, (__bridge CFStringRef)extension,
      NULL
    )
  );
}

+ (BOOL)setMyselfAsDefaultApplicationForFileExtension:
  (NSString *)fileExtension
{
  return LSSetDefaultRoleHandlerForContentType(
    (__bridge CFStringRef) [LaunchServicesWrapper
    UTIforFileExtension:fileExtension], kLSRolesAll,
    (__bridge CFStringRef) [[NSBundle mainBundle]
    bundleIdentifier]
  );
}

@end
