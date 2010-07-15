/*
	This file is part of ppather.

	PPather is free software: you can redistribute it and/or modify
	it under the terms of the GNU Lesser General Public License as published by
	the Free Software Foundation, either version 3 of the License, or
	(at your option) any later version.

	PPather is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU Lesser General Public License for more details.

	You should have received a copy of the GNU Lesser General Public License
	along with ppather.  If not, see <http://www.gnu.org/licenses/>.

	Copyright Pontus Borg 2008
	Ported to Objective-C by wjlafrance@gmail.com
*/
 
#import "DBC.h"

@implementation DBC

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
	stringdata = [[NSMutableArray alloc] init];
	
	int i, j;
	for (i = 0; i < recordCount; i++) {
		NSMutableArray *thisRecord = [NSMutableArray arrayWithCapacity:fieldCount];
		for (j = 0; j < fieldCount; j++)
			[thisRecord addObject:[NSNumber numberWithUnsignedInt:fgetui32(fh)]];
		[data addObject:thisRecord];
	}
	
	// read all them strings
	int nextIndex = 0;		// index to insert next string at
	int currentIndex = 0;	// index we're currently at
	NSMutableString *myString = [NSMutableString string];
	while(true) {
		currentIndex++;
		int c = fgetc(fh);
		if (c < 1) { // null or EOF
			if ([myString length] > 0) { // don't add empty strings
				//PGLog(@"New string: %@", myString);
				[stringdata insertObject:[NSString stringWithString:myString] atIndex:nextIndex];
				myString = [NSMutableString string];
			}
			nextIndex = currentIndex;
			if (c == -1) {	// EOF
				break;
			}
		} else {
			[myString appendFormat:@"%c", (char)c];
			[stringdata addObject:[NSString string]]; // this is a serious waste of memory
			// but unfortunately, we need to have an object in there, not just nil. I figure
			// an empty string is pretty small. Any better ideas?
			#warning fix bad idea
		}
	}
	
	// clean up
	fclose(fh);
	
	return self;
}

- (uint) numberOfRecords {
	return recordCount;
}

- (uint) getUintForRecord:(int)record andField:(int)field {
	if (record < 0)
		return 0;
		
	NSArray *thisRecord = [data objectAtIndex:record];
	return [[thisRecord objectAtIndex:field] unsignedIntValue];
}

- (NSString *) getStringForRecord:(int)record andField:(int)field {
	if (record < 0)
		return @"(unknown)";
	
	NSArray *thisRecord = [data objectAtIndex:record];
	int thisField = [[thisRecord objectAtIndex:field] unsignedIntValue];
	if (thisField >= [stringdata count]) {
		return @"(unknown)";
	}
	return [stringdata objectAtIndex:thisField];
}

- (int) getRecordNumberByValue:(uint)value ofField:(uint)field {
	int i;
	for (i = 0; i < recordCount; i++) {
		if ([self getUintForRecord:i andField:field] == value) {
			return i;
		}
	}

	return -1;
}

@end
