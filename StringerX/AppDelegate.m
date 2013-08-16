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

#import "URLHelper.h"
#import "TheTableCellView.h"
#import "AccountPreferencesViewController.h"

@interface AppDelegate () {
  NSWindowController *_preferencesWindowController;
}

@end

@implementation AppDelegate

@synthesize items;
@synthesize itemIds;
@synthesize feeds;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
  [[self tableView] setDataSource:self];
  [[self tableView] setDelegate:self];
  [[self tableView] setAllowsTypeSelect:NO];
  items = [NSMutableDictionary dictionary];
  itemIds = [NSMutableArray array];
  feeds = [NSMutableDictionary dictionary];
  [[self webView] setHidden:YES];
  [[self webView] setPolicyDelegate:self];
  
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
      [self getFeeds];
      return;
    }
  }
  [self onPreferences:nil];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
  return YES;
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
  if (!_preferencesWindowController) {
    NSViewController *accountViewController = [[AccountPreferencesViewController alloc] init];
    NSArray *controllers = @[accountViewController];

    NSString *title = NSLocalizedString(@"Preferences", @"Common title for Preferences window");
    _preferencesWindowController = [[MASPreferencesWindowController alloc] initWithViewControllers:controllers title:title];
  }
  [_preferencesWindowController showWindow:nil];
}

#pragma mark Network

- (void)getFeeds {
  [[URLHelper sharedInstance] requestWithPath:@"/fever/?feeds" success:^(AFHTTPRequestOperation *operation, id JSON) {
    for (NSDictionary *feed in JSON[@"feeds"]) {
      [self feeds][feed[@"id"]] = feed[@"title"];
    };
    [self syncWithServer];
    [NSTimer scheduledTimerWithTimeInterval:300 target:self selector:@selector(syncWithServer) userInfo:nil repeats:YES];
  } failure:nil];
}

- (void)syncWithServer {
  [[URLHelper sharedInstance] requestWithPath:@"/fever/?items" success:^(AFHTTPRequestOperation *operation, id JSON) {
    NSArray *newItems = JSON[@"items"];
    BOOL changed = NO;
    NSInteger currentRow = [[self tableView] selectedRow];
    NSNumber *currentId;
    if (currentRow != -1) {
      currentId = [self itemIds][currentRow];
    }
    for (NSDictionary * item in newItems) {
      if ([[self itemIds] containsObject:item[@"id"]]) {
        continue;
      }
      if ([[self itemIds] count] == 0) {
        [[self itemIds] addObject:item[@"id"]];
      } else {
        for (int i = 0; i < [[self itemIds] count]; i++) {
          if ([self items][[self itemIds][i]][@"created_on_time"] < item[@"created_on_time"]) {
            [[self itemIds] insertObject:item[@"id"] atIndex:i];
            break;
          }
          if (i == ([[self itemIds] count] - 1)) {
            [[self itemIds] addObject:item[@"id"]];
            break;
          }
        }
      }
      [[self items] setObject:item forKey:item[@"id"]];
      changed = YES;
    }
    if (changed) {
      [self refresh];
      if (currentRow != -1) {
        [[self tableView] selectRowIndexes:[NSIndexSet indexSetWithIndex:[[self itemIds] indexOfObject:currentId]] byExtendingSelection:NO];
      }
    }
    last_refreshed = [JSON[@"last_refreshed_on_time"] intValue];
  } failure:nil];
}

- (void)refresh {
  [[self tableView] reloadData];
  if ([[self items] count] > 0) {
    [[[NSApplication sharedApplication] dockTile] setBadgeLabel:[NSString stringWithFormat:@"%lu", [[self items] count]]];
  } else {
    [[[NSApplication sharedApplication] dockTile] setBadgeLabel:@""];
  }
}

#pragma mark Table source and delegate

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
  return [[self items] count];
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
  TheTableCellView *view = [tableView makeViewWithIdentifier:@"Items" owner:self];
  [view setAutoresizingMask:NSViewWidthSizable];
  
  // title
  [[view textField] setStringValue:[self items][[self itemIds][row]][@"title"]];
  
  // source
  [[view sourceField] setStringValue:[self feeds][[self items][[self itemIds][row]][@"feed_id"]]];
  
  // detailed text
  NSString *html = [self items][[self itemIds][row]][@"html"];
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

#pragma mark Item operations

- (IBAction)nextItem:(id)sender {
  NSInteger current = [[self tableView] selectedRow];
  if ((current + 1) >= (NSInteger)[[self itemIds] count]) {
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
  NSDictionary *item = [self items][[self itemIds][[[self tableView] selectedRow]]];
  NSString *html = [NSString stringWithFormat:@"<h1>%@</h1><div style=\"max-width:800px; margin\">%@</div>",
                    item[@"title"],
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
  NSURL *url = [NSURL URLWithString:[self items][[self itemIds][current]][@"url"]];
  [self openInBrowserForURL:url];
}

- (IBAction)markAllRead:(id)sender {
  [[URLHelper sharedInstance] requestWithPath:[NSString stringWithFormat:@"/fever/?mark=group&as=read&id=1&before=%d", last_refreshed]
                                      success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                        [[self itemIds] removeAllObjects];
                                        [[self items] removeAllObjects];
                                        [self refresh];
                                      }
                                      failure:nil];
}

@end
