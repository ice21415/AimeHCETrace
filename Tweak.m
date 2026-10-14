#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <substrate.h>
#include <unistd.h>
#include <string.h>

// Opt-in gate is checked on each callback. No APDU bytes, AIDs, UID or keys logged.
static BOOL enabled(void) {
    return access("/var/tmp/aime-hce-trace.enabled", F_OK) == 0;
}
static void trace(const char *event) {
    if (enabled()) NSLog(@"AimeHCETrace %s", event);
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
    if (!method || strcmp(method_getTypeEncoding(method), encoding) != 0) {
        trace("hook skipped: missing method or ABI mismatch");
        return;
    }
    MSHookMessageEx(cls, selector, replacement, original);
    trace(selectorName);
}
__attribute__((constructor)) static void start(void) {
    @autoreleasepool {
        if (![[NSProcessInfo processInfo].processName isEqualToString:@"nfcd"] || !enabled()) return;
        install("NFHostCardEmulationManager", "runHostCardEmulation:paymentEnabled:",
                "v28@0:8@16B24", (IMP)run, (IMP *)&originalRun);
        install("NFHostCardEmulationDeviceHandle", "readAPDU", "@16@0:8",
                (IMP)readAPDU, (IMP *)&originalRead);
        install("NFHostCardEmulationDeviceHandle", "sendAPDU:", "B24@0:8@16",
                (IMP)sendAPDU, (IMP *)&originalSend);
    }
}
