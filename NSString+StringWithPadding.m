//
//  NSString+StringWithPadding.m
//  Pocket Gnome
//
//  Created by William LaFrance on 7/13/10.
//  Copyright 2010 Savory Software, LLC. All rights reserved.
//

#import "NSString+StringWithPadding.h"


@implementation NSString (PPatherAdditions)

+ (NSString *)stringWithLeftPadding:(int)padding originalString:(NSString *)originalString {
	int i;
	NSMutableString *newString = [NSMutableString string];
	for (i = [originalString length]; i < padding; i++)
		[newString appendString:@" "];
	[newString appendString:originalString];
	return [NSString stringWithString:newString];
}

+ (NSString *)stringWithRightPadding:(int)padding originalString:(NSString *)originalString {
	int i;
	NSMutableString *newString = [NSMutableString string];
	[newString appendString:originalString];
	for (i = [originalString length]; i < padding; i++)
		[newString appendString:@" "];
	return [NSString stringWithString:newString];
}

+ (NSString *)stringWithDirectoryOfFile:(NSString *)filename {
	int i;
	for (i = [filename length] - 1; i >= 0; i--) {
		if ([filename characterAtIndex:i] == '/') {
			return [filename substringToIndex:i + 1];
		}
	}
	return nil;
}

@end
