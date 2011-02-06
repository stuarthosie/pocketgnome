//
//  MPState.m
//  Pocket Gnome
//
//  Created by Coding Monkey on 1/23/11.
//  Copyright 2011 Savory Software, LLC
//

#import "MPState.h"
#import "PatherController.h"
#import "MPToonData.h"

@implementation MPState



- (id) initWithPather:(PatherController *)controller {
	if ((self = [super initWithPather:controller])) {
		isString = YES;
		requiresParameter = YES;
		
		
	}
	return self;
}




- (NSString *) value {
	
	return [[patherController toonData] valueForKey:parameter];
}



+ (MPState *) initWithPather:(PatherController*)controller {
	
	return  [[[MPState alloc] initWithPather:controller] autorelease];
}

@end
