//
//  AppUtils.h
//  StringerX
//
//  Created by Tony Wang on 3/4/17.
//  Copyright © 2017 Tony Wang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ServiceHelper.h"

@interface AppUtils : NSObject

+ (instancetype)sharedInstance;

- (void)updateBadge;

@end
