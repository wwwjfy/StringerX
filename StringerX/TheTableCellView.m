//
//  TheTableCellView.m
//  StringerX
//
//  Created by Tony Wang on 7/8/13.
//  Copyright (c) 2013 Tony Wang. All rights reserved.
//

#import "TheTableCellView.h"

@implementation TheTableCellView

- (void)setSticked:(BOOL)sticked {
  if (sticked) {
    [_stickIndicator setHidden:NO];
    [_stickIndicator setWantsLayer:YES];
    _stickIndicator.layer.cornerRadius = _stickIndicator.frame.size.width / 2;
    _stickIndicator.layer.masksToBounds = YES;
    [_stickIndicator.layer setBackgroundColor:[NSColor redColor].CGColor];
  } else {
    [_stickIndicator setHidden:YES];
  }
}

@end
