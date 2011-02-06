//
//  MPTaskWalk.m
//  Pocket Gnome
//
//  Created by Coding Monkey on 12/28/10.
//  Copyright 2010 Savory Software, LLC
//
#import "MPTaskWalk.h"


@implementation MPTaskWalk
@synthesize nextLocation;




- (id) initWithPather:(PatherController*)controller {
	if ((self = [super initWithPather:controller])) {
		name = @"Walk";
		
		isOrder = YES;
		shouldUpdate = YES;
		currentIndex = -1;
		
		self.nextLocation = nil;
		
	}
	return self;
}



- (void) setup {
	
	
	NSString *valOrder = [self stringFromVariable:@"order" orReturnDefault:@"order"];
	
	
	isOrder = [valOrder isEqualToString:@"order"];
	
	[super setup];
	
}




- (void) dealloc
{
	[nextLocation release];
	
    [super dealloc];
}


#pragma mark -


- (BOOL) isFinished {
	return (currentIndex >= [locations count]);
}



- (void) restart {
	
	currentIndex = -1;
	shouldUpdate = YES;
	self.nextLocation = nil;
}



- (BOOL) activityDone: (MPActivity*)activity {
	
	
	// we're done?  Then choose a new location to return.
	shouldUpdate = YES;
	
	return [super activityDone:activity]; // ??
}



- (MPLocation *) bestLocation {
	
	
	if ((nextLocation == nil) || (shouldUpdate) ) {
		
		MPLocation *newLocation = nil;
		int numLocations = [locations count];
		

			
		currentIndex ++;
		
		if (currentIndex < numLocations)
		{
			if (isOrder) {
				
				newLocation = [locations objectAtIndex:currentIndex];
				
			} else {
				
				newLocation = [locations objectAtIndex:(numLocations - currentIndex)-1];
				
			}
			
			
		}

		
		self.nextLocation = newLocation;
		shouldUpdate = NO;
		
	}
	
	
	return nextLocation;
}



#pragma mark -

+ (id) initWithPather: (PatherController*)controller {
	return [[[MPTaskWalk alloc] initWithPather:controller] autorelease];
}




@end
