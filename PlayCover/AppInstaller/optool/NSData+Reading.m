//
//  NSData+Reading.m
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

#import "NSData+Reading.h"
#import <objc/runtime.h>

@implementation NSData (Reading)

static char OFFSET;
- (NSUInteger)currentOffset
{
    NSNumber *value = objc_getAssociatedObject(self, &OFFSET);
    return value.unsignedIntegerValue;
}

- (void)setCurrentOffset:(NSUInteger)offset
{
    [self willChangeValueForKey:@"currentOffset"];
    objc_setAssociatedObject(self, &OFFSET, [NSNumber numberWithUnsignedInteger:offset], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self didChangeValueForKey:@"currentOffset"];
}

- (uint8_t)nextByte
{
    uint8_t nextByte    = [self byteAtOffset:self.currentOffset];
    self.currentOffset += sizeof(uint8_t);
    return nextByte;
}

- (uint8_t)byteAtOffset:(NSUInteger)offset
{
    uint8_t result;
    [self getBytes:&result range:NSMakeRange(offset, sizeof(result))];
    return result;
}

- (uint16_t)nextShort
{
    uint16_t nextShort = [self shortAtOffset:self.currentOffset];
    self.currentOffset += sizeof(uint16_t);
    return nextShort;
}

- (uint16_t)shortAtOffset:(NSUInteger)offset
{
    uint16_t result;
    [self getBytes:&result range:NSMakeRange(offset, sizeof(result))];
    return result;
}

- (uint32_t)nextInt
{
    uint32_t nextInt = [self intAtOffset:self.currentOffset];
    self.currentOffset += sizeof(uint32_t);
    return nextInt;
}

- (uint32_t)intAtOffset:(NSUInteger)offset
{
    uint32_t result;
    [self getBytes:&result range:NSMakeRange(offset, sizeof(result))];
    return result;
}

- (uint64_t)nextLong
{
    uint64_t nextLong = [self longAtOffset:self.currentOffset];
    self.currentOffset += sizeof(uint64_t);
    return nextLong;
}

- (uint64_t)longAtOffset:(NSUInteger)offset;
{
    uint64_t result;
    [self getBytes:&result range:NSMakeRange(offset, sizeof(result))];
    return result;
}

@end

@implementation NSMutableData (ByteAdditions)

- (void)appendByte:(uint8_t)value
{
    [self appendBytes:&value length:sizeof(value)];
}

- (void)appendShort:(uint16_t)value
{
    uint16_t swap = CFSwapInt16HostToLittle(value);
    [self appendBytes:&swap length:sizeof(swap)];
}

- (void)appendInt:(uint32_t)value
{
    uint32_t swap = CFSwapInt32HostToLittle(value);
    [self appendBytes:&swap length:sizeof(swap)];
}

- (void)appendLong:(uint64_t)value;
{
    uint64_t swap = CFSwapInt64HostToLittle(value);
    [self appendBytes:&swap length:sizeof(swap)];
}

@end
