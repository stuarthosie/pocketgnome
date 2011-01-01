//
//  MPTaskHotspots.m
//  Pocket Gnome
//
//  Created by Coding Monkey on 12/28/10.
//  Copyright 2010 Savory Software, LLC
//
#import "MPTaskHotspots.h"


@implementation MPTaskHotspots
@synthesize nextLocation;




- (id) initWithPather:(PatherController*)controller {
	if ((self = [super initWithPather:controller])) {
		name = @"Hotspots";
		
		isRandom = YES;
		isOrder = NO;
		shouldUpdate = YES;
		currentIndex = -1;
		
		self.nextLocation = nil;
		
	}
	return self;
}



- (void) setup {
	
	
	NSString *valOrder = [self stringFromVariable:@"order" orReturnDefault:@"random"];
	
	isRandom = [valOrder isEqualToString:@"random"];
	if (!isRandom) {
		isOrder = [valOrder isEqualToString:@"order"];
	}
	
	[super setup];
	
}




- (void) dealloc
{
	[nextLocation dealloc];
	
    [super dealloc];
}


#pragma mark -





- (BOOL) activityDone: (MPActivity*)activity {
	
	
	// we're done?  Then choose a new location to return.
	shouldUpdate = YES;
	
	return [super activityDone:activity]; // ??
}



- (MPLocation *) bestLocation {
	
	
	if ((nextLocation == nil) || (shouldUpdate) ) {
		
		MPLocation *newLocation = nextLocation;
		int numLocations = [locations count];
		
		if (isRandom) {
			
			
			if (numLocations > 1) {
				while( newLocation == nextLocation) {
					
					currentIndex = arc4random() % numLocations;
					newLocation = [locations objectAtIndex:currentIndex];
					
				}
			}
			
			
		} else {
			
			currentIndex ++;
			
			if (currentIndex > numLocations) currentIndex = 0;
			
			if (isOrder) {
				
				newLocation = [locations objectAtIndex:currentIndex];
				
			} else {
				newLocation = [locations objectAtIndex:(numLocations - currentIndex)];
				
			}
		}
		
		self.nextLocation = newLocation;
		shouldUpdate = NO;
		
	}
	
	
	return nextLocation;
}



#pragma mark -

+ (id) initWithPather: (PatherController*)controller {
	return [[[MPTaskHotspots alloc] initWithPather:controller] autorelease];
}




@end
