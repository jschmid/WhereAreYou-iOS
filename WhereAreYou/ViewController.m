//
//  ViewController.m
//  WhereAreYou
//
//  Created by Jonas Schmid on 16.05.13.
//  Copyright (c) 2013 Jonas Schmid. All rights reserved.
//

#import "ViewController.h"

#import "Firebase/Firebase.h"

#import "Constants.h"

@implementation ViewController {
    Firebase *firebase;
    Firebase *myself;
    Firebase *myPosition;
    
    NSMutableDictionary *markers;
    
    NSString *myName;
    
    NSDateFormatter *formatter;
    NSUserDefaults *prefs;
}

- (void)viewDidLoad
{
    
    markers = [NSMutableDictionary dictionary];
    
    formatter=[[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"dd/MM/yyyy HH:mm"];
    
    prefs = [NSUserDefaults standardUserDefaults];
    
    [super viewDidLoad];
    self.mapView.delegate = self;
    
}

- (void)viewWillAppear:(BOOL)animated {
    
    firebase = [[Firebase alloc] initWithUrl:@"https://whereareyou.firebaseio.com/v1/-InAHfjSC2dI8kpYofrD"];
    
    NSString *roomName = [firebase name];
    
    myName = [prefs stringForKey:roomName];
    
    if(myName) {
        myself = [firebase childByAppendingPath:myName];
    } else {
        myself = [firebase childByAutoId];
        myName = [myself name];
        [prefs setObject:myName forKey:roomName];
        [prefs synchronize];
    }
    
    [[myself childByAppendingPath:FB_NAME] setValue:@"iOS l0l"];
    myPosition = [myself childByAppendingPath:FB_POSITION];
    
    [firebase observeEventType:FEventTypeChildAdded withBlock:^(FDataSnapshot *snapshot) {
        [self personAddedWithSnapshot:snapshot];
    }];
    
}

- (void) personAddedWithSnapshot:(FDataSnapshot *)snapshot {
    NSString *snapshotName = snapshot.name;
    
    // Do not capture myself
    if([snapshotName isEqualToString:myName]) {
        return;
    }
    
    NSDictionary *value = snapshot.value;
    
    NSString *guyName = [value objectForKey:FB_NAME];
    
    NSLog(@"New guy %@", guyName);
    
    Firebase *positionRef = [[snapshot ref] childByAppendingPath:FB_POSITION];
    
    [positionRef observeEventType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        [self positionChangedWithName:guyName andSnapshot:snapshot];
    }];
}

- (void) positionChangedWithName:(NSString *)guyName andSnapshot:(FDataSnapshot *)snapshot {
    NSDictionary *position = snapshot.value;
    
    if([position isKindOfClass:[NSNull class]]) {
        return;
    }
    
    Firebase *ref = [snapshot ref];
    Firebase *parent = [ref parent];
    NSString *parentName = [parent name];
    
    CLLocationCoordinate2D zoomLocation;
    zoomLocation.latitude = [[position objectForKey:FB_LAT] doubleValue];
    zoomLocation.longitude = [[position objectForKey:FB_LONG] doubleValue];
    
    NSNumber *dateTimestamp = [position objectForKey:FB_DATETIME];
    NSTimeInterval interval = [dateTimestamp doubleValue] / 1000.0;
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:interval];
    NSString *dateString = [formatter stringFromDate:date];
    
    MKPointAnnotation *marker = [markers objectForKey:parentName];
    
    if(marker) {
        marker.coordinate = zoomLocation;
        marker.subtitle = dateString;
        
    } else {
        marker = [[MKPointAnnotation alloc] init];
        marker.coordinate = zoomLocation;
        marker.title = guyName;
        marker.subtitle = dateString;
    
        [self.mapView addAnnotation:marker];
        
        [markers setValue:marker forKey:parentName];
    }
}

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation {
//    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(userLocation.coordinate, 800, 800);
//    [self.mapView setRegion:region animated:YES];
    
    NSMutableDictionary *newPos = [NSMutableDictionary dictionary];
    [newPos setValue:[NSNumber numberWithDouble:userLocation.coordinate.latitude] forKey:FB_LAT];
    [newPos setValue:[NSNumber numberWithDouble:userLocation.coordinate.longitude] forKey:FB_LONG];
    [newPos setValue:[NSNumber numberWithDouble:userLocation.location.horizontalAccuracy] forKey:FB_ACCURACY];
    
    NSNumber *date = [NSNumber numberWithDouble:([[NSDate date] timeIntervalSince1970] * 1000.0)];
    [newPos setValue:date forKey:FB_DATETIME];
    
    [myPosition setValue:newPos];
}

@end
