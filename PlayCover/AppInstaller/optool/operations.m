//
//  operations.m
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


#import "operations.h"
#import "NSData+Reading.h"
#import "defines.h"

// Reads ulen128 from a buffer and returns the value and the length read
static uint64_t read_uleb128(uint8_t *p, uint32_t *read_length) {
    uint8_t *orig  = p;
    uint64_t value = 0;
    unsigned shift = 0;
    
    do {
        value += (*p & 0x7f) << shift;
        shift += 7;
    } while (*p++ >= 128);
    
    if (read_length)
        *read_length = (uint32_t)(p - orig);
    
    return value;
}

// Writes a uint64_t as a uleb to a buffer and returns the length
// Also passes in a length limit so we can pad to it
static uint32_t write_uleb128(uint8_t *p, uint64_t value, uint32_t length_limit) {
    uint8_t *orig = p;
    do {
        uint8_t byte = value & 0x7f;
        value >>= 7;
        
        if (value != 0) {
            byte |= 0x80;
        }
        
        *p++ = byte;
    } while (value != 0);
    
    uint32_t len = (uint32_t)(p - orig);
    
    int32_t pad = length_limit - len;
    if (pad < 0 && length_limit != 0) {
        exit(OPErrorULEBEncodeFailure);
    }
    
    if (pad != 0 && pad > 0) {
        // mark these bytes to show more follow
        for (; pad != 1; --pad) {
            *p++ = '\x80';
        }
        
        // mark terminating byte
        *p++ = '\x00';
    }
    
    return len;
}

unsigned int OP_SOFT_STRIP = 0x00001337;
const char *OP_SOFT_UNRESTRICT = "\xf0\x9f\x92\xa9";

BOOL stripCodeSignatureFromBinary(NSMutableData *binary, struct thin_header macho, BOOL softStrip) {
    binary.currentOffset = macho.offset + macho.size;
    BOOL success = NO;

    // Loop through the commands until we found an LC_CODE_SIGNATURE command
    // and either replace it and its corresponding signature with zero-bytes
    // or change LC_CODE_SIGNATURE to OP_SOFT_STRIP, so the compiler
    // can't interpret the load command for the code signature and treats
    // the binary as if it doesn't exist
    for (int i = 0; i < macho.header.ncmds; i++) {
        if (binary.currentOffset >= binary.length ||
            binary.currentOffset > macho.header.sizeofcmds + macho.size + macho.offset) // dont go past the header
            break;
        
        uint32_t cmd  = [binary intAtOffset:binary.currentOffset];
        uint32_t size = [binary intAtOffset:binary.currentOffset + sizeof(uint32_t)];
        
        switch (cmd) {
            case LC_CODE_SIGNATURE: {
                struct linkedit_data_command command = *(struct linkedit_data_command *)(binary.bytes + binary.currentOffset);
                LOG("stripping code signature for architecture %s...", CPU(macho.header.cputype));
                
                if (!softStrip) {
                    macho.header.ncmds -= 1;
                    macho.header.sizeofcmds -= sizeof(struct linkedit_data_command);
                    [binary replaceBytesInRange:NSMakeRange(command.dataoff, command.datasize) withBytes:0 length:command.datasize];
                    [binary replaceBytesInRange:NSMakeRange(binary.currentOffset, sizeof(struct linkedit_data_command)) withBytes:0 length:0];
                    [binary replaceBytesInRange:NSMakeRange(macho.offset + macho.header.sizeofcmds + macho.size, 0) withBytes:0 length:size];
                } else {
                    [binary replaceBytesInRange:NSMakeRange(binary.currentOffset, 4)
                                      withBytes:&OP_SOFT_STRIP];
                }
                
                success = YES;
                break;
            }
            default:
                binary.currentOffset += size;
                break;
        }
    }

    // paste in a modified header with an updated number and size of load commands
    if (!softStrip) {
        [binary replaceBytesInRange:NSMakeRange(macho.offset, sizeof(macho.header)) withBytes:&macho.header length:sizeof(macho.header)];
    }
    
    return success;
}

BOOL unrestrictBinary(NSMutableData *binary, struct thin_header macho, BOOL soft) {
    binary.currentOffset = macho.offset + macho.size;
    BOOL success = NO;
    
    // Loop through the commands for an LC_SEGMENT(_64) command which has the name __RESTRICT
    // then remove its section with the name "__restrict". If soft is true, then we will simply rename
    // the __restrict section, if not, we will completely delete it and delete the entire __RESTRICT segment if it is
    // empty.
    LOG("unrestricting for architecture %s...", CPU(macho.header.cputype));

    for (int i = 0; i < macho.header.ncmds; i++) {
        if (binary.currentOffset >= binary.length ||
            binary.currentOffset > macho.header.sizeofcmds + macho.size + macho.offset) // dont go past the header
            break;
        
        uint32_t cmd  = [binary intAtOffset:binary.currentOffset];
        uint32_t size = [binary intAtOffset:binary.currentOffset + sizeof(uint32_t)];
        
#define CROSS(CODE...) \
    case LC_SEGMENT: {\
        typedef struct segment_command segment_type; \
        typedef struct section section_type; \
        CODE \
    }\
    case LC_SEGMENT_64: {\
        typedef struct segment_command_64 segment_type; \
        typedef struct section_64 section_type; \
        CODE \
    }
        
        switch (cmd) {
            CROSS(
                segment_type *command = (segment_type *)(binary.mutableBytes + binary.currentOffset);
                if (!strncmp(command->segname, "__RESTRICT", 16)) {
                    LOG("Found __RESTRICT segment");
                    if (size < sizeof(command) ||
                        command->nsects > (size - sizeof(*command)) / sizeof(section_type)) {
                        LOG("Bad segment_command");
                        return false;
                    }
                    
                    section_type *section = (section_type *)(binary.mutableBytes + binary.currentOffset + sizeof(*command));
                    for (uint32_t i = 0; i < command->nsects; i++, section++) {
                        if (!strncmp(section->sectname, "__restrict", 16)) {
                            LOG("Found __restrict section. Patching...");
                            
                            if (soft) {
                                strcpy(section->sectname, OP_SOFT_UNRESTRICT);
                                success = YES;
                            } else {
                                command->nsects--;
                                command->cmdsize -= sizeof(*section);
                                macho.header.sizeofcmds -= sizeof(*section);
                                
                                uint64_t sectionSize = sizeof(*section);
                                [binary replaceBytesInRange:NSMakeRange((NSUInteger)section - (NSUInteger)binary.mutableBytes,
                                                                        sectionSize)
                                                  withBytes:0
                                                     length:0];
                                [binary replaceBytesInRange:NSMakeRange(macho.offset + macho.header.sizeofcmds + macho.size, 0)
                                                  withBytes:0
                                                     length:sectionSize];
                                success = YES;
                            }
                        }
                    }
                    
                    // remove the whole segment
                    if (command->nsects == 0 && !soft) {
                        LOG("__RESTRICT segment has no more sections. Removing...");
                        macho.header.ncmds--;
                        uint32_t cmdSize = sizeof(*command);
                        macho.header.sizeofcmds -= command->cmdsize;
                        [binary replaceBytesInRange:NSMakeRange((NSUInteger)command - (NSUInteger)binary.mutableBytes,
                                                                cmdSize)
                                          withBytes:0
                                             length:0];
                        [binary replaceBytesInRange:NSMakeRange(macho.offset + macho.header.sizeofcmds + macho.size, 0)
                                          withBytes:0
                                             length:cmdSize];
                    } else {
                        binary.currentOffset += command->cmdsize;
                    }
                    
                } else {
                    binary.currentOffset += size;
                }
                break;
            )
            default:
                binary.currentOffset += size;
                break;
        }
    }
#undef CROSS
    
    // paste in a modified header with an updated number and size of commands
    if (!soft) {
        [binary replaceBytesInRange:NSMakeRange(macho.offset, sizeof(macho.header))
                          withBytes:&macho.header
                             length:sizeof(macho.header)];
    }
    
    return success;
}

BOOL removeLoadEntryFromBinary(NSMutableData *binary, struct thin_header macho, NSString *payload) {
    // parse load commands to see if our load command is already there
    binary.currentOffset = macho.offset + macho.size;
    
    uint32_t num = 0;
    uint32_t cumulativeSize = 0;
    uint32_t removedOrdinal = -1;
    
    for (int i = 0; i < macho.header.ncmds; i++) {
        if (binary.currentOffset >= binary.length ||
            binary.currentOffset > macho.offset + macho.size + macho.header.sizeofcmds)
            break;
        
        uint32_t cmd  = [binary intAtOffset:binary.currentOffset];
        uint32_t size = [binary intAtOffset:binary.currentOffset + 4];
        
        // delete the bytes in all of the load commands matching the description
        switch (cmd) {
            case LC_REEXPORT_DYLIB:
            case LC_LOAD_UPWARD_DYLIB:
            case LC_LOAD_WEAK_DYLIB:
            case LC_LOAD_DYLIB: {
                
                struct dylib_command command = *(struct dylib_command *)(binary.bytes + binary.currentOffset);
                char *name = (char *)[[binary subdataWithRange:NSMakeRange(binary.currentOffset + command.dylib.name.offset, command.cmdsize - command.dylib.name.offset)] bytes];
                if ([@(name) isEqualToString:payload] && removedOrdinal == -1) {
                    LOG("removing payload from %s...", LC(cmd));
                    // remove load command
                    // remove these bytes and append zeroes to the end of the header
                    [binary replaceBytesInRange:NSMakeRange(binary.currentOffset, size) withBytes:0 length:0];
                    num++;
                    cumulativeSize += size;
                    
                    removedOrdinal = i;
                }
                
                binary.currentOffset += size;
                break;
            }
                
            //! EXPERIMENTAL: Shifting binding ordinals
            case LC_DYLD_INFO:
            case LC_DYLD_INFO_ONLY: {
                if (removedOrdinal == -1) {
                    binary.currentOffset += size;
                    break;
                }
#ifdef DEBUG
                struct dyld_info_command info;
                [binary getBytes:&info range:NSMakeRange(binary.currentOffset, size)];
                
                uint8_t *p = (uint8_t *)binary.mutableBytes + info.bind_off;
                uint32_t s = 0;
                while (s < info.bind_size) {
                    
                    uint8_t opcode = *p & BIND_OPCODE_MASK;
                    
                    p++;
                    s += (sizeof(&p));
                    
                    // we dont support opcode == BIND_OPCODE_SET_DYLIB_SPECIAL_IMM
                    if (opcode == BIND_OPCODE_SET_DYLIB_ORDINAL_ULEB) {
                        NSLog(@"ULEB");
                        
                        // Convert the ULEB into something we can use
                        uint32_t len = 0;
                        uint64_t ordinal = read_uleb128(p, &len);
                        // Decrement it if necessary
                        if (ordinal > removedOrdinal) {
                            ordinal--;
                            
                            // Write it back if necessary
                            write_uleb128(p, ordinal, len);
                        }
                        
                        // increment s by the size of the ULEB
                        s += len;

                        
                    } else if (opcode == BIND_OPCODE_SET_DYLIB_ORDINAL_IMM) {
                        uint8_t immediate = *p & BIND_IMMEDIATE_MASK;
                        
                        // decrement this immediate if this opcode is greater than the one we removed
                        if (immediate > i) {
                            immediate--;
                            
                            // no need to shift the opcode since we never shifted it right
                            uint8_t binding = opcode | (immediate & BIND_IMMEDIATE_MASK);
                            // reset the binding ordinal
                            *p = binding;
                        }
                    }
                }
#endif
                binary.currentOffset += size;
                break;
            }
            default:
                binary.currentOffset += size;
                break;
        }
    }
    
    if (num == 0)
        return NO;
    
    // fix the header
    macho.header.ncmds -= num;
    macho.header.sizeofcmds -= cumulativeSize;
    
    unsigned int zeroByte = 0;
    
    // append a null byte for every one we removed to the end of the header
    [binary replaceBytesInRange:NSMakeRange(macho.offset + macho.header.sizeofcmds + macho.size, 0) withBytes:&zeroByte length:cumulativeSize];
    [binary replaceBytesInRange:NSMakeRange(macho.offset, sizeof(macho.header))
                      withBytes:&macho.header
                         length:sizeof(macho.header)];
    
    return YES;
}

BOOL binaryHasLoadCommandForDylib(NSMutableData *binary, NSString *dylib, uint32_t *lastOffset, struct thin_header macho) {
    binary.currentOffset = macho.size + macho.offset;
    unsigned int loadOffset = (unsigned int)binary.currentOffset;

    // Loop through compatible LC_LOAD commands until we find one which points
    // to the given dylib and tell the caller where it is and if it exists
    for (int i = 0; i < macho.header.ncmds; i++) {
        if (binary.currentOffset >= binary.length ||
            binary.currentOffset > macho.offset + macho.size + macho.header.sizeofcmds)
            break;
        
        uint32_t cmd  = [binary intAtOffset:binary.currentOffset];
        uint32_t size = [binary intAtOffset:binary.currentOffset + 4];
        
        switch (cmd) {
            case LC_REEXPORT_DYLIB:
            case LC_LOAD_UPWARD_DYLIB:
            case LC_LOAD_WEAK_DYLIB:
            case LC_LOAD_DYLIB: {
                struct dylib_command command = *(struct dylib_command *)(binary.bytes + binary.currentOffset);
                char *name = (char *)[[binary subdataWithRange:NSMakeRange(binary.currentOffset + command.dylib.name.offset, command.cmdsize - command.dylib.name.offset)] bytes];
                
                if ([@(name) isEqualToString:dylib]) {
                    *lastOffset = (unsigned int)binary.currentOffset;
                    return YES;
                }
                
                binary.currentOffset += size;
                loadOffset = (unsigned int)binary.currentOffset;
                break;
            }
            default:
                binary.currentOffset += size;
                break;
        }
    }
    
    if (lastOffset != NULL)
        *lastOffset = loadOffset;
    
    return NO;
}

BOOL renameBinary(NSMutableData *binary, struct thin_header macho, NSString *from, NSString *to) {
    binary.currentOffset = macho.size + macho.offset;
    
    BOOL success = NO;
    
    // Loop through compatible LC_LOAD commands until we find one which points
    // to the given dylib and tell the caller where it is and if it exists
    for (int i = 0; i < macho.header.ncmds; i++) {
        if (binary.currentOffset >= binary.length ||
            binary.currentOffset > macho.offset + macho.size + macho.header.sizeofcmds)
            break;
        
        uint32_t cmd  = [binary intAtOffset:binary.currentOffset];
        uint32_t size = [binary intAtOffset:binary.currentOffset + 4];
        
        switch (cmd) {
            case LC_ID_DYLIB:
            case LC_REEXPORT_DYLIB:
            case LC_LOAD_UPWARD_DYLIB:
            case LC_LOAD_WEAK_DYLIB:
            case LC_LOAD_DYLIB: {
                struct dylib_command *command = (struct dylib_command *)(binary.mutableBytes + binary.currentOffset);
                off_t name_offset = binary.currentOffset + command->dylib.name.offset;
                NSRange name_range = NSMakeRange(name_offset, command->cmdsize - command->dylib.name.offset);
                char *name = (char *)[[binary subdataWithRange:name_range] bytes];

                if ([@(name) isEqualToString:from] || (!from && cmd == LC_ID_DYLIB)) {
                    const char *replacement = to.fileSystemRepresentation;
                    
                    NSInteger name_length = strlen(replacement) + 1;
                    unsigned int padding = (4 - (name_length % 4));
                    if (padding < 4)
                        name_length += padding;
                    
                    NSInteger shift = name_length - name_range.length;
                    
                    if (shift > 0) {
                        // accomodate for shift by replacing null bytes
                        [binary replaceBytesInRange:NSMakeRange(macho.header.sizeofcmds + macho.offset + macho.size,
                                                                shift)
                                          withBytes:0
                                             length:0];
                        
                    } else if (shift < 0) {
                        uint8_t zero = 0;
                        // accomodate for shift by inserting null bytes
                        [binary replaceBytesInRange:NSMakeRange(macho.header.sizeofcmds + macho.offset + macho.size,
                                                                0)
                                          withBytes:&zero
                                             length:labs(shift)];
                    }
                                        
                    command->cmdsize += shift;
                    macho.header.sizeofcmds += shift;
                    
                    [binary replaceBytesInRange:NSMakeRange(macho.offset, sizeof(macho.header)) withBytes:&macho.header];
                    [binary replaceBytesInRange:name_range withBytes:replacement length:name_length];
                    
                    success = YES;
                }
                
                binary.currentOffset += size;
                break;
            }
            default:
                binary.currentOffset += size;
                break;
        }
    }
    
    return success;
}

BOOL insertLoadEntryIntoBinary(NSString *dylibPath, NSMutableData *binary, struct thin_header macho, uint32_t type) {
    if (type != LC_REEXPORT_DYLIB &&
        type != LC_LOAD_WEAK_DYLIB &&
        type != LC_LOAD_UPWARD_DYLIB &&
        type != LC_LOAD_DYLIB) {
        LOG("Invalid load command type");
        return NO;
    }
    // parse load commands to see if our load command is already there
    uint32_t lastOffset = 0;
    if (binaryHasLoadCommandForDylib(binary, dylibPath, &lastOffset, macho)) {
        // there already exists a load command for this payload so change the command type
        uint32_t originalType = *(uint32_t *)(binary.bytes + lastOffset);
        if (originalType != type) {
            LOG("A load command already exists for %s. Changing command type from %s to desired %s", dylibPath.UTF8String, LC(originalType), LC(type));
            [binary replaceBytesInRange:NSMakeRange(lastOffset, sizeof(type)) withBytes:&type];
        } else {
            LOG("Load command already exists");
        }
        
        return YES;
    }
    
    // create a new load command
    unsigned int length = (unsigned int)sizeof(struct dylib_command) + (unsigned int)dylibPath.length;
    unsigned int padding = (8 - (length % 8));
    
    // check if data we are replacing is null
    NSData *occupant = [binary subdataWithRange:NSMakeRange(macho.header.sizeofcmds + macho.offset + macho.size,
                                                            length + padding)];

    // All operations in optool try to maintain a constant byte size of the executable
    // so we don't want to append new bytes to the binary (that would break the executable
    // since everything is offset-based–we'd have to go in and adjust every offset)
    // So instead take advantage of the huge amount of padding after the load commands
    if (strcmp([occupant bytes], "\0")) {
        NSLog(@"cannot inject payload into %s because there is no room", dylibPath.fileSystemRepresentation);
        return NO;
    }
    
    LOG("Inserting a %s command for architecture: %s", LC(type), CPU(macho.header.cputype));
    
    struct dylib_command command;
    struct dylib dylib;
    dylib.name.offset = sizeof(struct dylib_command);
    dylib.timestamp = 2; // load commands I've seen use 2 for some reason
    dylib.current_version = 0;
    dylib.compatibility_version = 0;
    command.cmd = type;
    command.dylib = dylib;
    command.cmdsize = length + padding;
    
    unsigned int zeroByte = 0;
    NSMutableData *commandData = [NSMutableData data];
    [commandData appendBytes:&command length:sizeof(struct dylib_command)];
    [commandData appendData:[dylibPath dataUsingEncoding:NSASCIIStringEncoding]];
    [commandData appendBytes:&zeroByte length:padding];
    
    // remove enough null bytes to account of our inserted data
    [binary replaceBytesInRange:NSMakeRange(macho.offset + macho.header.sizeofcmds + macho.size, commandData.length)
                      withBytes:0
                         length:0];
    // insert the data
    [binary replaceBytesInRange:NSMakeRange(lastOffset, 0) withBytes:commandData.bytes length:commandData.length];
    
    // fix the existing header
    macho.header.ncmds += 1;
    macho.header.sizeofcmds += command.cmdsize;
    
    // this is safe to do in 32bit because the 4 bytes after the header are still being put back
    [binary replaceBytesInRange:NSMakeRange(macho.offset, sizeof(macho.header)) withBytes:&macho.header];
    
    return YES;
}
BOOL removeASLRFromBinary(NSMutableData *binary, struct thin_header macho) {
    // MH_PIE is a flag on the macho header whcih indicates that the address space of the executable
    // should be randomized
    if (macho.header.flags & MH_PIE) {
        macho.header.flags &= ~MH_PIE;
        [binary replaceBytesInRange:NSMakeRange(macho.offset, sizeof(macho.header)) withBytes:&macho.header];
    } else {
        LOG("binary is not protected by ASLR");
        return NO;
    }
    
    return YES;
}
