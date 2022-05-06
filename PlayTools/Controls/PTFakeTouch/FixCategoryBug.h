//
//  FixCategoryBug.h
//  FakeTouch
//
//  Created by PugaTang on 16/4/7.
//  Copyright © 2016年 PugaTang. All rights reserved.
//

#ifndef MainLib_FixCategoryBug_h
#define MainLib_FixCategoryBug_h

#define __kw_to_string_1(x) #x
#define __kw_to_string(x)  __kw_to_string_1(x)

// 需要在有category的头文件中调用，例如 KW_FIX_CATEGORY_BUG_H(NSString_Extented)
#define KW_FIX_CATEGORY_BUG_H(name) \
@interface KW_FIX_CATEGORY_BUG_##name : NSObject \
+(void)print; \
@end

// 需要在有category的源文件中调用，例如 KW_FIX_CATEGORY_BUG_M(NSString_Extented)
#define KW_FIX_CATEGORY_BUG_M(name) \
@implementation KW_FIX_CATEGORY_BUG_##name \
+ (void)print { \
NSLog(@"[Enable]"); \
} \
@end \


// 在target中启用这个宏，其实就是调用下category中定义的类的print方法。
#define KW_ENABLE_CATEGORY(name) [KW_FIX_CATEGORY_BUG_##name print]

#endif