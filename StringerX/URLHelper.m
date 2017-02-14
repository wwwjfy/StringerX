//
//  URLHelper.m
//  StringerX
//
//  Created by Tony Wang on 8/14/13.
//  Copyright (c) 2013 Tony Wang. All rights reserved.
//

#import "URLHelper.h"
#import <AFNetworking.h>

@interface URLHelper () {
  NSString *token;
  AFHTTPSessionManager *sessionManager;
}

@end

@implementation URLHelper

+ (instancetype)sharedInstance {
  static URLHelper *instance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    instance = [[self alloc] init];
  });
  return instance;
}

- (void)setToken:(NSString *)newToken {
  token = newToken;
}

- (NSURL *)baseURL {
  return [sessionManager baseURL];
}

- (void)setBaseURL:(NSURL *)baseURL {
  NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
  sessionManager = [[AFHTTPSessionManager alloc] initWithBaseURL:baseURL sessionConfiguration:configuration];
//  [sessionManager setRequestSerializer:[[AFJSONRequestSerializer alloc] init]];
  [sessionManager setResponseSerializer:[[AFJSONResponseSerializer alloc] init]];
}

- (void)requestWithPath:(NSString *)path
                success:(void (^)(NSHTTPURLResponse *response, id responseObject))success
                failure:(void (^)(NSHTTPURLResponse *response, NSError *error))failure {
  if (!token) {
    NSLog(@"ERROR: login token is not set");
    return;
  }
  if (!sessionManager) {
    NSLog(@"ERROR: base url is not set");
    return;
  }
  [sessionManager GET:path parameters:@{@"api_key": token} progress:nil
              success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                success((NSHTTPURLResponse *)[task response], responseObject);
              }
              failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                failure((NSHTTPURLResponse *)[task response], error);
              }];
}

@end
