//
//  AppUtils.m
//  StringerX
//
//  Created by Tony Wang on 3/4/17.
//  Copyright © 2017 Tony Wang. All rights reserved.
//

#import "AppUtils.h"

@implementation AppUtils

+ (instancetype)sharedInstance {
  static AppUtils *instance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    instance = [[self alloc] init];
  });
  return instance;
}

- (void)updateBadge {
  NSUInteger unreadCount = 0;
  for (Item *item in [[[ServiceHelper sharedInstance] items] allValues]) {
    if (![item localRead]) {
      unreadCount++;
    }
  }
  if (unreadCount > 0) {
    [[[NSApplication sharedApplication] dockTile] setBadgeLabel:[NSString stringWithFormat:@"%lu", unreadCount]];
  } else {
    [[[NSApplication sharedApplication] dockTile] setBadgeLabel:@""];
  }
}

@end
