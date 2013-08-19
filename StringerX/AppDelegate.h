//
//  AppDelegate.h
//  StringerX
//
//  Created by Tony Wang on 6/30/13.
//  Copyright (c) 2013 Tony Wang. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

@interface AppDelegate : NSObject <NSApplicationDelegate, NSTableViewDataSource, NSTableViewDelegate> {
  BOOL webViewOpen;
  int last_refreshed;
}

@property (weak) IBOutlet NSTableView *tableView;
@property (assign) IBOutlet NSWindow *window;
@property (weak) IBOutlet WebView *webView;
@property (weak) IBOutlet NSTextField *urlText;
- (IBAction)prevItem:(id)sender;
- (IBAction)nextItem:(id)sender;
- (IBAction)openItem:(id)sender;
- (IBAction)openExternal:(id)sender;
- (IBAction)markAllRead:(id)sender;
- (IBAction)onClose:(id)sender;
- (IBAction)onPreferences:(id)sender;

@end
