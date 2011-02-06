//
//  MPActivityApproach.m
//  Pocket Gnome
//
//  Created by codingMonkey on 9/23/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MPActivityApproach.h"
#import "MPTask.h"
#import	"Unit.h"
#import "MovementController.h"
#import "PlayerDataController.h"
#import "PatherController.h"
#import "Position.h"
#import "MPTimer.h"
#import "MPMover.h"
#import "MPNavigationController.h"
#import "Route.h"



@interface MPActivityApproach (Internal)


- (NSArray *)listLocationsFromRoute: (Route *) route;
- (void) updateCurrentIndex;
- (void) setupLocationsToUnit;
- (void) checkRouteDone;
- (void) doMoveAction;

@end


@implementation MPActivityApproach
@synthesize unit, mover, useMount, listLocations, destinationLocation;



- (id) initWithUnit: (Unit*)aUnit andDistance:(float)howClose andTask:(MPTask*)aTask  {
	
	if ((self = [super initWithName:@"Approach" andTask:aTask])) {
		self.unit = aUnit;
		distance = howClose;
		
		self.mover = [MPMover sharedMPMover];
		
		
		// route following variables
		self.listLocations = nil;
		
		self.destinationLocation = (MPLocation *)[unit position];
		
		// currentIndx = 0;
		currentIndex = -1;  // uninitialized state
		howCloseToLocation = 2.0f;

	}
	return self;
}



- (void) dealloc
{
    [unit release];
	[mover release];
	[listLocations release];
	[destinationLocation release];
	
    [super dealloc];
}



#pragma mark -



- (void) start {

	[self setupLocationsToUnit];
	
	[self checkRouteDone]; // will set currentIndex == 0 when done.
	
	[self updateCurrentIndex];
	if (currentIndex != -1) {
		if (currentIndex < [listLocations count]) 
			[mover moveTowards:[listLocations objectAtIndex:currentIndex] within:howCloseToLocation facing:(MPLocation *)[unit position]];
	}

}



// Make sure we are making progress towards the target.  Stop when in range.
- (BOOL) work {
	
	
	// if the unit has moved, then calc a new route
	if ([destinationLocation distanceToPosition:[unit position]] > distance) {
		
		// this is only called when destLoc is > distance from unit.position, but calling
		// setupLocactionsToUnit will reset destLoc == unit.pos, so no spamming should occur
		

		currentIndex = -1;
		[self setupLocationsToUnit];

	}
	
	[self checkRouteDone];
	
	// make sure our current point is updated when we are close enough
	[self updateCurrentIndex];
	
	// if we still have places to move to then tell mover
	if (([listLocations count] >0) && (currentIndex < [listLocations count]))
		[mover moveTowards:[listLocations objectAtIndex:currentIndex] within:howCloseToLocation facing:(MPLocation *)[unit position]];
	
	// make sure Mover faces us towards unit:
	[mover faceLocation:(MPLocation *)[unit position]];
	return (([task myDistanceToPosition2D:[unit position]] <= distance) || (currentIndex >= [listLocations count]));

}



// we are interrupted before we arrived.  Make sure we stop moving.
- (void) stop{
	
	[mover stopAllMovement];
	currentIndex = -1;  // reset our list
}



#pragma mark -



- (NSString *) description {
	NSMutableString *text = [NSMutableString string];
	
	[text appendFormat:@"%@\n", self.name];
	if (unit != nil) {
		
//		Position *playerPosition = [playerDataController position];
		float currentDistance = [task myDistanceToPosition2D:[unit position]];
	
		[text appendFormat:@"  approaching [%@]  [%0.2f / %0.2f]\n  cI[%d]/l[%d]", [unit name], currentDistance, distance, currentIndex, [listLocations count]];
		
	} else {
		[text appendString:@"  no unit to approach"];
	}
	
	return text;
}


#pragma mark -
#pragma mark Internal Helpers


- (void) setupLocationsToUnit {
	
	self.destinationLocation = (MPLocation *)[unit position];
	[[[task patherController] navigationController] setupRouteFromLocation:(MPLocation *)[task myPosition] toLocation:destinationLocation];
	

}


- (void) checkRouteDone {
	
	
	if ([[[task patherController] navigationController] isRouteWorkComplete]) {
		
		// only update the currentIndx & listLocations if they are uninitialized
		if (currentIndex == -1) {
			Route *route = [[[task patherController] navigationController] completedRoute];
			self.listLocations = [self listLocationsFromRoute:route];
			currentIndex = 0;
PGLog(@" +++++ routeDone: countLocations[%d] currentIndex[%d]", [listLocations count], currentIndex);
		}
	}
	
	
}


- (NSArray *)listLocationsFromRoute: (Route *) route {
	
	NSMutableArray *list = [NSMutableArray array];
	
	NSArray *listWaypoints = [route waypoints];
	for( Waypoint *wp in listWaypoints){
		[list addObject: (MPLocation *)[wp position]];
	}
	
	return list;
}



- (void) updateCurrentIndex {
	
	if (currentIndex != -1) {
		while ((currentIndex < [listLocations count]) && ([task myDistanceToPosition2D:[listLocations objectAtIndex:currentIndex]] <= howCloseToLocation)) {
PGLog(@" +++++ updateCurrentIndex: cIndx[%d] < countListLoc[%d] : distToPos2D[%0.2f]  howClose[%0.2f]", currentIndex, [listLocations count], [task myDistanceToPosition2D:[listLocations objectAtIndex:currentIndex]], howCloseToLocation);
			currentIndex++;
		}
	}
	
}



- (void) doMoveAction {
	MPLocation *myLocation = (MPLocation *)[task myPosition];
	
	// move to next location 
	MPLocation *nextStep = (MPLocation *)[listLocations	objectAtIndex:currentIndex];
	MPLocation *facingStep = nextStep;
	
	if (currentIndex < ([listLocations count]-1)) {
		float distanceNext = [myLocation distanceToPosition2D:nextStep];
		if (distanceNext < 5.0f ) {
			facingStep = [listLocations objectAtIndex:currentIndex +1];
		}
	}
	
	
	[mover moveTowards:nextStep within:howCloseToLocation facing:facingStep];
	
}


#pragma mark -



+ (id) approachUnit:(Unit*)aUnit withinDistance:(float) howClose forTask:(MPTask *)aTask {

	return [[[MPActivityApproach alloc] initWithUnit:aUnit andDistance:howClose andTask:aTask] autorelease];

}
@end
