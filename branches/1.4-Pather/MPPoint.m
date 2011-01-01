//
//  MPPoint.m
//  Pocket Gnome
//
//  Created by Coding Monkey on 10/13/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MPPoint.h"
#import "MPLocation.h"
#import "Position.h"
#import "MPSquare.h"


@implementation MPPoint
@synthesize location, squaresContainedIn;


-(id) init {

	return [self initWithLocation:nil];
}

- (id) initWithLocation: (MPLocation *) aLocation {
	
	if ((self = [super init])) {
		self.location = aLocation;
		self.squaresContainedIn = [NSMutableArray array];
	}
	return self;
}



- (void) dealloc
{
    [location autorelease];
    [squaresContainedIn autorelease];
	
    [super dealloc];
}

#pragma mark -


- (void) setX: (float) xPos {
	[location setXPosition:xPos];
}

- (void) setY: (float) yPos {
	[location setYPosition:yPos];
}

- (void) setZ: (float) zPos {
	[location setZPosition:zPos];
}


- (BOOL) isAt: (MPLocation *)aLocation withinZTolerance:(float) zTolerance {

	if (([location xPosition] == [aLocation xPosition]) &&
		([location yPosition] == [aLocation yPosition])) {
		
		if (abs( ([location zPosition] - [aLocation zPosition]) * 100 ) <= (zTolerance *100)) {
			return YES;
		}
	}
	return NO;
}


- (float) zDistanceTo: (MPLocation *)aLocation {
	float distance;
	
	if ([aLocation zPosition] >= [location zPosition]) {
		distance = [aLocation zPosition] - [location zPosition];
	} else {
		distance = [location zPosition] - [aLocation zPosition];
	}

	return distance;
}


- (void) containedInSquare: (MPSquare *) aSquare {

	NSArray *copyPoints = [squaresContainedIn copy]; // prevent Threading problem?
	if (![copyPoints containsObject:aSquare]) {
		[squaresContainedIn addObject:aSquare];
	}
}

- (void) removeContainingSquare: (MPSquare *) aSquare {
	if ([squaresContainedIn containsObject:aSquare]) {
		[squaresContainedIn removeObject:aSquare];
	}
}


- (MPSquare *) squareWherePointIsInPosition: (int) position {
	NSArray *copySquares = [squaresContainedIn copy]; //prevents threading problem
	for (MPSquare *square in copySquares) {
//PGLog( "squareWherePointIsInPosition [ %@ ]", square);
		if ( [[square points] objectAtIndex: position] == self) {
			return square;
		}
	}
	return nil;
}


#pragma mark -
#pragma mark Graph Optimizations


- (BOOL) canQuadReduce {
	
	// point can Quad Reduce if:
	//		- has 4 squares around it
	//		- each square is Reduceable
	//		- each square is same size (width & height)
	//		- each square has same cost
	
	// if # of squares < 4 return NO;
	if ([squaresContainedIn count] < 4) return NO;
	
	
	int width = 0;
	int height = 0;
	float cost = 0;
	
	width = (int)[(MPSquare *)[squaresContainedIn objectAtIndex:0] width];
	height = (int)[(MPSquare *)[squaresContainedIn objectAtIndex:0] height];
	cost = [(MPSquare *)[squaresContainedIn objectAtIndex:0] costAdjustment];
	
	MPSquare *square = nil;
	
	// for each square
	for( square in squaresContainedIn) {
		
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


- (MPSquare *) upperLeftSquare {
	
	return [self squareWherePointIsInPosition:2];
	
}


- (MPSquare *) upperRightSquare {
	
	return [self squareWherePointIsInPosition:1];
	
}


- (MPSquare *) lowerLeftSquare {
	
	return [self squareWherePointIsInPosition:3];
	
}


- (MPSquare *) lowerRightSquare {
	
	return [self squareWherePointIsInPosition:0];
	
}

#pragma mark -
#pragma mark Debug Labels

- (NSString *) describe {
	return [NSMutableString stringWithFormat: @"p(%0.2f, %0.2f, %0.2f) ", [location xPosition], [location yPosition], [location zPosition]];
}

#pragma mark -
#pragma mark Convienience Constructors

+ (MPPoint *) pointAtX: (float)locX Y:(float) locY Z:(float) locZ {
	
	MPLocation *thisLocation = [MPLocation locationAtX:locX Y:locY Z:locZ];
	return [[[MPPoint alloc] initWithLocation:thisLocation] autorelease];
}
@end
