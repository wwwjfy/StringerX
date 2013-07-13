//
//  AppDelegate.m
//  StringerX
//
//  Created by Tony Wang on 6/30/13.
//  Copyright (c) 2013 Tony Wang. All rights reserved.
//

#import <WebKit/WebKit.h>
#import <AFNetworking.h>
#import "AppDelegate.h"
#import "TheTableCellView.h"

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
  
  [self getFeeds];
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
  if (webViewOpen) {
    [[self webView] setHidden:YES];
    webViewOpen = NO;
  } else {
    [[NSApplication sharedApplication] terminate:nil];
  }
}

#pragma mark Network

- (void)getFeeds {
  NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://209.141.59.135:5000/fever/?api_key=46eb2d35afa7e6c1855d68b68fd6a330&feeds"] cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:10];
  [[AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
    for (NSDictionary *feed in JSON[@"feeds"]) {
      [self feeds][feed[@"id"]] = feed[@"title"];
    };
    [self syncWithServer];
    [NSTimer scheduledTimerWithTimeInterval:300 target:self selector:@selector(syncWithServer) userInfo:nil repeats:YES];
  } failure:nil] start];
}

- (void)syncWithServer {
  NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://209.141.59.135:5000/fever/?api_key=46eb2d35afa7e6c1855d68b68fd6a330&items"] cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:10];
  [[AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
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
  } failure:nil] start];
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
  NSDictionary *query = @{@"ids": [[self itemIds] componentsJoinedByString:@","]};
  AFHTTPClient *client = [[AFHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:@"http://209.141.59.135:5000"]];
  [client postPath:@"/fever/?api_key=46eb2d35afa7e6c1855d68b68fd6a330&mark=item&as=read" parameters:query success:^(AFHTTPRequestOperation *operation, id responseObject) {
    [[self itemIds] removeAllObjects];
    [[self items] removeAllObjects];
    [self refresh];
  } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
    
  }];
}

@end
