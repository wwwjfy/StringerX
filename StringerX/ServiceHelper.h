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

+ (instancetype)sharedInstance;
- (void)loginWithBaseURL:(NSURL *)url
               withToken:(NSString *)token
                   retry:(BOOL)retry
                 success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
                 failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;
- (void)getFeeds;
- (void)markAllRead;
- (void)setCurrentRow:(NSInteger)row;
- (NSMutableDictionary *)getItemAt:(NSInteger)index;

@end
