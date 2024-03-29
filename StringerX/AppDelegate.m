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

#import "AppUtils.h"
#import "ServiceHelper.h"
#import "Notifications.h"
#import "TheTableCellView.h"
#import "AccountPreferencesViewController.h"
#import "SWebView.h"

@interface WebViewMouseOverHandler: NSObject <WKScriptMessageHandler>
@property (copy) void (^onURLHover)(id url);
@end

@implementation WebViewMouseOverHandler

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
  if (self.onURLHover) {
    self.onURLHover(message.body);
  }
  return;
}

@end

@interface AppDelegate () {
  NSWindowController *_preferencesWindowController;
}

@property SWebView *webView;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
  [[self tableView] setDataSource:self];
  [[self tableView] setDelegate:self];
  [[self tableView] setAllowsTypeSelect:NO];
  NSSize spacing = [[self tableView] intercellSpacing];
  spacing.height = 10;
  [[self tableView] setIntercellSpacing:spacing];

  NSString *script = @"document.onmouseover = function (event) {"
    "var target = event.target; "
    "while (target) {"
      "if (target.href) {"
        "window.webkit.messageHandlers.mouseover.postMessage(target.href);"
        "return;"
      "}"
      "target = target.parentNode;"
    "}"
    "window.webkit.messageHandlers.mouseover.postMessage(null);"
  "}";
  WKUserScript *mouseoverScript = [[WKUserScript alloc] initWithSource:script
                                                         injectionTime:WKUserScriptInjectionTimeAtDocumentEnd
                                                      forMainFrameOnly:YES];
  WKUserContentController *contentController = [[WKUserContentController alloc] init];
  [contentController addUserScript:mouseoverScript];
  WebViewMouseOverHandler *messageHandler = [[WebViewMouseOverHandler alloc] init];
  [messageHandler setOnURLHover:^(id url) {
    NSString *urlString = (NSString *)url;
    if (urlString && url != [NSNull null]) {
      [[self urlText] setStringValue:urlString];
      [[self urlText] setHidden:NO];
    } else {
      if (![[self urlText] isHidden]) {
        [[self urlText] setHidden:YES];
        [[self webView] setNeedsDisplay:YES];
      }
    }
  }];
  [contentController addScriptMessageHandler:messageHandler name:@"mouseover"];
  WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
  configuration.userContentController = contentController;
  self.webView = [[SWebView alloc] initWithFrame:[[[self window] contentView] bounds] configuration:configuration];
  [[[self window] contentView] addSubview:self.webView];
  [[self webView] setNavigationDelegate:self];
  [[self webView] setUIDelegate:self];
  [[self webView] setHidden:YES];
  [[self webView] setTranslatesAutoresizingMaskIntoConstraints:NO];
  [[[self window] contentView] addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[webView]|"
                                                                                      options:NSLayoutFormatAlignAllTop
                                                                                      metrics:nil
                                                                                        views:@{@"webView": self.webView}]];
  [[[self window] contentView] addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[webView]|"
                                                                                      options:NSLayoutFormatAlignAllTop
                                                                                      metrics:nil
                                                                                        views:@{@"webView": self.webView}]];

  [self setUrlText:[[NSTextField alloc] init]];
  self.urlText = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 500, 21)];
  [[self urlText] setTranslatesAutoresizingMaskIntoConstraints:NO];
  [[self urlText] setEditable:NO];
  [[self urlText] setTextColor:[NSColor controlTextColor]];
  [[self urlText] setBackgroundColor:[NSColor controlBackgroundColor]];
  [self.webView addSubview:[self urlText]];
  [[[self window] contentView] addConstraint:[NSLayoutConstraint constraintWithItem:[self urlText]
                                                                          attribute:NSLayoutAttributeLeading
                                                                          relatedBy:NSLayoutRelationEqual
                                                                             toItem:[[self window] contentView]
                                                                          attribute:NSLayoutAttributeLeading
                                                                         multiplier:1
                                                                           constant:10]];
  [[[self window] contentView] addConstraint:[NSLayoutConstraint constraintWithItem:[self urlText]
                                                                          attribute:NSLayoutAttributeBottom
                                                                          relatedBy:NSLayoutRelationEqual
                                                                             toItem:[[self window] contentView]
                                                                          attribute:NSLayoutAttributeBottom
                                                                         multiplier:1
                                                                           constant:-10]];

  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(refresh:)
                                               name:REFRESH_NOTIFICATION
                                             object:nil];

  AccountPreferencesViewController *accountViewController = [[AccountPreferencesViewController alloc] initWithNibName:@"AccountPreferencesViewController"
                                                                                                               bundle:nil];

  NSString *title = NSLocalizedString(@"Preferences", @"Common title for Preferences window");
  _preferencesWindowController = [[MASPreferencesWindowController alloc] initWithViewControllers:@[accountViewController] title:title];

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
      [accountViewController setLoginStatus:LOGGING_IN];
      [accountViewController setBaseURL:accountDict[@"URL"]];
      [[ServiceHelper sharedInstance] loginWithBaseURL:[NSURL URLWithString:accountDict[@"URL"]]
                                             withToken:accountDict[@"token"]
                                                 retry:YES
                                               success:^(NSURLResponse *response, id responseObject) {
                                                 [accountViewController setLoginStatus:LOGGED_IN];
                                               } failure:^(NSHTTPURLResponse *response, NSError *error) {
                                                 [accountViewController setLoginStatus:LOGGED_OUT];
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
  LSLaunchURLSpec urlSpec = {(__bridge CFURLRef)[NSURL fileURLWithPath:@"/Applications/Safari.app"], (__bridge CFArrayRef)@[url], nil, kLSLaunchDontSwitch, nil};
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
  if (currentRow && [currentRow integerValue] >= 0) {
    [[self tableView] selectRowIndexes:[NSIndexSet indexSetWithIndex:[currentRow unsignedIntegerValue]] byExtendingSelection:NO];
  }
  [[AppUtils sharedInstance] updateBadge];
}

#pragma mark WebView

- (void)webView:(WKWebView *)webView decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler {
  decisionHandler(WKNavigationResponsePolicyAllow);
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
  NSURL *url = [[navigationAction request] URL];
  if ([[url absoluteString] isEqualToString:@"about:blank"]) {
    decisionHandler(WKNavigationActionPolicyAllow);
  } else {
    // iframe is included in this
    if ([navigationAction navigationType] == WKNavigationTypeOther) {
      decisionHandler(WKNavigationActionPolicyAllow);
      return;
    }

    decisionHandler(WKNavigationActionPolicyCancel);
    [self openInBrowserForURL:url];
  }
}

- (WKWebView *)webView:(WKWebView *)webView createWebViewWithConfiguration:(WKWebViewConfiguration *)configuration forNavigationAction:(WKNavigationAction *)navigationAction windowFeatures:(WKWindowFeatures *)windowFeatures {
  [self openInBrowserForURL:navigationAction.request.URL];
  return nil;
}

#pragma mark Table source and delegate

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
  return (NSInteger)[[[ServiceHelper sharedInstance] items] count];
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
  TheTableCellView *view = [tableView makeViewWithIdentifier:@"Items" owner:self];
  [view setAutoresizingMask:NSViewWidthSizable];
  if (row < 0) {
    return view;
  }
  NSUInteger urow = (NSUInteger)row;

  Item *item = [[ServiceHelper sharedInstance] getItemAt:urow];
  // title
  [[view textField] setStringValue:[item title]];

  // source
  [[view sourceField] setStringValue:[[ServiceHelper sharedInstance] getFeedNameOfItemAt:urow]];

  // favicon
  [[view imageView] setImage:[[ServiceHelper sharedInstance] getFaviconOfItemAt:urow]];

  [view setStarred:[item is_saved]];

  // detailed text
  NSString *html = [item html];
  NSRange r;
  int count = 0;
  while ((r = [html rangeOfString:@"<[^>]+>" options:NSRegularExpressionSearch]).location != NSNotFound) {
    html = [html stringByReplacingCharactersInRange:r withString:@""];
    count++;
    if (count >= 100) {
      break;
    }
  }
  NSString *text = [NSString string];
  count = 0;
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
  if (current < -1) {
    return;
  }
  NSUInteger index;
  if (current == -1) {
    index = [[[ServiceHelper sharedInstance] itemIds] count] - 1;
  } else {
    index = (NSUInteger)(current - 1);
  }
  [[self tableView] selectRowIndexes:[NSIndexSet indexSetWithIndex:index] byExtendingSelection:NO];
  [[self tableView] scrollRowToVisible:(NSInteger)index];
  if (webViewOpen) {
    [self loadWeb];
  }
}

- (IBAction)nextItem:(id)sender {
  NSInteger current = [[self tableView] selectedRow];
  if ((current + 1) >= (NSInteger)[[[ServiceHelper sharedInstance] itemIds] count]) {
    return;
  }
  [[self tableView] selectRowIndexes:[NSIndexSet indexSetWithIndex:(NSUInteger)(current + 1)] byExtendingSelection:NO];
  [[self tableView] scrollRowToVisible:(current + 1)];
  if (webViewOpen) {
    [self loadWeb];
  }
}

- (IBAction)openItem:(id)sender {
  if ([[self tableView] selectedRow] == -1) {
    return;
  }
  if (webViewOpen) {
    [[self webView] setHidden:YES];
    [[self webView] clear];
    webViewOpen = NO;
    [[self window] makeFirstResponder:[self tableView]];
  } else {
    [self loadWeb];
    [[self webView] setHidden:NO];
    webViewOpen = YES;
  }
}

- (void)loadWeb {
  NSInteger current = [[self tableView] selectedRow];
  if ([[self tableView] selectedRow] == -1) {
    return;
  }
  Item *item = [[ServiceHelper sharedInstance] getItemAt:(NSUInteger)current];
  [item setLocalRead:YES];
  [[AppUtils sharedInstance] updateBadge];
  [[self webView] setItem:item];
  [[self window] makeFirstResponder:[self webView]];
}

- (IBAction)openExternal:(id)sender {
  NSInteger current = [[self tableView] selectedRow];
  if (current == -1) {
    return;
  }
  NSString *urlString = [[[ServiceHelper sharedInstance] getItemAt:(NSUInteger)current] url];
  NSURL *url = [NSURL URLWithString:[urlString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]];
  [self openInBrowserForURL:url];
}

- (IBAction)stick:(id)sender {
  NSInteger row = [[self tableView] selectedRow];
  if (row >= 0) {
    NSUInteger urow = (NSUInteger)row;
    [[ServiceHelper sharedInstance] toggleSticked:urow];
    [[self tableView] reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:(NSUInteger)row] columnIndexes:[NSIndexSet indexSetWithIndex:0]];
  }
}

- (IBAction)goToTop:(id)sender {
  if ([[[ServiceHelper sharedInstance] itemIds] count] == 0) {
    return;
  }
  if (webViewOpen) {
    return;
  }
  [[self tableView] selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
  [[self tableView] scrollRowToVisible:0];
}

- (IBAction)markAllRead:(id)sender {
  if (webViewOpen) {
    [self openItem:nil];
  }
  [[ServiceHelper sharedInstance] markAllRead];
}

@end
