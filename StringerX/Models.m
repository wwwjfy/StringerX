//
//  Models.m
//  StringerX
//
//  Created by Tony Wang on 2/14/17.
//  Copyright © 2017 Tony Wang. All rights reserved.
//

#import "Models.h"

@implementation Favicon
@end

@implementation Favicons

+ (NSDictionary *)modelContainerPropertyGenericClass {
  return @{@"favicons": [Favicon class]};
}

@end

@implementation Feed
@end

@implementation Feeds

+ (NSDictionary *)modelContainerPropertyGenericClass {
  return @{@"feeds": [Feed class]};
}

@end

@implementation Item
@end

@implementation Items

+ (NSDictionary *)modelContainerPropertyGenericClass {
  return @{@"items": [Item class]};
}

@end
