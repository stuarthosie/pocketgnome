//
//  NSData+ByteAtIndex.h
//  Pocket Gnome
//
//  Created by William LaFrance on 7/9/10.
//  Copyright 2010 Savory Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSData (PPatherAdditions)

/**
 * Returns the byte at a certain index. Durr. Binary safe.
 */
- (Byte) byteAtIndex:(NSUInteger)index;

@end
