//
//  defines.h
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


#import <mach-o/loader.h>

#ifndef CPU_TYPE_ARM64
    #define CPU_TYPE_ARM64 (CPU_TYPE_ARM | CPU_ARCH_ABI64)
#endif

#define LOG(fmt, args...) printf(fmt "\n", ##args)

#define CPU(CPUTYPE) ({ \
    const char *c = ""; \
    if (CPUTYPE == CPU_TYPE_I386) \
        c = "x86"; \
    if (CPUTYPE == CPU_TYPE_X86_64) \
        c = "x86_64"; \
    if (CPUTYPE == CPU_TYPE_ARM) \
        c = "arm"; \
    if (CPUTYPE == CPU_TYPE_ARM64) \
        c = "arm64"; \
    c; \
})

#define LC(LOADCOMMAND) ({ \
    const char *c = ""; \
    if (LOADCOMMAND == LC_REEXPORT_DYLIB) \
        c = "LC_REEXPORT_DYLIB";\
    else if (LOADCOMMAND == LC_LOAD_WEAK_DYLIB) \
        c = "LC_LOAD_WEAK_DYLIB";\
    else if (LOADCOMMAND == LC_LOAD_UPWARD_DYLIB) \
        c = "LC_LOAD_UPWARD_DYLIB";\
    else if (LOADCOMMAND == LC_LOAD_DYLIB) \
        c = "LC_LOAD_DYLIB";\
    c;\
})

#define COMMAND(str) ({ \
    uint32_t cmd = -1; \
    if ([str isEqualToString: @"reexport"]) \
        cmd = LC_REEXPORT_DYLIB; \
    else if ([str isEqualToString: @"weak"]) \
        cmd = LC_LOAD_WEAK_DYLIB; \
    else if ([str isEqualToString: @"upward"]) \
        cmd = LC_LOAD_UPWARD_DYLIB; \
    else if ([str isEqualToString: @"load"]) \
        cmd = LC_LOAD_DYLIB; \
    cmd; \
})

// we pass around this header which includes some extra information
// and a 32-bit header which we used for both 32-bit and 64-bit files
// since the 64-bit just adds an extra field to the end which we don't need
struct thin_header {
    uint32_t offset;
    uint32_t size;
    struct mach_header header;
};

typedef NS_ENUM(int, OPError) {
    OPErrorNone               = 0,
    OPErrorRead               = 1,           // failed to read target path
    OPErrorIncompatibleBinary = 2,           // couldn't find x86 or x86_64 architecture in binary
    OPErrorStripFailure       = 3,           // failed to strip codesignature
    OPErrorWriteFailure       = 4,           // failed to write data to final output path
    OPErrorNoBackup           = 5,           // no backup to restore
    OPErrorRemovalFailure     = 6,           // failed to remove executable during restore
    OPErrorMoveFailure        = 7,           // failed to move backup to correct location
    OPErrorNoEntries          = 8,           // cant remove dylib entries because they dont exist
    OPErrorInsertFailure      = 9,           // failed to insert load command
    OPErrorInvalidLoadCommand = 10,          // user provided an unnacceptable load command string
    OPErrorResignFailure      = 11,          // codesign failed for some reason
    OPErrorBackupFailure      = 12,          // failed to write backup
    OPErrorInvalidArguments   = 13,          // bad arguments
    OPErrorBadULEB            = 14,          // uleb while reading binding ordinals is in an invalid format
    OPErrorULEBEncodeFailure  = 15           // failed to encode a uleb within specified length requirements
};