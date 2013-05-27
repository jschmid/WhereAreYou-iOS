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
    
    NSString *myRoomId;
    NSString *myUserName;
    
    NSDateFormatter *formatter;
    NSUserDefaults *prefs;
}

- (void)awakeFromNib {
        
    formatter=[[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"dd/MM/yyyy HH:mm"];
    
    prefs = [NSUserDefaults standardUserDefaults];
    
    myUserName = [prefs stringForKey:PREF_NAME];
    if(!myUserName) {
        myUserName = [[UIDevice currentDevice] name];
        [prefs setObject:myUserName forKey:PREF_NAME];
        [prefs synchronize];
    }
}

- (void)viewDidLoad
{
    NSLog(@"View did load");
    
    [super viewDidLoad];
    
    // Delegate for the map events
    self.mapView.delegate = self;
    
    // Register to get claled when the user clicks a link
    NSNotificationCenter *nsCenter = [NSNotificationCenter defaultCenter];
    [nsCenter addObserver:self selector:@selector(openNewRoom:) name:OPEN_NOTIFICATION object:nil];
    
    [self prepareMap];
}

- (void)openNewRoom:(NSNotification *)notification {
    
    NSLog(@"Got notification: %@", notification);
    
    NSString *roomName = [notification.userInfo objectForKey:OPEN_NOTIFICATION];
    
    [self prepareMapWithRoomName:roomName];
}

- (void)prepareMap {
    [self prepareMapWithRoomName:nil];
}

- (void)prepareMapWithRoomName:(NSString *)roomName {
    
    NSLog(@"Preparing map with: >%@<", roomName);
    
    [self cleanMapIfNeeded];
    
    markers = [NSMutableDictionary dictionary];
    
    NSString *firebaseBaseUrl = [FB_URL stringByAppendingString:PROTOCOL_VERSION];
    Firebase *roomsFirebase = [[Firebase alloc] initWithUrl:firebaseBaseUrl];
    
    if(roomName.length > 0) {
        firebase = [roomsFirebase childByAppendingPath:roomName];
    } else {
        firebase = [roomsFirebase childByAutoId];
        roomName = firebase.name;
    }
    
    myRoomId = [prefs stringForKey:roomName];
    
    if(myRoomId) {
        myself = [firebase childByAppendingPath:myRoomId];
    } else {
        myself = [firebase childByAutoId];
        myRoomId = [myself name];
        [prefs setObject:myRoomId forKey:roomName];
        [prefs synchronize];
    }
    
    [[myself childByAppendingPath:FB_NAME] setValue:myUserName];
    myPosition = [myself childByAppendingPath:FB_POSITION];
    
    [firebase observeEventType:FEventTypeChildAdded withBlock:^(FDataSnapshot *snapshot) {
        [self personAddedWithSnapshot:snapshot];
    }];
    
    [firebase observeEventType:FEventTypeChildRemoved withBlock:^(FDataSnapshot *snapshot) {
        [self personRemovedWithSnapshot:snapshot];
    }];
    
    // Follow the user (until he moves the map manually)
    [self.mapView setUserTrackingMode:MKUserTrackingModeFollow animated:YES];
}

- (void)cleanMapIfNeeded {
    if(firebase) {
        NSLog(@"Cleaning map");
        
        [firebase removeAllObservers];
        [self.mapView removeAnnotations:[markers allValues]];
    }
}

- (void)personAddedWithSnapshot:(FDataSnapshot *)snapshot {
    NSString *snapshotName = snapshot.name;
    
    // Do not capture myself
    if([snapshotName isEqualToString:myRoomId]) {
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

- (void)personRemovedWithSnapshot:(FDataSnapshot *)snapshot {
    NSString *snapshotName = snapshot.name;
    
    MKPointAnnotation *marker = [markers objectForKey:snapshotName];
    
    if(marker) {
        [self.mapView removeAnnotation:marker];
        [markers removeObjectForKey:snapshotName];
    }
    
    [snapshot.ref removeAllObservers];
}

- (void) positionChangedWithName:(NSString *)guyName andSnapshot:(FDataSnapshot *)snapshot {
    NSDictionary *position = snapshot.value;
    
    NSLog(@"Position changed: %@", position);
    
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
    
    NSLog(@"User updated his position: %@", userLocation);
    
    NSMutableDictionary *newPos = [NSMutableDictionary dictionary];
    [newPos setValue:[NSNumber numberWithDouble:userLocation.coordinate.latitude] forKey:FB_LAT];
    [newPos setValue:[NSNumber numberWithDouble:userLocation.coordinate.longitude] forKey:FB_LONG];
    [newPos setValue:[NSNumber numberWithDouble:userLocation.location.horizontalAccuracy] forKey:FB_ACCURACY];
    
    NSNumber *date = [NSNumber numberWithDouble:([[NSDate date] timeIntervalSince1970] * 1000.0)];
    [newPos setValue:date forKey:FB_DATETIME];
    
    [myPosition setValue:newPos];
}

- (IBAction)shareButton:(id)sender {
    NSString *shareText = NSLocalizedString(@"SHARE_TEXT", @"Text used when sharing the WAY url");
    NSString *shareUrl = [BASE_URL stringByAppendingString:firebase.name];
    NSString *shareComplete = [NSString stringWithFormat:shareText, shareUrl];
    
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    [pasteboard setString:shareComplete];
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"SHARE_ALERT_TITLE", @"Title of the alert when sharing the WAY url")
                                                    message:NSLocalizedString(@"SHARE_ALERT_CONTENT", @"Content of the alert when sharing the WAY url")
                                                   delegate:nil
                                          cancelButtonTitle:NSLocalizedString(@"SHARE_ALERT_BUTTON", @"OK Button when sharing the WAY url")
                                          otherButtonTitles:nil];
    
    [alert show];
}

- (IBAction)gpsButton:(id)sender {
    [self.mapView setUserTrackingMode:MKUserTrackingModeFollow animated:YES];
}


- (IBAction)cancel:(UIStoryboardSegue *)segue {

    if([segue.identifier isEqualToString:@"CancelInput"]) {
        // We don't do anything if the user cancelled
        
        NSLog(@"User dismissed the settings");
        
        [self dismissViewControllerAnimated:YES completion:NULL];
    }
}

- (IBAction)done:(UIStoryboardSegue *)segue {
    
    if([segue.identifier isEqualToString:@"DoneInput"]) {
    
        NSLog(@"User submitted the settings");
        
        myUserName = [prefs stringForKey:PREF_NAME];
        [[myself childByAppendingPath:FB_NAME] setValue:myUserName];
        
        [self dismissViewControllerAnimated:YES completion:NULL];
    }
}

@end
