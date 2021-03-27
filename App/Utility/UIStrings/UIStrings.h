//
// --------------------------------------------------------------------------
// UIStrings.h
// Created for Mac Mouse Fix (https://github.com/noah-nuebling/mac-mouse-fix)
// Created by Noah Nuebling in 2021
// Licensed under MIT
// --------------------------------------------------------------------------
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIStrings : NSObject

+ (NSString *)getButtonString:(int)buttonNumber;
+ (NSString *)stringForKeyCode:(NSInteger *)keyCode;

@end

NS_ASSUME_NONNULL_END