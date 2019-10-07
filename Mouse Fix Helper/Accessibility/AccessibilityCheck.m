//
// --------------------------------------------------------------------------
// AccessibilityCheck.m
// Created for: Mac Mouse Fix (https://github.com/noah-nuebling/mac-mouse-fix)
// Created by: Noah Nuebling in 2019
// Licensed under MIT
// --------------------------------------------------------------------------
//

#import "AccessibilityCheck.h"

#import <AppKit/AppKit.h>
#import "../MessagePort/MessagePort_HelperApp.h"
#import "../DeviceManager/DeviceManager.h"
#import "../MessagePort/MessagePort_HelperApp.h"
#import "../Config/ConfigFileInterface_HelperApp.h"
#import "../ScrollFix/SmoothScroll.h"

@implementation AccessibilityCheck

+ (void)load {
    
    [MessagePort_HelperApp load_Manual];
    
    Boolean accessibilityEnabled = [self check];
    
    if (!accessibilityEnabled) {
        [NSTimer scheduledTimerWithTimeInterval:0.5 repeats:NO block:^(NSTimer * _Nonnull timer) {
            NSLog(@"send acc message to prefpane");
            [MessagePort_HelperApp sendMessageToPrefPane:@"accessibilityDisabled"];
        }];
        [NSTimer scheduledTimerWithTimeInterval:0.5 repeats:YES block:^(NSTimer * _Nonnull timer) {
            if ([self check]) {
                
                [NSWorkspace.sharedWorkspace openFile:[[NSBundle bundleForClass:self.class].bundlePath stringByAppendingPathComponent:@"/../../../.."]];
                
                [NSApp terminate:NULL];
            }
        }];
            
    } else {
        [DeviceManager load_Manual];
        [ConfigFileInterface_HelperApp load_Manual];
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
@end