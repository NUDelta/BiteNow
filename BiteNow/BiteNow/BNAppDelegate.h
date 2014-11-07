//
//  BNAppDelegate.h
//  BiteNow
//
//  Created by Stephen Chan on 10/29/14.
//  Copyright (c) 2014 Delta Lab. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import <AudioToolbox/AudioToolbox.h>

@interface BNAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property BOOL firstLaunch;

@end
