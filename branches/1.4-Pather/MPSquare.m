//
//  MPSquare.m
//  Pocket Gnome
//
//  Created by Coding Monkey on 10/13/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MPSquare.h"
#import "MPPoint.h"
#import "MPLocation.h"
#import "Position.h"
#import "MPLine.h"
#import "PlayerDataController.h"

//#import "QuickLite/QuickLiteGlobals.h"
//#import "PlausibleDatabase/PlausibleDatabase.h"


@implementation MPSquare
@synthesize name, 
			points, 
			topBorderConnections, 
			leftBorderConnections, 
			bottomBorderConnections, 
			rightBorderConnections,
			myDrawRect,
			isTraversible, 
			onPath,
			isConsideredForPath,
			costAdjustment,
			zPos, 
			dbID,
			zoneID,
			width, height;




-(id) init {
	
	if ((self = [super init])) {
		self.name = [NSString stringWithFormat:@" NA "];
		self.points = nil;
		self.topBorderConnections = [NSMutableArray array];
		self.leftBorderConnections = [NSMutableArray array];
		self.bottomBorderConnections = [NSMutableArray array];
		self.rightBorderConnections = [NSMutableArray array];
		self.myDrawRect = nil;
		
		costAdjustment = 1.0f;
		isTraversible = YES; // most new squares are for marking traversible nodes.
		onPath = NO;
		isConsideredForPath = NO;
		
		zPos = 0;
		dbID = 0;
		width = 0;
		height = 0;
		
		zoneID = [[PlayerDataController sharedController] zone];
		
	}
	return self;
}



- (void) dealloc
{
	[name autorelease];
    [points autorelease];
    [topBorderConnections autorelease];
	[leftBorderConnections autorelease];
	[rightBorderConnections autorelease];
	[bottomBorderConnections autorelease];
	[myDrawRect autorelease];
	
    [super dealloc];
}

#pragma mark -

/*
- (NSArray *) points {
	return points;
}
*/

- (BOOL) containsLocation: (MPLocation *)aLocation {
	
	float x0, x3, y0, y1;
	
	x0 = [[(MPPoint *)[points objectAtIndex:0] location] xPosition];
	x3 = [[(MPPoint *)[points objectAtIndex:3] location] xPosition];
	y0 = [[(MPPoint *)[points objectAtIndex:0] location] yPosition];
	y1 = [[(MPPoint *)[points objectAtIndex:1] location] yPosition];
	
	float locX, locY;
	locX = [aLocation xPosition];
	locY = [aLocation yPosition];
	
	if ((locX >= x0) && (locX <= x3) && (locY >= y1) && (locY <= y0)) {
		return YES;
	}

	return NO;
}


- (MPSquare *) adjacentSquareContainingLocation: (MPLocation*)aLocation {
	
	// check top connections:
	for( MPSquare* square in topBorderConnections) {
		if ([square containsLocation:aLocation]) {
			return square;	
		}
	}
	
	// check Left connections:
	for( MPSquare* square in leftBorderConnections) {
		if ([square containsLocation:aLocation]) {
			return square;	
		}
	}
	
	// check bottom connections:
	for( MPSquare* square in bottomBorderConnections) {
		if ([square containsLocation:aLocation]) {
			return square;	
		}
	}
	
	// check right connections:
	for( MPSquare* square in rightBorderConnections) {
		if ([square containsLocation:aLocation]) {
			return square;	
		}
	}
	
	// not found
	return nil;
}


- (MPPoint *) pointAtPosition: (int) position {

	MPPoint *point = nil;
	
	if ( position < [points count]) {
		point = [points objectAtIndex:position];
	}
	return point;
}


- (void) addTopBorderConnection: (MPSquare *) square {

	NSArray *copyConnections = [topBorderConnections copy];
	if (![copyConnections containsObject:square]) {
		[topBorderConnections addObject:square];
	}
}

- (void) addLeftBorderConnection: (MPSquare *) square {

	NSArray *copyConnections = [leftBorderConnections copy];
	if (![copyConnections containsObject:square]) {
		[leftBorderConnections addObject:square];
	}
}

- (void) addRightBorderConnection: (MPSquare *) square {

	NSArray *copyConnections = [rightBorderConnections copy];
	if (![copyConnections containsObject:square]) {
		[rightBorderConnections addObject:square];
	}
}

- (void) addBottomBorderConnection: (MPSquare *) square {

	NSArray *copyConnections = [bottomBorderConnections copy];
	if (![copyConnections containsObject:square]) {
		[bottomBorderConnections addObject:square];
	}
}


- (MPLocation *) locationOfIntersectionWithSquare: (MPSquare *) aSquare {
	
	MPLocation *location = nil;
	
	if ([topBorderConnections containsObject:aSquare]) {
		
		location = [self topEdgeMidPointWithSquare: (MPSquare *)aSquare];
			
	} else if ([leftBorderConnections containsObject:aSquare]) {
		
		location = [self leftEdgeMidPointWithSquare: (MPSquare *)aSquare];
			
	} else if ([bottomBorderConnections containsObject:aSquare]) {

		location = [self bottomEdgeMidPointWithSquare: (MPSquare *)aSquare];
		
	} else if ([rightBorderConnections containsObject:aSquare]) {
			
		location = [self rightEdgeMidPointWithSquare: (MPSquare *)aSquare];
		
	}
	
	return location;
}






- (MPLocation *) locationOfMidPoint {
	
	MPPoint *point1, *point3;
	
	point1 = [points objectAtIndex:1];
	point3 = [points objectAtIndex:3];
	
	float minX, maxX, minY, maxY;
	
	minX = [[point1 location] xPosition];
	maxX = [[point3 location] xPosition];
	
	minY = [[point1 location] yPosition];
	maxY = [[point3 location] yPosition];
	
	
	float midX, midY;
	
	midX = minX + ((maxX - minX)/2);
	midY = minY + ((maxY - minY)/2);
	
	return [MPLocation locationAtX:midX Y:midY Z:zPos];
	
}




- (MPLocation *) topEdgeMidPointWithSquare: (MPSquare *)aSquare {

	MPLocation *point0 = [(MPPoint *)[points objectAtIndex:0] location];
	
	NSArray *sqPoints = [aSquare points];
	float myP0X, myP3X, sqP1X, sqP2X;
	
	// get X positions of my top edge : Point0, Point3
	myP0X = [[(MPPoint *)[points objectAtIndex:0] location] xPosition];
	myP3X = [[(MPPoint *)[points objectAtIndex:3] location] xPosition];
	
	// get X positions of aSquare's bottom edge: Point1 & Point2
	sqP1X = [[(MPPoint *)[sqPoints objectAtIndex:1] location] xPosition];
	sqP2X = [[(MPPoint *)[sqPoints objectAtIndex:2] location] xPosition];
	
	
	// decide on which X positions make up the edge
	float x0,x3, xMid;
	x0 = (myP0X > sqP1X)? myP0X: sqP1X;  // max(myP0X, sqP1X);
	x3 = (myP3X < sqP2X)? myP3X: sqP2X;  // min(myP3X, sqP2X);
	
	
	// get mid point of the edge
	xMid = x0 + ((x3 - x0)/2);
	
	return [MPLocation locationAtX:xMid Y:[point0 yPosition] Z:[point0 zPosition]];
}



- (MPLocation *) bottomEdgeMidPointWithSquare: (MPSquare *)aSquare {
	
	MPLocation *point0 = [(MPPoint *)[points objectAtIndex:0] location];
	
	NSArray *sqPoints = [aSquare points];
	float sqP0X, sqP3X, myP1X, myP2X;
	
	// get X positions of aSquare's top edge : Point0, Point3
	sqP0X = [[(MPPoint *)[sqPoints objectAtIndex:0] location] xPosition];
	sqP3X = [[(MPPoint *)[sqPoints objectAtIndex:3] location] xPosition];
	
	// get X positions of my bottom edge: Point1 & Point2
	myP1X = [[(MPPoint *)[points objectAtIndex:1] location] xPosition];
	myP2X = [[(MPPoint *)[points objectAtIndex:2] location] xPosition];
	
	
	// decide on which X positions make up the edge
	float x0,x3, xMid;
	x0 = (sqP0X > myP1X)? sqP0X: myP1X;  // max(sqP0X, myP1X);
	x3 = (sqP3X < myP2X)? sqP3X: myP2X;  // min(sqP3X, myP2X);
	
	
	// get mid point of the edge
	xMid = x0 + ((x3 - x0)/2);
	
	return [MPLocation locationAtX:xMid Y:[point0 yPosition] Z:[point0 zPosition]];
	
}



- (MPLocation *) leftEdgeMidPointWithSquare: (MPSquare *)aSquare {
	
	MPLocation *point1 = [(MPPoint *)[points objectAtIndex:1] location];
	
	NSArray *sqPoints = [aSquare points];
	
	float myP0Y, myP1Y, sqP3Y, sqP2Y;
	
	// get the y positions on my left edge
	myP0Y = [[(MPPoint *)[points objectAtIndex:0] location] yPosition];
	myP1Y = [[(MPPoint *)[points objectAtIndex:1] location] yPosition];
	
	// get the y positions of aSquare's  Right edge
	sqP3Y = [[(MPPoint *)[sqPoints objectAtIndex:3] location] yPosition];
	sqP2Y = [[(MPPoint *)[sqPoints objectAtIndex:2] location] yPosition];
	
	
	float y0,y1, yMid;
	y0 = (myP0Y < sqP3Y)? myP0Y: sqP3Y;  // upper Y is min of myP0Y & sqP3Y
	y1 = (myP1Y > sqP2Y)? myP1Y: sqP2Y;  // lower Y is max of myP1Y & sqP2Y
	
	yMid = y1 + ((y0 - y1)/2); // mid point 
	
	return [MPLocation locationAtX:[point1 xPosition] Y:yMid Z:[point1 zPosition]];
}




- (MPLocation *) rightEdgeMidPointWithSquare: (MPSquare *)aSquare {
	
	MPLocation *point1 = [(MPPoint *)[points objectAtIndex:1] location];
	
	NSArray *sqPoints = [aSquare points];
	
	float myP3Y, myP2Y, sqP0Y, sqP1Y;
	
	// get the y positions on my left edge
	myP3Y = [[(MPPoint *)[points objectAtIndex:3] location] yPosition];
	myP2Y = [[(MPPoint *)[points objectAtIndex:2] location] yPosition];
	
	// get the y positions of aSquare's  Right edge
	sqP0Y = [[(MPPoint *)[sqPoints objectAtIndex:0] location] yPosition];
	sqP1Y = [[(MPPoint *)[sqPoints objectAtIndex:1] location] yPosition];
	
	
	float y0,y1, yMid;
	y0 = (myP3Y < sqP0Y)? myP3Y: sqP0Y;  // upper Y is min of myP3Y & sqP0Y
	y1 = (myP2Y > sqP1Y)? myP2Y: sqP1Y;  // lower Y is max of myP2Y & sqP1Y
	
	yMid = y1 + ((y0 - y1)/2); // mid point 
	
	return [MPLocation locationAtX:[point1 xPosition] Y:yMid Z:[point1 zPosition]];
}


- (BOOL) hasClearPathFrom: (MPLocation *)startLocation to:(MPLocation *)endLocation {
	MPLine *thisLine = [MPLine lineStartingAt:startLocation endingAt:endLocation];
	return [self hasClearPathFrom:startLocation to:endLocation usingLine:thisLine ];
}


- (BOOL) hasClearPathFrom: (MPLocation *)startLocation to:(MPLocation *)endLocation usingLine:(MPLine *) aLine  {
	return [self hasClearPathFrom:startLocation to:endLocation usingLine:aLine ignoringSquares:nil];
}


- (BOOL) hasClearPathFrom: (MPLocation *)startLocation to:(MPLocation *)endLocation usingLine:(MPLine *) aLine ignoringSquares:(NSMutableArray *)listSquares {
	
	if ([self containsLocation:endLocation]) {
		return YES;
	}
	
	if (listSquares == nil) listSquares = [NSMutableArray array];

	float selectedDist = INFINITY;
	float currentDist = 0;
	int selectedIndex = -1;
	MPLocation *selectedLocation = nil;
	
	int index, nextIndx;
	for (index = 0; index <= 3; index ++ ) {
		
		nextIndx = index +1;
		if (nextIndx > 3) nextIndx = 0;
		
		MPLocation *loc0 = [(MPPoint *)[points objectAtIndex:index] location];
		MPLocation *loc1 = [(MPPoint *)[points objectAtIndex:nextIndx] location];
		
		MPLine *currLine = [MPLine lineStartingAt:loc0 endingAt:loc1];
		MPLocation *currentLocation = [aLine locationOfIntersectionWithLine:currLine];
		
		if (currentLocation != nil) {
		
			currentDist = [currentLocation distanceToPosition:endLocation];
			if (currentDist < selectedDist) {
				selectedDist = currentDist;
				selectedIndex = index;
				selectedLocation = currentLocation;
			}
			
		}
	}
	
	if ( selectedIndex != -1 ) {
		
		NSArray *exitBorderSquares = nil;
		
		switch (selectedIndex) {
			case 0:
				// left Side
				exitBorderSquares = leftBorderConnections;
				break;
			case 1:
				// bottom
				exitBorderSquares = bottomBorderConnections;
				break;
			case 2:
				// right side
				exitBorderSquares = rightBorderConnections;
				break;
			case 3:
				// top 
				exitBorderSquares = topBorderConnections;
				break;
			default:
				break;
		}
		
		for( MPSquare *square in exitBorderSquares) {
			if (![listSquares containsObject:square]) {
				if ([square isTraversible]) {
					if ([square containsLocation:selectedLocation]) {
					
//	PGLog(@"---- %@  checking %@", self.name, square.name);
						[listSquares addObject:self];
						return [square hasClearPathFrom:startLocation to:endLocation usingLine:aLine ignoringSquares:listSquares];
					}
				}
			}
		}
		
	}
	
	
	
	return NO;
	
}



- (BOOL) isReduceable {
	
	// ok, a square is reduceable if it :
	//	- isn't near the edge (has any empty edges)
	//	- isn't next to an intraversable square
	
	// Abort on empty edges
	if ([topBorderConnections count] == 0) return NO;
	if ([leftBorderConnections count] == 0) return NO;
	if ([bottomBorderConnections count] == 0) return NO;
	if ([rightBorderConnections count] == 0) return NO;
	
	
	// Abort with inTraversible neighbors
	MPSquare *square;
	for(square in topBorderConnections) {
		if (![square isTraversible]) return NO;
	}
	for(square in leftBorderConnections) {
		if (![square isTraversible]) return NO;
	}
	for(square in bottomBorderConnections) {
		if (![square isTraversible]) return NO;
	}
	for(square in rightBorderConnections) {
		if (![square isTraversible]) return NO;
	}
	
	// hmmm, everything looks good
	return YES;
}


- (void) disconnectFromGraph {
	
	MPSquare *square;
	for(square in topBorderConnections) {
		[(NSMutableArray *)[square bottomBorderConnections] removeObject:self];
	}
	for(square in leftBorderConnections) {
		[(NSMutableArray *)[square rightBorderConnections] removeObject:self];
	}
	for(square in bottomBorderConnections) {
		[(NSMutableArray *)[square topBorderConnections] removeObject:self];
	}
	for(square in rightBorderConnections) {
		[(NSMutableArray *)[square leftBorderConnections] removeObject:self];
	}
	
	MPPoint * point;
	for (point in points) {
		[[point squaresContainedIn] removeObject:self];
	}
}

#pragma mark -
#pragma mark DB helper methods

- (NSString *) stringDBFields {
	
	return @"name, zoneID, minX, maxX, minY, maxY, zPos, traversible, cost";
}

- (NSString *) stringDBValues {
	
	// decode our points into minX, maxX, minY, maxY, zPos
	float minX, maxX, minY, maxY, posZ, cost;
	int traversible;
	
	MPLocation *loc1 = [(MPPoint *)[points objectAtIndex:1] location];
	MPLocation *loc3 = [(MPPoint *)[points objectAtIndex:3] location];
	
	minX = [loc1 xPosition];
	maxX = [loc3 xPosition];
	minY = [loc1 yPosition];
	maxY = [loc3 yPosition];
	posZ = self.zPos;
	
	traversible = (self.isTraversible ? 1:0);
	cost = self.costAdjustment;
	
	return [NSString stringWithFormat:@"'%@', %d, %0.2f, %0.2f, %0.2f, %0.2f, %0.2f, %d, %0.2f", self.name, zoneID, minX, maxX, minY, maxY, posZ, traversible, cost];
}



- (NSString *) stringDBUpdateValues {
	
	// decode our points into minX, maxX, minY, maxY, zPos
	float minX, maxX, minY, maxY, posZ, cost;
	int traversible;
	
	MPLocation *loc1 = [(MPPoint *)[points objectAtIndex:1] location];
	MPLocation *loc3 = [(MPPoint *)[points objectAtIndex:3] location];
	
	minX = [loc1 xPosition];
	maxX = [loc3 xPosition];
	minY = [loc1 yPosition];
	maxY = [loc3 yPosition];
	posZ = self.zPos;
	
	traversible = (self.isTraversible ? 1:0);
	cost = self.costAdjustment;
	
	return [NSString stringWithFormat:@"name='%@', zoneID=%d, minX=%0.2f, maxX=%0.2f, minY=%0.2f, maxY=%0.2f, zPos=%0.2f, traversible=%d, cost=%0.2f", self.name, zoneID, minX, maxX, minY, maxY, posZ, traversible, cost];
}


#pragma mark -
#pragma mark NavMeshView Display Routines


- (NSRect) nsrect {

	float x1, x2, y1, y0;
	
	x1 = [[(MPPoint *)[points objectAtIndex:1] location] xPosition];
	x2 = [[(MPPoint *)[points objectAtIndex:2] location] xPosition];
	y1 = [[(MPPoint *)[points objectAtIndex:1] location] yPosition];
	y0 = [[(MPPoint *)[points objectAtIndex:0] location] yPosition];
	
	return NSMakeRect( x1, y1, x2 - x1, y0 - y1);
}

- (void) display {
	
	
	if (myDrawRect == nil) {
//		PGLog(@"Calculating Draw Rect ... ");
		
		NSRect newRect = [self nsrect];
		self.myDrawRect = [NSBezierPath bezierPathWithRect: newRect];
	}
	
	[myDrawRect setLineWidth: 0.02f];  // or just use 0.02
	[[NSColor grayColor] set];
	[myDrawRect stroke];
	
	if (onPath) {
		[[NSColor redColor] set];
	} else if ( !isTraversible) {
		[[NSColor blackColor] set];
	} else if (costAdjustment > 1.0) {
		[[NSColor yellowColor] set];
	} else if (costAdjustment < 1.0) {
		[[NSColor grayColor] set];
	} else if (isConsideredForPath) {
		[[NSColor colorWithCalibratedRed:1.0 green:0.81 blue:0.85 alpha:1.0 ] set]; // Pink
		
	} else {
		[[NSColor whiteColor] set];
	}
	[myDrawRect fill];
	
	
}




- (void) connectToAdjacentSquaresByPointReferences {
	
	// if [point0 squareWhereImPoint1] != nil then
	MPSquare *square;
	square = [(MPPoint *)[points objectAtIndex:0] squareWherePointIsInPosition:1];
	if (square != nil) {
		// assign this square to top border
		[topBorderConnections addObject:square];
		[square addBottomBorderConnection:self];
	}
	
	// if [point0 squareWhereImPoint3] != nil then
	square = [(MPPoint *)[points objectAtIndex:0] squareWherePointIsInPosition:3];
	if (square != nil) {
		// assign this square to left border
		[leftBorderConnections addObject:square];
		[square addRightBorderConnection:self];
	}
	
	// if [point1 squareWhereImPoint0] != nil then
	square = [(MPPoint *)[points objectAtIndex:1] squareWherePointIsInPosition:0];
	if (square != nil) {
		// assign this square to bottom border
		[bottomBorderConnections addObject:square];
		[square addTopBorderConnection:self];
	}
	
	// if [point3 squareWhereImPoint0] != nil then
	square = [(MPPoint *)[points objectAtIndex:3] squareWherePointIsInPosition:0];
	if (square != nil) {
		// assign this square to right border
		[rightBorderConnections addObject:square];
		[square addLeftBorderConnection:self];
	}

}



- (void) compileAdjacentSquaresThatIntersectRect: (NSRect) viewRect  intoList: (NSMutableArray *)listSquares {


		// check top connections:
	for( MPSquare* square in topBorderConnections) {
		if (NSIntersectsRect(viewRect, [square nsrect])) {
			[listSquares addObject:square];
			[square compileAdjacentSquaresThatIntersectRect:viewRect  intoList:listSquares];	
		}
	}
	
	// check Left connections:
	for( MPSquare* square in leftBorderConnections) {
		if (NSIntersectsRect(viewRect, [square nsrect])) {
			[listSquares addObject:square];
			[square compileAdjacentSquaresThatIntersectRect:viewRect  intoList:listSquares];	
		}
	}
	
	// check bottom connections:
	for( MPSquare* square in bottomBorderConnections) {
		if (NSIntersectsRect(viewRect, [square nsrect])) {
			[listSquares addObject:square];
			[square compileAdjacentSquaresThatIntersectRect:viewRect  intoList:listSquares];	
		}
	}
	
	// check right connections:
	for( MPSquare* square in rightBorderConnections) {
		if (NSIntersectsRect(viewRect, [square nsrect])) {
			[listSquares addObject:square];
			[square compileAdjacentSquaresThatIntersectRect:viewRect  intoList:listSquares];	
		}
	}

}




- (NSMutableArray *) adjacentSquares {
	
	NSMutableArray *listSquares = [NSMutableArray array];
	
	//// TODO: tie into MPQ reading routines to dynamically create graph:
	//// Note:
	//// method to create a missing square and decide if traversible:
	////	- Create a New Square
	////	- if ( ([MPQGraph isStandableAtLocation:[square midpoint]]) 
	////		&& (![MPGraph isAreaTooSteep:square]) ) {
	////		square.isTraversible = YES;
	////	  } else {
	////		square.isTraversible = NO;
	////	  }
	
	
	
	
	// check top connections:
	//// TO DO: check to see if topBorderConnections is null, 
	////		if null -> perform above method and add square to topBorderConnections
	for( MPSquare* square in topBorderConnections) {
		[listSquares addObject:square];
	}
	
	// check Left connections:
	//// TO DO: check to see if leftBorderConnections is null, 
	////		if null -> perform above method and add square to leftBorderConnections
	for( MPSquare* square in leftBorderConnections) {
		[listSquares addObject:square];
	}
	
	// check bottom connections:
	//// TO DO: check to see if bottomBorderConnections is null, 
	////		if null -> perform above method and add square to bottomBorderConnections
	for( MPSquare* square in bottomBorderConnections) {
		[listSquares addObject:square];
	}
	
	// check right connections:
	//// TO DO: check to see if rightBorderConnections is null, 
	////		if null -> perform above method and add square to rightBorderConnections
	for( MPSquare* square in rightBorderConnections) {
		[listSquares addObject:square];
	}
	
	return listSquares;
	
}


- (float) maxAmountZIncreaseForTolerance:(float)zTolernace {
	// return the maximum amount we can increase our Z while remaining connected to our current
	// connections.
	
	// we can increase only as much as (minAdjacentZ + zTolerance) - ourZ
	
	NSMutableArray *listSquares = [self adjacentSquares];
	
	float minAdjacentZ = INFINITY;
	
	// foreach adjacent square
	for( MPSquare *square in listSquares) {
		if (minAdjacentZ > [square zPos]) {
			minAdjacentZ = [square zPos];
		}
	}
	
	return (minAdjacentZ + zTolernace) - zPos;
	
}



- (float) maxAmountZDecreaseForTolerance:(float)zTolerance {
	// return the maximum amount we can decrease our Z while remaining connected to our current
	// connections.
	
	// we can decrease only as much as: ourZ - (maxAdjacentZ - zTolerance)
	
	NSMutableArray *listSquares = [self adjacentSquares];
	
	float maxAdjacentZ = -INFINITY;
	
	// foreach adjacent square
	for( MPSquare *square in listSquares) {
		if (maxAdjacentZ < [square zPos]) {
			maxAdjacentZ = [square zPos];
		}
	}
	
	return zPos - (maxAdjacentZ - zTolerance);
	
}



- (NSString *) describe {
	
	NSMutableString *description = [NSMutableString stringWithFormat:@"square [%@][", self.name];

	/*
	int indx=0;
	MPPoint *currentPoint;
	for( indx=0; indx < [points count]; indx++ ) {
		currentPoint = [points objectAtIndex:indx];
		[description appendString:[currentPoint describe]];
	}
	
	[description appendFormat:@" zPos:%0.2f  t%d:l%d:b%d:r%d]", self.zPos, [topBorderConnections count], [leftBorderConnections count], [bottomBorderConnections count], [rightBorderConnections count]];
	*/
	
	[description appendFormat:@" t%d:l%d:b%d:r%d]", [topBorderConnections count], [leftBorderConnections count], [bottomBorderConnections count], [rightBorderConnections count]];
	[description appendFormat:@" t["];
	for( MPSquare *square in topBorderConnections) {
		[description appendFormat:@" %@, ", square.name];
	}
	[description appendFormat:@"]  "];
	
	
	[description appendFormat:@" l["];
	for( MPSquare *square in leftBorderConnections) {
		[description appendFormat:@" %@, ", square.name];
	}
	[description appendFormat:@"]  "];
	
	[description appendFormat:@" b["];
	for( MPSquare *square in bottomBorderConnections) {
		[description appendFormat:@" %@, ", square.name];
	}
	[description appendFormat:@"]  "];
	
	[description appendFormat:@" r["];
	for( MPSquare *square in rightBorderConnections) {
		[description appendFormat:@" %@, ", square.name];
	}
	[description appendFormat:@"]  "];
	
	
	return description;
}


- (NSString *) navViewDescription {
	
	NSMutableString *description = [NSMutableString stringWithFormat:@"%@\n", self.name];
	
	MPLocation *point1, *point3;
	point1 = [(MPPoint *)[points objectAtIndex:1] location];
	point3 = [(MPPoint *)[points objectAtIndex:3] location];
	[description appendFormat:@" [%0.0f, %0.0f], [%0.0f, %0.0f]  z:%0.2f\n", [point1 xPosition], [point1 yPosition], [point3 xPosition], [point3 yPosition], zPos];
	
	
	/*
	 int indx=0;
	 MPPoint *currentPoint;
	 for( indx=0; indx < [points count]; indx++ ) {
	 currentPoint = [points objectAtIndex:indx];
	 [description appendString:[currentPoint describe]];
	 }
	 
	 [description appendFormat:@" zPos:%0.2f  t%d:l%d:b%d:r%d]", self.zPos, [topBorderConnections count], [leftBorderConnections count], [bottomBorderConnections count], [rightBorderConnections count]];
	 */
	
	[description appendFormat:@" t%d:l%d:b%d:r%d\n", [topBorderConnections count], [leftBorderConnections count], [bottomBorderConnections count], [rightBorderConnections count]];
	[description appendFormat:@" t["];
	for( MPSquare *square in topBorderConnections) {
		[description appendFormat:@" %@, ", square.name];
	}
	[description appendFormat:@"]  \n"];
	
	
	[description appendFormat:@" l["];
	for( MPSquare *square in leftBorderConnections) {
		[description appendFormat:@" %@, ", square.name];
	}
	[description appendFormat:@"]  \n"];
	
	[description appendFormat:@" b["];
	for( MPSquare *square in bottomBorderConnections) {
		[description appendFormat:@" %@, ", square.name];
	}
	[description appendFormat:@"]  \n"];
	
	[description appendFormat:@" r["];
	for( MPSquare *square in rightBorderConnections) {
		[description appendFormat:@" %@, ", square.name];
	}
	[description appendFormat:@"]  "];
	
	
	return description;
	
}

#pragma mark -
#pragma mark Convienience Constructors

+ (id) squareWithPoints:(NSArray *) points {
	
	return [MPSquare squareWithPoints:points connectByPoints:YES];
}



+ (id) squareWithPoints:(NSArray *) points connectByPoints:(BOOL)pointReview {
	
	MPLocation *refLocation = [(MPPoint *)[points objectAtIndex:0] location];
	
	MPSquare *newObject = [[MPSquare alloc] init];
	newObject.name = nil;
	
	newObject.name = [NSString stringWithFormat: @"sq-%d-%d", (int)[refLocation xPosition], (int)[refLocation yPosition]];
	newObject.points = points;
	
	//// update points contained in
	for (MPPoint* point in points) {
		[point containedInSquare: newObject];
	}
	
	// calculate the squares zPos for zTolerance checking.
	// (for now just take zPos of point0, but should find zMin and zMax then zPos = zMin + ((zMax-zMin)/2);
	newObject.zPos = [[(MPPoint*)[points objectAtIndex:0] location] zPosition];

	
	//// find adjoining squares based on given points
	if (pointReview) {
		[newObject connectToAdjacentSquaresByPointReferences];
	}
	
	//// store the square's width 
	float x0, x3;
	x0 = [[(MPPoint *)[points objectAtIndex:0] location] xPosition];
	x3 = [[(MPPoint *)[points objectAtIndex:3] location] xPosition];
	newObject.width = x3 - x0;
	
	//// store the square's height 
	float y0, y1;
	y0 = [[(MPPoint *)[points objectAtIndex:0] location] yPosition];
	y1 = [[(MPPoint *)[points objectAtIndex:1] location] yPosition];
	newObject.height = y0 - y1;
		
	//PGLog( @"new Square at location %@", [newObject describe]);
	return newObject;
}


/*
+ (NSArray *) arrayDBTableColumns {
	return [NSArray arrayWithObjects:QLRecordUID, @"name", @"minX", @"maxX", @"minY", @"maxY", nil];
}

+ (NSArray *) arrayDBTableDataTypes {
	return [NSArray arrayWithObjects:QLRecordUIDDatatype, QLString, QLNumber, QLNumber, QLNumber, QLNumber, nil];
}
*/

@end
