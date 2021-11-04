//
// --------------------------------------------------------------------------
// AppTranslocationManager.m
// Created for Mac Mouse Fix (https://github.com/noah-nuebling/mac-mouse-fix)
// Created by Noah Nuebling in 2021
// Licensed under MIT
// --------------------------------------------------------------------------
//

#import "AppTranslocationManager.h"
#import <dlfcn.h>
#import "SharedUtil.h"
#import "Constants.h"
#import <Cocoa/Cocoa.h>

@implementation AppTranslocationManager

CFURLRef getAppURL() {
    
    return (__bridge CFURLRef)[NSURL fileURLWithPath:NSBundle.mainBundle.bundlePath];
}

/// \discussion We should probably do some more error handling, and use `dlclose()` to prevent memory leak. But this is only called once and it works fine so whatevs.
void *getFunctionFromSecurityFramework(const char *functionName) {
    
    // Open security framework
    void *handle = NULL;
    handle = dlopen("/System/Library/Frameworks/Security.framework/Security", RTLD_LAZY);
    // Return function pointer
    return dlsym(handle, functionName);
}

bool getIsTranslocated() {
    
    bool isTranslocated = false;
    
    // Declare function for ‘SecTranslocateIsTranslocatedURL’
    Boolean (*mySecTranslocateIsTranslocatedURL)(CFURLRef path, bool *isTranslocated, CFErrorRef * __nullable error); // Flag for API request
    
    // Get function from security framework
    mySecTranslocateIsTranslocatedURL = getFunctionFromSecurityFramework("SecTranslocateIsTranslocatedURL");
    
    // Invoke it
    CFErrorRef err = NULL;
    mySecTranslocateIsTranslocatedURL(getAppURL(), &isTranslocated, &err);
    NSError *error = (__bridge NSError *)err;
    if (error != nil) {
        NSLog(@"Error checking if app is translocated: %@", err);
    }
    
    return isTranslocated;
}

NSURL *getUntranslocatedURL() {
    
    NSURL* untranslocatedURL = nil;
    
    // Get current application path
    
    // Declare function for ‘SecTranslocateCreateOriginalPathForURL’
    CFURLRef __nullable (*mySecTranslocateCreateOriginalPathForURL)(CFURLRef translocatedPath, CFErrorRef * __nullable error);
    
    // Get function from security framework
    mySecTranslocateCreateOriginalPathForURL = getFunctionFromSecurityFramework("SecTranslocateCreateOriginalPathForURL");
    
    // Get original URL
    CFErrorRef err = NULL;
    untranslocatedURL = (__bridge NSURL*)mySecTranslocateCreateOriginalPathForURL(getAppURL(), &err);
    if (err != NULL) {
        NSError *error = (__bridge NSError *)err;
        NSLog(@"Error getting untranslocated URL: %@", error);
    }
    
    return untranslocatedURL;
}

void removeQuarantineFlagAndRestart(NSURL* untranslocatedURL) {

    assert(untranslocatedURL != nil);
    
    NSURL *xattrURL = [NSURL fileURLWithPath:kMFXattrPath];
    NSURL *openURL = [NSURL fileURLWithPath:kMFOpenCLTPath];
    
    NSError *error;
    
    // Remove quarantine attributes of original
    [SharedUtil launchCTL:xattrURL withArguments:@[@"-cr", untranslocatedURL.path] error:&error];
    
    if (error != nil) {
        NSLog(@"Error while removing quarantine: %@", error);
        return;
    }
    
    // Relaunch app at original (untranslocated) location
    //  -> Use ‘open’ as it allows two instances of app (this instance is exiting)
    [SharedUtil launchCTL:openURL withArguments:@[@"-n", @"-a", untranslocatedURL.path] error:&error];
    // ^ This successfully relaunches the app but AccessibilityOverlay doesn't work on the relaunched instance. I assume it's sth to do with message ports. Yes that turned out to be it. Using `initialize` instead of `load` to make the message port be created after this is executed fixed it.
    // ^ We need to make sure not to use MessagePort_App from within any `load` methods, as that would lead to MessagePort_App being initialized before this is called, leading to the same issue. (This is currently being called from [AppDelegate + initialize])
    
    if (error != nil) {
        NSLog(@"Error while relaunching app: %@", error);
        return;
    }
    
    NSLog(@"Terminating translocated instance of the app");
    
    [NSApplication.sharedApplication terminate:nil];
}

/// If the app is translocated, then remove the quarantine flag and restart it.
/// This effectively removes the translocation.
/// Credits: https://www.synack.com/blog/untranslocating-apps/
/// \discussion As far as I understand, if we ever run executables in the same folder as the app then this poses a security risk, but I don't think we do that so it should be fine.
/// \discussion If we can't remove translocation, this will result in an infinte restarting loop.
+ (void)removeTranslocation {
    
    bool translocated = getIsTranslocated();
    NSURL *originalURL = getUntranslocatedURL();
    
    NSLog(@"Mac Mouse Fix is translocated: %d\n original URL: %@", translocated, originalURL);
    
    if (translocated) {
        removeQuarantineFlagAndRestart(originalURL);
    }
    
}

@end
