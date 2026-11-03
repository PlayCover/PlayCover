#import <UIKit/UIKit.h>
#import <Security/Security.h>
#import <objc/runtime.h>
#import <dlfcn.h>
#import <mach-o/dyld.h>
#import <mach-o/loader.h>
#import <mach-o/nlist.h>
#import <sys/mman.h>
#include <string.h>

// Old 64-bit games call UIApplication's idle-timer setter from a worker thread.
// FrontBoard updates the scene on the main run-loop queue and aborts if the call
// arrives anywhere else, so the setter is moved onto the main thread.
//
// The same games use Apple's KeychainItemWrapper. It stores an iOS access group
// that this Mac sandbox does not have, then aborts unless SecItem returns success
// or, for delete, item-not-found. The item is stored again without that group.

typedef void (*GuestSetIdleIMP)(id, SEL, BOOL);
typedef void (*GuestSetIdleReasonIMP)(id, SEL, BOOL, id);
typedef OSStatus (*GuestSecItemAddIMP)(CFDictionaryRef, CFTypeRef *);
typedef OSStatus (*GuestSecItemUpdateIMP)(CFDictionaryRef, CFDictionaryRef);
typedef OSStatus (*GuestSecItemDeleteIMP)(CFDictionaryRef);

static GuestSetIdleIMP guestOrigSetIdle;
static GuestSetIdleReasonIMP guestOrigSetIdleReason;
static GuestSecItemAddIMP guestRealSecItemAdd;
static GuestSecItemUpdateIMP guestRealSecItemUpdate;
static GuestSecItemDeleteIMP guestRealSecItemDelete;

static void GuestRunOnMain(void (^work)(void)) {
    if (work == nil) {
        return;
    }
    if ([NSThread isMainThread]) {
        work();
        return;
    }
    dispatch_sync(dispatch_get_main_queue(), work);
}

static void GuestSetIdle(id self, SEL cmd, BOOL disabled) {
    GuestSetIdleIMP original = guestOrigSetIdle;
    if (original == NULL) {
        return;
    }
    GuestRunOnMain(^{
        original(self, cmd, disabled);
    });
}

static void GuestSetIdleReason(id self, SEL cmd, BOOL disabled, id reason) {
    GuestSetIdleReasonIMP original = guestOrigSetIdleReason;
    if (original == NULL) {
        return;
    }
    GuestRunOnMain(^{
        original(self, cmd, disabled, reason);
    });
}

static CFDictionaryRef GuestKeychainWithoutAccessGroup(CFDictionaryRef attributes) {
    if (attributes == NULL || CFGetTypeID(attributes) != CFDictionaryGetTypeID()) {
        return NULL;
    }
    if (!CFDictionaryContainsKey(attributes, kSecAttrAccessGroup)) {
        return NULL;
    }
    CFMutableDictionaryRef copy = CFDictionaryCreateMutableCopy(kCFAllocatorDefault, 0, attributes);
    if (copy == NULL) {
        return NULL;
    }
    CFDictionaryRemoveValue(copy, kSecAttrAccessGroup);
    return copy;
}

static OSStatus GuestSecItemAdd(CFDictionaryRef attributes, CFTypeRef *result) {
    if (guestRealSecItemAdd == NULL) {
        return errSecUnimplemented;
    }
    OSStatus status = guestRealSecItemAdd(attributes, result);
    if (status == errSecSuccess || status == errSecDuplicateItem) {
        return status;
    }
    CFDictionaryRef stripped = GuestKeychainWithoutAccessGroup(attributes);
    if (stripped == NULL) {
        return status;
    }
    OSStatus retried = guestRealSecItemAdd(stripped, result);
    CFRelease(stripped);
    if (retried == errSecSuccess || retried == errSecDuplicateItem) {
        return errSecSuccess;
    }
    return retried;
}

static OSStatus GuestSecItemUpdate(CFDictionaryRef query, CFDictionaryRef attributesToUpdate) {
    if (guestRealSecItemUpdate == NULL) {
        return errSecUnimplemented;
    }
    OSStatus status = guestRealSecItemUpdate(query, attributesToUpdate);
    if (status == errSecSuccess) {
        return status;
    }
    CFDictionaryRef strippedQuery = GuestKeychainWithoutAccessGroup(query);
    CFDictionaryRef strippedUpdate = GuestKeychainWithoutAccessGroup(attributesToUpdate);
    OSStatus retried = guestRealSecItemUpdate(strippedQuery != NULL ? strippedQuery : query,
                                              strippedUpdate != NULL ? strippedUpdate : attributesToUpdate);
    if (strippedQuery != NULL) {
        CFRelease(strippedQuery);
    }
    if (strippedUpdate != NULL) {
        CFRelease(strippedUpdate);
    }
    if (retried == errSecSuccess) {
        return retried;
    }
    if (retried == errSecItemNotFound) {
        return GuestSecItemAdd(query, NULL);
    }
    return retried;
}

static OSStatus GuestSecItemDelete(CFDictionaryRef query) {
    if (guestRealSecItemDelete == NULL) {
        return errSecUnimplemented;
    }
    OSStatus status = guestRealSecItemDelete(query);
    if (status == errSecSuccess || status == errSecItemNotFound) {
        return status;
    }
    CFDictionaryRef stripped = GuestKeychainWithoutAccessGroup(query);
    if (stripped == NULL) {
        return status;
    }
    OSStatus retried = guestRealSecItemDelete(stripped);
    CFRelease(stripped);
    return retried;
}

static void GuestWriteSlot(void **slot, void *replacement) {
    if (slot == NULL || replacement == NULL) {
        return;
    }
    uintptr_t page = (uintptr_t)slot & ~(uintptr_t)0x3fff;
    mprotect((void *)page, 0x8000, PROT_READ | PROT_WRITE);
    *slot = replacement;
}

static void *GuestReplacementForSymbol(const char *name) {
    if (name == NULL) {
        return NULL;
    }
    if (strcmp(name, "_SecItemAdd") == 0 || strcmp(name, "SecItemAdd") == 0) {
        return (void *)GuestSecItemAdd;
    }
    if (strcmp(name, "_SecItemUpdate") == 0 || strcmp(name, "SecItemUpdate") == 0) {
        return (void *)GuestSecItemUpdate;
    }
    if (strcmp(name, "_SecItemDelete") == 0 || strcmp(name, "SecItemDelete") == 0) {
        return (void *)GuestSecItemDelete;
    }
    return NULL;
}

static void GuestRebindSecItemImports(void) {
    const struct mach_header_64 *header = (const struct mach_header_64 *)_dyld_get_image_header(0);
    if (header == NULL || header->magic != MH_MAGIC_64) {
        return;
    }
    intptr_t slide = _dyld_get_image_vmaddr_slide(0);
    uintptr_t linkeditBase = 0;
    uintptr_t cursor = (uintptr_t)(header + 1);
    const struct symtab_command *symtab = NULL;
    const struct dysymtab_command *dysym = NULL;
    for (uint32_t i = 0; i < header->ncmds; i++) {
        const struct load_command *cmd = (const struct load_command *)cursor;
        if (cmd->cmd == LC_SYMTAB) {
            symtab = (const struct symtab_command *)cmd;
        } else if (cmd->cmd == LC_DYSYMTAB) {
            dysym = (const struct dysymtab_command *)cmd;
        } else if (cmd->cmd == LC_SEGMENT_64) {
            const struct segment_command_64 *seg = (const struct segment_command_64 *)cmd;
            if (strcmp(seg->segname, "__LINKEDIT") == 0) {
                linkeditBase = (uintptr_t)slide + seg->vmaddr - seg->fileoff;
            } else if (strcmp(seg->segname, "__DATA") == 0 && guestRealSecItemAdd != NULL) {
                const struct section_64 *section = (const struct section_64 *)(seg + 1);
                for (uint32_t s = 0; s < seg->nsects; s++, section++) {
                    if (strncmp(section->sectname, "__data", 16) != 0) {
                        continue;
                    }
                    void **slots = (void **)(section->addr + slide);
                    size_t count = section->size / sizeof(void *);
                    for (size_t slot = 0; slot < count; slot++) {
                        if (slots[slot] == (void *)guestRealSecItemAdd) {
                            GuestWriteSlot(&slots[slot], (void *)GuestSecItemAdd);
                        } else if (slots[slot] == (void *)guestRealSecItemUpdate) {
                            GuestWriteSlot(&slots[slot], (void *)GuestSecItemUpdate);
                        } else if (slots[slot] == (void *)guestRealSecItemDelete) {
                            GuestWriteSlot(&slots[slot], (void *)GuestSecItemDelete);
                        }
                    }
                }
            }
        }
        cursor += cmd->cmdsize;
    }
    if (symtab == NULL || dysym == NULL || linkeditBase == 0) {
        return;
    }
    const struct nlist_64 *symbols = (const struct nlist_64 *)(linkeditBase + symtab->symoff);
    const char *strings = (const char *)(linkeditBase + symtab->stroff);
    const uint32_t *indirect = (const uint32_t *)(linkeditBase + dysym->indirectsymoff);
    cursor = (uintptr_t)(header + 1);
    for (uint32_t i = 0; i < header->ncmds; i++) {
        const struct load_command *cmd = (const struct load_command *)cursor;
        if (cmd->cmd == LC_SEGMENT_64) {
            const struct segment_command_64 *seg = (const struct segment_command_64 *)cmd;
            const struct section_64 *section = (const struct section_64 *)(seg + 1);
            for (uint32_t s = 0; s < seg->nsects; s++, section++) {
                uint32_t type = section->flags & SECTION_TYPE;
                if (type != S_LAZY_SYMBOL_POINTERS && type != S_NON_LAZY_SYMBOL_POINTERS) {
                    continue;
                }
                void **slots = (void **)(section->addr + slide);
                uint32_t count = (uint32_t)(section->size / sizeof(void *));
                for (uint32_t slot = 0; slot < count; slot++) {
                    uint32_t index = indirect[section->reserved1 + slot];
                    if (index == INDIRECT_SYMBOL_ABS || index == INDIRECT_SYMBOL_LOCAL ||
                        index >= symtab->nsyms) {
                        continue;
                    }
                    const char *name = strings + symbols[index].n_un.n_strx;
                    void *replacement = GuestReplacementForSymbol(name);
                    if (replacement != NULL) {
                        GuestWriteSlot(&slots[slot], replacement);
                    }
                }
            }
        }
        cursor += cmd->cmdsize;
    }
}

__attribute__((constructor))
static void GuestInstallUIKitMainQueue(void) {
    void *security = dlopen("/System/Library/Frameworks/Security.framework/Security", RTLD_NOW);
    if (security != NULL) {
        guestRealSecItemAdd = dlsym(security, "SecItemAdd");
        guestRealSecItemUpdate = dlsym(security, "SecItemUpdate");
        guestRealSecItemDelete = dlsym(security, "SecItemDelete");
    }
    GuestRebindSecItemImports();

    Class cls = NSClassFromString(@"UIApplication");
    if (cls == Nil) {
        return;
    }

    Method plain = class_getInstanceMethod(cls, @selector(setIdleTimerDisabled:));
    if (plain != NULL) {
        guestOrigSetIdle = (GuestSetIdleIMP)method_getImplementation(plain);
        method_setImplementation(plain, (IMP)GuestSetIdle);
    }

    SEL reasonSel = sel_registerName("_setIdleTimerDisabled:forReason:");
    Method reason = class_getInstanceMethod(cls, reasonSel);
    if (reason != NULL) {
        guestOrigSetIdleReason = (GuestSetIdleReasonIMP)method_getImplementation(reason);
        method_setImplementation(reason, (IMP)GuestSetIdleReason);
    }
}
