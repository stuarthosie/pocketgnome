//
//  NSData+ByteAtIndex.m
//  Pocket Gnome
//
//  Created by William LaFrance on 7/9/10.
//  Copyright 2010 Savory Software, LLC. All rights reserved.
//

#import "NSData+ByteAtIndex.h"


@implementation NSData (PPatherAdditions)

- (Byte) byteAtIndex:(NSUInteger)index {
	NSString *string = [NSString stringWithCString:[self bytes] encoding:NSASCIIStringEncoding];
	return [string characterAtIndex:index];
}

@end
