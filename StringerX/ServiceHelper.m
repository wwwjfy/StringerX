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

typedef enum {
  NONE,
  LOGIN,
  SYNC
} ACTION;

@interface ServiceHelper () {
  ACTION nextAction;
}

@end

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

- (void)nextCall {
  switch (nextAction) {
    case NONE:
      break;

    case LOGIN:
      {
        [self loginWithBaseURL:nil withToken:nil retry:NO success:^(AFHTTPRequestOperation *operation, id responseObject) {
          [self getFeeds];
        } failure:nil];
      }
      break;

    case SYNC:
      {
        [self syncWithServer];
      }
      break;
  }
}

- (void)loginWithBaseURL:(NSURL *)url
               withToken:(NSString *)token
                   retry:(BOOL)retry
                 success:(void (^)(AFHTTPRequestOperation *, id))success
                 failure:(void (^)(AFHTTPRequestOperation *, NSError *))failure {
  if (!retry && nextAction != LOGIN && timer) {
    [timer invalidate];
    timer = nil;
  }
  if (retry) {
    if (!timer) {
      timer = [NSTimer scheduledTimerWithTimeInterval:300 target:self selector:@selector(nextCall) userInfo:nil repeats:YES];
    }
    if (nextAction != LOGIN) {
      nextAction = LOGIN;
    }
  }
  if (url && token) {
    [[URLHelper sharedInstance] setBaseURL:url];
    [[URLHelper sharedInstance] setToken:token];
  }
  [[URLHelper sharedInstance] requestWithPath:@"/fever/" success:^(AFHTTPRequestOperation *operation, id responseObject) {
    success(operation, responseObject);
    [self getFeeds];
  } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
    failure(operation, error);
  }];
}

- (void)getFeeds {
  [[URLHelper sharedInstance] requestWithPath:@"/fever/?feeds" success:^(AFHTTPRequestOperation *operation, id JSON) {
    for (NSDictionary *feed in JSON[@"feeds"]) {
      [self feeds][feed[@"id"]] = feed[@"title"];
    };
    [self syncWithServer];
    nextAction = SYNC;
  } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
    NSLog(@"Failed to get feeds: %@", [error localizedDescription]);
  }];
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
        NSUInteger row = [[self itemIds] indexOfObject:currentId];
        if (row != NSNotFound) {
          userInfo = @{@"currentRow": [NSNumber numberWithUnsignedInteger:row]};
        }
      }
      [[NSNotificationCenter defaultCenter] postNotificationName:REFRESH_NOTIFICATION
                                                          object:nil
                                                        userInfo:userInfo];
    }
    last_refreshed = [JSON[@"last_refreshed_on_time"] intValue];
  } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
    NSLog(@"Failed to get items: %@", [error localizedDescription]);
  }];
}

- (void)markAllRead {
  [[URLHelper sharedInstance] requestWithPath:[NSString stringWithFormat:@"/fever/?mark=group&as=read&id=1&before=%d", last_refreshed]
                                      success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                        [[[ServiceHelper sharedInstance] itemIds] removeAllObjects];
                                        [[[ServiceHelper sharedInstance] items] removeAllObjects];
                                        [[NSNotificationCenter defaultCenter] postNotificationName:REFRESH_NOTIFICATION object:nil];
                                      } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                        NSLog(@"Failed to mark all read: %@", [error localizedDescription]);
                                      }];
  currentRow = -1;
}

- (void)setCurrentRow:(NSInteger)row {
  currentRow = row;
}

@end
