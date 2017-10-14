//
//  Models.h
//  StringerX
//
//  Created by Tony Wang on 2/14/17.
//  Copyright © 2017 Tony Wang. All rights reserved.
//

#import <Foundation/Foundation.h>

#pragma mark Favicon

@interface Favicon : NSObject

@property NSNumber *id;
@property NSString *data;
@property NSImage *image;

@end

#pragma mark Favicons

@interface Favicons : NSObject

@property NSArray *favicons;

@end

#pragma mark Feed

@interface Feed : NSObject

@property NSNumber *id;
@property NSString *title;
@property NSNumber *favicon_id;
@property Favicon *favicon;

@end

#pragma mark Feeds

@interface Feeds : NSObject

@property NSArray *feeds;

@end

#pragma mark Item

@interface Item : NSObject

@property NSNumber *id;
@property NSNumber *feed_id;
@property NSNumber *created_on_time;
@property BOOL is_read;
@property NSString *title;
@property NSString *html;
@property NSString *author;
@property NSString *url;
@property BOOL is_saved;
@property BOOL localRead;

@end

#pragma mark Items

@interface Items : NSObject

@property NSArray *items;

@end
