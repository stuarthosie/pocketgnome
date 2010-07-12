//
//  MpqOneshotExtractor.h
//  Pocket Gnome
//
//  Created by William LaFrance on 7/11/10.
//  Copyright 2010 Savory Software, LLC. All rights reserved.
//
 
#import "DBC.h"

@implementation DBC

uint fgetui32(FILE *fh) {
	return ((fgetc(fh) << 0) & 0x000000FF) |
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

- (id) initWithDbcFile:(NSString *)filename {

	FILE *fh = fopen([filename cStringUsingEncoding:NSASCIIStringEncoding], "r");
	if (!fh) {
		PGLog(@"Unable to open DBC file \"%@\".", filename);
		return nil;
	}
	
	if (!((fgetc(fh) == 'W') && (fgetc(fh) == 'D') && (fgetc(fh) == 'B') && (fgetc(fh) == 'C'))) {
		PGLog(@"Invalid DBC header for file \"%@\".", filename);
		return nil;
	}
	
	recordCount = fgetui32(fh);
	fieldCount = fgetui32(fh);
	recordSize = fgetui32(fh);
	stringSize = fgetui32(fh);
	
	//PGLog(@"Loaded header for DBC file \"%@\". Records: %i, fields: %i, record size: %i, string size: %i",
	//	filename, recordCount, fieldCount, recordSize, stringSize);
	
	data = [NSMutableArray arrayWithCapacity:recordCount];
	
	int i, j;
	for (i = 0; i < recordCount; i++) {
		NSMutableArray *thisRecord = [NSMutableArray arrayWithCapacity:fieldCount];
		for (j = 0; j < fieldCount; j++)
			[thisRecord addObject:[NSNumber numberWithUnsignedInt:fgetui32(fh)]];
		[data addObject:thisRecord];
	}
	
	return self;
}

- (uint) numberOfRecords {
	return recordCount;
}

- (uint) getUintForRecord:(int)record andField:(int)field {
	NSArray *thisRecord = [data objectAtIndex:record];
	return [[thisRecord objectAtIndex:field] unsignedIntValue];
}

@end
