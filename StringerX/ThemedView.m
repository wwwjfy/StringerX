//
//  ThemedView.m
//  StringerX
//
//  Created by Tony on 7/10/18.
//  Copyright © 2018 Tony Wang. All rights reserved.
//

#import "ThemedView.h"

@implementation ThemedView

- (void)updateLayer {
  [[self layer] setBackgroundColor:[NSColor unemphasizedSelectedTextBackgroundColor].CGColor];
  [super updateLayer];
}

@end
