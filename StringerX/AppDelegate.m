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
#import "TheTableCellView.h"
#import "AccountPreferencesViewController.h"

#define RESIZE_ANIMATION_DURATION .3

@interface AppDelegate () {
  NSWindowController *_preferencesWindowController;
  BOOL isResizing;
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
  self.webView = [[WebView alloc] init];
  [[[self window] contentView] addSubview:[self webView] positioned:NSWindowBelow relativeTo:[self urlText]];
  [[self webView] setPolicyDelegate:self];
  [[self webView] setUIDelegate:self];
  [self resizeWebView:NO];

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
      [[ServiceHelper sharedInstance] loginWithBaseURL:[NSURL URLWithString:accountDict[@"URL"]]
                                             withToken:accountDict[@"token"]
                                                 retry:YES
                                               success:^(AFHTTPRequestOperation *operation, id responseObject) {
        [[NSNotificationCenter defaultCenter] postNotificationName:STRINGER_LOGIN_STATUS_NOTIFICATION object:nil];
      } failure:nil];
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
    [self openItem:nil];
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

- (void)resizeWebView:(BOOL)fullscreen {
  if (isResizing) {
    return;
  }
  isResizing = YES;
  NSRect windowFrame = [[[self window] contentView] frame];
  NSRect centerFrame;
  if (fullscreen) {
    centerFrame = NSMakeRect(0, 0, windowFrame.size.width, windowFrame.size.height);
  } else {
    centerFrame = NSMakeRect(windowFrame.size.width/2, windowFrame.size.height/2, 1, 1);
  }
  [NSAnimationContext beginGrouping];
  [[NSAnimationContext currentContext] setDuration:RESIZE_ANIMATION_DURATION];
  [[[self webView] animator] setFrame:centerFrame];
  [NSAnimationContext endGrouping];
  [self performSelector:@selector(animationDidEnd) withObject:nil afterDelay:RESIZE_ANIMATION_DURATION];
}

- (void)animationDidEnd {
  isResizing = NO;
}

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
  for (NSString *paragraph in [[html stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] componentsSeparatedByString:@"\n"]) {
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

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
  [[ServiceHelper sharedInstance] setCurrentRow:[[self tableView] selectedRow]];
}

#pragma mark Item operations

- (IBAction)prevItem:(id)sender {
  NSInteger current = [[self tableView] selectedRow];
  if (current == 0) {
    return;
  }
  NSUInteger index;
  if (current == -1) {
    index = [[[ServiceHelper sharedInstance] itemIds] count] - 1;
  } else {
    index = current - 1;
  }
  [[self tableView] selectRowIndexes:[NSIndexSet indexSetWithIndex:index] byExtendingSelection:NO];
  [[self tableView] scrollRowToVisible:index];
  if (webViewOpen) {
    [self loadWeb];
  }
}

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
  if ([[self tableView] selectedRow] == -1 || isResizing) {
    return;
  }
  if (webViewOpen) {
    [self resizeWebView:NO];
    [[self urlText] setHidden:YES];
    webViewOpen = NO;
    [[self window] makeFirstResponder:[self tableView]];
  } else {
    [self resizeWebView:YES];
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
    [self openItem:nil];
  }
  [[ServiceHelper sharedInstance] markAllRead];
}

@end
