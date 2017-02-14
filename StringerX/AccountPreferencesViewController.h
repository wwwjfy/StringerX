//
//  AccountPreferencesViewController.h
//  StringerX
//
//  Created by Tony Wang on 8/13/13.
//  Copyright (c) 2013 Tony Wang. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef enum {
  LOGGED_IN,
  LOGGING_IN,
  LOGGED_OUT
} LOGIN_STATUS;

@interface AccountPreferencesViewController : NSViewController {
  LOGIN_STATUS status;
}

@property (weak) IBOutlet NSTextField *URLField;
@property (weak) IBOutlet NSSecureTextField *passwordField;
@property (weak) IBOutlet NSButton *loginButton;
- (IBAction)onLogin:(id)sender;
- (void)setLoginStatus:(LOGIN_STATUS)status;
@property NSString *baseURL;

@end
