//
//  BNViewController.m
//  BiteNow
//
//  Created by Stephen Chan on 10/29/14.
//  Copyright (c) 2014 Delta Lab. All rights reserved.
//

#import "BNViewController.h"

@interface BNViewController ()

@property (weak, nonatomic) IBOutlet UILabel *trackingLabel;
@property (weak, nonatomic) IBOutlet UIButton *foodButton;
@property (weak, nonatomic) IBOutlet UIButton *drinkButton;
@property (weak, nonatomic) IBOutlet UISegmentedControl *notificationSegmentControl;
@property (weak, nonatomic) IBOutlet UILabel *notification2Label;
@property (weak, nonatomic) IBOutlet UILabel *tutorialLabel;
@property (strong, nonatomic) NSString *tracking;
@property (strong, nonatomic) NSMutableArray *toolTipArray;
@property (strong, nonatomic) TSTapDetector *detector;
@property (strong, nonatomic) CLLocationManager *locationManager;

@end

@implementation BNViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self initUI];
    [self initDetector];
    [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^(void){}];
    [self initLocationListener];
    [self initSegmentedControl];
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"gotTutorial"]) {
        self.tutorialLabel.alpha = 0;
    }
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

-(void)initSegmentedControl
{
    [self.notificationSegmentControl addTarget:self
                         action:@selector(segmentedControlValueChanged)
               forControlEvents:UIControlEventValueChanged];
}

-(void)segmentedControlValueChanged
{
    [[PFUser currentUser] setObject:[self.notificationSegmentControl titleForSegmentAtIndex:[self.notificationSegmentControl selectedSegmentIndex]] forKey:@"notificationSelection"];
    [[PFUser currentUser] saveInBackground];
}

-(void)saveToolTipArray
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    NSString *libraryDirectory = [paths objectAtIndex:0];
    NSString *location = [libraryDirectory stringByAppendingString:@"/tooltips.plist"];
    [self.toolTipArray writeToFile:location atomically:YES];
}

-(void)initLocationListener
{
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    self.locationManager.distanceFilter = kCLDistanceFilterNone;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    if ([self.locationManager respondsToSelector:@selector(requestAlwaysAuthorization)]) {
        [self.locationManager requestAlwaysAuthorization];
    }
    [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^(void){}];
}

-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    PFGeoPoint *currentGeoPoint = [PFGeoPoint geoPointWithLocation:[locations lastObject]];
    [[PFUser currentUser] setObject:currentGeoPoint forKey:@"currentLocation"];
    [[PFUser currentUser] setObject:[NSDate date] forKey:@"locationUpdateDate"];
    [[PFUser currentUser] saveInBackground];
}

-(void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    if (status == kCLAuthorizationStatusAuthorizedAlways) {
        [self.locationManager startUpdatingLocation];
    }
}

-(void)initDetector
{
    self.detector = [[TSTapDetector alloc] init];
    self.detector.delegate = self;
}

- (IBAction)trackButtonPressed:(id)sender
{
    UIButton *pressedButton = (UIButton *)sender;
    if (pressedButton.selected) {
        pressedButton.selected = NO;
        self.tracking = nil;
        [self.trackingLabel setText:@"Help us track one of these:"];
        [self.detector.listener stopCollectingMotionInformation];
    } else {
        [self.detector.listener collectMotionInformationWithInterval:10];
        self.foodButton.selected = NO;
        self.drinkButton.selected = NO;
        pressedButton.selected = YES;
        self.tracking = pressedButton.restorationIdentifier;
        [self.trackingLabel setText:[NSString stringWithFormat:@"You're tracking %@!", self.tracking]];
    }
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    self.foodButton.layer.backgroundColor = [[UIColor clearColor] CGColor];
    self.trackingLabel.layer.backgroundColor = [[UIColor clearColor] CGColor];
    [self.toolTipArray removeObjectAtIndex:0];
    [self updateUI];
}

-(void)detectorDidDetectKnock:(TSTapDetector *)detector
{
    UILocalNotification *notification = [[UILocalNotification alloc] init];
    notification.alertBody = [NSString stringWithFormat:@"You reported free %@!", self.tracking];
    notification.soundName = @"short_double_low.wav";
    [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
    [self messageNearbyUsers];
}

-(void)messageNearbyUsers
{
    CLLocation *currentLocation = self.locationManager.location;
    CLGeocoder *geocoder = [[CLGeocoder alloc] init];
    [geocoder reverseGeocodeLocation:currentLocation completionHandler:^(NSArray *placemarks, NSError *error) {
        NSString *placemarkString = [placemarks firstObject];
        /* sending out a push notification to nearby users */
        PFQuery *userQuery = [PFUser query];
        [userQuery whereKey:@"currentLocation"
               nearGeoPoint:[PFGeoPoint geoPointWithLocation:currentLocation]
           withinKilometers:1];
        /* when the user has been nearby within the last two minutes */
        [userQuery whereKey:@"locationUpdateDate" greaterThan:[NSDate dateWithTimeIntervalSinceNow:-120]];
        [userQuery whereKey:@"notificationSelection" containedIn:@[self.tracking, @"Both"]];
        
        PFQuery *pushQuery = [PFInstallation query];
        [pushQuery whereKey:@"user" matchesQuery:userQuery];
        
        PFPush *push = [[PFPush alloc] init];
        [push setMessage:[NSString stringWithFormat:@"Someone reported free food at %@! Check it out.", placemarkString]];
        [push setQuery:pushQuery];
        [push sendPushInBackground];
    }];
}

-(void)initUI
{
    self.foodButton.layer.cornerRadius = 10;
    self.foodButton.clipsToBounds = YES;
    [self.foodButton setBackgroundImage:[UIImage imageWithColor:[UIColor lavenderColor]] forState:UIControlStateNormal];
    [self.foodButton setBackgroundImage:[UIImage imageWithColor:[UIColor midLavenderColor]] forState:UIControlStateHighlighted];
    [self.foodButton setBackgroundImage:[UIImage imageWithColor:[UIColor darkLavenderColor]] forState:UIControlStateSelected];
    
    self.drinkButton.layer.cornerRadius = 10;
    self.drinkButton.clipsToBounds = YES;
    [self.drinkButton setBackgroundImage:[UIImage imageWithColor:[UIColor lavenderColor]] forState:UIControlStateNormal];
    [self.drinkButton setBackgroundImage:[UIImage imageWithColor:[UIColor midLavenderColor]] forState:UIControlStateHighlighted];
    [self.drinkButton setBackgroundImage:[UIImage imageWithColor:[UIColor darkLavenderColor]] forState:UIControlStateSelected];
    
    self.trackingLabel.userInteractionEnabled = YES;
    UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(trackingLabelTapped)];
    [self.trackingLabel addGestureRecognizer:gestureRecognizer];
}

-(void)updateUI
{
    if ([[self.toolTipArray firstObject] isEqualToString:@"tracking"]) {
        // hide everything but the title and intro
        self.drinkButton.alpha = 0;
        self.notificationSegmentControl.alpha = 0;
        self.trackingLabel.alpha = 0;
        self.notification2Label.alpha = 0;
        self.foodButton.alpha = 0;
        self.tutorialLabel.alpha = 0;
        // fade the food button into view
        [UIView animateWithDuration:1 delay:2 options:UIViewAnimationOptionCurveEaseInOut
        animations:^{
            self.foodButton.alpha = 1;
            self.tutorialLabel.alpha = 1;
        } completion:nil];
    } else if ([[self.toolTipArray firstObject] isEqualToString:@"taps"]) {
        [UIView animateWithDuration:1 delay:0.5 options:UIViewAnimationOptionCurveEaseInOut
        animations:^{
            self.tutorialLabel.alpha = 0;
            self.drinkButton.alpha = 1;
        } completion:^(BOOL didComplete){
            [UIView animateWithDuration:1 delay:0.1 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            self.trackingLabel.alpha = 1;
            } completion:nil];}];
    } else {
        [UIView animateWithDuration:1 delay:0.5 options:UIViewAnimationOptionCurveEaseInOut
        animations:^{
            self.notification2Label.alpha = 1;
            self.notificationSegmentControl.alpha = 1;
        } completion:nil];
    }
}

-(void)trackingLabelTapped
{
    CATransition* transition = [CATransition animation];
    transition.duration = 0.8;
    transition.type = kCATransitionFade;
    [[self navigationController].view.layer addAnimation:transition forKey:kCATransition];
    [[self navigationController] pushViewController:[[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"Video"] animated:NO];
}

-(void)startToolTips
{
    [self beginToolTipAnimation];
}

-(void)beginToolTipAnimation
{
    if ([[self.toolTipArray firstObject] isEqualToString:@"tracking"]) {
        [UIView animateWithDuration:1.0
                              delay:0
                            options:(UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionCurveEaseInOut)
                         animations:^{
            self.foodButton.layer.backgroundColor = [[UIColor clearColor] CGColor];
        } completion:^(BOOL finished) {
            [self finishToolTipAnimation];
        }];
    } else if ([[self.toolTipArray firstObject] isEqualToString:@"taps"]) {
        [UIView animateWithDuration:1.0
                              delay:0
                            options:(UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionCurveEaseInOut)
                         animations:^{
            self.trackingLabel.layer.backgroundColor = [[UIColor clearColor] CGColor];
        } completion:^(BOOL finished) {
            [self finishToolTipAnimation];
        }];       
    } else if ([[self.toolTipArray firstObject] isEqualToString:@"notifications"]) {
        [UIView animateWithDuration:1.0
                              delay:0
                            options:(UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionCurveEaseInOut)
                         animations:^{
                            self.notificationSegmentControl.alpha = 0.0;
        } completion:^(BOOL finished) {
            [self finishToolTipAnimation];
        }];
        
    }
}

-(void)finishToolTipAnimation
{
    if ([[self.toolTipArray firstObject] isEqualToString:@"tracking"]) {
        [UIView animateWithDuration:1.0
                              delay:0
                            options:(UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionCurveEaseInOut)
                         animations:^{
            self.foodButton.layer.backgroundColor = [[UIColor darkLavenderColor] CGColor];
        } completion:^(BOOL finished) {
            [self beginToolTipAnimation];
        }];
    } else if ([[self.toolTipArray firstObject] isEqualToString:@"taps"]) {
        [UIView animateWithDuration:1.0
                              delay:0
                            options:(UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionCurveEaseInOut)
                         animations:^{
            self.trackingLabel.layer.backgroundColor = [[UIColor darkLavenderColor] CGColor];
        } completion:^(BOOL finished) {
            [self beginToolTipAnimation];
        }];       
    } else if ([[self.toolTipArray firstObject] isEqualToString:@"notifications"]) {
        [UIView animateWithDuration:1.0
                              delay:0
                            options:(UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionCurveEaseInOut)
                         animations:^{
                             self.notificationSegmentControl.alpha = 1.0;
        } completion:^(BOOL finished) {
            [self beginToolTipAnimation];
        }];
        
    }
}

@end