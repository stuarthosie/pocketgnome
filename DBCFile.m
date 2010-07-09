//
//  DBCFile.m
//  Pocket Gnome
//
//  Created by William LaFrance on 7/9/10.
//  Copyright 2010 Savory Software, LLC. All rights reserved.
//

#import "DBCFile.h"


@implementation DBCFile

- (id)initWithFile:(NSString *)filename {

	NSData *filedata = [NSData dataWithContentsOfURL:
			[NSURL URLWithString:filename]];
	NSString *filestring = [NSString stringWithCString:[filedata bytes]
			encoding:NSASCIIStringEncoding];
	
	
	NSString *type = [filestring substringToIndex:4];
	if ([type isEqualToString:@"CBDW"] || [type isEqualToString:@"WDBC"]) {
		[self handleWDBC];
		return self;
	} else {
		PGLog(@"Attempted to open DBC file with unknown type (%@), filename %@",
			type, filename);
		return nil;
	}
	
}

- (void)handleWDBC {
	PGLog(@"Haven't yet added WDBC loading.");
	#warning handleWDBC not finished porting
			/*dbc.recordCount=file.ReadUInt32();

			dbc.fieldCount=file.ReadUInt32(); // words per record
			dbc.recordSize=file.ReadUInt32();
			dbc.stringSize=file.ReadUInt32();

			if(dbc.fieldCount*4!=dbc.recordSize)
			{
				// !!!
				System.Console.WriteLine("WOOT");
			}
			int off=0;
			uint[] raw=new uint[dbc.fieldCount*dbc.recordCount];
			for(uint i=0;i<dbc.recordCount;i++)
			{
				for(int j=0;j<dbc.fieldCount;j++)
				{
					raw[off++]=file.ReadUInt32();
				}
			}
			dbc.rawRecords=raw;

			byte[] b=file.ReadBytes((int)dbc.stringSize);
			dbc.strings=b;
		}
	}*/

}

@end
