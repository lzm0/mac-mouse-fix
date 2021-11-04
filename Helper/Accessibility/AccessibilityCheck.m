//
// --------------------------------------------------------------------------
// AccessibilityCheck.m
// Created for Mac Mouse Fix (https://github.com/noah-nuebling/mac-mouse-fix)
// Created by Noah Nuebling in 2019
// Licensed under MIT
// --------------------------------------------------------------------------
//

#import "AccessibilityCheck.h"

#import <AppKit/AppKit.h>
#import "../MessagePort/MessagePort_HelperApp.h"
#import "../DeviceManager/DeviceManager.h"
#import "../MessagePort/MessagePort_HelperApp.h"
#import "../Config/ConfigFileInterface_HelperApp.h"
#import "../Scroll/SmoothScroll.h"
#import "../Scroll/RoughScroll.h"
#import "Constants.h"

#import <os/log.h>

@implementation AccessibilityCheck

+ (void)load {
    
    os_log_t MFLog = os_log_create(kMFBundleIDHelper.UTF8String, "status");
    os_log(MFLog, "Mac Mouse Fix Helper begins logging excessively...");
    
    [MessagePort_HelperApp load_Manual];
    
    Boolean accessibilityEnabled = [self check];
    
    if (!accessibilityEnabled) {
        
        NSLog(@"Accessibility Access Disabled");
        
        [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(sendAccessibilityMessageToMainApp) userInfo:NULL repeats:NO];
        
        [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(openMainApp) userInfo:NULL repeats:YES];
            
    } else {
        
        // using load_Manual instead of normal load, because creating an eventTap crashes the program, if we don't have accessibility access (I think - I don't really remember)
        [DeviceManager load_Manual];
        [ConfigFileInterface_HelperApp load_Manual];
        [ScrollControl load_Manual];
        [SmoothScroll load_Manual];
    }
}
+ (Boolean)check {
    CFMutableDictionaryRef options = CFDictionaryCreateMutable(kCFAllocatorDefault, 1, NULL, NULL);
    CFDictionaryAddValue(options, kAXTrustedCheckOptionPrompt, kCFBooleanFalse);
    Boolean result = AXIsProcessTrustedWithOptions(options);
    CFRelease(options);
    return result;
}


// Timer Callbacks

+ (void)sendAccessibilityMessageToMainApp {
    NSLog(@"Sending accessibility disabled message to main app");
    [MessagePort_HelperApp sendMessageToMainApp:@"accessibilityDisabled"];
}

+ (void)openMainApp {
    
    if ([self check]) {
        
        // Open app
        NSArray<NSRunningApplication *> *apps = [NSRunningApplication runningApplicationsWithBundleIdentifier:kMFBundleIDApp];
        for (NSRunningApplication *app in apps) {
            [app activateWithOptions:NSApplicationActivateIgnoringOtherApps];
        }
        // Close this app (Will be restarted immediately by launchd)
        [NSApp terminate:NULL];
    }
}


@end
