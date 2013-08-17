//
//  AccountPreferencesViewController.h
//  StringerX
//
//  Created by Tony Wang on 8/13/13.
//  Copyright (c) 2013 Tony Wang. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AccountPreferencesViewController : NSViewController {
  BOOL loggedIn;
}

@property (weak) IBOutlet NSTextField *URLField;
@property (weak) IBOutlet NSSecureTextField *passwordField;
@property (weak) IBOutlet NSButton *loginButton;
- (IBAction)onLogin:(id)sender;

@end
