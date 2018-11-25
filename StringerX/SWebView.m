//
//  SWebView.m
//  StringerX
//
//  Created by Tony Wang on 25/11/18.
//  Copyright © 2018 Tony Wang. All rights reserved.
//

#import "SWebView.h"
#import <HTMLKit.h>

@interface SWebView () {
  Item *_item;
}

@end

@implementation SWebView

- (Item *)item {
  return self->_item;
}

- (void)setItem:(Item *)anItem {
  self->_item = anItem;
  [self loadPage];
}

- (void)loadPage {
  if (![self item]) {
    return;
  }
  HTMLDocument *document = [HTMLDocument documentWithString:[[self item] html]];
  HTMLElement *cssNode = [[HTMLElement alloc] initWithTagName:@"style" attributes:@{@"type": @"text/css"}];
  NSString *css = @"img {max-width: 100%; height: auto; display: block; margin: 0 auto;}";
  if ([self isDark]) {
    css = [css stringByAppendingString:@"body {color: #eee; background-color: #333} a:link {color: #37abc8}</style>"];
  }
  [cssNode setTextContent:css];
  HTMLElement *title = [[HTMLElement alloc] initWithTagName:@"div" attributes:@{@"style": @"text-align: center;"}];
  [title setInnerHTML:[NSString stringWithFormat:@"<h1>%@</h1>"
                       "<div style=\"color: gray\">%@</div>"
                       "<div style=\"color: gray\">%@</div>",
                       [[self item] title],
                       [[self item] author],
                       [NSDateFormatter localizedStringFromDate:[NSDate dateWithTimeIntervalSince1970:[[[self item] created_on_time] intValue]]
                                                      dateStyle:NSDateFormatterShortStyle
                                                      timeStyle:NSDateFormatterMediumStyle]]];
  HTMLElement *body = [[HTMLElement alloc] initWithTagName:@"div" attributes:@{@"style": @"max-width:1000px; margin: 0 auto;"}];
  [body setInnerHTML:[document.body innerHTML]];
  [document.body removeAllChildNodes];
  [document.body appendNodes:@[cssNode, title, body]];

  [self loadHTMLString:[document innerHTML] baseURL:nil];
}

- (BOOL)isDark {
  if ([[[self effectiveAppearance] bestMatchFromAppearancesWithNames:@[NSAppearanceNameAqua, NSAppearanceNameDarkAqua]] isEqualToString:NSAppearanceNameDarkAqua]) {
    return YES;
  }
  return NO;
}

- (void)viewDidChangeEffectiveAppearance {
  [self loadPage];
  [super viewDidChangeEffectiveAppearance];
}

@end
