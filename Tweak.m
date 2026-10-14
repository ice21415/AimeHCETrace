#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <substrate.h>
#include <unistd.h>
#include <string.h>
#include <fcntl.h>
#include <sys/stat.h>
#include <sys/time.h>
#include <stdio.h>

// Opt-in gate is checked on each callback. No APDU bytes, AIDs, UID or keys logged.
static BOOL enabled(void) {
    return access("/var/tmp/aime-hce-trace.enabled", F_OK) == 0;
}
static void record(const char *event, const char *detail) {
    int fd = open("/var/tmp/aime-hce-trace.log", O_WRONLY | O_CREAT | O_APPEND | O_CLOEXEC | O_NOFOLLOW, 0600);
    if (fd >= 0) {
        struct stat st;
        if (fstat(fd, &st) == 0 && S_ISREG(st.st_mode) && st.st_size < 262144) {
            struct timeval now;
            gettimeofday(&now, NULL);
            char line[512];
            int length = snprintf(line, sizeof(line), "%lld.%06d pid=%d %s %s\n",
                                  (long long)now.tv_sec, (int)now.tv_usec, getpid(), event, detail);
            if (length > 0 && (size_t)length < sizeof(line)) (void)write(fd, line, (size_t)length);
        }
        close(fd);
    } else {
        NSLog(@"AimeHCETrace file log unavailable: %s %s", event, detail);
    }
}
static void trace(const char *event) {
    if (enabled()) record("call", event);
}
static void (*originalRun)(id, SEL, id, BOOL);
static void run(id self, SEL selector, id device, BOOL paymentEnabled) {
    trace("runHostCardEmulation enter");
    originalRun(self, selector, device, paymentEnabled);
    trace("runHostCardEmulation return");
}
static id (*originalRead)(id, SEL);
static id readAPDU(id self, SEL selector) {
    trace("readAPDU enter");
    id result = originalRead(self, selector);
    trace(result ? "readAPDU returned object" : "readAPDU returned nil");
    return result;
}
static BOOL (*originalSend)(id, SEL, id);
static BOOL sendAPDU(id self, SEL selector, id data) {
    trace("sendAPDU enter");
    BOOL result = originalSend(self, selector, data);
    trace(result ? "sendAPDU success" : "sendAPDU failure");
    return result;
}
static void install(const char *className, const char *selectorName,
                    const char *encoding, IMP replacement, IMP *original) {
    Class cls = objc_getClass(className);
    SEL selector = sel_registerName(selectorName);
    Method method = cls ? class_getInstanceMethod(cls, selector) : NULL;
    if (!method) {
        record("hook_missing", selectorName);
        return;
    }
    if (strcmp(method_getTypeEncoding(method), encoding) != 0) {
        record("hook_abi_mismatch", selectorName);
        return;
    }
    MSHookMessageEx(cls, selector, replacement, original);
    record(*original ? "hook_installed" : "hook_original_missing", selectorName);
}
__attribute__((constructor)) static void start(void) {
    @autoreleasepool {
        if (![[NSProcessInfo processInfo].processName isEqualToString:@"nfcd"]) return;
        record("loaded", "version=0.1.1");
        if (!enabled()) {
            record("disabled", "opt-in flag absent");
            return;
        }
        install("NFHostCardEmulationManager", "runHostCardEmulation:paymentEnabled:",
                "v28@0:8@16B24", (IMP)run, (IMP *)&originalRun);
        install("NFHostCardEmulationDeviceHandle", "readAPDU", "@16@0:8",
                (IMP)readAPDU, (IMP *)&originalRead);
        install("NFHostCardEmulationDeviceHandle", "sendAPDU:", "B24@0:8@16",
                (IMP)sendAPDU, (IMP *)&originalSend);
    }
}
