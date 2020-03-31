//
// --------------------------------------------------------------------------
// RoughScroll.h
// Created for: Mac Mouse Fix (https://github.com/noah-nuebling/mac-mouse-fix)
// Created by: Noah Nuebling in 2020
// Licensed under MIT
// --------------------------------------------------------------------------
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// Traditional, non-smooth scrolling.

@interface RoughScroll : NSObject
+ (void)load_Manual;
+ (void)start;
+ (void)stop;
@end

NS_ASSUME_NONNULL_END