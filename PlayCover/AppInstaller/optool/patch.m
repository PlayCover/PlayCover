//
//  patch.m
//  PlayCover
//
//  Created by Александр Дорофеев on 20.11.2021.
//

#import <Foundation/Foundation.h>

#import "patch.h"

BOOL patch_binary_with_dylib(NSString *binaryPath, NSString *dylibName) {
    
    NSLog(@"%@", dylibName);
    // Extract binary data
    NSMutableData *binary = [NSMutableData dataWithContentsOfFile:binaryPath];

    // Extract binary headers
    struct thin_header headers[4];
    uint32_t numHeaders = 0;
    headersFromBinary(headers, binary, &numHeaders);
    
    // Loop through headers
    for (uint32_t i = 0; i < numHeaders; i++) {
        struct thin_header macho = headers[i];
        // Insert dylib load entry into binary
        if (insertLoadEntryIntoBinary(dylibName, binary, macho, LC_LOAD_DYLIB)) {
            LOG("Successfully inserted a command for %s", CPU(macho.header.cputype));
        } else {
            LOG("Failed to insert a command for %s", CPU(macho.header.cputype));
        }
    }
    
    [binary writeToFile:binaryPath atomically:NO];

    return YES;
}

BOOL remove_play_tools_from(NSString *binaryPath, NSString *dylibName) {
    NSMutableData *binary = [NSMutableData dataWithContentsOfFile:binaryPath];
    
    struct thin_header headers[4];
    uint32_t numHeaders = 0;
    headersFromBinary(headers, binary, &numHeaders);
    
    // Loop through headers
    for (uint32_t i = 0; i < numHeaders; i++) {
        struct thin_header macho = headers[i];
        // Insert dylib load entry into binary
        removeLoadEntryFromBinary(binary, macho, dylibName);
    }
    
    [binary writeToFile:binaryPath atomically:NO];
    
    return YES;
}
