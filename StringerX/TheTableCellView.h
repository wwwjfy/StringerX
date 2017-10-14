//
//  TheTableCellView.h
//  StringerX
//
//  Created by Tony Wang on 7/8/13.
//  Copyright (c) 2013 Tony Wang. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface TheTableCellView : NSTableCellView

@property (weak) IBOutlet NSTextField *sourceField;
@property (weak) IBOutlet NSTextField *detailedText;
@property (weak) IBOutlet NSView *starredIndicator;

- (void)setStarred:(BOOL)starred;

@end
