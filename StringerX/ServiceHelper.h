//
//  ServiceHelper.h
//  StringerX
//
//  Created by Tony Wang on 8/17/13.
//  Copyright (c) 2013 Tony Wang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AFNetworking.h>

@interface ServiceHelper : NSObject {
  int last_item_created_on;
  NSInteger currentRow;
  NSTimer *timer;
}

@property NSMutableDictionary *items;
@property NSMutableArray *itemIds;
@property NSMutableDictionary *feeds;
@property NSMutableDictionary *favicons;

+ (instancetype)sharedInstance;
- (void)loginWithBaseURL:(NSURL *)url
               withToken:(NSString *)token
                   retry:(BOOL)retry
                 success:(void (^)(NSHTTPURLResponse *response, id responseObject))success
                 failure:(void (^)(NSHTTPURLResponse *response, NSError *error))failure;
- (void)markAllRead;
- (void)setCurrentRow:(NSInteger)row;
- (NSMutableDictionary *)getItemAt:(NSInteger)index;
- (NSString *)getFeedOfItemAt:(NSInteger)index;
- (NSImage *)getFaviconOfItemAt:(NSInteger)index;

@end
