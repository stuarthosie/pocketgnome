//
//  MpqOneshotExtractor.h
//  Pocket Gnome
//
//  Created by William LaFrance on 7/11/10.
//  Copyright 2010 Savory Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PPather.h"


@interface DBC : NSObject {

	uint recordSize;
	uint recordCount;
	uint fieldCount;
	uint stringSize;
	
	NSMutableArray *data;
	NSMutableArray *stringdata;
	
}

- (id) initWithDbcFile:(NSString *)filename;
- (uint) numberOfRecords;
- (uint) getUintForRecord:(int)record andField:(int)field;

@end
