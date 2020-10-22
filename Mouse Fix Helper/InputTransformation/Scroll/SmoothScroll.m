//
// --------------------------------------------------------------------------
// SmoothScroll.m
// Created for Mac Mouse Fix (https://github.com/noah-nuebling/mac-mouse-fix)
// Created by Noah Nuebling in 2019
// Licensed under MIT
// --------------------------------------------------------------------------
//

#import <CoreVideo/CoreVideo.h>
#import <Foundation/Foundation.h>
//#import <HIServices/AXUIElement.h>

#import "SmoothScroll.h"
#import "ScrollUtility.h"

#import "AppDelegate.h"
#import "ScrollModifiers.h"
#import "../../Config/ConfigFileInterface_HelperApp.h"

#import "ButtonInputReceiver.h"
#import "DeviceManager.h"
#import "Utility_HelperApp.h"
#import "TouchSimulator.h"
#import "GestureScrollSimulator.h"

@implementation SmoothScroll

#pragma mark - Globals

#pragma mark parameters

// wheel phase
static uint8_t  _pxStepSize;
static double   _msPerStep;
static double   _accelerationForScrollBuffer;
// momentum phase
static double   _frictionCoefficient;
static double   _frictionDepth;
static uint8_t  _nOfOnePixelScrollsMax;
// objects
static CVDisplayLinkRef _displayLink;

#pragma mark dynamic vars

// any phase
static MFDisplayLinkPhase _displayLinkPhase;
static int32_t _pxToScrollThisFrame;
//static int _previousPhase; // which phase was active the last time that displayLinkCallback was called. Used to compute artificial scroll phases

// linear phase
static int32_t      _pxScrollBuffer;
static double   _msLeftForScroll;
// momentum phase
static double   _pxPerMsVelocity;
static uint8_t      _onePixelScrollsCounter;

#pragma mark - Interface

+ (void)load_Manual {
    [SmoothScroll start];
    [SmoothScroll stop];
    if (_displayLink == nil) {
        CVDisplayLinkCreateWithActiveCGDisplays(&_displayLink);
        CVDisplayLinkSetOutputCallback(_displayLink, displayLinkCallback, nil);
//        _displaysUnderMousePointer = malloc(sizeof(CGDirectDisplayID) * 3); // TODO: Why 3? Is this necessary at all?
//        _numberOfDisplaysUnderMousePointer = 0;
    }
}

/// Consider calling [ScrollControl resetDynamicGlobals] to reset not only SmoothScroll specific globals.
+ (void)resetDynamicGlobals {
    _displayLinkPhase                   =   kMFPhaseStart; // kMFPhaseNone;
    _pxToScrollThisFrame                =   0;
    _pxScrollBuffer                     =   0;
    _msLeftForScroll                    =   0;
    _pxPerMsVelocity                    =   0;
    _onePixelScrollsCounter             =   0;
    
//    [ScrollUtility resetConsecutiveTicksAndSwipes]; // MARK: Put this here, because it fixes problem with magnification scrolling. I feel like this might lead to issues. UPDATE: Yep, this breaks fast scrolling. I disabled it now and magnifications scrolling still seems to work.
    // TODO: Delete this if no problems occur.
    _isScrolling = false;
}

+ (void)configureWithParameters:(NSDictionary *)params {
    _pxStepSize                         =   [[params objectForKey:@"pxPerStep"] intValue];
    _msPerStep                          =   [[params objectForKey:@"msPerStep"] intValue];
    _frictionCoefficient                =   [[params objectForKey:@"friction"] floatValue];
    _frictionDepth                      =   [[params objectForKey:@"frictionDepth"] floatValue];
    _accelerationForScrollBuffer         =   [[params objectForKey:@"acceleration"] floatValue];
    _nOfOnePixelScrollsMax              =   [[params objectForKey:@"onePixelScrollsLimit"] intValue]; // After opl+1 frames of only scrolling 1 pixel, scrolling stops. Should probably change code to stop after opl frames.
}

static BOOL _isScrolling = NO;
+ (BOOL)isScrolling {
    return _isScrolling;
}
static BOOL _hasStarted;
+ (BOOL)hasStarted {
    return _hasStarted;
}
+ (void)start {
    if (_hasStarted) {
        return;
    }
    NSLog(@"SmoothScroll started");
    
    _hasStarted = YES;
    [SmoothScroll resetDynamicGlobals];
    CGDisplayRemoveReconfigurationCallback(Handle_displayReconfiguration, NULL); // don't know if necesssary
    CGDisplayRegisterReconfigurationCallback(Handle_displayReconfiguration, NULL);
}
+ (void)stop {
    if (!_hasStarted) {
        return;
    }
    NSLog(@"SmoothScroll stopped");
    
    _hasStarted = NO;
    _isScrolling = NO;
    CVDisplayLinkStop(_displayLink);
    CGDisplayRemoveReconfigurationCallback(Handle_displayReconfiguration, NULL);
}

#pragma mark - Run Loop

+ (void)handleInput:(CGEventRef)event info:(NSDictionary * _Nullable)info {
    
    long long scrollDeltaAxis1 = CGEventGetIntegerValueField(event, kCGScrollWheelEventDeltaAxis1);

    // Update global vars
    
    _isScrolling = YES;
    
    // Reset _pixelScrollQueue and related values if appropriate
    if (ScrollUtility.scrollDirectionDidChange) { // Why are we resetting what we are resetting?
        _pxScrollBuffer = 0;
        _pxToScrollThisFrame = 0;
        _pxPerMsVelocity = 0;
    }
    // TODO: Commenting this out might cause weird behaviour. Think about what this actually does.
//    if (_scrollPhase != kMFPhaseLinear) { // Why are we resetting what we are resetting?
//        _onePixelScrollsCounter =   0;
//        _pxPerMsVelocity        =   0;
//        _pxScrollBuffer       =   0;
//    }
  
//        // Apply fast scroll to _pxStepSize
    long long pxStepSizeWithFastScrollApplied = _pxStepSize;
//    if (ScrollUtility.consecutiveScrollSwipeCounter >= ScrollControl.fastScrollThreshold_inSwipes
//        && ScrollUtility.consecutiveScrollTickCounter >= ScrollControl.scrollSwipeThreshold_inTicks) {
//        pxStepSizeWithFastScrollApplied = _pxStepSize * pow(ScrollControl.fastScrollExponentialBase, ((int32_t)ScrollUtility.consecutiveScrollSwipeCounter - ScrollControl.fastScrollThreshold_inSwipes + 1));
//    }
//
    // Apply scroll wheel input to _pxScrollBuffer
    _msLeftForScroll = _msPerStep;
//    _msLeftForScroll = 1 / (_pxPerMSBaseSpeed / _pxStepSize);
    if (scrollDeltaAxis1 > 0) {
        _pxScrollBuffer += pxStepSizeWithFastScrollApplied * ScrollControl.scrollDirection;
    } else if (scrollDeltaAxis1 < 0) {
        _pxScrollBuffer -= pxStepSizeWithFastScrollApplied * ScrollControl.scrollDirection;
    } else {
        NSLog(@"scrollDeltaAxis1 is 0. This shouldn't happen.");
    }
    
//    // Apply acceleration to _pxScrollBuffer
//    if (ScrollUtility.consecutiveScrollTickCounter != 0) {
//        _pxScrollBuffer = _pxScrollBuffer * _accelerationForScrollBuffer;
//    }
    
//    if (ScrollUtility.consecutiveScrollTickCounter == 0) {
//        NSLog(@"tick: %d", ScrollUtility.consecutiveScrollTickCounter);
//        NSLog(@"swip: %d", ScrollUtility.consecutiveScrollSwipeCounter);
//    }
    
    // Apply fast scroll to _pxScrollBuffer
    int fastScrollThresholdDelta = ScrollUtility.consecutiveScrollSwipeCounter - ScrollControl.fastScrollThreshold_inSwipes;
    if (fastScrollThresholdDelta >= 0) {
        //&& ScrollUtility.consecutiveScrollTickCounter >= ScrollControl.scrollSwipeThreshold_inTicks) {
        _pxScrollBuffer = _pxScrollBuffer * ScrollControl.fastScrollFactor * pow(ScrollControl.fastScrollExponentialBase, ((int32_t)fastScrollThresholdDelta));
    }
//    NSLog(@"buff: %d", _pxScrollBuffer);
//    NSLog(@"--------------");
    
    // Start displaylink and stuff
    
    // Update display link phase
    _displayLinkPhase = kMFPhaseStart;
    
    if (ScrollUtility.consecutiveScrollTickCounter == 0) {
        if (ScrollUtility.mouseDidMove) {
            // Set diplaylink to the display that is actally being scrolled - not sure if this is necessary, because having the displaylink at 30fps on a 30fps display looks just as horrible as having the display link on 60fps, if not worse
            @try {
                setDisplayLinkToDisplayUnderMousePointer(event);
            } @catch (NSException *e) {
                NSLog(@"Error while trying to set display link to display under mouse pointer: %@", [e reason]);
            }
        }
        while (CVDisplayLinkIsRunning(_displayLink) == NO) {
            // Executing this on _scrollQueue (like the rest of this function) leads to `CVDisplayLinkStart()` failing sometimes. Once it has failed it will fail over and over again, taking a few minutes or so to start working again, if at all.
            // Solution: I have no idea why, but executing on the main queue does the trick! ^^
            dispatch_sync(dispatch_get_main_queue(), ^{
                CVReturn rt = CVDisplayLinkStart(_displayLink);
                if (rt != kCVReturnSuccess) {
                    NSLog(@"Failed to start displayLink. Trying again.");
                    NSLog(@"Error code: %d", rt);
                }
            });
        }
    }
}

static CVReturn displayLinkCallback(CVDisplayLinkRef displayLink, const CVTimeStamp *inNow, const CVTimeStamp *inOutputTime, CVOptionFlags flagsIn, CVOptionFlags *flagsOut, void *displayLinkContext) {
    
    double msSinceLastFrame = CVDisplayLinkGetActualOutputVideoRefreshPeriod(_displayLink) * 1000;
    
//    if (msSinceLastFrame != 16.674562) {
//        NSLog(@"frameTimeSpike: %fms", msSinceLastFrame);
//    }
    
//    CVTime msBetweenFramesNominal = CVDisplayLinkGetNominalOutputVideoRefreshPeriod(_displayLink);
//    msSinceLastFrame =
//    ( ((double)msBetweenFramesNominal.timeValue) / ((double)msBetweenFramesNominal.timeScale) ) * 1000;
    
    
# pragma mark Linear Phase
    
    if (_displayLinkPhase == kMFPhaseLinear || _displayLinkPhase == kMFPhaseStart) {
        
        _pxToScrollThisFrame = round( (_pxScrollBuffer/_msLeftForScroll) * msSinceLastFrame ); // TODO: Consider making _pxToScrollThisFrame not a global variable.
        
        if (_msLeftForScroll == 0.0) { // Diving by zero yields infinity, we don't want that.
            NSLog(@"_msLeftForScroll was 0.0");
            _pxToScrollThisFrame = _pxScrollBuffer; // TODO: But it happens sometimes - check if this handles that situation well
        }
        
        // Update buffers
        
        _pxScrollBuffer   -=  _pxToScrollThisFrame;
        _msLeftForScroll    -=  msSinceLastFrame;
        
        
        
        // Apply acceleration

        // TODO: Clean this up and put parameters into the config file
        
        double overPlusAccelerationCoefficient = 2.0; // > 0
        double overPlusAccelerationThreshold = 1.0; // >= 0

        double pxToScrollThisFrameBase = (_pxStepSize/_msPerStep) * msSinceLastFrame; // > 0
        double pxToScrollThisFrameOverPlus = abs(_pxToScrollThisFrame) - pxToScrollThisFrameBase; // Should always be >= 0 and == 0 for the linear phase of a tick which occured when the system wasn't scrolling already, but there will be rounding errors.
        // TODO: Consider making `_pxScrollBuffer` as well as `_pxToScrollThisFrame`, etc doubles to avoid rounding errors.

        if (overPlusAccelerationThreshold < fabs(pxToScrollThisFrameOverPlus) && 0 < pxToScrollThisFrameOverPlus) { // Catch rounding errors
            double acceleratedOverPlus = pxToScrollThisFrameOverPlus * overPlusAccelerationCoefficient;
            _pxToScrollThisFrame = [ScrollUtility signOf: _pxToScrollThisFrame] * round(pxToScrollThisFrameBase + acceleratedOverPlus);
        }
        
        
//        double _accelerationMaxScalingFactor = 2.0;
//        double _accelerationRampUp = 0.5;
//
//        double velocity = _pxToScrollThisFrame / msSinceLastFrame;
//        double defaultVelocity = _pxStepSize / _msPerStep;
//        defaultVelocity = defaultVelocity * [ScrollUtility signOf:velocity];
//        double normalizedVelocity = (velocity - defaultVelocity); // "Normalized" isn't the right term here
//        double acceleratedNormalizedVelocity = _accelerationMaxScalingFactor * normalizedVelocity;
////        acceleratedRelativeVelocity = [ScrollUtility signOf:velocity] * acceleratedRelativeVelocity;
//
//        double acceleratedVelocity = acceleratedNormalizedVelocity + defaultVelocity;
//
//        _pxToScrollThisFrame = acceleratedVelocity * msSinceLastFrame;
        
        
        
        
        // Entering momentum phase
        
        if (_msLeftForScroll <= 0 || _pxScrollBuffer == 0) { // TODO: Is `_pxScrollBuffer == 0` necessary? Do the conditions for entering momentum phase make sense?
            _msLeftForScroll    =   0; // TODO: Is this necessary?
            _pxScrollBuffer   =   0; // What about this? This stuff isn't used in momentum phase and should get reset elsewhere efore getting used again
            
            _displayLinkPhase = kMFPhaseMomentum;
            _pxPerMsVelocity = (_pxToScrollThisFrame / msSinceLastFrame);
        }
    }
    
# pragma mark Momentum Phase
    
    else if (_displayLinkPhase == kMFPhaseMomentum) {
//        NSLog(@"ENTERING MOMENTUM PHASE");
        _pxToScrollThisFrame = round(_pxPerMsVelocity * msSinceLastFrame);
        double oldVel = _pxPerMsVelocity;
        double newVel = oldVel - [ScrollUtility signOf:oldVel] * pow(fabs(oldVel), _frictionDepth) * (_frictionCoefficient/100) * msSinceLastFrame;
        _pxPerMsVelocity = newVel;
        if ( ((newVel < 0) && (oldVel > 0)) || ((newVel > 0) && (oldVel < 0)) ) {
            _pxPerMsVelocity = 0;
        }
        if (_pxToScrollThisFrame == 0 || _pxPerMsVelocity == 0) {
            _displayLinkPhase = kMFPhaseEnd;
        }
        if (abs(_pxToScrollThisFrame) == 1) {
            _onePixelScrollsCounter += 1;
            if (_onePixelScrollsCounter > _nOfOnePixelScrollsMax) { // I think using > instead of >= might put the actual maximum at _nOfOnePixelScrollsMax + 1.
                _displayLinkPhase = kMFPhaseEnd;
            }
        }
    }
    
# pragma mark Send Event
    
    if (ScrollModifiers.magnificationScrolling) {
        [ScrollModifiers handleMagnificationScrollWithAmount:_pxToScrollThisFrame/800.0];
    } else {
        postPointBasedScrollEventWithDelta(_pxToScrollThisFrame, ScrollModifiers.horizontalScrolling);
    }
    
#pragma mark Other
    
    if (_displayLinkPhase == kMFPhaseStart) {
        _displayLinkPhase = kMFPhaseLinear;
    }
    else if (_displayLinkPhase == kMFPhaseEnd) {
        [SmoothScroll resetDynamicGlobals];
        CVDisplayLinkStop(displayLink);
        return 0;
    }
    return 0;
}


#pragma mark - Utility functions

static void postPointBasedScrollEventWithDelta(int32_t delta, BOOL horizontal) {
    
    CGEventRef scrollEvent = CGEventCreateScrollWheelEvent(NULL, kCGScrollEventUnitPixel, 1, 0);
            // CGEventSourceSetPixelsPerLine(_eventSource, 1);
            // it might be a cool idea to diable scroll acceleration and then try to make the scroll events line based (kCGScrollEventUnitPixel)
            
            // Setting event phases
            
    //        if (_scrollPhase >= kMFPhaseMomentum) {
    //            CGEventSetIntegerValueField(scrollEvent, kCGScrollWheelEventScrollPhase, _scrollPhase >> 1); // shifting bits so that values match up with appropriate NSEventPhase values.
    //        } else {
    //            CGEventSetIntegerValueField(scrollEvent, kCGScrollWheelEventScrollPhase, _scrollPhase);
    //        }
            
            CGEventSetIntegerValueField(scrollEvent, kCGScrollWheelEventScrollPhase, 0);
            CGEventSetIntegerValueField(scrollEvent, kCGScrollWheelEventMomentumPhase, 0);
            
            // Set scrollDelta
            
            if (horizontal == FALSE) {
                CGEventSetIntegerValueField(scrollEvent, kCGScrollWheelEventDeltaAxis1, delta / 8);
                CGEventSetIntegerValueField(scrollEvent, kCGScrollWheelEventPointDeltaAxis1, delta);
            } else {
                CGEventSetIntegerValueField(scrollEvent, kCGScrollWheelEventDeltaAxis2, delta / 8);
                CGEventSetIntegerValueField(scrollEvent, kCGScrollWheelEventPointDeltaAxis2, delta);
            }
            
            // Post event
            
            CGEventPost(kCGSessionEventTap, scrollEvent);
            CFRelease(scrollEvent);
            
        ////     set phases
        ////         the native "scrollPhase" is roughly equivalent to my "wheelPhase"
        //
        //    CGEventSetIntegerValueField(scrollEvent, kCGScrollWheelEventMomentumPhase, kCGMomentumScrollPhaseNone);
        //
        //
        //
        //    NSLog(@"intern scrollphase: %d", _scrollPhase);
        //    if (_scrollPhase == kMFWheelPhase) {
        //        if (_previousPhase == kMFWheelPhase) {
        //                CGEventSetIntegerValueField(scrollEvent, kCGScrollWheelEventScrollPhase, 2);
        //        } else {
        //                CGEventSetIntegerValueField(scrollEvent, kCGScrollWheelEventScrollPhase, 1);
        //        }
        //    }
        //    if (_scrollPhase == kMFMomentumPhase) {
        //        CGEventSetIntegerValueField(scrollEvent, kCGScrollWheelEventScrollPhase, 2);
        //    }
        //
        ////    NSLog(@"scrollPhase: %lld", CGEventGetIntegerValueField(scrollEvent, kCGScrollWheelEventScrollPhase));
        ////    NSLog(@"momentumPhase: %lld \n", CGEventGetIntegerValueField(scrollEvent, kCGScrollWheelEventMomentumPhase));
        //
}


#pragma mark display link

// TODO: What does this do? Is this necessary?
static void Handle_displayReconfiguration(CGDirectDisplayID display, CGDisplayChangeSummaryFlags flags, void *userInfo) {
    if ( (flags & kCGDisplayAddFlag) || (flags & kCGDisplayRemoveFlag) ) {
        NSLog(@"display added / removed");
        CVDisplayLinkStop(_displayLink);
        CVDisplayLinkRelease(_displayLink);
        CVDisplayLinkCreateWithActiveCGDisplays(&_displayLink);
        CVDisplayLinkSetOutputCallback(_displayLink, displayLinkCallback, nil);
    }
}

static uint32_t _numberOfDisplaysUnderMousePointer; // NEED to allways set this when setting _displaysUnderMousePointer
static CGDirectDisplayID *_displaysUnderMousePointer;

static void setDisplayLinkToDisplayUnderMousePointer(CGEventRef event) {
    
    CGPoint mouseLocation = CGEventGetLocation(event);
    
    uint32_t maxNumberOfDisplays;
    CGGetDisplaysWithPoint(mouseLocation, 0, NULL, &maxNumberOfDisplays);
    CGDirectDisplayID *newDisplaysUnderMousePointer = malloc(sizeof(CGDirectDisplayID) * maxNumberOfDisplays);
    uint32_t newNumberOfDisplaysUnderMousePointer;
    CGGetDisplaysWithPoint(mouseLocation, maxNumberOfDisplays, newDisplaysUnderMousePointer, &newNumberOfDisplaysUnderMousePointer);
    // TODO: Check if this is slow. If so, check if there's a dedicated way for getting the active display. If so, consider using that instead of CGGetDisplaysWithPoint().
    
    if (newNumberOfDisplaysUnderMousePointer >= 1) {
        if (!displayIDArraysAreEqual(_displaysUnderMousePointer, _numberOfDisplaysUnderMousePointer, newDisplaysUnderMousePointer, newNumberOfDisplaysUnderMousePointer)) {
            //sets dsp to the master display if _displaysUnderMousePointer[0] is part of the mirror set
            CGDirectDisplayID dsp = CGDisplayPrimaryDisplay(_displaysUnderMousePointer[0]);
            CVDisplayLinkSetCurrentCGDisplay(_displayLink, dsp);
            
            free(_displaysUnderMousePointer);
            _displaysUnderMousePointer = newDisplaysUnderMousePointer;
            _numberOfDisplaysUnderMousePointer = newNumberOfDisplaysUnderMousePointer;
        }
        if (newNumberOfDisplaysUnderMousePointer > 1) {
            NSLog(@"more than one display for current mouse position");
        }
    } else if (newNumberOfDisplaysUnderMousePointer == 0) {
        NSException *e = [NSException exceptionWithName:NSInternalInconsistencyException reason:@"There are 0 diplays under the mouse pointer" userInfo:NULL];
        @throw e;
    }
}

static bool displayIDArraysAreEqual(CGDirectDisplayID *arr1, int32_t count1, CGDirectDisplayID *arr2, int32_t count2) {
    for (int i = 0; i < count1 && i < count2; i++) {
        if (arr1[i] != arr2[i]) {
            return false;
        }
    }
    return true;
}

@end

// ((From displayLinkCallback))
// stop displayLink when app under mouse pointer changes mid scroll
/*
 CGEventRef fakeEvent = CGEventCreate(NULL);
 CGPoint mouseLocation = CGEventGetLocation(fakeEvent);
 CFRelease(fakeEvent);
 AXUIElementRef elementUnderMousePointer;
 AXUIElementCopyElementAtPosition(AXUIElementCreateSystemWide(), mouseLocation.x, mouseLocation.y, &elementUnderMousePointer);
 pid_t elementUnderMousePointerPID;
 AXUIElementGetPid(elementUnderMousePointer, &elementUnderMousePointerPID);
 NSRunningApplication *appUnderMousePointer = [NSRunningApplication runningApplicationWithProcessIdentifier:elementUnderMousePointerPID];
 
 if ( !([_bundleIdentifierOfScrolledApp isEqualToString:[appUnderMousePointer bundleIdentifier]]) ) {
 resetDynamicGlobals();
 CVDisplayLinkStop(_displayLink);
 return 0;
 }
 */