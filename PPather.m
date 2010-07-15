//
//  PPather.m
//  Pocket Gnome
//
//  Created by William LaFrance on 7/15/10.
//  Copyright 2010 Savory Software, LLC. All rights reserved.
//
//  These are some global functions I needed to use in multiple files with
//  PatherGnome.
//

// ---- FILE READING FUNCTIONS ----
uint fgetui32(FILE *fh) {
	return ((fgetc(fh) <<  0) & 0x000000FF) |
		   ((fgetc(fh) <<  8) & 0x0000FF00) |
		   ((fgetc(fh) << 16) & 0x00FF0000) |
		   ((fgetc(fh) << 24) & 0xFF000000);
}

NSData *fgetdata(FILE *fh, int length) {
	int i;
	NSMutableData *ret = [[NSMutableData alloc] initWithLength:length];
	for (i = 0; i < length; i++) {
		int c = fgetc(fh);
		[ret appendBytes:&c length:1];
	}
	return [NSData dataWithData:ret];
}

NSString *fgetstr(FILE *fh, int length) {
	int i;
	NSMutableString *ret = [[NSMutableString alloc] initWithCapacity:length];
	for (i = 0; i < length; i++) {
		[ret appendFormat:@"%c", fgetc(fh)];
	}
	return [NSString stringWithString:ret];
}

NSString *fgetntstr(FILE *fh) {
	NSMutableString *myString = [NSMutableString string];
	while(true) {
		int c = fgetc(fh);
		if (c < 1) { // null or EOF
			if ([myString length] > 0) {
				return [NSString stringWithString:myString];
			} else {
				return nil;
			}
		}
	}	
}

// ---- FILE READING FUNCTIONS ----



/*@implementation PPather

@end*/
