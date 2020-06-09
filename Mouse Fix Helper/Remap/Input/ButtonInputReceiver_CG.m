//
// --------------------------------------------------------------------------
// ButtonInputReceiver.m
// Created for Mac Mouse Fix (https://github.com/noah-nuebling/mac-mouse-fix)
// Created by Noah Nuebling in 2019
// Licensed under MIT
// --------------------------------------------------------------------------
//

#import "ButtonInputReceiver_CG.h"
#import "InputReceiver_HID.h"
#import "DeviceManager.h"
#import <IOKit/hid/IOHIDManager.h>
#import "ButtonInputParser.h"
#import "AppDelegate.h"
#import <ApplicationServices/ApplicationServices.h>

#import "Utility_HelperApp.h"

#import "ScrollControl.h"

@implementation ButtonInputReceiver_CG

CGEventSourceRef eventSource;
CFMachPortRef eventTap;


+ (void)load_Manual {
    eventSource = CGEventSourceCreate(kCGEventSourceStatePrivate);
    registerInputCallback();
}

+ (void)decide {
    if ([DeviceManager relevantDevicesAreAttached]) {
        NSLog(@"started (InputReceiver)"); 
        [ButtonInputReceiver_CG start];
    } else {
        NSLog(@"stopped (InputReceiver)");
        [ButtonInputReceiver_CG stop];
    }
}
/// we don't start/stop the IOHIDDeviceRegisterInputValueCallback.
/// I think new devices should be attached to the callback by DeviceManager if a relevant device is attached to the computer
/// I think there is no cleanup we need to do if a device is detached from the computer.
+ (void)start {
    InputReceiver_HID.buttonEventInputSourceIsDeviceOfInterest = NO;
    CGEventTapEnable(eventTap, true);
}
+ (void)stop {
    CGEventTapEnable(eventTap, false);
}

static void registerInputCallback() {
    // Register event Tap Callback
    CGEventMask mask = CGEventMaskBit(kCGEventOtherMouseDown) | CGEventMaskBit(kCGEventOtherMouseUp);

    eventTap = CGEventTapCreate(kCGHIDEventTap, kCGTailAppendEventTap, kCGEventTapOptionDefault, mask, handleInput, NULL);
    CFRunLoopSourceRef runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0);
    CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, kCFRunLoopDefaultMode);
    
    CFRelease(runLoopSource);
}

+ (void)insertFakeEvent:(CGEventRef)event {
    CGEventRef ret = handleInput(0,0,event,nil);
    CGEventPost(kCGHIDEventTap, ret);
}

CGEventRef handleInput(CGEventTapProxy proxy, CGEventType type, CGEventRef event, void *userInfo) {
    
    BOOL b = InputReceiver_HID.buttonEventInputSourceIsDeviceOfInterest;
    InputReceiver_HID.buttonEventInputSourceIsDeviceOfInterest = NO;
    
    if (b) {
        int64_t buttonNumber = CGEventGetIntegerValueField(event, kCGMouseEventButtonNumber) + 1;
        
        long long pr = CGEventGetIntegerValueField(event, kCGMouseEventPressure);
        MFButtonInputType type = pr == 0 ? kMFButtonInputTypeButtonUp : kMFButtonInputTypeButtonDown;
        
        if (3 <= buttonNumber) {
            MFEventPassThroughEvaluation rt = [ButtonInputParser sendActionTriggersForInputWithButton:buttonNumber type:type];
            if (rt == kMFEventPassThroughRefusal) {
                return nil;
            }
        } else {
            NSLog(@"Received input from primary / secondary mouse button. This should never happen! Button Number: %lld", buttonNumber);
        }
    }
    return event;
}

@end
