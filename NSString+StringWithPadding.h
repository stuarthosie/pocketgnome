//
//  NSString+StringWithPadding.h
//  Pocket Gnome
//
//  Created by William LaFrance on 7/13/10.
//  Copyright 2010 Savory Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSString (PPatherAdditions)

/**
 * Returns a left-padded string, useful for aligning numerical data
 * IE: 8, @"string" would return
 *     @"   string"
 */
+ (NSString *)stringWithLeftPadding:(int)padding originalString:(NSString *)originalString;

/**
 * Returns a right-padded string, useful for aligning text-data
 * IE: 8, @"string" would return
 *        @"string    "
 */
+ (NSString *)stringWithRightPadding:(int)padding originalString:(NSString *)originalString;

/**
 * Returns a the path of a file.
 * IE: @"/this/is/a/path/to/file.txt" would return
 *     @"/this/is/a/path/to/"
 */
+ (NSString *)stringWithDirectoryOfFile:(NSString *)filename;

@end
