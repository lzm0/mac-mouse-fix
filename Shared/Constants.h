//
// --------------------------------------------------------------------------
// Constants.h
// Created for Mac Mouse Fix (https://github.com/noah-nuebling/mac-mouse-fix)
// Created by Noah Nuebling in 2020
// Licensed under MIT
// --------------------------------------------------------------------------
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface Constants : NSObject

// Other

#define kMFBundleIDApp      @"com.nuebling.mac-mouse-fix"
#define kMFBundleIDHelper   @"com.nuebling.mac-mouse-fix.helper"

#define kMFRelativeAccomplicePath           @"Contents/Library/LaunchServices/Mac Mouse Fix Accomplice"
#define kMFRelativeHelperAppPath            @"Contents/Library/LoginItems/Mac Mouse Fix Helper.app"
#define kMFRelativeHelperExecutablePath     @"Contents/Library/LoginItems/Mac Mouse Fix Helper.app/Contents/MacOS/Mac Mouse Fix Helper"

#define kMFRelativeMainAppPathFromHelperBundle          @"../../../../"
#define kMFRelativeMainAppPathFromAccomplice            @"../../../../"
#define kMFRelativeMainAppPathFromAccompliceFolder      @"../../../"

#define kMFMainAppName      @"Mac Mouse Fix.app"
#define kMFAccompliceName   @"Mac Mouse Fix Accomplice"

#define kMFLaunchdHelperIdentifier  @"mouse.fix.helper" // Should rename to `kMFLaunchdHelperLabel`
    // ^ Keep this in sync with `Label` value in `default_launchd.plist`
    // ^ The old value @"mouse.fix.helper" was also used with the old prefpane version which could lead to conflicts. See Mail beginning with 'I attached the system log. Happening with this version too'. < We moved back to the old `mouse.fix.helper` label

// #define kMFLaunchdHelperIdentifier  @"com.nuebling.mac-mouse-fix.helper"
//      ^ We meant to move the launchd label over to a new one to avoid conflicts when upgrading from the old prefpane, but I think it can lead to more complications. Also we'd fragment things, because the first few versions of the app version already shipped with the old "mouse.fix.helper" label

#define kMFLaunchctlPath            @"/bin/launchctl"
#define kMFXattrPath                @"/usr/bin/xattr"
#define kMFOpenCLTPath              @"/usr/bin/open"


// Accomplice Arguments

#define kMFAccompliceModeUpdate         @"update"
#define kMFAccompliceModeReloadHelper   @"reloadHelper"

// Website

#define kMFWebsiteAddress   @"https://noah-nuebling.github.io/mac-mouse-fix-website" //@"https://mousefix.org"

// Remapping dictionary keywords

typedef NSString*                                                       MFStringConstant; // Not sure if this is useful

#pragma mark - NSNotificationCenter notification names

#define kMFNotificationNameRemapsChanged                                @"remapsChanged"

#pragma mark - Remaps dictionary keys

#define kMFRemapsKeyModifiedDrag                                        @"modifiedDrag"

#define kMFModifiedDragTypeTwoFingerSwipe                               @"twoFingerSwipe"
#define kMFModifiedDragTypeThreeFingerSwipe                             @"threeFingerSwipe"

#define kMFModificationPreconditionKeyButtons                           @"buttonModifiers"
#define kMFModificationPreconditionKeyKeyboard                          @"keyboardModifiers"

#define kMFActionDictKeyType                                            @"type"

#define kMFActionDictTypeSymbolicHotkey                                 @"symbolicHotkey"
#define kMFActionDictTypeNavigationSwipe                                @"navigationSwipe"
#define kMFActionDictTypeSmartZoom                                      @"smartZoom"
#define kMFActionDictTypeKeyboardShortcut                               @"keyboardShortcut"
#define kMFActionDictTypeMouseButtonClicks                              @"mouseButton"

#define kMFActionDictKeyVariant                                         @"value"
#define kMFActionDictKeyKeyboardShortcutVariantKeycode                  @"keycode"
#define kMFActionDictKeyKeyboardShortcutVariantModifierFlags            @"flags"
#define kMFActionDictKeyMouseButtonClicksVariantButtonNumber            @"button"
#define kMFActionDictKeyMouseButtonClicksVariantNumberOfClicks          @"nOfClicks"

#define kMFNavigationSwipeVariantUp                                     @"up"
#define kMFNavigationSwipeVariantRight                                  @"right"
#define kMFNavigationSwipeVariantDown                                   @"down"
#define kMFNavigationSwipeVariantLeft                                   @"left"

#define kMFButtonTriggerDurationClick                                   @"click"
#define kMFButtonTriggerDurationHold                                    @"hold"

// Symbolic Hotkeys

typedef enum {
    kMFSHMissionControl = 32,
    kMFSHAppExpose = 33,
    kMFSHShowDesktop = 36,
    kMFSHLaunchpad = 160,
    kMFSHLookUp = 70,
    kMFSHAppSwitcher = 71,
    kMFSHMoveLeftASpace = 79,
    kMFSHMoveRightASpace = 81,
    kMFSHCycleThroughWindows = 27,
    
    kMFSHSwitchToDesktop1 = 118,
    kMFSHSwitchToDesktop2 = 119,
    kMFSHSwitchToDesktop3 = 120,
    kMFSHSwitchToDesktop4 = 121,
    kMFSHSwitchToDesktop5 = 122,
    kMFSHSwitchToDesktop6 = 123,
    kMFSHSwitchToDesktop7 = 124,
    kMFSHSwitchToDesktop8 = 125,
    kMFSHSwitchToDesktop9 = 126,
    kMFSHSwitchToDesktop10 = 127,
    kMFSHSwitchToDesktop11 = 128,
    kMFSHSwitchToDesktop12 = 129,
    kMFSHSwitchToDesktop13 = 130,
    kMFSHSwitchToDesktop14 = 131,
    kMFSHSwitchToDesktop15 = 132,
    kMFSHSwitchToDesktop16 = 133,
    
    kMFSHSpotlight = 64,
    kMFSHSiri = 176,
    kMFSHNotificationCenter = 163,
    kMFSHToggleDoNotDisturb = 175,
} MFSymbolicHotkey;

// Mouse Buttons

/// Note that CGMouseButton (and all CG APIs) assign 0 to left mouse button while MFMouseButtonNumber (and the rest of Mac Mouse Fix which doesn't use it yet) assigns 1 to lmb
typedef enum {
    kMFMouseButtonNumberLeft = 1,
    kMFMouseButtonNumberRight = 2,
    kMFMouseButtonNumberMiddle = 3,
} MFMouseButtonNumber;

@end

NS_ASSUME_NONNULL_END
