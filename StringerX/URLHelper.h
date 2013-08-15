//
//  URLHelper.h
//  StringerX
//
//  Created by Tony Wang on 8/14/13.
//  Copyright (c) 2013 Tony Wang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AFNetworking.h>

@interface URLHelper : NSObject {
  NSString *_token;
  AFHTTPClient *_client;
}

+ (instancetype)sharedInstance;
- (void)setToken:(NSString *)token;
- (void)setBaseURL:(NSURL *)baseURL;
- (void)requestWithPath:(NSString *)path
                success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
                failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;

@end
