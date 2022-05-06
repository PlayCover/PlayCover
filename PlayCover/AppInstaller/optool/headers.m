//
//  headers.m
//  optool
//  Copyright (c) 2014, Alex Zielenski
//  All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions are met:
//
//  * Redistributions of source code must retain the above copyright notice, this
//  list of conditions and the following disclaimer.
//
//  * Redistributions in binary form must reproduce the above copyright notice,
//  this list of conditions and the following disclaimer in the documentation
//  and/or other materials provided with the distribution.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
//  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
//  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
//  DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
//  FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
//  DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
//  SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
//  CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
//  OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
//  OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

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

struct thin_header *headersFromBinary(struct thin_header *headers, NSData *binary, uint32_t *amount) {
    // In a MachO/FAT binary the first 4 bytes is a magic number
    // which gives details about the type of binary it is
    // CIGAM and co. mean the target binary has a byte order
    // in reverse relation to the host machine so we have to swap the bytes
    uint32_t magic = [binary intAtOffset:0];
    bool shouldSwap = magic == MH_CIGAM || magic == MH_CIGAM_64 || magic == FAT_CIGAM;
#define SWAP(NUM) shouldSwap ? CFSwapInt32(NUM) : NUM
    
    uint32_t numArchs = 0;

    // a FAT file is basically a collection of thin MachO binaries
    if (magic == FAT_CIGAM || magic == FAT_MAGIC) {
        LOG("Found FAT Header");
        
        // WE GOT A FAT ONE
        struct fat_header fat = *(struct fat_header *)binary.bytes;
        fat.nfat_arch = SWAP(fat.nfat_arch);
        int offset = sizeof(struct fat_header);

        // Loop through the architectures within the FAT binary to find
        // a thin macho header that we can work with (x86 or x86_64)
        for (int i = 0; i < fat.nfat_arch; i++) {
            struct fat_arch arch;
            arch = *(struct fat_arch *)([binary bytes] + offset);
            arch.cputype = SWAP(arch.cputype);
            arch.offset = SWAP(arch.offset);

            struct thin_header macho = headerAtOffset(binary, arch.offset);
            if (macho.size > 0) {
                LOG("Found thin header...");

                headers[numArchs] = macho;
                numArchs++;
            }
            
            offset += sizeof(struct fat_arch);
        }
    // The binary is thin, meaning it contains only one architecture
    } else if (magic == MH_MAGIC || magic == MH_MAGIC_64) {
        struct thin_header macho = headerAtOffset(binary, 0);
        if (macho.size > 0) {
            LOG("Found thin header...");

            numArchs++;
            headers[0] = macho;
        }
        
    } else {
        LOG("No headers found.");
    }
    
    *amount = numArchs;
    
    return headers;
}
