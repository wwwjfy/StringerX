//
//  AppDelegate.m
//  Stringer
//
//  Created by Tony Wang on 6/30/13.
//  Copyright (c) 2013 Tony Wang. All rights reserved.
//

#import <WebKit/WebKit.h>
#import <AFNetworking.h>
#import "AppDelegate.h"

@implementation AppDelegate

@synthesize items;
@synthesize itemIds;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
  [[self tableView] setDataSource:self];
  [[self tableView] setDelegate:self];
  [[self tableView] setAllowsTypeSelect:NO];
  items = [NSMutableDictionary dictionary];
  itemIds = [NSMutableArray array];
  
  [self syncWithServer];
  [NSTimer scheduledTimerWithTimeInterval:300 target:self selector:@selector(syncWithServer) userInfo:nil repeats:YES];
}

- (void)syncWithServer {
  NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://209.141.59.135:5000/fever/?api_key=46eb2d35afa7e6c1855d68b68fd6a330&items"]];
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

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
  return [[self items] count];
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
  NSTableCellView *view = [tableView makeViewWithIdentifier:@"Items" owner:self];
  [[view textField] setStringValue:[self items][[self itemIds][row]][@"title"]];
  return view;
}

- (IBAction)prevItem:(id)sender {
  NSInteger current = [[self tableView] selectedRow];
  if (current == -1) {
    return;
  }
  [[self tableView] selectRowIndexes:[NSIndexSet indexSetWithIndex:(current - 1)] byExtendingSelection:NO];
}

- (IBAction)nextItem:(id)sender {
  NSInteger current = [[self tableView] selectedRow];
  [[self tableView] selectRowIndexes:[NSIndexSet indexSetWithIndex:(current + 1)] byExtendingSelection:NO];
}

- (IBAction)openItem:(id)sender {

}

- (IBAction)openExternal:(id)sender {
  NSInteger current = [[self tableView] selectedRow];
  [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[self items][[self itemIds][current]][@"url"]]];
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
