//
//  ServiceHelper.h
//  StringerX
//
//  Created by Tony Wang on 8/17/13.
//  Copyright (c) 2013 Tony Wang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AFNetworking.h>
#import "Models.h"

@interface ServiceHelper : NSObject {
  int last_item_created_on;
  NSInteger currentRow;
  NSTimer *timer;
}

@property NSMutableDictionary *items;
@property NSMutableArray *itemIds;
@property NSMutableDictionary *feeds;

+ (instancetype)sharedInstance;
- (void)loginWithBaseURL:(NSURL *)url
               withToken:(NSString *)token
                   retry:(BOOL)retry
                 success:(void (^)(NSHTTPURLResponse *response, id responseObject))success
                 failure:(void (^)(NSHTTPURLResponse *response, NSError *error))failure;
- (void)markAllRead;
- (void)markAllReadExceptSticked;
- (void)setCurrentRow:(NSInteger)row;
- (Item *)getItemAt:(NSInteger)index;
- (NSString *)getFeedNameOfItemAt:(NSInteger)index;
- (NSImage *)getFaviconOfItemAt:(NSInteger)index;
- (void)toggleSticked:(NSInteger)row;

@end
