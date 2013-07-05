//
//  AppDelegate.h
//  Stringer
//
//  Created by Tony Wang on 6/30/13.
//  Copyright (c) 2013 Tony Wang. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate, NSTableViewDataSource, NSTableViewDelegate>

@property NSMutableDictionary *items;
@property NSMutableArray *itemIds;
@property (weak) IBOutlet NSTableView *tableView;
@property (assign) IBOutlet NSWindow *window;
@property (weak) IBOutlet WebView *webView;
- (IBAction)prevItem:(id)sender;
- (IBAction)nextItem:(id)sender;
- (IBAction)openItem:(id)sender;
- (IBAction)openExternal:(id)sender;
- (IBAction)markAllRead:(id)sender;

@end
