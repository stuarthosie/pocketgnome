//
//  MPNavigationController.m
//  Pocket Gnome
//
//  Created by Coding Monkey on 10/13/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MPNavigationController.h"
#import "MPNavMeshView.h"
#import "MPLocation.h"
#import "Position.h"
#import "MPSquare.h"
#import "MPPoint.h"
#import "MPPointTree.h"
#import "MPSquareTree.h"
#import "Route.h"
#import "MPPathNode.h"

#import "PatherController.h"
#import "PlayerDataController.h"

#import "PlausibleDatabase/PlausibleDatabase.h"


@interface MPNavigationController (Internal)

- (MPSquare *) findOrCreateSquareContainingLocation: (MPLocation *)aLocation;

- (MPSquare *) newSquareWithDimentionsMixX: (float) minX maxX: (float) maxX minY: (float) minY maxY:(float) maxY avgZ:(float) avgZ;
- (MPSquare *) newSquareContainingLocation: (MPLocation *) aLocation;

- (void) includeLocationInLoadedGraph: (MPLocation *) location;
- (void) loadTopGraph: (float) newYmax;
- (void) loadBottomGraph: (float) newYmin;
- (void) loadRightGraph: (float) newXmax;
- (void) loadLeftGraph: (float) newXmin;
- (void) loadGraphChunkWithCondition: (NSString *)condition;
- (void) storeSquareInDB: (MPSquare *) newSquare;
- (void) removeSquareFromDB: (MPSquare *) square;
- (void) updateSquareInDB: (MPSquare *) square;
- (void) connectSquare: (MPSquare *)square;
- (NSMutableArray *) listLocationsOfMissingBorderConnectionsForSquare:(MPSquare *)square;
- (float) minAmountZMovementToConnectSquare: (MPSquare *)curSquare withSquare: (MPSquare *)missingSquare;

- (NSArray *) arraySquaresInQuadAroundSquare: (MPSquare *) currentSquare;
- (BOOL) canQuadReduceSquares: (NSArray *) listSquares;



// Non Blocking Methods
- (BOOL) isPathWorkComplete;
- (BOOL) isOptimizationWorkComplete;

@end


@implementation MPNavigationController
@synthesize allSquares, pointArray, allPoints, previousSquare, toleranceZ, squareWidth, currentPath, loadedXmin, loadedXmax, loadedYmin, loadedYmax, dbLock;

@synthesize timerWorkTime, currentStartLocation, currentDestLocation, currentStartSquare, completedRoute;
@synthesize currentOpenList, currentClosedList, foundPath;
@synthesize currentListAllPathLocations, currentListOptimizedLocations;
@synthesize gridProblemStart, gridProblemEnd;
@synthesize zone;

-(id) init {
	
	if ((self = [super init])) {
//		self.allSquares = [NSMutableArray array];
//		self.allPoints = [NSMutableArray array];
		
		self.previousSquare = nil;
		
		squareWidth = 2.0;  // minimum square width
		toleranceZ = 5.5f;
		self.pointArray = [NSMutableArray array];
		self.allPoints = [MPPointTree treeWithZTolerance:toleranceZ];
		self.allSquares = [MPSquareTree treeWithSquareWidth:squareWidth ZTolerance:toleranceZ];
		self.currentPath = nil;
		
		
		//// DB and Graph routines
		db = nil;
		graphChunkSize = 1000;
		loadedXmin = 0;
		loadedXmax = 0;
		loadedYmin = 0;
		loadedYmax = 0;
		self.dbLock = [[NSLock alloc] init];
		
		// optimizations
		goalSize = squareWidth * 2;  // beginning goal .
		
		
		// non blocking routing data:
		timerWorkTime = [MPTimer timer:75]; // 75 ms of work at a time (max)
		state = NavRoutingStateDone;
		isCurrentRouteValid = NO;
		self.currentStartLocation = nil;
		self.currentDestLocation = nil;
		self.currentStartSquare = nil;
		self.completedRoute = nil;
		self.currentOpenList = [NSMutableArray array];
		self.currentClosedList = [NSMutableArray array];
		self.foundPath = nil;
		self.currentListAllPathLocations = [NSMutableArray array];
		self.currentListOptimizedLocations = [NSMutableArray array];
		currentOptimizationLocC=0;
		currentOptimizationLocB=0;
		currentOptimizationLocA=0;
		
		self.gridProblemStart = nil;
		self.gridProblemEnd = nil;
		
		
		zone = [[PlayerDataController sharedController] zone];
		
PGLog(@" +++++ navController loaded with zone:%d", zone);
		
		
		// make sure our DB is closed upon application exit
		[[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(applicationWillTerminate:) 
                                                     name: NSApplicationWillTerminateNotification 
                                                   object: nil];
		
		
	}
	return self;
}



- (void) dealloc
{
	[db autorelease];
    [allSquares autorelease];
    [allPoints autorelease];
	[pointArray autorelease];
	[previousSquare autorelease];
	[dbLock autorelease];
	
	[timerWorkTime autorelease];
	[currentStartLocation autorelease];
	[currentDestLocation autorelease];
	[currentStartSquare autorelease];
	[completedRoute autorelease];
	[currentOpenList autorelease];
	[currentClosedList autorelease];
	[foundPath autorelease];
	
	[currentListAllPathLocations autorelease];
	[currentListOptimizedLocations autorelease];
	
	[gridProblemStart release];
	[gridProblemEnd release];
	
    [super dealloc];
}


#pragma mark -




- (NSArray *) listSquaresInView: (MPNavMeshView *) navMeshView aroundLocation: (MPLocation *)playerPosition {
	
	[[allSquares lock] lock];
	NSArray *listSquares = [[allSquares listSquares] copy];
	[[allSquares lock] unlock];
	
	
	return listSquares;
	
	
	//	return [allSquares listSquares];
	
/*	
	NSMutableArray *listSquares = [NSMutableArray array];
	int numSlices = [navMeshView scaleSetting];
	
	
	float baseX, baseY, halfDistance, posX, posY;
	halfDistance = ((numSlices * squareWidth) /2 );
	baseX = [playerPosition xPosition] - halfDistance;
	baseY = [playerPosition yPosition] - halfDistance;
	
	int indexY, indexX;
	MPSquare *currentSquare, *prevSquare;
	prevSquare = nil;
	
	
	for (indexX = 0; indexX < numSlices; indexX++) {
		posX = baseX + (indexX * squareWidth);
		for (indexY=0; indexY < numSlices; indexY++ ) {
		
			posY = baseY + (indexY * squareWidth);
			
			currentSquare = [allSquares squareAtX:posX Y:posY Z:[playerPosition zPosition]];
			
			if (currentSquare != nil) {
			
				if (currentSquare != prevSquare) {
					
					if (![listSquares containsObject:currentSquare]) {
					
						[listSquares addObject:currentSquare];
					}
				
					prevSquare = currentSquare;
				}
			}
		}
		
	}
	
	
	return listSquares;
*/	
	

	
	/*
	 * Perhaps this isn't all that necessary ...
	 * 
	NSMutableArray *listSquares = [NSMutableArray array];

	// find current square containing position
	MPSquare *playerSquare = [self findOrCreateSquareContainingLocation:playerPosition];
	
	// get rect that should represent our view (translated and Scaled)
	float viewRectX, viewRectY, viewRectWidth, viewRectHeight;
	float halfWidth;
	
	viewRectHeight = ([navMeshView scaleSetting] * squareWidth);
	viewRectWidth  = (viewRectHeight * ( [navMeshView viewWidth] / [navMeshView viewHeight] ));  // since the viewRect isn't actually square ... 
	halfWidth = viewRectHeight/2;
	
	viewRectX = [playerPosition xPosition] - halfWidth;
	viewRectY = [playerPosition yPosition] - halfWidth;
	
	NSRect viewRect = NSMakeRect( viewRectX, viewRectY, viewRectWidth, viewRectHeight);
	
	
	// if (NSIntersectsRect(viewRect, square.rect))
	if ( NSIntersectsRect(viewRect, [playerSquare nsrect])) {
	
		// add square to list
		[listSquares addObject:playerSquare];
		
		[playerSquare compileAdjacentSquaresThatIntersectRect: viewRect  intoList: listSquares];
		
	}
	
	
	// return list
	return listSquares;
	
//	return allSquares;

	*/
	
}



- (MPSquare *) closestSquareContainingLocation: (MPLocation *) aLocation {
	
	return [allSquares closestSquareAtLocation:aLocation];
	
}



- (MPSquare *) lowestSquareContainingLocation: (MPLocation *) aLocation {
	
	return [allSquares lowestSquareAtLocation:aLocation];
	
}



- (MPSquare *) smallestSquareContainingLocation: (MPLocation *) aLocation {
	
	return [allSquares smallestSquareAtLocation:aLocation];
	
}



- (MPSquare *) squareContainingLocation: (MPLocation *) aLocation {
	
	return [allSquares squareAtLocation:aLocation];
	
}



- (MPSquare *) findOrCreateSquareContainingLocation: (MPLocation *)aLocation {

	// updatedSquare = nil
	MPSquare *updatedSquare = nil;
	
	
	// ok, scanning the whole list of squares can get time consuming on large meshes ...
	// lets see if we can reduce our overhead by :
	
	
	//// checking the last square we worked with:
	// if previousSquare contains location
	if (previousSquare != nil) {
		if ([previousSquare containsLocation:aLocation]) {
			updatedSquare = previousSquare;
		}
		
		//// checking an adjacent square from the last one we worked with:
		// if updatedSquare == nil
// (OK, now that we use AVL trees ... just go find the square)
//		if (updatedSquare == nil) {
//			updatedSquare = [previousSquare adjacentSquareContainingLocation: aLocation];
//		}
		
	}
	
	
	
	
	//// ok, fine: check the whole graph then:
	// if updatedSquare == nil
	if (updatedSquare == nil) {
		updatedSquare = [self squareContainingLocation: aLocation];
	}
	
	
	//// No?  Maybe we haven't loaded that part of the mesh from DB
	if (updatedSquare == nil) {
		
		// load that section of the Mesh
		[self includeLocationInLoadedGraph: aLocation];
		
		// check the loaded graph again
		updatedSquare = [self squareContainingLocation: aLocation];
		
	}
	
	
	
	//// still no?  must be a new location!
	// if updatedSquare == nil
	if (updatedSquare == nil) {
		updatedSquare = [self newSquareContainingLocation: aLocation];
	}
	
	return updatedSquare;
	
}


- (void) updateMeshAtLocation: (MPLocation*)aLocation isTraversible:(BOOL)canTraverse {
	

	MPSquare *updatedSquare = [self findOrCreateSquareContainingLocation:aLocation];
	
	// if updatedSquare != nil
	if (updatedSquare != nil) {
		
		// updatedSquare isTraversible:canTraverse
		[updatedSquare setIsTraversible:canTraverse];
		
		// previousSquare = updatedSquare
		self.previousSquare = updatedSquare;
		
	} // end if
	
}


- (void) resetSquareDisplay {
	PGLog(@"Resetting Square Displays ... ");
	/*
	for( MPSquare *square in allSquares) {
		square.myDrawRect = nil;
	}
	 */
}



- (MPSquare *) newSquareContainingLocation: (MPLocation *) aLocation {
	
	
	// ok get the surrounding points for this location:
	float locX, locY, locZ;
	locX = [aLocation xPosition];
	locY = [aLocation yPosition];
	locZ = [aLocation zPosition];
	
	float lowerX, upperX, lowerY, upperY, nextVal;
	nextVal = (locX >=0)? 1.0f: -1.0f;
	if ( locX >= 0 ) {
	
		lowerX = ( (int) (locX / squareWidth) * squareWidth);
		upperX = lowerX + (nextVal * squareWidth);
		
	} else {
		upperX = ( (int) (locX / squareWidth) * squareWidth);
		lowerX = upperX + (nextVal * squareWidth);
	}
	
	nextVal = (locY >=0)? 1.0f: -1.0f;
	if (locY >= 0) {
		lowerY = ( (int)(locY / squareWidth) * squareWidth);
		upperY = lowerY + (nextVal * squareWidth);
	} else {
		upperY = ( (int)(locY / squareWidth) * squareWidth);
		lowerY = upperY + (nextVal * squareWidth);
	}
	
	NSMutableArray *pointList = [NSMutableArray array];
	
	
	//// The order here is important:
	////   0  --  3    0(lowerX,upperY),   3(upperX, upperY)
	////   |      |
	////   1  --  2    1(lowerX,lowerY),   2(upperX, lowerY)
	////
	
	
	// Point 0:  
	MPLocation *location0 = [MPLocation locationAtX:lowerX Y:upperY Z:locZ];
	MPPoint *point0 = [self findOrCreatePointAtLocation: location0 withinZTolerance: toleranceZ];
	[pointList addObject:point0];
	
	// Point 1:  
	MPLocation *location1 = [MPLocation locationAtX:lowerX Y:lowerY Z:locZ];
	MPPoint *point1 = [self findOrCreatePointAtLocation: location1 withinZTolerance: toleranceZ];
	[pointList addObject:point1];
	
	// Point 2:  
	MPLocation *location2 = [MPLocation locationAtX:upperX Y:lowerY Z:locZ];
	MPPoint *point2 = [self findOrCreatePointAtLocation: location2 withinZTolerance: toleranceZ];
	[pointList addObject:point2];
	
	// Point 3:  
	MPLocation *location3 = [MPLocation locationAtX:upperX Y:upperY Z:locZ];
	MPPoint *point3 = [self findOrCreatePointAtLocation: location3 withinZTolerance: toleranceZ];
	[pointList addObject:point3];
	
	
	MPSquare *newSquare = [MPSquare squareWithPoints:pointList];
	[newSquare setZPos:locZ];
	
	[self connectSquare:newSquare];

	//// Now we have a new Square fully connected to our Graph (right?)
	//// so add to our list of squares :
	[allSquares addSquare: newSquare];
	
//PGLog(@" ---- new square : %@", [newSquare describe]);
	
	[self storeSquareInDB:newSquare];
	
	return newSquare;
	
	
}



- (void) connectSquare: (MPSquare *)newSquare {
	// This routine will scan the potential locations around this square to see if
	// there are any adjacent squares within the given zTolerance.  If there are,
	// we mark them as border connections.
	
	float lowerX, upperX, lowerY, upperY;
	float locZ = [newSquare zPos];
	
	//// figure out the x,y limits from the square's point list:
	//// The order here is important:
	////   0  --  3    0(lowerX,upperY),   3(upperX, upperY)
	////   |      |
	////   1  --  2    1(lowerX,lowerY),   2(upperX, lowerY)
	////
	
	MPPoint *point = [[newSquare points] objectAtIndex:1];
	lowerX = [[point location] xPosition];
	lowerY = [[point location] yPosition];
	
	point = [[newSquare points] objectAtIndex:3];
	upperX = [[point location] xPosition];
	upperY = [[point location] yPosition];
	
	
	
	MPSquare *possibleBorder = nil;
	MPSquare *lastBorder = nil;
	
	
	
	// Scan for Top Border connections
	float curX, curY, offset;
	offset = (squareWidth /2);
	MPLocation *currLocation;
	
	curX = lowerX + offset;  // 1/2 sqWidth in
	curY = upperY + offset;  // 1/2 sqWidth up
	
	int indx, countSteps;
	
	//// Top and bottom scans need to check along the X axis  (Width of the square) 
	countSteps = (upperX - lowerX) / squareWidth;
	
	for(indx=0; indx<countSteps; indx++ ) {
		
		currLocation = [MPLocation locationAtX:(curX + (indx*squareWidth)) Y:curY Z:locZ];
		
PGLog(@" --- connecting with location: %@", currLocation);
		possibleBorder = [self squareContainingLocation:currLocation];
		if (possibleBorder != nil) {
			
			// if this isn't the same as the last square we just added
			if (lastBorder != possibleBorder) {
				
				// newSquare addTopBorder possibleBorder
				[newSquare addTopBorderConnection: possibleBorder];
				[possibleBorder addBottomBorderConnection:newSquare];
				
				lastBorder = possibleBorder;
				
			}
		}
		
	}
	
	
	
	
	/// scan bottom border connections
	curX = lowerX + offset;
	curY = lowerY - offset;
	lastBorder = nil;
	for(indx=0; indx<countSteps; indx++ ) {
		
		currLocation = [MPLocation locationAtX:(curX + (indx*squareWidth)) Y:curY Z:locZ];
		
		possibleBorder = [self squareContainingLocation:currLocation];
		if (possibleBorder != nil) {
			
			if (lastBorder != possibleBorder) {
				
				// newSquare addTopBorder possibleBorder
				[newSquare addBottomBorderConnection: possibleBorder];
				[possibleBorder addTopBorderConnection:newSquare];
				
				lastBorder = possibleBorder;
			}
		}
		
	}
	
	
	
	
	////left and Right border connections depend on the difference in Y axis (Height)
	countSteps = (upperY - lowerY) / squareWidth;
	
	/// scan left border connections
	curX = lowerX - offset;
	curY = lowerY + offset;
	lastBorder = nil;
	for(indx=0; indx<countSteps; indx++ ) {
		
		currLocation = [MPLocation locationAtX:curX Y:(curY + (indx*squareWidth)) Z:locZ];
		
		possibleBorder = [self squareContainingLocation:currLocation];
		if (possibleBorder != nil) {
			
			if (lastBorder != possibleBorder) {
				
				// newSquare addTopBorder possibleBorder
				[newSquare addLeftBorderConnection: possibleBorder];
				[possibleBorder addRightBorderConnection:newSquare];
				
				lastBorder = possibleBorder;
			}
		}
		
	}
	
	
	/// scan Right border connections
	curX = upperX + offset;
	curY = lowerY + offset;
	lastBorder = nil;
	for(indx=0; indx<countSteps; indx++ ) {
		
		currLocation = [MPLocation locationAtX:curX Y:(curY + (indx*squareWidth)) Z:locZ];
		
		possibleBorder = [self squareContainingLocation:currLocation];
		if (possibleBorder != nil) {
			
			if (lastBorder != possibleBorder) {
				
				// newSquare addTopBorder possibleBorder
				[newSquare addRightBorderConnection: possibleBorder];
				[possibleBorder addLeftBorderConnection:newSquare];
				
				lastBorder = possibleBorder;
			}
		}
		
	}
	
	
}


- (MPSquare *) newSquareWithDimentionsMixX: (float) minX maxX: (float) maxX minY: (float) minY maxY:(float) maxY avgZ:(float) avgZ {
	
	
	
	NSMutableArray *pointList = [NSMutableArray array];
	
	
	//// The order here is important:
	////   0  --  3    0(minX,maxY),   3(maxX, maxY)
	////   |      |
	////   1  --  2    1(minX,minY),   2(maxX, minY)
	////
	
	
	// Point 0:  
	MPLocation *location0 = [MPLocation locationAtX:minX Y:maxY Z:avgZ];
	MPPoint *point0 = [self findOrCreatePointAtLocation: location0 withinZTolerance: toleranceZ];
	[pointList addObject:point0];
	
	// Point 1:  
	MPLocation *location1 = [MPLocation locationAtX:minX Y:minY Z:avgZ];
	MPPoint *point1 = [self findOrCreatePointAtLocation: location1 withinZTolerance: toleranceZ];
	[pointList addObject:point1];
	
	// Point 2:  
	MPLocation *location2 = [MPLocation locationAtX:maxX Y:minY Z:avgZ];
	MPPoint *point2 = [self findOrCreatePointAtLocation: location2 withinZTolerance: toleranceZ];
	[pointList addObject:point2];
	
	// Point 3:  
	MPLocation *location3 = [MPLocation locationAtX:maxX Y:maxY Z:avgZ];
	MPPoint *point3 = [self findOrCreatePointAtLocation: location3 withinZTolerance: toleranceZ];
	[pointList addObject:point3];
	
	
	MPSquare *newSquare = [MPSquare squareWithPoints:pointList];
	newSquare.zPos = avgZ;
	
	// the [MPSquare squareWithPoints] did some initial border checks based upon existing
	// point assignments.
	// but now we need to do more extensive checks based upon squares containing my points
	
	//// NOTE: don't have to worry about existing square returning from [squareContaintingLocation] because
	//// it hasn't been added to our list yet.
	
	MPSquare *possibleBorder = nil;
	MPSquare *lastBorder = nil;
	
	
	
	// Scan for Top Border connections
	float curX, curY, offset;
	offset = (squareWidth /2);
	MPLocation *currLocation;
	
	curX = minX + offset;  // 1/2 sqWidth in
	curY = maxY + offset;  // 1/2 sqWidth up
	
	int indx, countSteps;
	
	//// Top and bottom scans need to check along the X axis  (Width of the square) 
	countSteps = (maxX - minX) / squareWidth;
	
	for(indx=0; indx<countSteps; indx++ ) {
		
		currLocation = [MPLocation locationAtX:(curX + (indx*squareWidth)) Y:curY Z:avgZ];
		
		possibleBorder = [self squareContainingLocation:currLocation];
		if (possibleBorder != nil) {
			
			// if this isn't the same as the last square we just added
			if (lastBorder != possibleBorder) {
			
				// newSquare addTopBorder possibleBorder
				[newSquare addTopBorderConnection: possibleBorder];
				[possibleBorder addBottomBorderConnection:newSquare];
				
				lastBorder = possibleBorder;
				
			}
		}
		
//		[currLocation release];
		
	}
	
	
	
	/// scan bottom border connections
	curX = minX + offset;
	curY = minY - offset;
	lastBorder = nil;
	for(indx=0; indx<countSteps; indx++ ) {
		
		currLocation = [MPLocation locationAtX:(curX + (indx*squareWidth)) Y:curY Z:avgZ];
		
		possibleBorder = [self squareContainingLocation:currLocation];
		if (possibleBorder != nil) {
			
			if (lastBorder != possibleBorder) {
			
				// newSquare addTopBorder possibleBorder
				[newSquare addBottomBorderConnection: possibleBorder];
				[possibleBorder addTopBorderConnection:newSquare];
			
				lastBorder = possibleBorder;
			}
		}
		
//		[currLocation release];
		
	}
	
	
	////left and Right border connections depend on the difference in Y axis (Height)
	countSteps = (maxY - minY) / squareWidth;
	
	/// scan left border connections
	curX = minX - offset;
	curY = minY + offset;
	lastBorder = nil;
	for(indx=0; indx<countSteps; indx++ ) {
		
		currLocation = [MPLocation locationAtX:curX Y:(curY + (indx*squareWidth)) Z:avgZ];
		
		possibleBorder = [self squareContainingLocation:currLocation];
		if (possibleBorder != nil) {
			
			if (lastBorder != possibleBorder) {
			
				// newSquare addTopBorder possibleBorder
				[newSquare addLeftBorderConnection: possibleBorder];
				[possibleBorder addRightBorderConnection:newSquare];
			
				lastBorder = possibleBorder;
			}
		}
		
//		[currLocation release];
		
	}
	
	
	/// scan Right border connections
	curX = maxX + offset;
	curY = minY + offset;
	lastBorder = nil;
	for(indx=0; indx<countSteps; indx++ ) {
		
		currLocation = [MPLocation locationAtX:curX Y:(curY + (indx*squareWidth)) Z:avgZ];
		
		possibleBorder = [self squareContainingLocation:currLocation];
		if (possibleBorder != nil) {
			
			if (lastBorder != possibleBorder) {
				
				// newSquare addTopBorder possibleBorder
				[newSquare addRightBorderConnection: possibleBorder];
				[possibleBorder addLeftBorderConnection:newSquare];
				
				lastBorder = possibleBorder;
			}
		}
		
//		[currLocation release];
		
	}
	
		
	
	//// Now we have a new Square fully connected to our Graph (right?)
	//// so add to our list of squares :
	[allSquares addSquare: newSquare];
	
//	PGLog(@" ---- new square : %@", [newSquare describe]);
	return newSquare;
	
	
}



// if it can't find an existing point, then create a new one
- (MPPoint *) findOrCreatePointAtLocation: (MPLocation *) aLocation withinZTolerance: (float) zTolerance {
	
	MPPoint *point = [self pointAtLocation:aLocation withinZTolerance: zTolerance];
	
	if (point == nil) {
	
		point = [MPPoint pointAtX:[aLocation xPosition] Y:[aLocation yPosition] Z:[aLocation zPosition]];
		
		// add this point to our list of points
		[allPoints addPoint:point];
		[pointArray addObject:point];
	}
	return point;
}

- (MPPoint *) pointAtLocation: (MPLocation *) aLocation withinZTolerance: (float) zTolerance {
	
	/*
	NSMutableArray *listPoints = [NSMutableArray array];
	NSArray *copyPoints = [allPoints copy]; // prevents Threading Problems
	for (MPPoint* point in copyPoints ) {
		if ([point isAt:aLocation withinZTolerance:zTolerance] ) {
			[listPoints addObject:point];
		}
	}
	
	float currentDistance = 0.0f;
	float selectedDistance = INFINITY;
	MPPoint *selectedPoint = nil;
	for( MPPoint *point in listPoints) {
		currentDistance = [point zDistanceTo:aLocation];
		if (currentDistance < selectedDistance) {
			selectedDistance = currentDistance;
			selectedPoint = point;
		}
	}
	
	return selectedPoint;
	*/
	return [allPoints pointAtX:[aLocation xPosition] Y:[aLocation yPosition] Z:[aLocation zPosition]];
}



- (void) flushGraph {
	
	
	[[allSquares lock] lock];
	NSArray *listSquares = [[allSquares listSquares] copy];
	[[allSquares lock] unlock];
	
	// remove all our squares
	for( MPSquare *square in listSquares) {
		[allSquares removeSquare:square];
	}
	
	
	loadedXmin = 0;
	loadedXmax = 0;
	loadedYmin = 0;
	loadedYmax = 0;
	
}





- (BOOL) doesGraphContainLocation: (MPLocation *)aLocation {
	
	MPSquare *aSquare = [self squareContainingLocation:aLocation];
	return (aSquare != nil);
}


#pragma mark -
#pragma mark Optimization Routines


- (void) optimizeGraph {
	
	if ([[[PatherController sharedPatherController] enableGraphOptimizations] state] ) {
		
			
		int indxX=0;
		int indxY=0;
		float curX, curY;
		
		BOOL found = NO;
		
	//	float curZ = [[[PlayerDataController sharedController] position] zPosition];
		
		int countX = (loadedXmax - loadedXmin) / goalSize;
		int countY = (loadedYmax - loadedYmin) / goalSize;
		
		int baseX = (((int)(loadedXmin / goalSize)) * goalSize);
		int baseY = ((int)(loadedYmin / goalSize)) * goalSize;
		
		//MPPoint *point = nil;
		MPSquare *square = nil;
		
		for( indxX = 0; indxX < countX; indxX++) {
			
			for( indxY = 0; indxY < countY; indxY++) {
				
	//			curX = (loadedXmin + ((float)indxX * squareWidth));
				curX = baseX + (indxX * goalSize) + (goalSize -1);
				curY = baseY + (indxY * goalSize) + (goalSize -1);
				
				//point = [allPoints lowestPointAtX:curX Y:curY];
				//if (point != nil) {
				//	[self optimizeGraphAtPoint:point];
				//}
				square = [allSquares lowestSquareAtX:curX Y:curY];
				if (square != nil) {
					if (square.width < goalSize) {
					
						found = found || [self optimizeGraphAtSquare:square];
					}
				}
				
			}
		}
		
		PGLog(@"end of optimizations. indxX[%d]/[%d], indxY[%d]/[%d] curX[%0.2f] curY[%0.2f]", indxX, countX, indxY, countY,  curX, curY);
		
		// we didn't find any optimizations at our current goal, so try to increase
		if (!found) {
			goalSize = goalSize * 2;
			if (goalSize > graphChunkSize) 
				goalSize = squareWidth *2;
		}
		
	}
	
}



- (void) optimizeGraphAtPoint:(MPPoint *)currentPoint {
	
	
	// for each point in our graph
	
	NSMutableArray *newPoints = nil;
	
	
	// if [point canQuadReduce]
	if ([currentPoint canQuadReduce]) {
		
		MPSquare *urSquare, *ulSquare, *lrSquare, *llSquare, *curSquare;
		
		// Get Border Squares: Upper Left, Lower Left, Lower Right, Upper Right
		urSquare = [currentPoint upperRightSquare];
		ulSquare = [currentPoint upperLeftSquare];
		lrSquare = [currentPoint lowerRightSquare];
		llSquare = [currentPoint lowerLeftSquare];
		
		
		// getPoints = ULSquare.point[0] + LLSquare.points[1] + LRSquare.points[2] + URSquare.points[3]
		newPoints = [NSMutableArray array];
		[newPoints addObject:[[ulSquare points] objectAtIndex:0]];
		[newPoints addObject:[[llSquare points] objectAtIndex:1]];
		[newPoints addObject:[[lrSquare points] objectAtIndex:2]];
		[newPoints addObject:[[urSquare points] objectAtIndex:3]];
		
		
		// topConnections = Array[ ULSquare.topConnections + URSquare.topConnections]
		NSMutableArray *topConnections = [NSMutableArray array];
		for(curSquare in [ulSquare topBorderConnections]) {
			[topConnections addObject:curSquare];
		}
		for(curSquare in [urSquare topBorderConnections]) {
			[topConnections addObject:curSquare];
		}
		
		// leftConnections = Array[ ULSquare.leftConnections + LLSquare.leftConnections];
		NSMutableArray *leftConnections = [NSMutableArray array];
		for(curSquare in [ulSquare leftBorderConnections]) {
			[leftConnections addObject:curSquare];
		}
		for(curSquare in [llSquare leftBorderConnections]) {
			[leftConnections addObject:curSquare];
		}
		//[NSMutableArray arrayWithObjects:[ulSquare leftBorderConnections], [llSquare leftBorderConnections], nil];
		
		// bottomConnections = Array[ LLSquare.bottomConnections + LRSquare.bottomConnections ];
		NSMutableArray *bottomConnections = [NSMutableArray array];
		for(curSquare in llSquare.bottomBorderConnections) {
			[bottomConnections addObject:curSquare];
		}
		for(curSquare in lrSquare.bottomBorderConnections) {
			[bottomConnections addObject:curSquare];
		}
		
		//[NSMutableArray arrayWithObjects:[llSquare bottomBorderConnections], [lrSquare bottomBorderConnections], nil];
		
		// rightConnections = Array[ URSquare.rightConnections + LRSquare.rightConnections];
		NSMutableArray *rightConnections = [NSMutableArray array];
		for(curSquare in urSquare.rightBorderConnections) {
			[rightConnections addObject:curSquare];
		}
		for(curSquare in lrSquare.rightBorderConnections) {
			[rightConnections addObject:curSquare];
		}
		//[NSMutableArray arrayWithObjects:[urSquare rightBorderConnections], [lrSquare rightBorderConnections], nil];
		
		MPSquare *newSquare = [MPSquare squareWithPoints:newPoints connectByPoints:NO];
		
		newSquare.topBorderConnections = topConnections;
		for( curSquare in newSquare.topBorderConnections) {
			[curSquare addBottomBorderConnection:newSquare];
		}
		
		newSquare.leftBorderConnections = leftConnections;
		for( curSquare in newSquare.leftBorderConnections) {
			[curSquare addRightBorderConnection:newSquare];
		}
		
		newSquare.bottomBorderConnections = bottomConnections;
		for( curSquare in newSquare.bottomBorderConnections) {
			[curSquare addTopBorderConnection:newSquare];
		}
		
		newSquare.rightBorderConnections = rightConnections;
		for( curSquare in newSquare.rightBorderConnections) {
			[curSquare addLeftBorderConnection:newSquare];
		}
		
		// remove currentPoint from points & pointArray
		[allPoints removePointAtX:[[currentPoint location] xPosition] Y:[[currentPoint location] yPosition] Z:[[currentPoint location] zPosition]];
		//		[removePoints addObject:currentPoint];
		
		// [URSquare disconnectFromGraph] ... [LLSquare disconnectFromGraph]
		[urSquare disconnectFromGraph];
		[ulSquare disconnectFromGraph];
		[lrSquare disconnectFromGraph];
		[llSquare disconnectFromGraph];
		
		
		// remove Squares from DB
		[self removeSquareFromDB:urSquare];
		[self removeSquareFromDB:ulSquare];
		[self removeSquareFromDB:lrSquare];
		[self removeSquareFromDB:llSquare];
		
		// insert New Square into DB
		[self storeSquareInDB:newSquare];
		
		
	} // end if
	
	
	// now remove all those points that should be removed:
	//	[pointArray removeObject:currentPoint];
	
	
}



- (NSArray *) arraySquaresInQuadAroundSquare: (MPSquare *) currentSquare {
	
	MPPoint *pivotPoint = [[currentSquare points] objectAtIndex:1];
	
	float locX = [[pivotPoint location] xPosition];
	float locY = [[pivotPoint location] yPosition];
	float locZ = [[pivotPoint location] zPosition];
	float halfStep = squareWidth / 2;
	
	
	NSMutableArray *listSquares = [NSMutableArray array];
	
	[listSquares addObject:currentSquare]; // UR square
	
	
	
	//// Warning:  for development, I changed all the [self squareContainingLocation:] to
	////		   [self closestSquareContainingLocation:].  However this runs the risk of connecting
	////		   a lower graph with an upper graph square (think a path under a bridge connecting
	////		   with a piece on the bridge).  Might want to change this back after development.
	////
	
	
	MPSquare *square = [self closestSquareContainingLocation:[MPLocation locationAtX:(locX - halfStep) Y:(locY + halfStep) Z:locZ]];
	if((square == nil) || ([listSquares containsObject:square])) {
		return listSquares;
	}
	[listSquares addObject:square]; // UL Square
	
	
	square = [self closestSquareContainingLocation:[MPLocation locationAtX:(locX - halfStep) Y:(locY - halfStep) Z:locZ]];
	if((square == nil) || ([listSquares containsObject:square])) {
		return listSquares;
	}
	[listSquares addObject:square]; // LL Square
	
	
	square = [self closestSquareContainingLocation:[MPLocation locationAtX:(locX + halfStep) Y:(locY - halfStep) Z:locZ]];
	if((square == nil) || ([listSquares containsObject:square])) {
		return listSquares;
	}
	[listSquares addObject:square]; // LR Square
	
	
	// if we made it here, we have found 4 squares ... ready for Quad combinations.
	return listSquares;
	
	
}

- (BOOL) canQuadReduceSquares: (NSArray *) listSquares {
	
	if ([listSquares count] != 4)   return NO;
	
	
	int width = 0;
	int height = 0;
	float cost = 0;
	
	width = (int)[(MPSquare *)[listSquares objectAtIndex:0] width];
	height = (int)[(MPSquare *)[listSquares objectAtIndex:0] height];
	cost = [(MPSquare *)[listSquares objectAtIndex:0] costAdjustment];
	
	MPSquare *square = nil;
	
	// for each square
	for( square in listSquares) {
		
		// if ![square isReducable]  canReduce = NO;
		if (![square isReduceable]) return NO;
		
		// if width != square.width  canReduce = NO;
		if (width != (int)[square width]) return NO;
		
		// if height != square.height canReduce = NO;
		if (height != (int)[square height]) return NO;
		
		// if cost != square.costAdjustment canReduce = NO;
		if(cost != [square costAdjustment]) return NO;
		
	} // next Square
	
	return YES;

}



- (BOOL) optimizeGraphAtSquare:(MPSquare *)currentSquare {
	
	
	NSArray *quadSquares = [self arraySquaresInQuadAroundSquare:currentSquare];
	
	
	NSMutableArray *newPoints = nil;
	
//PGLog(@"  --- quadSquares c[%d] ", [quadSquares count] );
	// if [point canQuadReduce]
	if (![self canQuadReduceSquares:quadSquares]) {
		return NO;
	}
	
		
	MPSquare *urSquare, *ulSquare, *lrSquare, *llSquare, *curSquare;
	
	// Get Border Squares: Upper Left, Lower Left, Lower Right, Upper Right
	urSquare = [quadSquares objectAtIndex:0];
	ulSquare = [quadSquares objectAtIndex:1];
	llSquare = [quadSquares objectAtIndex:2];
	lrSquare = [quadSquares objectAtIndex:3];
	
	
	// getPoints = ULSquare.point[0] + LLSquare.points[1] + LRSquare.points[2] + URSquare.points[3]
	newPoints = [NSMutableArray array];
	[newPoints addObject:[[ulSquare points] objectAtIndex:0]];
	[newPoints addObject:[[llSquare points] objectAtIndex:1]];
	[newPoints addObject:[[lrSquare points] objectAtIndex:2]];
	[newPoints addObject:[[urSquare points] objectAtIndex:3]];
	
	
	// topConnections = Array[ ULSquare.topConnections + URSquare.topConnections]
	NSMutableArray *topConnections = [NSMutableArray array];
	for(curSquare in [ulSquare topBorderConnections]) {
		if (![topConnections containsObject:curSquare]) {
			[topConnections addObject:curSquare];
		}
	}
	for(curSquare in [urSquare topBorderConnections]) {
		if (![topConnections containsObject:curSquare]) {
			[topConnections addObject:curSquare];
		}
	}
	
	// leftConnections = Array[ ULSquare.leftConnections + LLSquare.leftConnections];
	NSMutableArray *leftConnections = [NSMutableArray array];
	for(curSquare in [ulSquare leftBorderConnections]) {
		if (![leftConnections containsObject:curSquare]) {
			[leftConnections addObject:curSquare];
		}
	}
	for(curSquare in [llSquare leftBorderConnections]) {
		if (![leftConnections containsObject:curSquare]) {
			[leftConnections addObject:curSquare];
		}
	}
	//[NSMutableArray arrayWithObjects:[ulSquare leftBorderConnections], [llSquare leftBorderConnections], nil];
	
	// bottomConnections = Array[ LLSquare.bottomConnections + LRSquare.bottomConnections ];
	NSMutableArray *bottomConnections = [NSMutableArray array];
	for(curSquare in llSquare.bottomBorderConnections) {
		if (![bottomConnections containsObject:curSquare]) {
			[bottomConnections addObject:curSquare];
		}
	}
	for(curSquare in lrSquare.bottomBorderConnections) {
		if (![bottomConnections containsObject:curSquare]) {
			[bottomConnections addObject:curSquare];
		}
	}
	
	//[NSMutableArray arrayWithObjects:[llSquare bottomBorderConnections], [lrSquare bottomBorderConnections], nil];
	
	// rightConnections = Array[ URSquare.rightConnections + LRSquare.rightConnections];
	NSMutableArray *rightConnections = [NSMutableArray array];
	for(curSquare in urSquare.rightBorderConnections) {
		if (![rightConnections containsObject:curSquare]) {
			[rightConnections addObject:curSquare];
		}
	}
	for(curSquare in lrSquare.rightBorderConnections) {
		if (![rightConnections containsObject:curSquare]) {
			[rightConnections addObject:curSquare];
		}
	}
	//[NSMutableArray arrayWithObjects:[urSquare rightBorderConnections], [lrSquare rightBorderConnections], nil];
	
	MPSquare *newSquare = [MPSquare squareWithPoints:newPoints connectByPoints:NO];
	
	newSquare.topBorderConnections = topConnections;
	for( curSquare in newSquare.topBorderConnections) {
		[curSquare addBottomBorderConnection:newSquare];
	}
	
	newSquare.leftBorderConnections = leftConnections;
	for( curSquare in newSquare.leftBorderConnections) {
		[curSquare addRightBorderConnection:newSquare];
	}
	
	newSquare.bottomBorderConnections = bottomConnections;
	for( curSquare in newSquare.bottomBorderConnections) {
		[curSquare addTopBorderConnection:newSquare];
	}
	
	newSquare.rightBorderConnections = rightConnections;
	for( curSquare in newSquare.rightBorderConnections) {
		[curSquare addLeftBorderConnection:newSquare];
	}
	
	
	// [URSquare disconnectFromGraph] ... [LLSquare disconnectFromGraph]
	[urSquare disconnectFromGraph];
	[ulSquare disconnectFromGraph];
	[lrSquare disconnectFromGraph];
	[llSquare disconnectFromGraph];
	
	
	// remove Squares from DB
	[self removeSquareFromDB:urSquare];
	[self removeSquareFromDB:ulSquare];
	[self removeSquareFromDB:lrSquare];
	[self removeSquareFromDB:llSquare];
	
	
	// remove from graph
	//[[allSquares lock] lock];
	[allSquares removeSquare:urSquare];
	[allSquares removeSquare:ulSquare];
	[allSquares removeSquare:llSquare];
	[allSquares removeSquare:lrSquare];
	//[[allSquares lock] unlock];
	
	
	// insert New Square into DB
	[self storeSquareInDB:newSquare];
	
	//[[allSquares lock] lock];
	[allSquares addSquare:newSquare];
	//[[allSquares lock] unlock];
		
	return YES;
	
	
	
}



- (void) removeSquare: (MPSquare *) aSquare {
	
	[aSquare disconnectFromGraph];
	[self removeSquareFromDB:aSquare];
	[allSquares removeSquare:aSquare];
	
}



- (NSMutableArray *) listLocationsOfMissingBorderConnectionsForSquare:(MPSquare *)square {
	//// Scan each border (top, left, bottom, right) and see if we are missing any 
	//// possible border connections, if so, add that location to the array
	
	NSMutableArray *listLocations = [NSMutableArray array];
	
	
	
	// This routine will scan the potential locations around this square to see if
	// there are any adjacent squares within the given zTolerance.  If there are,
	// we mark them as border connections.
	
	float lowerX, upperX, lowerY, upperY;
	
	
	//// figure out the x,y limits from the square's point list:
	//// The order here is important:
	////   0  --  3    0(lowerX,upperY),   3(upperX, upperY)
	////   |      |
	////   1  --  2    1(lowerX,lowerY),   2(upperX, lowerY)
	////
	
	MPPoint *point = [[square points] objectAtIndex:1];
	lowerX = [[point location] xPosition];
	lowerY = [[point location] yPosition];
	
	point = [[square points] objectAtIndex:3];
	upperX = [[point location] xPosition];
	upperY = [[point location] yPosition];
	
	
	
	MPSquare *possibleBorder = nil;
	MPSquare *lastBorder = nil;
	
	
	
	// Scan for Top Border connections
	float curX, curY, offset;
	offset = (squareWidth /2);
	MPLocation *currLocation;
	
	curX = lowerX + offset;  // 1/2 sqWidth in
	curY = upperY + offset;  // 1/2 sqWidth up
	
	float locZ = [square zPos];
	
	int indx, countSteps;
	
	//// Top and bottom scans need to check along the X axis  (Width of the square) 
	countSteps = (upperX - lowerX) / squareWidth;

	
	for(indx=0; indx<countSteps; indx++ ) {
		
		currLocation = [MPLocation locationAtX:(curX + (indx*squareWidth)) Y:curY Z:locZ];
//PGLog(@" --- current x:%0.2f, y:%0.2f, z:%0.2f, i:%d, countS:%d", curX, curY, locZ, indx, countSteps);
		possibleBorder = [self squareContainingLocation:currLocation];
		if (possibleBorder != nil) {
			
			
			if (![[square topBorderConnections] containsObject:possibleBorder]) {
				
				// current square didn't have this square listed, so add to list
				[listLocations addObject:currLocation];
			}

		} else {
			// didn't find a square here, so add location
			[listLocations addObject:currLocation];
		}
		
	}
	
	
	
	/// scan bottom border connections
	curX = lowerX + offset;
	curY = lowerY - offset;
	lastBorder = nil;
	for(indx=0; indx<countSteps; indx++ ) {
		
		currLocation = [MPLocation locationAtX:(curX + (indx*squareWidth)) Y:curY Z:locZ];
		
		possibleBorder = [self squareContainingLocation:currLocation];
		if (possibleBorder != nil) {
			
			if (![[square bottomBorderConnections] containsObject:possibleBorder]) {
				
				// current square didn't have this square listed, so add to list
				[listLocations addObject:currLocation];
			}
			
		} else {
			// didn't find a square here, so add location
			[listLocations addObject:currLocation];
		}
		
	}
	
	
	
	////left and Right border connections depend on the difference in Y axis (Height)
	countSteps = (upperY - lowerY) / squareWidth;
	
	/// scan left border connections
	curX = lowerX - offset;
	curY = lowerY + offset;
	lastBorder = nil;
	for(indx=0; indx<countSteps; indx++ ) {
		
		currLocation = [MPLocation locationAtX:curX Y:(curY + (indx*squareWidth)) Z:locZ];
		
		possibleBorder = [self squareContainingLocation:currLocation];
		if (possibleBorder != nil) {
			
			if (![[square leftBorderConnections] containsObject:possibleBorder]) {
				
				// current square didn't have this square listed, so add to list
				[listLocations addObject:currLocation];
			}
			
		} else {
			// didn't find a square here, so add location
			[listLocations addObject:currLocation];
		}
		
	}
	
	
	
	/// scan Right border connections
	curX = upperX + offset;
	curY = lowerY + offset;
	lastBorder = nil;
	for(indx=0; indx<countSteps; indx++ ) {
		
		currLocation = [MPLocation locationAtX:curX Y:(curY + (indx*squareWidth)) Z:locZ];
		
		possibleBorder = [self squareContainingLocation:currLocation];
		if (possibleBorder != nil) {
			
			if (![[square rightBorderConnections] containsObject:possibleBorder]) {
				
				// current square didn't have this square listed, so add to list
				[listLocations addObject:currLocation];
			}
			
		} else {
			// didn't find a square here, so add location
			[listLocations addObject:currLocation];
		}
		
	}
	
	
	return listLocations;
	
}



- (float) minAmountZMovementToConnectSquare: (MPSquare *)curSquare withSquare: (MPSquare *)missingSquare {
	
	float amountDiff = [curSquare zPos] - [missingSquare zPos];
	if (amountDiff < 0) amountDiff = amountDiff * -1;
	
	if (amountDiff < toleranceZ) return 0;
	
	float minAmountChange = amountDiff - toleranceZ;
	
	return minAmountChange + 0.2f;
	
}


- (void) nudgeConnectionsAtLocation:(MPLocation *)curLocation {
	
	// get square at location (closest)
	MPSquare *curSquare = [allSquares closestSquareAtLocation:curLocation];
	
	float maxAmount, minAmount;
	
	// for each location with a missing connection
	NSMutableArray *listMissingLocations = [self listLocationsOfMissingBorderConnectionsForSquare:curSquare];
	while ([listMissingLocations count] > 0) {
	
		// get closest square at missing location
		MPLocation *curLocation = [listMissingLocations objectAtIndex:0];
		[listMissingLocations removeObjectAtIndex:0];
		
		MPSquare *missingSquare = [allSquares closestSquareAtLocation:curLocation];
		
		if (missingSquare != nil) {
			
			// find min amount current square needs to change to connect
			minAmount = [self minAmountZMovementToConnectSquare: curSquare withSquare: missingSquare];
			
			// find max amount current square can move
			if( [curSquare zPos] > [missingSquare zPos]) {
				maxAmount = [curSquare maxAmountZDecreaseForTolerance:toleranceZ];
			} else{
				maxAmount = [curSquare maxAmountZIncreaseForTolerance:toleranceZ];
			}
			
			// if minAmount < maxAmount then
			if (minAmount <= maxAmount) {
				
				// change current Square z by minAmount
				if ([curSquare zPos] > [missingSquare zPos]) {
					[curSquare setZPos:([curSquare zPos] - minAmount)];
				} else {
					[curSquare setZPos:([curSquare zPos] + minAmount)];
PGLog(@" --- curSquare updated to: %@",curSquare);
				}
				
			} else {

				// change current square by maxAmount
				if ([curSquare zPos] > [missingSquare zPos]) {
					[curSquare setZPos:([curSquare zPos] - maxAmount)];
				} else {
					[curSquare setZPos:([curSquare zPos] + maxAmount)];
				}
				
				// get min amount sideSquare needs to move
				minAmount = [self minAmountZMovementToConnectSquare:missingSquare withSquare:curSquare];
				
			
				// get max amount sideSquare can move
				if( [missingSquare zPos] > [curSquare zPos]) {
					maxAmount = [missingSquare maxAmountZDecreaseForTolerance:toleranceZ];
				} else{
					maxAmount = [missingSquare maxAmountZIncreaseForTolerance:toleranceZ];
				}
				
				// if minAmount < maxAmount then  sideSquare change by minAmount
				if (minAmount < maxAmount) {
					
					// change sideSquare z by minAmount
					if ([missingSquare zPos] > [curSquare zPos]) {
						[missingSquare setZPos:([missingSquare zPos] - minAmount)];
					} else {
						[missingSquare setZPos:([missingSquare zPos] + minAmount)];
					}
					
				} else {
					
					//// in this case we can't seem to nudge either enough to connect
					//// but we'll just move it the maximum we can and hope for the best
					
					
					// change missing square by maxAmount
					if ([missingSquare zPos] > [curSquare zPos]) {
						[missingSquare setZPos:([missingSquare zPos] - maxAmount)];
					} else {
						[missingSquare setZPos:([missingSquare zPos] + maxAmount)];
					}
					
				} // end if min < max (second)
				
			}// end if min < max  (original)
			
			// attempt to reconnect this square now.
			[self connectSquare:curSquare];
			[self updateSquareInDB:curSquare];
		} // end if missingSquare != nil
		
	} // end While
}



- (int) squareCountAtLocation:(MPLocation *)location {
	return [allSquares countSquaresAtLocation: location];
}

#pragma mark -
#pragma mark Non Blocking Routing


- (void) setupRouteFromLocation: (MPLocation *)startLocation toLocation:(MPLocation *)destLocation {
	
	// make sure both locations are within the currently loaded graph
	[self includeLocationInLoadedGraph:startLocation];
	[self includeLocationInLoadedGraph:destLocation];
	
	// store currentStart, currentDest
	self.currentStartLocation = startLocation;
	self.currentDestLocation = destLocation;
	
	// isCurrentRouteValid = NO
	isCurrentRouteValid = NO;
	
	// reset A* routing data
	MPSquare *square;
	for( MPPathNode* node in currentOpenList) {
		square = node.square;
		square.isConsideredForPath = NO;
	}
	for( MPPathNode* node in currentClosedList) {
		square = node.square;
		square.isConsideredForPath = NO;
	}
	[currentOpenList removeAllObjects];
	[currentClosedList removeAllObjects];
	self.foundPath = nil;
	
	
	
	
	
	// find square with current location
	self.currentStartSquare = [allSquares squareAtX:[startLocation xPosition] Y:[startLocation yPosition] Z:[startLocation zPosition]];
	
	
	//// check for grid problems with starting location:
	self.gridProblemStart = nil;
	if (currentStartSquare == nil) {
		
		// oops, we are off the grid!  attempt to route to closest grid location.
		self.gridProblemStart = startLocation;
		self.currentStartSquare = [self recursiveSquareFinderAroundLocation:startLocation atRadius:1 limitAttempts:15];
		self.currentStartLocation = [currentStartSquare locationOfMidPoint];
	}
	
	
	//// check for grid problems with ending location
	self.gridProblemEnd = nil;
	MPSquare *endSquare = [self squareContainingLocation:destLocation];
	if (endSquare == nil) {
		
		// oops: end location is off the grid!
		self.gridProblemEnd = destLocation;
		endSquare = [self recursiveSquareFinderAroundLocation:destLocation atRadius:1 limitAttempts:15];
		if (endSquare != nil) {
			// destLocation = [endSquare midPoint];
			self.currentDestLocation = [endSquare locationOfMidPoint];
		}
	}
	
	
	if (currentStartSquare != nil) {
		state = NavRoutingStateGeneratingRoute;
		self.completedRoute = [Route route]; // empty route
		
		
		// setup initial A* node:
		MPPathNode *startNode = [MPPathNode nodeWithSquare:currentStartSquare];
		[startNode setReferencePointTowardsLocation:currentDestLocation];
		
		[startNode setCostG: 0 ];
		[startNode setCostH: 0 ];
		
		[currentOpenList addObject:startNode];
		
	} else {
		// state = CantRoute
		state = NavRoutingStateNoCanDo;
	}
	
}


- (MPSquare *) recursiveSquareFinderAroundLocation:(MPLocation *)location atRadius:(int)currentRadius limitAttempts:(int)maxRadius {
	
	MPSquare *found = nil;
	float minDistance = INFINITY;  // for finding the closest square 
	
	float locX, locY, locZ;
	locX = [location xPosition];
	locY = [location yPosition];
	locZ = [location zPosition];
	
	int indx;
	float curX, curY;
	
	
	//// scan top and bottom boundries
	float topY, bottomY;
	topY = locY + ( currentRadius * squareWidth);
	bottomY = locY - (currentRadius * squareWidth);

	NSMutableArray *listCoordinates = [NSMutableArray array];
	
	for(indx =0; indx<= currentRadius; indx++) {
		if (indx == 0) {
			[listCoordinates addObject:[NSArray arrayWithObjects:[NSNumber numberWithFloat:locX], [NSNumber numberWithFloat:topY], nil]];
			[listCoordinates addObject:[NSArray arrayWithObjects:[NSNumber numberWithFloat:locX], [NSNumber numberWithFloat:bottomY], nil]];

		} else {
			
			//// Q1 & Q3:
			curX = locX - (indx * squareWidth);
			[listCoordinates addObject:[NSArray arrayWithObjects:[NSNumber numberWithFloat:curX], [NSNumber numberWithFloat:topY], nil]];
			[listCoordinates addObject:[NSArray arrayWithObjects:[NSNumber numberWithFloat:curX], [NSNumber numberWithFloat:bottomY], nil]];
			
			//// Q2 & Q4:
			curX = locX + (indx * squareWidth);
			[listCoordinates addObject:[NSArray arrayWithObjects:[NSNumber numberWithFloat:curX], [NSNumber numberWithFloat:topY], nil]];
			[listCoordinates addObject:[NSArray arrayWithObjects:[NSNumber numberWithFloat:curX], [NSNumber numberWithFloat:bottomY], nil]];

		}
	}
	
	
	
	//// scan left and right boundries
	float leftX, rightX;
	leftX = locX - ( currentRadius * squareWidth);
	rightX = locX + (currentRadius * squareWidth);
	
	for( indx = 0; indx <= (currentRadius-1); indx++) {
		
		if (indx == 0) {
			
			curY = locY;
			[listCoordinates addObject:[NSArray arrayWithObjects:[NSNumber numberWithFloat:leftX], [NSNumber numberWithFloat:curY], nil]];
			[listCoordinates addObject:[NSArray arrayWithObjects:[NSNumber numberWithFloat:rightX], [NSNumber numberWithFloat:curY], nil]];
			
		} else {
			
			curY = locY + (indx * squareWidth);
			[listCoordinates addObject:[NSArray arrayWithObjects:[NSNumber numberWithFloat:leftX], [NSNumber numberWithFloat:curY], nil]];
			[listCoordinates addObject:[NSArray arrayWithObjects:[NSNumber numberWithFloat:rightX], [NSNumber numberWithFloat:curY], nil]];
			
			curY = locY - (indx * squareWidth);
			[listCoordinates addObject:[NSArray arrayWithObjects:[NSNumber numberWithFloat:leftX], [NSNumber numberWithFloat:curY], nil]];
			[listCoordinates addObject:[NSArray arrayWithObjects:[NSNumber numberWithFloat:rightX], [NSNumber numberWithFloat:curY], nil]];
		}
		
	}

	
	
	MPSquare *tempSquare;
	MPLocation *searchLocation;
	float currDistance;
	
	for( NSArray *coord in listCoordinates) {
		
		NSNumber *xPos = [coord objectAtIndex:0];
		NSNumber *yPos = [coord objectAtIndex:1];
		
		searchLocation = [MPLocation locationAtX:[xPos floatValue] Y:[yPos floatValue] Z:locZ];
		tempSquare = [self squareContainingLocation:searchLocation];
		
		if (tempSquare != nil) {
			currDistance = [[tempSquare locationOfMidPoint] distanceToPosition: location];
			if ( currDistance < minDistance) {
				minDistance = currDistance;
				found = tempSquare;
			}
		}
	}
	
	
	
	
	// if nothing found at current Radius then increase and try again:
	if (found == nil) {
		
		// but don't go beyond our limit
		if (currentRadius < maxRadius) {
			found = [self recursiveSquareFinderAroundLocation:location atRadius:(currentRadius +1) limitAttempts:maxRadius];
		}
	}
	
	return found;
	
	
}


- (BOOL) isRouteWorkComplete {
	
	int indx, countLocations;
	Position *tempPosition;
	[timerWorkTime start];

//PGLog(@" state[%d]  destLoc[ %@ ] ", state,  currentDestLocation);
	
	switch (state) {
		case NavRoutingStateGeneratingRoute:			
			if ([self isPathWorkComplete]) {
				
				// TO DO: how to handle an incomplete route?
				// current is to just go with the closest we know about.
				
				[self updateRouteDisplay:foundPath];

				
				// create list of points in mid-point of square edges
				self.currentListAllPathLocations = [self listLocationsFromPathNode:foundPath];
				[currentListAllPathLocations insertObject:currentStartLocation atIndex:0];
				[currentListAllPathLocations addObject:currentDestLocation]; // add destination location at end
								
				// prepare for optimization work:
				currentOptimizationLocC = [currentListAllPathLocations count]-1;
				currentOptimizationLocB = currentOptimizationLocC -1;
				currentOptimizationLocA = currentOptimizationLocB -1;
				
				[currentListOptimizedLocations removeAllObjects];
				[currentListOptimizedLocations addObject:[currentListAllPathLocations lastObject]];
							
				state = NavRoutingStateOptimizingRoute;
				if ([self isOptimizationWorkComplete]) {
				
					// current list of optimized locations are in Reverse Order, so reverse them into the Route
					countLocations = [currentListOptimizedLocations count];
					for(indx=1; indx <= countLocations; indx++) {
						tempPosition = [currentListOptimizedLocations objectAtIndex:(countLocations - indx)];
						[completedRoute addWaypoint:[Waypoint waypointWithPosition:tempPosition]];
					}
					/*// convert remaining points into waypoints and insert into newRoute
					for( MPLocation *location in currentListOptimizedLocations) {
						[completedRoute addWaypoint:[Waypoint waypointWithPosition:location]];
					}
					 */

					state = NavRoutingStateDone;
					isCurrentRouteValid = YES;
					return YES;

				}
			}
			break;
			
		case NavRoutingStateOptimizingRoute:
PGLog( @"   ---  optimizing route --- ");
			
			if ([self isOptimizationWorkComplete]) {
				
				countLocations = [currentListOptimizedLocations count];
				for(indx=1; indx <= countLocations; indx++) {
					tempPosition = [currentListOptimizedLocations objectAtIndex:(countLocations - indx)];
					[completedRoute addWaypoint:[Waypoint waypointWithPosition:tempPosition]];
				}
				
				
				// now check to see if we had gridProblems and update route to attempt direct 
				// running to off-grid locations
				if (gridProblemStart != nil) {
					[completedRoute insertWaypoint:[Waypoint waypointWithPosition:gridProblemStart]  atIndex:0];
				}
				if (gridProblemEnd != nil) {
					[completedRoute addWaypoint: [Waypoint waypointWithPosition:gridProblemEnd]];
				}
				
				
				state = NavRoutingStateDone;
				isCurrentRouteValid = YES;
				return YES;
				
			}
			break;
		
		default:
		case NavRoutingStateDone:
		case NavRoutingStateNoCanDo:
			return YES;
			break;

	}
	
	return NO;
	
}


- (BOOL) isRouteValid {
	return isCurrentRouteValid;
}



// following generated by synthesize:
//- (Route *) completedRoute {
//	return completedRoute;
//}



- (BOOL) isPathWorkComplete {
	
	
	MPPathNode *currentNode = nil;
	MPPathNode *aNode = nil;
	
	while(( [currentOpenList count]) && (![timerWorkTime ready]) ) {
		
		currentNode = [self lowestCostNodeInArray:currentOpenList];
		if ( [[currentNode square] containsLocation:currentDestLocation] ) {
			
			//// Path Found
			self.foundPath = currentNode;
			return YES;
			
			
		} else {
			
			MPSquare *currentSquare = [currentNode square];
			currentSquare.isConsideredForPath = YES;
			
			[currentClosedList addObject:currentNode];
			[currentOpenList removeObject:currentNode];
			
			NSArray *adjacentSquares = [[currentNode square] adjacentSquares];
			
			for (MPSquare *square in adjacentSquares ) {
				
				if ([square isTraversible] ) {
					
					if (![self isSquare:square inNodeList:currentClosedList]) {
						
						
						aNode = [self nodeWithSquare: square fromNodeList: currentOpenList];
						if (aNode == nil) {
							
							aNode = [MPPathNode nodeWithSquare:square];
							[aNode setParent:currentNode];
							[aNode setReferencePointTowardsLocation: currentDestLocation];
							
							int costH = [self costFromNode: aNode toLocation:currentDestLocation];
							[aNode setCostH: costH];
							[currentOpenList addObject:aNode];
						}
						
						
						int costG = [currentNode costG] + [self costFromNode:currentNode  toNode:aNode];
						
						
						if ([aNode costG] != 0) {
							
							if ([aNode costG] > costG) {
								
								[aNode setCostG: costG];
								[aNode setParent:currentNode];
							}
							
						} else {
							[aNode setCostG:costG];
						}
						
						
					}
				}
			}
			
		}
		
	}

	
	if ([currentOpenList count] == 0) {
		
		// ran out of known path options, so failure:
		
		// TO DO: figure out how to handle this type of failure
		// for now we just go with the best option we know about.
		
		// currentNode was the last point we tried, so that is the closest
		// we know about ... go ahead and assign it.
		self.foundPath = currentNode;
		return YES; // work is complete
	}
	
	
	return NO;
}



- (BOOL) isOptimizationWorkComplete {
	
	
	
	MPSquare *startSquare = nil;
	MPLocation *startLocation, *endLocation;
	
	while ((currentOptimizationLocA >= 0) && (![timerWorkTime ready])){
		
		startLocation = [currentListAllPathLocations objectAtIndex:currentOptimizationLocA];
		endLocation = [currentListAllPathLocations objectAtIndex:currentOptimizationLocC];
		
		startSquare = [allSquares squareAtLocation:[currentListAllPathLocations objectAtIndex:currentOptimizationLocA]];
		
		if ([startSquare hasClearPathFrom:startLocation to:endLocation]) {
			
			currentOptimizationLocB = currentOptimizationLocA;
			currentOptimizationLocA --;
			
		} else {
			
			[currentListOptimizedLocations addObject:[currentListAllPathLocations objectAtIndex:currentOptimizationLocB]];
			currentOptimizationLocC = currentOptimizationLocB;
			currentOptimizationLocB = currentOptimizationLocA;
			currentOptimizationLocA --;
		}
		
	}
	
	
	if (currentOptimizationLocA < 0) {
		[currentListOptimizedLocations addObject:[currentListAllPathLocations objectAtIndex:0]];
	
		return YES;
	}
	
	PGLog(@"  +++ locA[%d] locB[%d] locC[%d] ", currentOptimizationLocA, currentOptimizationLocB, currentOptimizationLocC);
	return NO;
}



- (Route *) bestCurrentRoute {
	// this is used when you want the best current option
	
	Route *newRoute = [Route route];
	
	// get lowest cost node
	MPPathNode * pathNode = [self lowestCostNodeInArray:currentOpenList];
	
	[self updateRouteDisplay:pathNode];
	
	// create list of points in mid-point of square edges
	NSMutableArray *listAllLocations = [self listLocationsFromPathNode:pathNode];
	[listAllLocations insertObject:currentStartLocation atIndex:0];

	
	
	// optimize the points (remove unnecessary)
	NSMutableArray *listLocations = [self reduceLocations:listAllLocations];
	//		NSMutableArray *listLocations = listAllLocations;
	
	// convert remaining points into waypoints and insert into newRoute
	int indx;
	int countLocations = [listLocations count];
	for(indx=1; indx <= countLocations; indx++) {
		[newRoute addWaypoint:[Waypoint waypointWithPosition:[listLocations objectAtIndex:(countLocations-indx)]]];
	}
	
	return newRoute;
}

#pragma mark -
#pragma mark Navigation and Routing


- (Route *) routeFromLocation: (MPLocation*)startLocation toLocation: (MPLocation*)destLocation {
	
	Route *newRoute = [Route route];
	
	// make sure both locations are within the currently loaded graph
	[self includeLocationInLoadedGraph:startLocation];
	[self includeLocationInLoadedGraph:destLocation];
	
	
	// find square with current location
	MPSquare *currentSquare = [allSquares squareAtX:[startLocation xPosition] Y:[startLocation yPosition] Z:[startLocation zPosition]];
	
	if (currentSquare != nil) {
		
		// use A* Routing to find series of squares from here to given destLocation
		MPPathNode * pathNode = [self pathFromSquare:currentSquare toLocation:destLocation];
		
		[self updateRouteDisplay:pathNode];
		
		// create list of points in mid-point of square edges
		NSMutableArray *listAllLocations = [self listLocationsFromPathNode:pathNode];
		[listAllLocations insertObject:startLocation atIndex:0];
		[listAllLocations addObject:destLocation]; // add destination location at end
		
		
		// optimize the points (remove unnecessary)
		NSMutableArray *listLocations = [self reduceLocations:listAllLocations];
//		NSMutableArray *listLocations = listAllLocations;
		
		// convert remaining points into waypoints and insert into newRoute
		int indx;
		int countLocations = [listLocations count];
		for(indx=1; indx <= countLocations; indx++) {
			[newRoute addWaypoint:[Waypoint waypointWithPosition:[listLocations objectAtIndex:(countLocations-indx)]]];
		}
		//for( MPLocation *location in listLocations) {
		//	[newRoute addWaypoint:[Waypoint waypointWithPosition:location]];
		//}
	}
	
	return newRoute;
	
}


- (MPPathNode *) pathFromSquare: (MPSquare *)currentSquare toLocation:(MPLocation *)destLocation {
	
	NSMutableArray *openList, *closedList;
	openList = [NSMutableArray array];
	closedList = [NSMutableArray array];
	
	MPPathNode *currentNode = nil;
	MPPathNode *aNode = nil;
	MPPathNode *startNode = [MPPathNode nodeWithSquare:currentSquare];
	[startNode setReferencePointTowardsLocation:destLocation];
	
	[startNode setCostG: 0 ];
	[startNode setCostH: 0 ];
	
	[openList addObject:startNode];
	
	while( [openList count] ) {
		
		currentNode = [self lowestCostNodeInArray:openList];
		if ( [[currentNode square] containsLocation:destLocation] ) {
			
			//// Path Found
			return currentNode;
			
			
		} else {
			
			[closedList addObject:currentNode];
			[openList removeObject:currentNode];
			
			NSArray *adjacentSquares = [[currentNode square] adjacentSquares];
			
			for (MPSquare *square in adjacentSquares ) {
				
				if ([square isTraversible] ) {
			
					if (![self isSquare:square inNodeList:closedList]) {
						
						
						aNode = [self nodeWithSquare: square fromNodeList: openList];
						if (aNode == nil) {
							
							aNode = [MPPathNode nodeWithSquare:square];
							[aNode setParent:currentNode];
							[aNode setReferencePointTowardsLocation: destLocation];
							
							int costH = [self costFromNode: aNode toLocation:destLocation];
							[aNode setCostH: costH];
							[openList addObject:aNode];
						}
						
						
						int costG = [currentNode costG] + [self costFromNode:currentNode  toNode:aNode];
						
					
						if ([aNode costG] != 0) {
						
							if ([aNode costG] > costG) {
								
								[aNode setCostG: costG];
								[aNode setParent:currentNode];
							}
							
						} else {
							[aNode setCostG:costG];
						}
					
					
					}
				}
			}
			
		}
		
	}
	
	return currentNode;
}


- (MPPathNode *) lowestCostNodeInArray:(NSMutableArray*) anArray {
	//Finds the node in a given array which has the lowest cost
	MPPathNode *n, *lowest;
	lowest = nil;
	NSEnumerator *e = [anArray objectEnumerator];
	if(e)
	{
		while((n = [e nextObject]))
		{
			if(lowest == nil)
			{
				lowest = n;
			}
			else
			{
				if(n.cost < lowest.cost)
				{
					lowest = n;
				}
			}
		}
		return lowest;
	}
	return nil;
}
					


- (BOOL ) isSquare: (MPSquare *)aSquare inNodeList: (NSArray*) nodeList {
	
	MPPathNode *node;
		
	NSEnumerator *e = [nodeList objectEnumerator];
	if(e)
	{
		while((node = [e nextObject]))
		{
			if (aSquare == [node square]) {
				return YES;
			}
		}
	}
	return NO;
}
						
						
- (MPPathNode *) nodeWithSquare: (MPSquare *)aSquare fromNodeList: (NSArray *) nodeList {
	MPPathNode *node;
	
	NSEnumerator *e = [nodeList objectEnumerator];
	if(e)
	{
		while((node = [e nextObject]))
		{
			if (aSquare == [node square]) {
				return node;
			}
		}
	}
	return nil;
}

					
- (int) costFromNode: (MPPathNode *) currentNode  toNode:(MPPathNode *)aNode {
	
	return [self costFromNode:currentNode toLocation: [[aNode referencePoint] location]];
}



- (int) costFromNode: (MPPathNode *)currentNode  toLocation:(MPLocation *) location {
		
	// for now just do raw distance.  I'm sure there is a better way 
	float rawDistance = [[[currentNode referencePoint] location] distanceToPosition2D:location];
	int distance = (int) (rawDistance * 1000.0);
	return distance;
}


- (void) updateRouteDisplay: (MPPathNode *)aNode {
	
	MPPathNode *currentNode = self.currentPath;
	
	// erase the previous path settings
	while (currentNode != nil) {
		[[currentNode square] setOnPath:NO];
		currentNode = [currentNode parent];
	}
	
	// now mark current path settings
	PGLog( @"---- New Route ----");
	
	currentNode = aNode;
	while (currentNode != nil) {
//		PGLog(@"----  %@ ", [currentNode describe]);
		[[currentNode square] setOnPath:YES];
		currentNode = [currentNode parent];
	}
	
	self.currentPath = aNode;
}



- (NSMutableArray *) listLocationsFromPathNode: (MPPathNode *)pathNode {
	
	NSMutableArray *listLocations = [NSMutableArray array];
	
	MPPathNode *current, *next;
	current = pathNode;
	next = [current parent];
	
	MPSquare *currentSquare, *nextSquare;
	
	MPLocation *intersectionLocation = nil;
	
	while (next != nil) {
		
		currentSquare = [current square];
		nextSquare = [next square];
		
		intersectionLocation = [currentSquare locationOfIntersectionWithSquare:nextSquare];
		
		[listLocations insertObject:intersectionLocation atIndex:0];
		
		current = next;
		next = [current parent];
	}
	
	return listLocations;
}

- (NSMutableArray *) reduceLocations: (NSMutableArray *)listAllLocations {
	
	int locationA, locationB, locationC;
	
	NSMutableArray *locations = [NSMutableArray array];
	
	locationC = [listAllLocations count] -1;
	locationB = locationC -1;
	locationA = locationB -1;
	
	[locations addObject:[listAllLocations lastObject]];
	
	MPSquare *startSquare = nil;
	MPLocation *startLocation, *endLocation;
	
	while (locationA >= 0) {
	
		startLocation = [listAllLocations objectAtIndex:locationA];
		endLocation = [listAllLocations objectAtIndex:locationC];
		
		startSquare = [allSquares squareAtLocation:[listAllLocations objectAtIndex:locationA]];
		
		if ([startSquare hasClearPathFrom:startLocation to:endLocation]) {
			
			locationB = locationA;
			locationA --;
			
		} else {
			
			[locations addObject:[listAllLocations objectAtIndex:locationB]];
			locationC = locationB;
			locationB = locationA;
			locationA --;
		}
		
	}
	
	[locations addObject:[listAllLocations objectAtIndex:0]];
	
	return locations;
	
}



#pragma mark -
#pragma mark DB Operations



- (void) openMeshData: (NSString *) folderPatherData {
	
	
	/*
	 *
	 // Option: Try to load DB into a RAM copy & use SQLite to query which square a given location is in,
	 // then use a simple AVL tree to store in memory squares by ID and retrieve the given ID for the found square.
	 
	 // How to move SQLite into memory:
	 //
	 What do you mean by loading it into memory?
	 If you want to dump the on-disk tables into memory and also want to
	 check the memory footprint used for caching try this:
	 
	 Open the :memory: database and attach the on-disk database with
	 ATTACH filename.db AS filename
	 
	 Then do a 
	 CREATE TABLE tableName AS SELECT * FROM filename.tableName
	 On each table in the file, thus creating an in-memory copy of the DB and
	 having done a select on each table (i.e. you'll see how much cache in
	 memory will be used, etc.)
	 
	 You can enumerate all tables in a your on-disk-file in the mentioned
	 scenario by doing a "SELECT tbl_name FROM filename.sqlite_master WHERE
	 type = 'table'".
	 
	 Best regards,
	 Stefan.
	 
	 
	 // to open an in memory DB:  (http://www.sqlite.org/inmemorydb.html)
	 //
	 *
	 */
	
	
	
	NSString* pathMeshDir = [folderPatherData stringByAppendingFormat:@"/mesh"];
	
	
	
	NSFileManager *fileManager = [[NSFileManager alloc] init];
	BOOL isDir;
	
	
    if (!([fileManager fileExistsAtPath:pathMeshDir isDirectory:&isDir] && isDir)) {
		
		// create the mesh directory:
		[fileManager createDirectoryAtPath:pathMeshDir withIntermediateDirectories:NO attributes:nil error:NULL ];
		
		
	}
	
	
	NSString* path = [pathMeshDir stringByAppendingFormat:@"/mesh.db"];
	db = [[PLSqliteDatabase alloc] initWithPath: path];
	
	if (![db open]) {
		PGLog(@" ---- Could not open database");
	}
	
	
	// now verify our navigation tables are there.
	if (![db tableExists:@"squares"]) {
		
		// not there so make them:
		NSString * sqlCreateTable = [NSString stringWithString:@"CREATE TABLE squares ( id INTEGER PRIMARY KEY, name TEXT, minX REAL, maxX REAL, minY REAL, maxY REAL, zPos REAL, traversible INTEGER, cost REAL);"];
		if (![db executeUpdate: sqlCreateTable]) {
			PGLog(@" ---- Error!  Can't create table 'squares'!");
		}
		
	}
	
	
	[fileManager release];
	
}


- (void) includeLocationInLoadedGraph: (MPLocation *) location  {
	
	float locX = [location xPosition];
	float locY = [location yPosition];
//	float locZ = [location zPosition];
	
	// if location within currently loaded graph, return;
	if ((loadedXmin <= locX) && (locX <= loadedXmax) &&
		(loadedYmin <= locY) && (locY <= loadedYmax)) {
		return;
	}
	
	
	// if location above graph, 
	if (locY > loadedYmax) {
		
		// load top graph,
		[self loadTopGraph:(locY + graphChunkSize)];
	}

	// if location below graph
	if (locY < loadedYmin) {
		// load below graph
		[self loadBottomGraph:(locY - graphChunkSize)];
		
	}

	// if location to right of graph
	if (locX > loadedXmax) {
		// load right graph
		[self loadRightGraph:(locX + graphChunkSize)];
	
	}

	// if location to left of graph
	if (locX < loadedXmin) {
		// load left graph
		[self loadLeftGraph:(locX - graphChunkSize)];
	}
}


- (void) loadTopGraph: (float) newYmax {
	
	if (newYmax > loadedYmax) {
		
		NSString *condition = [NSString stringWithFormat:@"(((minX >= %0.2f) AND (minX <= %0.2f)) OR ((maxX >= %0.2f) AND (maxX <= %0.2f))) AND ((minY >= %0.2f) AND (minY <= %0.2f))", loadedXmin, loadedXmax, loadedXmin, loadedXmax, loadedYmax, newYmax ];
		[self loadGraphChunkWithCondition: condition];
		loadedYmax = newYmax;
	}
}


- (void) loadBottomGraph: (float) newYmin {
	
	if (newYmin < loadedYmin) {
		
		//[self loadGraphChunkWithXmin: loadedXmin xMax:loadedXmax yMin:newYmin yMax:loadedYmin];
		NSString *condition = [NSString stringWithFormat:@"(((minX >= %0.2f) AND (minX <= %0.2f)) OR ((maxX >= %0.2f) AND (maxX <= %0.2f))) AND ((maxY >= %0.2f) AND (maxY <= %0.2f))", loadedXmin, loadedXmax, loadedXmin, loadedXmax, newYmin, loadedYmin ];
		[self loadGraphChunkWithCondition: condition];
		loadedYmin = newYmin;
	}
}


- (void) loadRightGraph: (float) newXmax {
	
	if (newXmax > loadedXmax) {
		
		//[self loadGraphChunkWithXmin: loadedXmax xMax:newXmax yMin:loadedYmin yMax:loadedYmax];
		NSString *condition = [NSString stringWithFormat:@"((minX >= %0.2f) AND (minX <= %0.2f)) AND (((maxY >= %0.2f) AND (maxY <= %0.2f)) OR ((minY >= %0.2f) AND (minY <= %0.2f)))",loadedXmax, newXmax, loadedYmin, loadedYmax, loadedYmin, loadedYmax  ];
		[self loadGraphChunkWithCondition: condition];
		
		
		loadedXmax = newXmax;
	}
}


- (void) loadLeftGraph: (float) newXmin {
	
	if (newXmin < loadedXmin) {
		
		//[self loadGraphChunkWithXmin: loadedXmax xMax:newXmax yMin:loadedYmin yMax:loadedYmax];
		NSString *condition = [NSString stringWithFormat:@"((maxX >= %0.2f) AND (maxX <= %0.2f)) AND (((maxY >= %0.2f) AND (maxY <= %0.2f)) OR ((minY >= %0.2f) AND (minY <= %0.2f)))",newXmin, loadedXmin, loadedYmin, loadedYmax, loadedYmin, loadedYmax  ];
		[self loadGraphChunkWithCondition: condition];
		
		loadedXmin = newXmin;
	}
}


- (void) loadInitialGraphChunkAroundLocation:(MPLocation *) location   {
	
	
	if ((loadedXmin == loadedXmax) && (loadedYmin == loadedYmax)) {
		
		float minX, maxX, minY, maxY, posZ, halfChunk;
		halfChunk = (graphChunkSize /2);
		minX = [location xPosition] - halfChunk;
		maxX = [location xPosition] + halfChunk;
		minY = [location yPosition] - halfChunk;
		maxY = [location yPosition] + halfChunk;
		posZ = [location zPosition];
		NSString *condition = [NSString stringWithFormat:@"( ((minX >= %0.2f) AND (minX <= %0.2f)) OR ((maxX >= %0.2f) AND (maxX <= %0.2f)) ) AND ( ((minY >= %0.2f) AND (minY <= %0.2f)) OR ((maxY >= %0.2f) AND (maxY <= %0.2f)) )", minX, maxX,minX,maxX, minY, maxY, minY, maxY];
		
		[self loadGraphChunkWithCondition:condition];
		
		loadedXmin = minX;
		loadedXmax = maxX;
		loadedYmin = minY;
		loadedYmax = maxY;
	}
}


- (void) loadAllSquares {
	
	float minX, maxX, minY, maxY, avgZ;
	MPSquare *square = nil;
	
	//NSString *sql = [NSString stringWithFormat:@"SELECT * FROM squares WHERE zoneID=%d", zone];
	NSString *sql = [NSString stringWithString:@"SELECT * FROM squares"];
	
	//	PGLog(@"---- loading squares with sql[%@] ---", sql);
	NSError *error=nil;
	
	id<PLResultSet> results = [db executeQueryAndReturnError:&error statement:sql];
	if (results == nil) {
		PGLog(@"    ---- error executing sql statement: e[%@]", error);
		[NSApp presentError:error];
		
	}else {
		
		loadedXmax = -INFINITY;
		loadedXmin = INFINITY;
		loadedYmax = -INFINITY;
		loadedYmin = INFINITY;
		while ([results next]) {
			
			minX = [results floatForColumn:@"minX"];
			maxX = [results floatForColumn:@"maxX"];
			minY = [results floatForColumn:@"minY"];
			maxY = [results floatForColumn:@"maxY"];
			avgZ = [results floatForColumn:@"zPos"];
			
			square = [self newSquareWithDimentionsMixX:minX maxX:maxX minY:minY maxY:maxY avgZ:avgZ];
			square.isTraversible = [results boolForColumn:@"traversible"]; 
			square.costAdjustment = [results floatForColumn:@"cost"];
			square.name = [results stringForColumn:@"name"];
			square.zoneID = [results intForColumn:@"zoneID"];
			square.dbID = [results intForColumn:@"id"];
			
			
			if (minX < loadedXmin) loadedXmin = minX;
			if (maxX > loadedXmax) loadedXmax = maxX;
			if (minY < loadedYmin) loadedYmin = minY;
			if (maxY > loadedYmax) loadedYmax = maxY;
			
			//PGLog(@"   ---- LOADING square [%@] created", square.name);
		}
		
		
		
		[results close];
		
	}
	
}


- (void) loadGraphChunkWithCondition: (NSString *)condition  {
	
	float minX, maxX, minY, maxY, avgZ;
	MPSquare *square = nil;
	
	NSString *sql = [NSString stringWithFormat:@"SELECT * FROM squares WHERE %@", condition];
	
	PGLog(@"---- loading squares with sql[%@] ---", sql);
	NSError *error=nil;
	
	id<PLResultSet> results = [db executeQueryAndReturnError:&error statement:sql];
	if (results == nil) {
		PGLog(@"    ---- error executing sql statement: e[%@]", error);
		[NSApp presentError:error];
		
	}else {
		
		while ([results next]) {
			
			minX = [results floatForColumn:@"minX"];
			maxX = [results floatForColumn:@"maxX"];
			minY = [results floatForColumn:@"minY"];
			maxY = [results floatForColumn:@"maxY"];
			avgZ = [results floatForColumn:@"zPos"];
			
			square = [self newSquareWithDimentionsMixX:minX maxX:maxX minY:minY maxY:maxY avgZ:avgZ];
			square.isTraversible = [results boolForColumn:@"traversible"]; 
			square.costAdjustment = [results floatForColumn:@"cost"];
			square.name = [results stringForColumn:@"name"];
			square.dbID = [results intForColumn:@"id"];
			
			//PGLog(@"   ---- LOADING square [%@] created", square.name);
		}
		
		
		
		[results close];
		
	}
	
}


- (void) storeSquareInDB: (MPSquare *) newSquare {
	
	NSString *sql = [NSString stringWithFormat:@"INSERT INTO squares (id, %@) VALUES (null, %@)", [newSquare stringDBFields], [newSquare stringDBValues]];
	NSError *error = nil;
	BOOL result = YES;
	
	PGLog(@"   ---- adding square [%@] ", sql);
	[dbLock lock];
	result = [db executeUpdateAndReturnError:(&error) statement:sql];
	[dbLock unlock];
	
	if (!result ){
		PGLog(@"   -----!!! Data insert failed. error[%@]", error );
		if (error) {
			[NSApp presentError:error];	
		}
		
	} else {
		newSquare.dbID = [db lastInsertRowId];
	}
	
}



- (void) removeSquareFromDB: (MPSquare *) square {
	
	NSString *sql = [NSString stringWithFormat:@"DELETE FROM squares WHERE id=%d", [square dbID]];
	NSError *error = nil;
	
	PGLog(@"   ---- removing square [%@] ", sql);
	
	BOOL result = YES;
	[dbLock lock];
	result = [db executeUpdateAndReturnError:(&error) statement:sql];
	[dbLock unlock];
	if (!result ){
		PGLog(@"   -----!!! Data Delete failed. error[%@]", error );
		if (error) {
			[NSApp presentError:error];	
		}
		
	} 
}



- (void) updateSquareInDB: (MPSquare *) square {
	
	NSString *sql = [NSString stringWithFormat:@"UPDATE squares SET %@ WHERE id=%d", [square stringDBUpdateValues], [square dbID]];
	NSError *error = nil;
	
	PGLog(@"   ---- updating square [%@] ", sql);
	
	BOOL result = YES;
	[dbLock lock];
	result = [db executeUpdateAndReturnError:(&error) statement:sql];
	[dbLock unlock];
	if (!result ){
		PGLog(@"   -----!!! Data UPDATE failed. error[%@]", error );
		if (error) {
			[NSApp presentError:error];	
		}
		
	} 
}




- (void)applicationWillTerminate: (NSNotification*)notification {
	[dbLock lock];
	[db close];
	[dbLock unlock];
}

@end
