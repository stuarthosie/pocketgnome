//
//  MPActivityWalk.m
//  Pocket Gnome
//
//  Created by codingMonkey on 9/22/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MPActivityWalk.h"
#import "MPActivity.h"
#import "MPTask.h"
#import "PatherController.h"

#import "MovementController.h"
#import "MPCustomClass.h"
#import "MPLocation.h"
#import "MPMover.h"
#import "MPNavigationController.h"
#import "PlayerDataController.h"
#import "Position.h"
#import "Route.h"
#import "Waypoint.h"



@interface MPActivityWalk (Internal)

- (BOOL) isRouteDone;

- (void) setupRouteToLocation: (MPLocation *)destLocation;
- (BOOL) isRouteFinished;
- (BOOL) isRouteValid;
- (Route *) completedRoute;
- (int) countSquares;

- (NSArray *)listLocationsFromRoute: (Route *) route;

- (void) updateCurrentIndex;
- (void) getLocationsFromRoute;
- (void) doMoveAction;
- (void) bestRouteSoFar;
- (void) resetNavRouting;

@end



@implementation MPActivityWalk
@synthesize customClass, destinationLocation, listLocations, movementController, mover, timerTooLong;




- (id) init {
	return [self initWithRoute:nil andTask:nil usingMount:NO];
}



- (id) initWithRoute: (Route*)aRoute andTask:(MPTask*)aTask usingMount:(BOOL)mount {
	
	if ((self = [super initWithName:@"Walk" andTask:aTask])) {
		
		
/*
		
		// store arrayLocations
		self.listLocations = [locations copy];
		
		// currentIndx = 0;
		currentIndex = 0;
		
		useMount = mount;
		self.mover = [MPMover sharedMPMover];
		self.movementController = [[task patherController] movementController];
		self.customClass = [[task patherController] customClass];
		
		state = WalkStateGeneratingRoute;
*/
		
	}
	return self;
}




- (id) initWithLocation: (MPLocation*)destination andTask:(MPTask*)aTask usingMount:(BOOL)mount {
	
	if ((self = [super initWithName:@"Walk" andTask:aTask])) {
		
		
		// store arrayLocations
		self.listLocations = nil;
		
		self.destinationLocation = destination;
		
		// currentIndx = 0;
		currentIndex = 0;
		
		useMount = mount;
		self.mover = [MPMover sharedMPMover];
		self.movementController = [[task patherController] movementController];
		self.customClass = [[task patherController] customClass];
		
		self.timerTooLong = [MPTimer timer:3500];
		
		state = WalkStateGeneratingRoute;
		
		howClose = 2.0f;
		
	}
	return self;
}




- (void) dealloc
{
	[customClass release];
	[destinationLocation release];
	[listLocations release];
	[mover release];
	[movementController release];
	[timerTooLong release];
	
    [super dealloc];
}



#pragma mark -



// get ready to start
- (void) start {

	// now that we have our own mover: make sure MC isn't running
	[movementController resetMovementState]; 

	
	// ok we are starting up (or restarting from being interrupted)
	state = WalkStateGeneratingRoute;
	
	self.listLocations = nil;
	currentIndex = -1;
	
	[self setupRouteToLocation:destinationLocation];
	if ([self isRouteFinished]) {
		
		state = WalkStateMoving;
		
		[self getLocationsFromRoute];
	}
	
	[timerTooLong start];
	
	
	/*
	
	///
	/// OK, let's try to find the closest point in our list of locations
	///
	Position *myPosition = [[PlayerDataController sharedController] position];
	
	float currentDistance, minDistance;
	int index = 0;
	int minIndex = 0;
	
	minDistance = INFINITY;
	
	for( Position *pos in listLocations) {
		currentDistance = [myPosition distanceToPosition:pos];
		if (currentDistance <= minDistance) {
			minIndex = index;
			minDistance = currentDistance;
		}
		index ++;
	}
	
	currentIndex = minIndex;
	
	///
	/// Now attempt to see if we are approaching currentIndex or have just
	/// passed it:
	///
	
	// find the previous location (index)
	int prevIndx = currentIndex;
	if (prevIndx == 0) {
		prevIndx = [listLocations count] -1;
	}
	
	float distToCurrent = INFINITY;
	float distToMe = INFINITY;
	
	// get the previous and current Positions
	Position *prevPosition = [listLocations objectAtIndex:prevIndx];
	Position *currPosition = [listLocations objectAtIndex:currentIndex];
	
	// figure the distance from Previous -> Current  && Previous -> Me
	distToCurrent = [prevPosition distanceToPosition:currPosition];
	distToMe = [prevPosition distanceToPosition:myPosition];
	
	// if distance to Current is < distance to Me : then we have already run past the current pos.
	// (or so I'm assuming ...)
	if (distToCurrent < distToMe) {
		
		// so let's assume the next position is the one we should be running to.
		currentIndex ++;
		
		// adjust for end of list
		if (currentIndex >= [listLocations count]) {
			currentIndex = 0;
		}
	}
	 
	 */
	
	
}



- (BOOL) work {

	BOOL wasFinished = NO;
	
	// if through generating route and 
	
	
	
	switch (state) {
		default:
		case WalkStateGeneratingRoute:
			
			if ([self isRouteFinished]) {
			
				state = WalkStateMoving;
				
				[self getLocationsFromRoute];
				
				return NO;
				
			}
			
			if ([timerTooLong ready] ) {
				
				state = WalkStateWalkWhileGenerating;
				
				// get best route so far
				[self bestRouteSoFar];
				
				// reset Nav Routing from last position to destination
				[self resetNavRouting];
				
			}
			
			return NO;
			
			break;
			
			
		case WalkStateWalkWhileGenerating:
			
			// adjust  currentIndx
			[self updateCurrentIndex];
			
			wasFinished = [self isRouteFinished]; 
			
			// do move
			if (currentIndex < [listLocations count]) {
				
				[self doMoveAction];
				
				
			} else {
				
				
				if (wasFinished) {
					
					[self getLocationsFromRoute];
					state = WalkStateMoving;
					
				} else {
					
					
					// get best route so far
					[self bestRouteSoFar];
					
					// reset Nav Routing from last position to destination
					[self resetNavRouting];
				}
				
			}

			return NO;
			
			break;
			
		case WalkStateMoving:
			
			// update currentIndex to the next Loction if necessary
			[self updateCurrentIndex];
			
			
			// do move
			if (currentIndex < [listLocations count]) {
				
				[self doMoveAction]; // keep moving 
				
				return NO;
				
			} else {
				
				// we are done
				[mover stopAllMovement];
				currentIndex = 0; // reset to 1st Location
				return YES;
			}
			break;
	}
	
	return NO;
}



- (void) stop{
	
	[mover stopAllMovement];
	
}



- (NSString *) description {
	
	NSMutableString *text = [NSMutableString stringWithString:@" ActivityWalk \n"];
	MPLocation *currLoc;
	
	switch (state) {
		case WalkStateGeneratingRoute:
			[text appendFormat:@" generating route\n  #squares[%d]", [self countSquares]];
			break;
			
		case WalkStateWalkWhileGenerating:
			[text appendFormat:@" generating route [%d]\n running %i/%i", [self countSquares], currentIndex+1, [listLocations count]];
			break;
			
		case WalkStateMoving:
			currLoc = [listLocations objectAtIndex:currentIndex];
			float distTo = [task myDistanceToPosition:(Position *)currLoc];
			[text appendFormat:@"%i of %i points in route \n  curr[x:%0.2f, y:%0.2f, z:%0.2f]\n   dist to[%0.2f]", currentIndex+1,[listLocations count], [currLoc xPosition], [currLoc yPosition], [currLoc zPosition], distTo ];
			break;
	}
	return text;
}



#pragma mark -
#pragma mark Helper methods




- (void) setupRouteToLocation: (MPLocation *)destLocation {
	[[[task patherController] navigationController] setupRouteFromLocation:(MPLocation *)[task myPosition] toLocation:destLocation];
}

- (BOOL) isRouteFinished {
	
	return [[[task patherController] navigationController] isRouteWorkComplete];
}

- (BOOL) isRouteValid {
	return [[[task patherController] navigationController] isRouteValid];
}

- (Route *) completedRoute {
	
	return [[[task patherController] navigationController] completedRoute];
}

- (int) countSquares {
	
	return [[[[task patherController] navigationController] currentOpenList] count];
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
	
	while ((currentIndex < [listLocations count]) && ([task myDistanceToPosition2D:[listLocations objectAtIndex:currentIndex]] <= howClose)) {
		currentIndex++;
	}
	
}

- (void) getLocationsFromRoute {
	
	Route *route = [self completedRoute];
	self.listLocations = [self listLocationsFromRoute:route];
	currentIndex = 0;
}

- (void) doMoveAction {
	MPLocation *myLocation = (MPLocation *)[task myPosition];
	
	// move to next location 
	MPLocation *nextStep = (MPLocation *)[listLocations	objectAtIndex:currentIndex];
	MPLocation *facingStep = nextStep;
	
	if (currentIndex < ([listLocations count]-1)) {
		float distance = [myLocation distanceToPosition2D:nextStep];
		if (distance < 5.0f ) {
			facingStep = [listLocations objectAtIndex:currentIndex +1];
		}
	}
	
		
	[mover moveTowards:nextStep within:howClose facing:facingStep];
	
	[customClass runningAction]; // <--- spam running action here
}


- (void) bestRouteSoFar {
	
	Route *route = [[[task patherController] navigationController] bestCurrentRoute];
	self.listLocations = [self listLocationsFromRoute:route];
	currentIndex = 0;
	
}


- (void) resetNavRouting {
	
	int lastIndex = [listLocations count]-1;
	MPLocation *lastLocation = [listLocations objectAtIndex:lastIndex];
	
	
	
	[[[task patherController] navigationController] setupRouteFromLocation:lastLocation toLocation:destinationLocation];
	
	
}


/*
// attempts to see if the mC has finished and is starting over
- (BOOL) isRouteDone {

	// the mC seems to auto repeat a route when it reaches the end.
	// that makes since for PG, but for this activity, we only want to run
	// it 1x and then stop.  so here we attempt to see if we jump from the end
	// point to the beginning.  if so, we should be done then.
	
	// find index of current pointer
	Waypoint *movementControllerDestination = [movementController destinationWaypoint];
	Waypoint *currentWaypoint = nil;
	currentIndex=0;
	int index = 0;
	for( index =0; index < [[route waypoints] count]; index++) {
		currentWaypoint = [[route waypoints] objectAtIndex:index];
		if (currentWaypoint == movementControllerDestination) {
			currentIndex = index;
			break;
		}
	}
	
	// if previous pointer == last index
	if (previousIndex == indexLastWaypoint) {
		
		// if current pointer != previous pointer
		if (currentIndex != indexLastWaypoint) {
			
			// return YES
			return YES;
			
		} // end if
	} // end if
	
	// update previous == current
	previousIndex = currentIndex;
	
	return NO;

}

- (Waypoint*)closestWaypoint{
	Waypoint *startWaypoint = nil;
	Position *playerPosition = (Position *)[[[task patherController] playerData] position];
	float minDist = INFINITY, tempDist;
	for(Waypoint *waypoint in [route waypoints]) {
		tempDist = [playerPosition distanceToPosition: [waypoint position]];
		if( (tempDist < minDist) && (tempDist >= 0.0f)) {
			minDist = tempDist;
			startWaypoint = waypoint;
		}
	}
	
	return startWaypoint;
}
 
 */


#pragma mark -


+ (id) walkRoute:(Route*)aRoute forTask:(MPTask*) aTask useMount:(BOOL)mount {
	
	MPActivityWalk *newActivity = [[MPActivityWalk alloc] initWithRoute:aRoute andTask: aTask usingMount:mount];
	return [newActivity autorelease];
}


+ (id) walkToLocation:(MPLocation*)aLocation forTask:(MPTask*) aTask useMount:(BOOL)mount {
	
	MPActivityWalk *newActivity = [[MPActivityWalk alloc] initWithLocation:aLocation andTask:aTask usingMount:mount];
	return [newActivity autorelease];
/*	
	MPLocation *currentLocation = (MPLocation *)[[[aTask patherController] playerData] position];
	Route *newRoute = [[[aTask patherController] navigationController] routeFromLocation:currentLocation toLocation:aLocation];
	// Route *newRoute = [navagationController routeToLocation: aLocation];
PGLog(@" --- ActivityWalk: new route with %d nodes",[[newRoute waypoints] count]);
	return [MPActivityWalk walkRoute:newRoute forTask:aTask useMount:mount];
 */
}


/*
+ (id) walkToUnit:(XXXX *)aUnit forTask:(MPTask*) aTask useMount:(BOOL)mount {
	return [MPActivityWalk walkToLocation:[aUnit position] forTask:aTask useMount:mount];
}
*/

@end
