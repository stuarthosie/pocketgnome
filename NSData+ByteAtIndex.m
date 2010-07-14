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
	Byte b;
	char *bytes = malloc([self length]);
	[self getBytes:bytes];
	
	bytes += index;
	memcpy(&b, bytes, 1);
	bytes -= index;
	
	free(bytes);
	return b;
}

@end
