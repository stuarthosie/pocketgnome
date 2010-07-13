//
//  NSString+StringWithPadding.h
//  Pocket Gnome
//
//  Created by William LaFrance on 7/13/10.
//  Copyright 2010 Savory Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSString (PPatherAdditions)

+ stringWithLeftPadding:(int)padding originalString:(NSString *)originalString;
+ stringWithRightPadding:(int)padding originalString:(NSString *)originalString;

@end
