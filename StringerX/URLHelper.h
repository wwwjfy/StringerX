//
//  URLHelper.h
//  StringerX
//
//  Created by Tony Wang on 8/14/13.
//  Copyright (c) 2013 Tony Wang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AFNetworking.h>

@interface URLHelper : NSObject

+ (instancetype)sharedInstance;
- (void)setToken:(NSString *)token;
- (NSURL *)baseURL;
- (void)setBaseURL:(NSURL *)baseURL;
- (void)requestWithPath:(NSString *)path
                success:(void (^)(NSHTTPURLResponse *response, id responseObject))success
                failure:(void (^)(NSHTTPURLResponse *response, NSError *error))failure;

@end
