//
//  ServiceHelper.m
//  StringerX
//
//  Created by Tony Wang on 8/17/13.
//  Copyright (c) 2013 Tony Wang. All rights reserved.
//

#import "ServiceHelper.h"
#import "Notifications.h"
#import "URLHelper.h"

@implementation ServiceHelper

@synthesize items;
@synthesize itemIds;
@synthesize feeds;

+ (instancetype)sharedInstance {
  static ServiceHelper *instance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    instance = [[self alloc] init];
  });
  return instance;
}

- (id)init {
  if (self = [super init]) {
    items = [NSMutableDictionary dictionary];
    itemIds = [NSMutableArray array];
    feeds = [NSMutableDictionary dictionary];
    currentRow = -1;
  }
  return self;
}

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
    NSNumber *currentId;
    if (currentRow != -1 && [[self itemIds] count] >= (currentRow + 1)) {
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
      NSDictionary *userInfo = nil;
      if (currentRow != -1) {
        userInfo = @{@"currentRow": [NSNumber numberWithInteger:[[self itemIds] indexOfObject:currentId]]};
      }
      [[NSNotificationCenter defaultCenter] postNotificationName:REFRESH_NOTIFICATION
                                                          object:nil
                                                        userInfo:userInfo];
    }
    last_refreshed = [JSON[@"last_refreshed_on_time"] intValue];
  } failure:nil];
}

- (void)markAllRead {
  [[URLHelper sharedInstance] requestWithPath:[NSString stringWithFormat:@"/fever/?mark=group&as=read&id=1&before=%d", last_refreshed]
                                      success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                        [[[ServiceHelper sharedInstance] itemIds] removeAllObjects];
                                        [[[ServiceHelper sharedInstance] items] removeAllObjects];
                                        [[NSNotificationCenter defaultCenter] postNotificationName:REFRESH_NOTIFICATION object:nil];
                                      }
                                      failure:nil];
  currentRow = -1;
}

- (void)setCurrentRow:(NSInteger)row {
  currentRow = row;
}

@end
