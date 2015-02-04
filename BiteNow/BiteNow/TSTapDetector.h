//
//  knockDetector.h
//  LocaleNatives
//
//  Created by Stephen Chan on 4/17/14.
//  Copyright (c) 2014 Stephen Chan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TSCoreMotionListener.h"
#import <AVFoundation/AVFoundation.h>
#import "ARAudioRecognizerDelegate.h"

@class TSTapDetector, ARAudioRecognizer;

@protocol KnockDetectorDelegate <NSObject>

-(void)detectorDidDetectKnock:(TSTapDetector *)detector;

@end

@interface TSTapDetector : NSObject <TSCoreMotionListenerDelegate> {
    CMDeviceMotion *currentDeviceMotion;
    CMDeviceMotion *lastDeviceMotion;
    CMAcceleration lastAccel;
    float jerk;
    float jounce;
    float normedAccel;
    float normedRotation;
    NSTimeInterval lastKnockTime;
    NSTimeInterval lastDoubleKnock;
    float filterConstant;
    UIAccelerationValue x;
    UIAccelerationValue y;
    UIAccelerationValue z;
    UIAccelerationValue lastX;
    UIAccelerationValue lastY;
    UIAccelerationValue lastZ;
    NSNumber *timeFromFirstKnock;
    CMAcceleration gravity;
    int accelUpdateCount;
    BOOL audioRecognized;
}

@property (strong, nonatomic) TSCoreMotionListener *listener;
@property (strong, nonatomic) id<KnockDetectorDelegate> delegate;

-(void)motionListener:(TSCoreMotionListener *)listener didReceiveDeviceMotion:(CMDeviceMotion *)deviceMotion;

@end
