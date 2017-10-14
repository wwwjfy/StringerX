//
//  TheTableCellView.m
//  StringerX
//
//  Created by Tony Wang on 7/8/13.
//  Copyright (c) 2013 Tony Wang. All rights reserved.
//

#import "TheTableCellView.h"

@implementation TheTableCellView

- (void)setStarred:(BOOL)starred {
  if (starred) {
    [_starredIndicator setHidden:NO];
    [_starredIndicator setWantsLayer:YES];
    _starredIndicator.layer.cornerRadius = _starredIndicator.frame.size.width / 2;
    _starredIndicator.layer.masksToBounds = YES;
    [_starredIndicator.layer setBackgroundColor:[NSColor redColor].CGColor];
  } else {
    [_starredIndicator setHidden:YES];
  }
}

@end
