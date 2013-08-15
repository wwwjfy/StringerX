//
//  URLHelper.m
//  StringerX
//
//  Created by Tony Wang on 8/14/13.
//  Copyright (c) 2013 Tony Wang. All rights reserved.
//

#import "URLHelper.h"

#import <AFJSONRequestOperation.h>

@interface StringerJSONRequestOperation : AFJSONRequestOperation

@end

@implementation StringerJSONRequestOperation

+ (BOOL)canProcessRequest:(NSURLRequest *)request {
  return YES;
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

- (void)setToken:(NSString *)token {
  _token = token;
}

- (void)setBaseURL:(NSURL *)baseURL {
  _client = [[AFHTTPClient alloc] initWithBaseURL:baseURL];
  [_client registerHTTPOperationClass:[StringerJSONRequestOperation class]];
}

- (void)requestWithPath:(NSString *)path
                success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
                failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure {
  if (!_token) {
    NSLog(@"ERROR: login token is not set");
    return;
  }
  if (!_client) {
    NSLog(@"ERROR: url is not set");
    return;
  }
  [_client postPath:path parameters:@{@"api_key": _token} success:success failure:failure];

}

@end
