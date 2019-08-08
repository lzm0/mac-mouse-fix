//
//  InputReceiver.h
//  Mouse Remap Helper
//
//  Created by Noah Nübling on 19.11.18.
//  Copyright © 2018 Noah Nuebling Enterprises Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import "IOKit/hid/IOHIDManager.h"


@interface MouseInputReceiver : NSObject

+ (void)startOrStopDecide;

+ (void)Register_InputCallback_HID:(IOHIDDeviceRef)device;
@end