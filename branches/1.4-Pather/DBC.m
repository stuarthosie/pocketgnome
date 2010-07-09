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
	Ported to Objective-C by wjlafrance@gmail.com (finished 07/08/2010)
*/
 
#import "DBC.h"

@implementation DBC

- (uint) getUintForRecord:(int)record withId:(int)id {
	int recoff = (int)(record * fieldCount + id);
	return (uint)[recordUints objectAtIndex:recoff];
}

- (uint) getIntForRecord:(int)record withId:(int)id {
	int recoff = (int)(record * fieldCount + id);
	return (int)[recordUints objectAtIndex:recoff];
}

- (NSString *) getStringForRecord:(int)record withId:(int)id {
	int recoff = (int)(record * fieldCount + id);
	NSMutableString * returnString = [NSMutableString stringWithCapacity:64];
	
	NSString *c = (NSString *)[recordBytes objectAtIndex:recoff++];
	while (c != 0)
		[returnString appendFormat:@"%@", c];
	
	return [NSString stringWithString:returnString];
}

@end
