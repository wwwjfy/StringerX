//
//  ServiceHelper.h
//  StringerX
//
//  Created by Tony Wang on 8/17/13.
//  Copyright (c) 2013 Tony Wang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ServiceHelper : NSObject {
  int last_refreshed;
  NSInteger currentRow;
}

@property NSMutableDictionary *items;
@property NSMutableArray *itemIds;
@property NSMutableDictionary *feeds;

+ (instancetype)sharedInstance;
- (void)getFeeds;
- (void)markAllRead;
- (void)setCurrentRow:(NSInteger)row;

@end
