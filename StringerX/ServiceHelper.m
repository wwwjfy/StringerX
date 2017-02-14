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
@synthesize favicons;

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
    favicons = [NSMutableDictionary dictionary];
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
        [self loginWithBaseURL:nil withToken:nil retry:NO success:nil failure:nil];
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
                 success:(void (^)(NSHTTPURLResponse *response, id responseObject))success
                 failure:(void (^)(NSHTTPURLResponse *response, NSError *error))failure {
  if (!retry && nextAction != LOGIN && timer) {
    [timer invalidate];
    timer = nil;
  }
  if (retry) {
    if (!timer) {
      timer = [NSTimer scheduledTimerWithTimeInterval:300 target:self selector:@selector(nextCall) userInfo:nil repeats:YES];
      [timer setTolerance:30];
    }
    if (nextAction != LOGIN) {
      nextAction = LOGIN;
    }
  }
  if (url && token) {
    [[URLHelper sharedInstance] setBaseURL:url];
    [[URLHelper sharedInstance] setToken:token];
  }
  [[URLHelper sharedInstance] requestWithPath:@"fever/" success:^(NSHTTPURLResponse *response, id responseObject) {
    if (![responseObject isKindOfClass:[NSDictionary class]] || !responseObject[@"api_version"]) {
      failure(response, [NSError errorWithDomain:@"StringerX" code:0 userInfo:@{NSLocalizedDescriptionKey: @"API mismatch"}]);
      return;
    }
    if (![responseObject[@"auth"] intValue]) {
      failure(response, [NSError errorWithDomain:@"StringerX" code:0 userInfo:@{NSLocalizedDescriptionKey: @"Authentication failed"}]);
      return;
    }
    if (success) {
      success(response, responseObject);
    }
    [self getFeeds:^{
      [self getFavicons:^{
        [self syncUnreadItemIds];
        nextAction = SYNC;
      }];
    }];
  } failure:^(NSHTTPURLResponse *response, NSError *error) {
    if (failure) {
      failure(response, error);
    }
  }];
}

- (void)getFeeds:(void (^)())success {
  [[URLHelper sharedInstance] requestWithPath:@"fever/?feeds" success:^(NSHTTPURLResponse *response, id JSON) {
    for (NSDictionary *feed in JSON[@"feeds"]) {
      [self feeds][feed[@"id"]] = feed[@"title"];
    };
    if (success) {
      success();
    }
  } failure:^(NSHTTPURLResponse *response, NSError *error) {
    NSLog(@"Failed to get feeds: %@", [error localizedDescription]);
  }];
}

- (void)getFavicons:(void (^)())success {
  [[URLHelper sharedInstance] requestWithPath:@"fever/?favicons" success:^(NSHTTPURLResponse *response, id JSON) {
    for (NSDictionary *favicon in JSON[@"favicons"]) {
      NSData *faviconData = [NSData dataWithContentsOfURL:[NSURL URLWithString:[@"data:" stringByAppendingString:favicon[@"data"]]]];
      [self favicons][favicon[@"id"]] = [[NSImage alloc] initWithData:faviconData];
    };
    if (success) {
      success();
    }
  } failure:^(NSHTTPURLResponse *response, NSError *error) {
    NSLog(@"Failed to get favicons: %@", [error localizedDescription]);
  }];
}

- (void)syncUnreadItemIds {
  [[URLHelper sharedInstance] requestWithPath:@"fever/?unread_item_ids" success:^(NSHTTPURLResponse *response, id JSON) {
    NSString *unreadItemIds = JSON[@"unread_item_ids"];
    if (![unreadItemIds isEqualToString:@""]) {
      [self syncItemsWithIds:unreadItemIds];
    }
  } failure:nil];
}

- (void)syncItemsWithIds:(NSString *)unreadItemIds {
  long min = NSIntegerMax;
  for (NSString *item in [unreadItemIds componentsSeparatedByString:@","]) {
    if ([item intValue] < min) {
      min = [item intValue];
    }
  }
  NSString *urlWithItemIds = [NSString stringWithFormat:@"fever/?items&since_id=%ld", min-1];
  [[URLHelper sharedInstance] requestWithPath:urlWithItemIds success:^(NSHTTPURLResponse *response, id JSON) {
    NSArray *newItems = [JSON[@"items"] sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
      if (obj1[@"created_on_time"] > obj2[@"created_on_time"]) {
        // reversed because the sort function itself return ascending results
        return NSOrderedAscending;
      }
      return NSOrderedDescending;
    }];

    BOOL changed = NO;
    NSNumber *currentId;
    if (currentRow != -1 && [[self itemIds] count] >= (currentRow + 1)) {
      currentId = [self itemIds][currentRow];
    }
    [[self itemIds] removeAllObjects];
    [[self items] removeAllObjects];
    for (NSDictionary * item in newItems) {
      if ([item[@"is_read"] intValue] == 1) {
        continue;
      }
      [[self itemIds] addObject:item[@"id"]];
      [[self items] setObject:item forKey:item[@"id"]];
      changed = YES;
    }
    if (changed) {
      last_item_created_on = [newItems[0][@"created_on_time"] intValue];
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
  } failure:^(NSHTTPURLResponse *response, NSError *error) {
    NSLog(@"Failed to get items: %@", [error localizedDescription]);
  }];
}

- (void)markAllRead {
  [[URLHelper sharedInstance] requestWithPath:[NSString stringWithFormat:@"fever/?mark=group&as=read&id=0&before=%d", last_item_created_on + 1]
                                      success:^(NSHTTPURLResponse *response, id responseObject) {
                                        [[self itemIds] removeAllObjects];
                                        [[self items] removeAllObjects];
                                        [[NSNotificationCenter defaultCenter] postNotificationName:REFRESH_NOTIFICATION object:nil];
                                      } failure:^(NSHTTPURLResponse *response, NSError *error) {
                                        NSLog(@"Failed to mark all read: %@", [error localizedDescription]);
                                      }];
  currentRow = -1;
}

- (void)setCurrentRow:(NSInteger)row {
  currentRow = row;
}

- (NSMutableDictionary *)getItemAt:(NSInteger)index {
    return self.items[[self itemIds][index]];
}

- (NSString *)getFeedOfItemAt:(NSInteger)index {
  return self.feeds[[self getItemAt:index][@"feed_id"]];
}

- (NSImage *)getFaviconOfItemAt:(NSInteger)index {
  return self.favicons[[self getItemAt:index][@"feed_id"]];
}

@end
