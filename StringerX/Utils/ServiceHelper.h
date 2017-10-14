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
}

@property NSMutableDictionary<NSNumber *, Item *> *items;
@property NSMutableArray<NSNumber *> *itemIds;
@property NSMutableDictionary<NSNumber *, Feed *> *feeds;

+ (instancetype)sharedInstance;
- (void)loginWithBaseURL:(NSURL *)url
               withToken:(NSString *)token
                   retry:(BOOL)retry
                 success:(void (^)(NSHTTPURLResponse *response, id responseObject))success
                 failure:(void (^)(NSHTTPURLResponse *response, NSError *error))failure;
- (void)markAllRead;
- (void)setCurrentRow:(NSInteger)row;
- (Item *)getItemAt:(NSUInteger)index;
- (NSString *)getFeedNameOfItemAt:(NSUInteger)index;
- (NSImage *)getFaviconOfItemAt:(NSUInteger)index;
- (void)toggleSticked:(NSUInteger)row;

@end
