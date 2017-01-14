//
//  HTMLText.h
//  HTMLKit
//
//  Created by Iska on 26/02/15.
//  Copyright (c) 2015 BrainCookie. All rights reserved.
//

#import "HTMLNode.h"

NS_ASSUME_NONNULL_BEGIN

/**
 A HTML Text node
 */
@interface HTMLText : HTMLNode

/** @brief The text string. */
@property (nonatomic, copy) NSMutableString *data;

/**
 Initializes a new HTML text node.

 @param data The text string.
 @return A new isntance of a HTML text node.
 */
- (instancetype)initWithData:(NSString *)data;

/**
 Appends the string to this text node.
 
 @param string The string to append.
 */
- (void)appendString:(NSString *)string;

@end

NS_ASSUME_NONNULL_END
