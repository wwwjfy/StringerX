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
#import <YYModel.h>

typedef enum {
  NONE,
  LOGIN,
  SYNC
} SACTION;

@interface ServiceHelper () {
  SACTION nextAction;
  NSTimer *timer;
  NSUInteger counter; // sync feed every 10 timer-triggers
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
      [self loginWithBaseURL:nil withToken:nil retry:NO success:nil failure:nil];
      break;
    case SYNC:
      [self syncUnreadItemIds];
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
      counter = 0;
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
        self->nextAction = SYNC;
      }];
    }];
  } failure:^(NSHTTPURLResponse *response, NSError *error) {
    if (failure) {
      failure(response, error);
    }
  }];
}

- (void)getFeeds:(void (^)(void))success {
  [[URLHelper sharedInstance] requestWithPath:@"fever/?feeds" success:^(NSHTTPURLResponse *response, id JSON) {
    for (Feed *feed in [[Feeds yy_modelWithJSON:JSON] feeds]) {
      Feed *oldFeed = [self feeds][feed.id];
      if (oldFeed) {
        [feed setFavicon:[oldFeed favicon]];
      }
      [self feeds][feed.id] = feed;
    };
    if (success) {
      success();
    }
  } failure:^(NSHTTPURLResponse *response, NSError *error) {
    NSLog(@"Failed to get feeds: %@", [error localizedDescription]);
  }];
}

- (void)getFavicons:(void (^)(void))success {
  [[URLHelper sharedInstance] requestWithPath:@"fever/?favicons" success:^(NSHTTPURLResponse *response, id JSON) {
    NSMutableDictionary *favicons = [NSMutableDictionary dictionary];
    for (Favicon *favicon in [[Favicons yy_modelWithJSON:JSON] favicons]) {
      if (![favicon data]) {
        continue;
      }
      NSData *faviconData = [NSData dataWithContentsOfURL:[NSURL URLWithString:[@"data:" stringByAppendingString:[favicon data]]]];
      [favicon setImage:[[NSImage alloc] initWithData:faviconData]];
      favicons[favicon.id] = favicon;
    }
    for (Feed *feed in [[self feeds] allValues]) {
      [feed setFavicon:favicons[feed.favicon_id]];
    }
    if (success) {
      success();
    }
  } failure:^(NSHTTPURLResponse *response, NSError *error) {
    NSLog(@"Failed to get favicons: %@", [error localizedDescription]);
  }];
}

- (void)syncUnreadItemIds {
  [[URLHelper sharedInstance] requestWithPath:@"fever/?unread_item_ids" success:^(NSHTTPURLResponse *responseUnread, id JSONUnread) {
    NSString *unreadItemIds = JSONUnread[@"unread_item_ids"];
    [[URLHelper sharedInstance] requestWithPath:@"fever/?saved_item_ids" success:^(NSHTTPURLResponse *responseSaved, id JSONSaved) {
      NSString *savedItemIds = JSONSaved[@"saved_item_ids"];
      [self syncItemsWithIds:[@[unreadItemIds, savedItemIds] componentsJoinedByString:@","]];
    } failure:nil];
  } failure:nil];
  counter++;
  if (counter % 10 == 0) {
    counter = 0;
    [self getFeeds:^{
      [self getFavicons:nil];
    }];
  }
}

- (void)syncItemsWithIds:(NSString *)newItemIds {
  NSString *urlWithItemIds = [NSString stringWithFormat:@"fever/?items&with_ids=%@", newItemIds];
  [[URLHelper sharedInstance] requestWithPath:urlWithItemIds success:^(NSHTTPURLResponse *response, id JSON) {
    NSArray *newItems = [[Items yy_modelWithJSON:JSON].items sortedArrayUsingComparator:^NSComparisonResult(Item *obj1, Item *obj2) {
      if ([obj1 created_on_time] > [obj2 created_on_time]) {
        // reversed because the sort function itself return ascending results
        return NSOrderedAscending;
      }
      return NSOrderedDescending;
    }];
    [self updateItems:newItems];
  } failure:^(NSHTTPURLResponse *response, NSError *error) {
    NSLog(@"Failed to get items: %@", [error localizedDescription]);
  }];
}

- (void)updateItems:(NSArray *)newItems {
  BOOL changed = NO;
  NSNumber *currentId;
  if (currentRow != -1 && [[self itemIds] count] >= (currentRow + 1)) {
    currentId = [self itemIds][(NSUInteger)currentRow];
  }
  if ([[self itemIds] count] > 0) {
    changed = YES;
  }
  NSMutableDictionary<NSNumber *, Item *> *oldItems = [self items];
  [[self itemIds] removeAllObjects];
  self.items = [NSMutableDictionary dictionary];
  for (Item *item in newItems) {
    Item *oldItem = oldItems[[item id]];
    if (oldItem) {
      [item setLocalRead:[oldItem localRead] || [item is_read]];
    } else {
      [item setLocalRead: [item is_read]];
    }
    [[self itemIds] addObject:[item id]];
    [self items][[item id]] = item;
    changed = YES;
  }
  if (changed) {
    if ([newItems count] > 0) {
      last_item_created_on = [[newItems[0] created_on_time] intValue];
    }
    NSDictionary *userInfo = nil;
    if (currentRow != -1) {
      NSUInteger row = [[self itemIds] indexOfObject:currentId];
      if (row != NSNotFound) {
        userInfo = @{@"currentRow": [NSNumber numberWithUnsignedInteger:row]};
      }
    } else {
      currentRow = -1;
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:REFRESH_NOTIFICATION
                                                        object:nil
                                                      userInfo:userInfo];
  }

}

- (void)markAllRead {
  NSNumber *currentId;
  if (currentRow != -1 && [[self itemIds] count] >= (currentRow + 1)) {
    currentId = [self itemIds][(NSUInteger)currentRow];
  }
  [[URLHelper sharedInstance] requestWithPath:[NSString stringWithFormat:@"fever/?mark=group&as=read&id=0&before=%d", last_item_created_on + 1]
                                      success:^(NSHTTPURLResponse *response, id responseObject) {
                                        NSMutableDictionary<NSNumber *, Item *> *newItems = [[NSMutableDictionary alloc] init];
                                        NSMutableArray<NSNumber *> *newItemIds = [[NSMutableArray alloc] init];
                                        for (NSNumber *itemId in self->itemIds) {
                                          if ([self items][itemId].is_saved) {
                                            [newItemIds addObject:itemId];
                                            newItems[itemId] = [self items][itemId];
                                          }
                                        }
                                        self.itemIds = newItemIds;
                                        self.items = newItems;
                                        NSDictionary *userInfo;
                                        if (currentId) {
                                          NSUInteger row = [[self itemIds] indexOfObject:currentId];
                                          if (row != NSNotFound) {
                                            userInfo = @{@"currentRow": [NSNumber numberWithUnsignedInteger:row]};
                                          }
                                        }
                                        [[NSNotificationCenter defaultCenter] postNotificationName:REFRESH_NOTIFICATION object:nil userInfo:userInfo];
                                      } failure:^(NSHTTPURLResponse *response, NSError *error) {
                                        NSLog(@"Failed to mark all read: %@", [error localizedDescription]);
                                      }];
  currentRow = -1;
}

- (void)setCurrentRow:(NSInteger)row {
  currentRow = row;
}

- (void)toggleSticked:(NSUInteger)row {
  Item *item = [self getItemAt:row];
  NSString *action = [item is_saved] ? @"unsaved" : @"saved";
  BOOL was_saved = item.is_saved;
  item.is_saved = !was_saved;
  [[URLHelper sharedInstance] requestWithPath:[NSString stringWithFormat:@"fever/?mark=item&as=%@&id=%@", action, [item id]]
                                      success:nil failure:^(NSHTTPURLResponse *response, NSError *error) {
                                        item.is_saved = was_saved;
                                      }];
}

- (Item *)getItemAt:(NSUInteger)index {
    return self.items[[self itemIds][index]];
}

- (NSString *)getFeedNameOfItemAt:(NSUInteger)index {
  return [self.feeds[[[self getItemAt:index] feed_id]] title];
}

- (NSImage *)getFaviconOfItemAt:(NSUInteger)index {
  return [[(Feed *)self.feeds[[[self getItemAt:index] feed_id]] favicon] image];
}

@end
