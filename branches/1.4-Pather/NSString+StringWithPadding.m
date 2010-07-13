//
//  NSString+StringWithPadding.m
//  Pocket Gnome
//
//  Created by William LaFrance on 7/13/10.
//  Copyright 2010 Savory Software, LLC. All rights reserved.
//

#import "NSString+StringWithPadding.h"


@implementation NSString (PPatherAdditions)

+ stringWithLeftPadding:(int)padding originalString:(NSString *)originalString {
	int i;
	NSMutableString *newString = [NSMutableString string];
	for (i = [originalString length]; i < padding; i++)
		[newString appendString:@" "];
	[newString appendString:originalString];
	return [NSString stringWithString:newString];
}

+ stringWithRightPadding:(int)padding originalString:(NSString *)originalString {
	int i;
	NSMutableString *newString = [NSMutableString string];
	[newString appendString:originalString];
	for (i = [originalString length]; i < padding; i++)
		[newString appendString:@" "];
	return [NSString stringWithString:newString];
}

@end
