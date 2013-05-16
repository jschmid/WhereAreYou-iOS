//
//  ViewController.m
//  WhereAreYou
//
//  Created by Jonas Schmid on 16.05.13.
//  Copyright (c) 2013 Jonas Schmid. All rights reserved.
//

#import "ViewController.h"

#import "Firebase/Firebase.h"

@implementation ViewController {
    Firebase *firebase;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.mapView.delegate = self;
    
}

- (void)viewWillAppear:(BOOL)animated {
    CLLocationCoordinate2D zoomLocation;
    zoomLocation.latitude = 39.28;
    zoomLocation.longitude = -76.5;
    
    MKPointAnnotation *pos = [[MKPointAnnotation alloc] init];
    pos.coordinate = zoomLocation;
    pos.title = @"Hello";
    pos.subtitle = @"World";
    
    [self.mapView addAnnotation:pos];
    
    
    firebase = [[Firebase alloc] initWithUrl:@"https://whereareyou.firebaseio.com/v1/-InAHfjSC2dI8kpYofrD"];
    
    [firebase observeEventType:FEventTypeChildAdded withBlock:^(FDataSnapshot *snapshot) {
        //        NSLog(@"%@ => %@", snapshot.name, snapshot.value);
        //        NSLog(@"Has children: %s, %d", snapshot.hasChildren ? "true" : "false", [[snapshot.children allObjects] count]);
        
        NSDictionary *value = snapshot.value;
        
        NSString *guyName = [value objectForKey:@"name"];
        
        NSLog(@"New guy %@", guyName);
        
        Firebase *positionRef = [[snapshot ref] childByAppendingPath:@"position"];
        
        [positionRef observeEventType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
            NSDictionary *position = snapshot.value;
            
            if([position isKindOfClass:[NSNull class]]) {
                return;
            }
            
            NSLog(@"%@ position: %@", guyName, position);
            
            CLLocationCoordinate2D zoomLocation;
            zoomLocation.latitude = [[position objectForKey:@"lat"] doubleValue];
            zoomLocation.longitude = [[position objectForKey:@"lon"] doubleValue];
            
            MKPointAnnotation *pos = [[MKPointAnnotation alloc] init];
            pos.coordinate = zoomLocation;
            pos.title = guyName;
            pos.subtitle = [position objectForKey:@"datetime"];
            
            [self.mapView addAnnotation:pos];
        }];
        
    }];
    
}

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation {
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(userLocation.coordinate, 800, 800);
    [self.mapView setRegion:region animated:YES];
}

@end
