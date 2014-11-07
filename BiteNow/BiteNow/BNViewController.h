//
//  BNViewController.h
//  BiteNow
//
//  Created by Stephen Chan on 10/29/14.
//  Copyright (c) 2014 Delta Lab. All rights reserved.
//

#import "BNAppDelegate.h"
#import "TSTapDetector.h"
#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <CoreLocation/CoreLocation.h>
#import <Parse/Parse.h>

@interface BNViewController : UIViewController <UIAlertViewDelegate, KnockDetectorDelegate, CLLocationManagerDelegate>

@end
