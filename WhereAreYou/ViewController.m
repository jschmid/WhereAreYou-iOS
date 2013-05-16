//
//  ViewController.m
//  WhereAreYou
//
//  Created by Jonas Schmid on 16.05.13.
//  Copyright (c) 2013 Jonas Schmid. All rights reserved.
//

#import "ViewController.h"

@implementation ViewController

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
    
}

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation {
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(userLocation.coordinate, 800, 800);
    [self.mapView setRegion:region animated:YES];
}

@end