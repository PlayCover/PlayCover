#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LoginKitWrapper : NSObject
+(BOOL) setLogin:(LSSharedFileListRef) inlist path:(NSString *) path;
@end

NS_ASSUME_NONNULL_END
