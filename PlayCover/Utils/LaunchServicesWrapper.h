//
//  LaunchServicesWrapper.h
//  PlayCover
//
//  Created by Александр Дорофеев on 23.02.2022.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LaunchServicesWrapper : NSObject

+ (BOOL)setMyselfAsDefaultApplicationForFileExtension:
  (NSString *)fileExtension;

@end

NS_ASSUME_NONNULL_END
