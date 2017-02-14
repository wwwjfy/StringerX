//
//  AccountPreferencesViewController.m
//  StringerX
//
//  Created by Tony Wang on 8/13/13.
//  Copyright (c) 2013 Tony Wang. All rights reserved.
//

#import "AccountPreferencesViewController.h"

#import <CommonCrypto/CommonDigest.h>
#import "Notifications.h"
#import "URLHelper.h"
#import "ServiceHelper.h"

@implementation AccountPreferencesViewController

- (void)loadView {
  [super loadView];
  if ([self baseURL]) {
    [[self URLField] setStringValue:[self baseURL]];
  }
  [self setLoginStatus:status];
}

- (NSString *)identifier {
  return @"AccountPreferences";
}

- (NSImage *)toolbarItemImage {
  return [NSImage imageNamed:NSImageNamePreferencesGeneral];
}

- (NSString *)toolbarItemLabel {
  return NSLocalizedString(@"General", @"Toolbar item name for the General preference pane");
}

- (IBAction)onLogin:(id)sender {
  if (status == LOGGED_IN) {
    NSError *err;
    NSURL *pDir = [[[NSFileManager defaultManager] URLForDirectory:NSApplicationSupportDirectory
                                                          inDomain:NSUserDomainMask
                                                 appropriateForURL:nil
                                                            create:YES
                                                             error:&err] URLByAppendingPathComponent:@"StringerX"];
    [[NSFileManager defaultManager] createDirectoryAtURL:pDir withIntermediateDirectories:YES attributes:nil error:&err];
    NSURL *pFile = [pDir URLByAppendingPathComponent:@"account.plist"];
    [[NSFileManager defaultManager] removeItemAtURL:pFile error:&err];
    if (err) {
      NSLog(@"ERROR: %@", [err localizedDescription]);
    }
    [self setLoginStatus:LOGGED_OUT];
    return;
  }
  NSURL *baseURL = [NSURL URLWithString:[[self URLField] stringValue]];
  if (!(baseURL &&
        ([baseURL.scheme isEqualToString:@"http"] || [baseURL.scheme isEqualToString:@"https"]) &&
        baseURL.host)) {
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:@"Invalid URL"];
    [alert runModal];
    return;
  }
  NSString *token = [NSString stringWithFormat:@"stringer:%@", [[self passwordField] stringValue]];
  const char *cstr = [token UTF8String];
  unsigned char result[16];
  CC_MD5(cstr, (CC_LONG)strlen(cstr), result);
  token = [NSString stringWithFormat:
           @"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
           result[0], result[1], result[2], result[3],
           result[4], result[5], result[6], result[7],
           result[8], result[9], result[10], result[11],
           result[12], result[13], result[14], result[15]
           ];
  void (^success)(NSHTTPURLResponse *, id) = ^void(NSHTTPURLResponse *response, id JSON) {
    [self setLoginStatus:LOGGED_IN];
    NSError *err;
    NSURL *pDir = [[[NSFileManager defaultManager] URLForDirectory:NSApplicationSupportDirectory
                                                          inDomain:NSUserDomainMask
                                                 appropriateForURL:nil
                                                            create:YES
                                                             error:&err] URLByAppendingPathComponent:@"StringerX"];
    [[NSFileManager defaultManager] createDirectoryAtURL:pDir withIntermediateDirectories:YES attributes:nil error:&err];
    NSURL *pFile = [pDir URLByAppendingPathComponent:@"account.plist"];
    if (!err && pFile) {
      NSData *accountData = [NSPropertyListSerialization dataWithPropertyList:@{@"URL": [baseURL absoluteString], @"token": token}
                                                                       format:NSPropertyListXMLFormat_v1_0
                                                                      options:0
                                                                        error:&err];
      if (accountData) {
        [accountData writeToURL:pFile options:NSDataWritingAtomic error:&err];
      }
    }
    if (err) {
      NSAlert *alert = [[NSAlert alloc] init];
      [alert setMessageText:@"Failed to record account info."];
      [alert runModal];
    }
  };
  void (^failure)(NSHTTPURLResponse *, NSError *) = ^void(NSHTTPURLResponse *response, NSError *error) {
    NSString *errString;
    if ([response statusCode] == 403) {
      errString = @"Authentication failed! Please verify the password.";
    } else {
      errString = [error localizedDescription];
    }
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:@"Failed to login"];
    [alert runModal];
    [self setLoginStatus:LOGGED_OUT];
  };
  [[ServiceHelper sharedInstance] loginWithBaseURL:baseURL
                                         withToken:token
                                             retry:NO
                                           success:success
                                           failure:failure];
}

- (void)setLoginStatus:(LOGIN_STATUS)newStatus {
  status = newStatus;
  switch (status) {
    case LOGGED_IN:
      [[self URLField] setEnabled:NO];
      [[self passwordField] setEnabled:NO];
      [[self loginButton] setTitle:@"Log out"];
      [[self loginButton] setEnabled:YES];
      break;

    case LOGGING_IN:
      [[self URLField] setEnabled:NO];
      [[self passwordField] setEnabled:NO];
      [[self loginButton] setTitle:@"Logging in..."];
      [[self loginButton] setEnabled:NO];
      break;

    case LOGGED_OUT:
      [[self URLField] setEnabled:YES];
      [[self passwordField] setEnabled:YES];
      [[self loginButton] setTitle:@"Log in"];
      [[self loginButton] setEnabled:YES];
      break;
  }
}

@end
