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

#import "WDT.h"


@implementation WDT

- (id) initWithWdtFile:(NSString *)filename {

	GMOs = [[NSMutableArray alloc] init];

	BOOL done = NO;

	FILE *fh = fopen([filename cStringUsingEncoding:NSASCIIStringEncoding], "r");
	if (!fh) {
		PGLog(@"Unable to open DBC file \"%@\".", filename);
		return nil;
	}
	
	do {
		
		NSString *type = fgetstr(fh, 4);
		int size = fgetui32(fh);
		long curpos = ftell(fh);
		
		if (type == nil) {
			done = YES;
		} else if ([type isEqualToString:@"MVER"]) {
			//
		} else if ([type isEqualToString:@"MPHD"]) {
			//
		} else if ([type isEqualToString:@"MODF"]) {
			// handleModf(size);
		} else if ([type isEqualToString:@"MWMO"]) {
			// handleMwmo(size);
		} else if ([type isEqualToString:@"MAIN"]) {
			// handleMain(size);
		} else {
			PGLog(@"WDT Type unknown: %u", type);
		}
		
		fseek(fh, curpos+size, SEEK_SET);
	} while (!done);
		
	fclose(fh);
	return self;
}


- (void)handleMwmoFromFile:(FILE *)fh withSize:(uint)size {
	if (size == 0) 
		return;
	
	int l = 0;
	while (l < size) {
		NSString *myStr = fgetntstr(fh);
		l += [myStr length] + 1;
		[GMOs addObject:myStr];
	}
}
		
- (void)handleModfFromFile:(FILE *)fh withSize:(uint)size {
	gnWMO = (int) size / 64;
	
	uint i;
	for (i = 0; i < gnWMO; i++) {
		int id = fgetui32(fh);
		NSString *path = [GMOs objectAtIndex:id];
		
		//WMO wmo=wmomanager.AddAndLoadIfNeeded(path);
		//WMOInstance wmoi=new WMOInstance(wmo, fh);
		//wdt.gwmois.Add(wmoi);
	}
}
		
- (void)handleMainFromFile:(FILE *)fh withSize:(uint)size {
	// global map objects
	int i, j;
	for (j = 0; j < 64; j++) {
		for(i = 0; i < 64; i++) {
			int d = fgetui32(fh);
			if(d != 0) {
				//wdt.maps[i, j] = true;
				//wdt.nMaps++;
			} else {
				//wdt.maps[i, j] = false;
			}
			fgetui32(fh);
		}
	}

}

@end
