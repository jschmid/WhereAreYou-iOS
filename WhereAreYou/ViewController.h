//
//  ViewController.h
//  WhereAreYou
//
//  Created by Jonas Schmid on 16.05.13.
//  Copyright (c) 2013 Jonas Schmid. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

@interface ViewController : UIViewController <MKMapViewDelegate>

@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *shareButton;

- (IBAction)shareButton:(id)sender;

@end
