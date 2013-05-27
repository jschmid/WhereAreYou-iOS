//
//  SettingsController.m
//  WhereAreYou
//
//  Created by Jonas Schmid on 5/27/13.
//  Copyright (c) 2013 Jonas Schmid. All rights reserved.
//

#import "SettingsController.h"

#import "Constants.h"

@implementation SettingsController {
    NSUserDefaults *prefs;
}

- (void)awakeFromNib {
    prefs = [NSUserDefaults standardUserDefaults];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSString *myUserName = [prefs stringForKey:PREF_NAME];
    self.userNameTextField.text = myUserName;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if([segue.identifier isEqualToString:@"DoneInput"]) {
        NSLog(@"Saving settings");
        
        NSString *trimmedUsername = [self.userNameTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
        if([trimmedUsername length] > 0) {
            [prefs setValue:trimmedUsername forKey:PREF_NAME];
            [prefs synchronize];
            NSLog(@"New username: %@", trimmedUsername);
        }
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if(textField == self.userNameTextField) {
        [textField resignFirstResponder];
    }
    
    return YES;
}

@end
