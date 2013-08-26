//
//  AppDelegate.m
//  StringerX
//
//  Created by Tony Wang on 6/30/13.
//  Copyright (c) 2013 Tony Wang. All rights reserved.
//

#import "AppDelegate.h"

#import <AFNetworking.h>
#import <MASPreferencesWindowController.h>

#import <ServiceHelper.h>
#import "Notifications.h"
#import "URLHelper.h"
#import "TheTableCellView.h"
#import "AccountPreferencesViewController.h"

@interface AppDelegate () {
  NSWindowController *_preferencesWindowController;
}

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
  [[self tableView] setDataSource:self];
  [[self tableView] setDelegate:self];
  [[self tableView] setAllowsTypeSelect:NO];
  NSSize spacing = [[self tableView] intercellSpacing];
  spacing.height = 10;
  [[self tableView] setIntercellSpacing:spacing];
  [[self webView] setHidden:YES];
  [[self webView] setPolicyDelegate:self];
  [[self webView] setUIDelegate:self];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(refresh:)
                                               name:REFRESH_NOTIFICATION
                                             object:nil];
  
  NSViewController *accountViewController = [[AccountPreferencesViewController alloc] init];
  NSArray *controllers = @[accountViewController];
  
  NSString *title = NSLocalizedString(@"Preferences", @"Common title for Preferences window");
  _preferencesWindowController = [[MASPreferencesWindowController alloc] initWithViewControllers:controllers title:title];
  
  NSError *err;
  NSURL *pDir = [[[NSFileManager defaultManager] URLForDirectory:NSApplicationSupportDirectory
                                                        inDomain:NSUserDomainMask
                                               appropriateForURL:nil
                                                          create:NO
                                                           error:&err] URLByAppendingPathComponent:@"StringerX"];
  if ([[NSFileManager defaultManager] fileExistsAtPath:[pDir path]]) {
    NSURL *pFile = [pDir URLByAppendingPathComponent:@"account.plist"];
    NSDictionary *accountDict = [[NSString stringWithContentsOfURL:pFile
                                                          encoding:NSUTF8StringEncoding
                                                             error:&err] propertyListFromStringsFileFormat];
    if (!err) {
      [[URLHelper sharedInstance] setBaseURL:[NSURL URLWithString:accountDict[@"URL"]]];
      [[URLHelper sharedInstance] setToken:accountDict[@"token"]];
      [[URLHelper sharedInstance] requestWithPath:@"/fever/" success:^(AFHTTPRequestOperation *operation, id JSON) {
        [[NSNotificationCenter defaultCenter] postNotificationName:STRINGER_LOGIN_STATUS_NOTIFICATION object:nil];
        [[ServiceHelper sharedInstance] getFeeds];
      } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [self onPreferences:nil];
      }];
      return;
    }
  }
  [self onPreferences:nil];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
  return YES;
}

- (void)openInBrowserForURL:(NSURL *)url {
  LSLaunchURLSpec urlSpec = {nil, (__bridge CFArrayRef)@[url], nil, kLSLaunchDontSwitch, nil};
  LSOpenFromURLSpec(&urlSpec, nil);
}

- (IBAction)onClose:(id)sender {
  if ([[_preferencesWindowController window] isVisible] && [[_preferencesWindowController window] isMainWindow]) {
    [_preferencesWindowController close];
  } else if (webViewOpen) {
    [[self webView] setHidden:YES];
    webViewOpen = NO;
  } else {
    [[NSApplication sharedApplication] terminate:nil];
  }
}

- (IBAction)onPreferences:(id)sender {
  [_preferencesWindowController showWindow:nil];
}

- (void)refresh:(NSNotification *)notification {
  [[self tableView] reloadData];
  NSNumber *currentRow = [[notification userInfo] objectForKey:@"currentRow"];
  if (currentRow) {
    [[self tableView] selectRowIndexes:[NSIndexSet indexSetWithIndex:[currentRow integerValue]] byExtendingSelection:NO];
  }
  if ([[[ServiceHelper sharedInstance] items] count] > 0) {
    [[[NSApplication sharedApplication] dockTile] setBadgeLabel:[NSString stringWithFormat:@"%lu", [[[ServiceHelper sharedInstance] items] count]]];
  } else {
    [[[NSApplication sharedApplication] dockTile] setBadgeLabel:@""];
  }
}

#pragma mark WebView

- (void)webView:(WebView *)webView decidePolicyForNavigationAction:(NSDictionary *)actionInformation request:(NSURLRequest *)request frame:(WebFrame *)frame decisionListener:(id<WebPolicyDecisionListener>)listener {
  if (webViewOpen && ![[[request URL] absoluteString] isEqualToString:@"about:blank"]) {
    [self openInBrowserForURL:[request URL]];
  } else {
    [listener use];
  }
}

- (void)webView:(WebView *)webView decidePolicyForNewWindowAction:(NSDictionary *)actionInformation request:(NSURLRequest *)request newFrameName:(NSString *)frameName decisionListener:(id<WebPolicyDecisionListener>)listener {
  if (webViewOpen) {
    [self openInBrowserForURL:[request URL]];
  } else {
    [listener use];
  }
}

- (void)webView:(WebView *)sender mouseDidMoveOverElement:(NSDictionary *)elementInformation modifierFlags:(NSUInteger)modifierFlags {
  NSString *url = elementInformation[@"WebElementLinkURL"];
  if (url) {
    [[self urlText] setStringValue:url];
    [[self urlText] setHidden:NO];
  } else {
    [[self urlText] setHidden:YES];
  }
}

#pragma mark Table source and delegate

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
  return [[[ServiceHelper sharedInstance] items] count];
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
  TheTableCellView *view = [tableView makeViewWithIdentifier:@"Items" owner:self];
  [view setAutoresizingMask:NSViewWidthSizable];
  
  // title
  [[view textField] setStringValue:[[ServiceHelper sharedInstance] items][[[ServiceHelper sharedInstance] itemIds][row]][@"title"]];
  
  // source
  [[view sourceField] setStringValue:[[ServiceHelper sharedInstance] feeds][[[ServiceHelper sharedInstance] items][[[ServiceHelper sharedInstance] itemIds][row]][@"feed_id"]]];
  
  // detailed text
  NSString *html = [[ServiceHelper sharedInstance] items][[[ServiceHelper sharedInstance] itemIds][row]][@"html"];
  NSRange r;
  while ((r = [html rangeOfString:@"<[^>]+>" options:NSRegularExpressionSearch]).location != NSNotFound)
    html = [html stringByReplacingCharactersInRange:r withString:@""];
  NSString *text = [NSString string];
  int count = 0;
  for (NSString *paragraph in [html componentsSeparatedByString:@"\n"]) {
    if ([paragraph isEqualToString:@""]) {
      continue;
    }
    text = [text stringByAppendingString:paragraph];
    text = [text stringByAppendingString:@"\n"];
    count++;
    if (count == 2) {
      break;
    }
  };
  [[view detailedText] setStringValue:text];
  
  // published time
  
  return view;
}

- (IBAction)prevItem:(id)sender {
  NSInteger current = [[self tableView] selectedRow];
  if (current == -1) {
    return;
  }
  [[self tableView] selectRowIndexes:[NSIndexSet indexSetWithIndex:(current - 1)] byExtendingSelection:NO];
  [[self tableView] scrollRowToVisible:(current - 1)];
  if (webViewOpen) {
    [self loadWeb];
  }
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
  [[ServiceHelper sharedInstance] setCurrentRow:[[self tableView] selectedRow]];
}

#pragma mark Item operations

- (IBAction)nextItem:(id)sender {
  NSInteger current = [[self tableView] selectedRow];
  if ((current + 1) >= (NSInteger)[[[ServiceHelper sharedInstance] itemIds] count]) {
    return;
  }
  [[self tableView] selectRowIndexes:[NSIndexSet indexSetWithIndex:(current + 1)] byExtendingSelection:NO];
  [[self tableView] scrollRowToVisible:(current + 1)];
  if (webViewOpen) {
    [self loadWeb];
  }
}

- (IBAction)openItem:(id)sender {
  if (webViewOpen) {
    [[self webView] setHidden:YES];
    [[self urlText] setHidden:YES];
    webViewOpen = NO;
  } else {
    [self loadWeb];
    webViewOpen = YES;
  }
}

- (void)loadWeb {
  if ([[self tableView] selectedRow] == -1) {
    return;
  }
  NSDictionary *item = [[ServiceHelper sharedInstance] items][[[ServiceHelper sharedInstance] itemIds][[[self tableView] selectedRow]]];
  NSString *html = [NSString stringWithFormat:@"<h1>%@</h1><div style=\"color: gray\">%@</div><div style=\"color: gray\">%@</div><div style=\"max-width:800px\">%@</div>",
                    item[@"title"],
                    item[@"author"],
                    [NSDateFormatter localizedStringFromDate:[NSDate dateWithTimeIntervalSince1970:[item[@"created_on_time"] intValue]]
                                                   dateStyle:NSDateFormatterShortStyle
                                                   timeStyle:NSDateFormatterMediumStyle],
                    item[@"html"]];
  [[[self webView] mainFrame] loadHTMLString:html baseURL:nil];
  [[self webView] setHidden:NO];
  [[self window] makeFirstResponder:[self webView]];
}

- (IBAction)openExternal:(id)sender {
  NSInteger current = [[self tableView] selectedRow];
  if (current == -1) {
    return;
  }
  NSURL *url = [NSURL URLWithString:[[ServiceHelper sharedInstance] items][[[ServiceHelper sharedInstance] itemIds][current]][@"url"]];
  [self openInBrowserForURL:url];
}

- (IBAction)markAllRead:(id)sender {
  if (webViewOpen) {
    [[self webView] setHidden:YES];
    webViewOpen = NO;
  }
  [[ServiceHelper sharedInstance] markAllRead];
}

@end
