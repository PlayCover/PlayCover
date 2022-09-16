#import "headers.h"
#import <mach-o/loader.h>
#import <mach-o/fat.h>
#import "NSData+Reading.h"

struct thin_header headerAtOffset(NSData *binary, uint32_t offset) {
    struct thin_header macho;
    macho.offset = offset;
    macho.header = *(struct mach_header *)(binary.bytes + offset);
    if (macho.header.magic == MH_MAGIC || macho.header.magic == MH_CIGAM) {
        macho.size = sizeof(struct mach_header);
    } else {
        macho.size = sizeof(struct mach_header_64);
    }
    if (macho.header.cputype != CPU_TYPE_X86_64 && macho.header.cputype != CPU_TYPE_I386 && macho.header.cputype != CPU_TYPE_ARM && macho.header.cputype != CPU_TYPE_ARM64){
        macho.size = 0;
    }
    
    return macho;
}
