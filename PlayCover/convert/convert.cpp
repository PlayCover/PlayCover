extern "C"
{
#include "convert.h"
}

#include <stdio.h>
#include <string>
#include <mach-o/loader.h>
#include <mach-o/fat.h>
#include <mach/machine.h>

static unsigned long max_header_size;

uint32_t swap_uint32( uint32_t val ) {
    val = ((val << 8) & 0xFF00FF00 ) | ((val >> 8) & 0xFF00FF );
    return (val << 16) | (val >> 16);
}
uint64_t swap_uint64( uint64_t val ) {
    val = ((val << 8) & 0xFF00FF00FF00FF00ULL ) | ((val >> 8) & 0x00FF00FF00FF00FFULL );
    val = ((val << 16) & 0xFFFF0000FFFF0000ULL ) | ((val >> 16) & 0x0000FFFF0000FFFFULL );
    return (val << 32) | (val >> 32);
}

bool patch_for_simulator(char *base) {
    static struct {
        build_version_command cmd;
        build_tool_version tool_ver;
    } buildVersionForSimulator = { LC_BUILD_VERSION, 0x20, 6, 0xA0000, 0xE0500, 1, 3, 0x2610700};
    struct load_command *lc;

    mach_header_64 *header = (mach_header_64 *)base;
    if (header->magic == FAT_CIGAM_64 || header->magic == FAT_CIGAM) {
        fat_header *fat = (fat_header *)base;
        if (swap_uint32(fat->nfat_arch) != 1) {
            printf("error: iOS App has fat macho with more than one architecture? (%d)\n", fat->nfat_arch);
            return false;
        }
        cpu_type_t cputype;
        uint64_t offset;
        if (header->magic == FAT_CIGAM_64) {
            fat_arch_64 *farch64 = (fat_arch_64 *)(base + sizeof(fat_header));
            cputype = swap_uint32(farch64->cputype);
            offset = swap_uint64(farch64->offset);
        } else {
            fat_arch *farch = (fat_arch *)(base + sizeof(fat_header));
            cputype = swap_uint32(farch->cputype);
            offset = swap_uint32(farch->offset);
        }

        if (cputype != CPU_TYPE_ARM64) {
            printf("error: iOS App has macho with wrong cputype:0x%x\n", cputype);
            return false;
        }
        if (offset > max_header_size) {
            printf("error: huge fat arch offset 0x%llx > 0x%lx, set MAX_HEADER_SIZE environment to change the default\n", offset, max_header_size);
        }
        header = (mach_header_64 *)(base + offset);
    }
    if (header->magic != MH_MAGIC_64) {
        printf("error: not a valid macho file\n");
        return false;
    }

    //load commands begins after the macho header
    lc = (load_command*)((mach_vm_address_t)header + sizeof(mach_header_64));
    uint32_t removedSize = 0, sizeofcmds = 0, numOfRemoved = 0, i = 0, cmdsize = 0;
    bool found_build_version_command = false, removed = false;
    for (; i < header->ncmds; i++) {
        removed = false;
        if (lc->cmd == LC_ENCRYPTION_INFO || lc->cmd == LC_ENCRYPTION_INFO_64 || lc->cmd == LC_VERSION_MIN_IPHONEOS){
            removed = true; // mark the load command as removed
            removedSize += lc->cmdsize;
            numOfRemoved += 1;
            printf("remove load command[0x%x] at offset:0x%llx\n", lc->cmd, (mach_vm_address_t)lc-(mach_vm_address_t)header);
        } else if (lc->cmd == LC_BUILD_VERSION) { // replace build version with simulator version
            memcpy(lc, &buildVersionForSimulator, sizeof(build_version_command)+sizeof(build_tool_version));
            found_build_version_command = true;
            printf("patch build version command at offset:0x%llx\n", (mach_vm_address_t)lc-(mach_vm_address_t)header);
        }
        cmdsize = lc->cmdsize; // maybe overwrite, backup cmdsize
        if (removedSize && !removed) { // move forward with removedSize bytes.
            memcpy((char *)lc-removedSize, lc, cmdsize);
        }
        sizeofcmds += cmdsize;
        lc = (struct load_command*)((mach_vm_address_t)lc + cmdsize);
    }
    if (sizeofcmds != header->sizeofcmds) {
        printf("error: sizeofcmds(0x%x) != header->sizeofcmds(0x%x)\n", sizeofcmds, header->sizeofcmds);
        return false;
    }

    if (!found_build_version_command) { // not found, then insert one
        memcpy((char *)lc-removedSize, &buildVersionForSimulator, sizeof(build_version_command)+sizeof(build_tool_version));
        removedSize -= (sizeof(build_version_command)+sizeof(build_tool_version));
        numOfRemoved -= 1;
    }
    header->ncmds -= numOfRemoved;
    header->sizeofcmds -= removedSize;
    return true;
}

int convert(const char* path) {
    max_header_size = 0x10000;
    const char *env = getenv("MAX_HEADER_SIZE");
    if (env) {
        max_header_size = strtoul(env, NULL, 16);
    }

    char *buffer = new char[max_header_size];
    FILE *fr = fopen(path, "r");
    size_t readLen = fread(buffer, 1, max_header_size, fr);


    if (patch_for_simulator(buffer)) {
        char *outfile = new char[strlen(path)+5];
        strcpy(outfile, path);
        strcat(outfile, "_sim");
        FILE *fw = fopen(outfile, "w");
        delete [] outfile;
        fwrite(buffer, 1, readLen, fw);
        while (readLen == max_header_size) { // copy the remain bytes
            readLen = fread(buffer, 1, max_header_size, fr);
            fwrite(buffer, 1, readLen, fw);
        }
        fclose(fw);
    } else {
        return -1;
    }
    fclose(fr);
    delete[] buffer;
    return 0;
}
