//
//  SWebView.h
//  StringerX
//
//  Created by Tony Wang on 25/11/18.
//  Copyright © 2018 Tony Wang. All rights reserved.
//

#import <WebKit/WebKit.h>
#import "Models.h"

NS_ASSUME_NONNULL_BEGIN

@interface SWebView : WKWebView

- (void)setItem:(Item *)item;

@end

NS_ASSUME_NONNULL_END
