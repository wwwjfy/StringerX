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
#import <HTMLKit.h>

#import "ServiceHelper.h"
#import "Notifications.h"
#import "TheTableCellView.h"
#import "AccountPreferencesViewController.h"

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

@property WKWebView *webView;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
  [[self tableView] setDataSource:self];
  [[self tableView] setDelegate:self];
  [[self tableView] setAllowsTypeSelect:NO];
  NSSize spacing = [[self tableView] intercellSpacing];
  spacing.height = 10;
  [[self tableView] setIntercellSpacing:spacing];

  NSString *script = @"document.onmouseover = function (event) {window.webkit.messageHandlers.mouseover.postMessage(event.target.href)}";
  WKUserScript *mouseoverScript = [[WKUserScript alloc] initWithSource:script
                                                         injectionTime:WKUserScriptInjectionTimeAtDocumentEnd
                                                      forMainFrameOnly:YES];
  WKUserContentController *contentController = [[WKUserContentController alloc] init];
  [contentController addUserScript:mouseoverScript];
  WebViewMouseOverHandler *messageHandler = [[WebViewMouseOverHandler alloc] init];
  [messageHandler setOnURLHover:^(id url) {
    NSString *urlString = (NSString *)url;
    if (urlString) {
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
  self.webView = [[WKWebView alloc] initWithFrame:[[[self window] contentView] bounds] configuration:configuration];
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

- (void)webView:(WKWebView *)webView decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler {
  decisionHandler(WKNavigationResponsePolicyAllow);
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
  decisionHandler(WKNavigationActionPolicyAllow);
}

- (WKWebView *)webView:(WKWebView *)webView createWebViewWithConfiguration:(WKWebViewConfiguration *)configuration forNavigationAction:(WKNavigationAction *)navigationAction windowFeatures:(WKWindowFeatures *)windowFeatures {
  [self openInBrowserForURL:navigationAction.request.URL];
  return nil;
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
  if ([[self tableView] selectedRow] == -1) {
    return;
  }
  if (webViewOpen) {
    [[self webView] setHidden:YES];
//    [[self urlText] setHidden:YES];
    webViewOpen = NO;
    [[self window] makeFirstResponder:[self tableView]];
  } else {
    [self loadWeb];
    [[self webView] setHidden:NO];
    webViewOpen = YES;
  }
}

- (NSString *)preprocessHTML: (NSDictionary *)item {
    HTMLDocument *document = [HTMLDocument documentWithString:item[@"html"]];
    HTMLElement *css = [[HTMLElement alloc] initWithTagName:@"style" attributes:@{@"type": @"text/css"}];
    [css setTextContent:@"img {max-width: 100%; height: auto}</style>"];
    HTMLElement *title = [[HTMLElement alloc] initWithTagName:@"div" attributes:@{@"style": @"text-align: center"}];
    [title setInnerHTML:[NSString stringWithFormat:@"<h1>%@</h1>"
                            "<div style=\"color: gray\">%@</div>"
                            "<div style=\"color: gray\">%@</div>",
                         item[@"title"],
                         item[@"author"],
                         [NSDateFormatter localizedStringFromDate:[NSDate dateWithTimeIntervalSince1970:[item[@"created_on_time"] intValue]]
                                                        dateStyle:NSDateFormatterShortStyle
                                                        timeStyle:NSDateFormatterMediumStyle]]];
    HTMLElement *body = [[HTMLElement alloc] initWithTagName:@"div" attributes:@{@"style": @"max-width:1000px; margin: 0 auto;"}];
    [body setInnerHTML:[document.body innerHTML]];
    [document.body removeAllChildNodes];
    [document.body appendNodes:@[css, title, body]];
    return [document innerHTML];
}

- (void)loadWeb {
  if ([[self tableView] selectedRow] == -1) {
    return;
  }
  NSDictionary *item = [[ServiceHelper sharedInstance] items][[[ServiceHelper sharedInstance] itemIds][[[self tableView] selectedRow]]];
  [[self webView] loadHTMLString:[self preprocessHTML:item] baseURL:nil];
  [[self window] makeFirstResponder:[self webView]];
}

- (IBAction)openExternal:(id)sender {
  NSInteger current = [[self tableView] selectedRow];
  if (current == -1) {
    return;
  }
  NSString *urlString = [[ServiceHelper sharedInstance] items][[[ServiceHelper sharedInstance] itemIds][current]][@"url"];
  NSURL *url = [NSURL URLWithString:[urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
  [self openInBrowserForURL:url];
}

- (IBAction)markAllRead:(id)sender {
  if (webViewOpen) {
    [self openItem:nil];
  }
  [[ServiceHelper sharedInstance] markAllRead];
}

@end
