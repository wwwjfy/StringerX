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
        [self syncUnreadItemIds];
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
  [[URLHelper sharedInstance] requestWithPath:@"fever/" success:^(AFHTTPRequestOperation *operation, id responseObject) {
    if (![responseObject isKindOfClass:[NSDictionary class]] || !responseObject[@"api_version"]) {
      failure(operation, [NSError errorWithDomain:@"StringerX" code:0 userInfo:@{NSLocalizedDescriptionKey: @"API mismatch"}]);
      return;
    }
    if (![responseObject[@"auth"] intValue]) {
      failure(operation, [NSError errorWithDomain:@"StringerX" code:0 userInfo:@{NSLocalizedDescriptionKey: @"Authentication failed"}]);
      return;
    }
    if (success) {
      success(operation, responseObject);
    }
    [self getFeeds];
  } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
    if (failure) {
      failure(operation, error);
    }
  }];
}

- (void)getFeeds {
  [[URLHelper sharedInstance] requestWithPath:@"fever/?feeds" success:^(AFHTTPRequestOperation *operation, id JSON) {
    for (NSDictionary *feed in JSON[@"feeds"]) {
      [self feeds][feed[@"id"]] = feed[@"title"];
    };
    [self syncUnreadItemIds];
    nextAction = SYNC;
  } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
    NSLog(@"Failed to get feeds: %@", [error localizedDescription]);
  }];
}

- (void)syncUnreadItemIds {
  [[URLHelper sharedInstance] requestWithPath:@"fever/?unread_item_ids" success:^(AFHTTPRequestOperation *operation, id JSON) {
    NSString *unreadItemIds = JSON[@"unread_item_ids"];
    if (![unreadItemIds isEqualToString:@""]) {
      [self syncItemsWithIds:unreadItemIds];
    }
  } failure:nil];
}

- (void)syncItemsWithIds:(NSString *)unreadItemIds {
  NSString *urlWithItemIds = [NSString stringWithFormat:@"fever/?items&with_ids=%@", unreadItemIds];
  [[URLHelper sharedInstance] requestWithPath:urlWithItemIds success:^(AFHTTPRequestOperation *operation, id JSON) {
    NSArray *newItems = JSON[@"items"];
    BOOL changed = NO;
    NSNumber *currentId;
    if (currentRow != -1 && [[self itemIds] count] >= (currentRow + 1)) {
      currentId = [self itemIds][currentRow];
    }
    [[self itemIds] removeAllObjects];
    [[self items] removeAllObjects];
    for (NSDictionary * item in newItems) {
      [[self itemIds] addObject:item[@"id"]];
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
  [[URLHelper sharedInstance] requestWithPath:[NSString stringWithFormat:@"fever/?mark=group&as=read&id=0&before=%d", last_refreshed]
                                      success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                        [[self itemIds] removeAllObjects];
                                        [[self items] removeAllObjects];
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
