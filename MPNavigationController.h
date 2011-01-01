//
//  MPNavigationController.h
//  Pocket Gnome
//
//  Created by Coding Monkey on 10/13/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class MPNavMeshView;
@class MPPoint;
@class MPSquare;
@class MPLocation;
@class MPPointTree;
@class MPSquareTree;
@class MPTimer;
@class Route;
@class MPPathNode;
@class PLSqliteDatabase;



typedef enum NavRoutingState { 
	NavRoutingStateGeneratingRoute	= 1, 
	NavRoutingStateOptimizingRoute	= 2, 
	NavRoutingStateDone				= 3,
	NavRoutingStateNoCanDo			= 4
} MPNavRoutingState; 


@interface MPNavigationController : NSObject {
//	NSMutableArray *allSquares;
	MPSquareTree *allSquares;
	NSMutableArray *pointArray;
	MPPointTree *allPoints;

	MPSquare *previousSquare;
	float squareWidth;
	float toleranceZ; // the z tolerance for graph considerations
	MPPathNode *currentPath;
	
	PLSqliteDatabase *db;
	float loadedXmin, loadedXmax, loadedYmin, loadedYmax;
	float graphChunkSize;
	NSLock *dbLock;
	
	// optimization
	float goalSize;
	
	// non Blocking Routing Stuff:
	MPNavRoutingState state;
	MPTimer *timerWorkTime;
	MPLocation *currentStartLocation, *currentDestLocation;
	MPSquare *currentStartSquare;
	BOOL isCurrentRouteValid;
	Route *completedRoute;
	NSMutableArray *currentOpenList, *currentClosedList;
	MPPathNode *foundPath;
	NSMutableArray *currentListAllPathLocations, *currentListOptimizedLocations;
	int currentOptimizationLocC, currentOptimizationLocB, currentOptimizationLocA;
}
@property (retain) MPSquareTree *allSquares; 
@property (retain) MPPointTree *allPoints;
@property (retain) NSMutableArray *pointArray;
@property (retain) MPSquare *previousSquare;
@property (readwrite) float toleranceZ;
@property (readonly) float squareWidth;
@property (readonly) float loadedXmin, loadedXmax, loadedYmin, loadedYmax;
@property (retain) MPPathNode *currentPath;
@property (retain) NSLock *dbLock;

// Non Blocking Properties
@property (retain) MPTimer *timerWorkTime;
@property (retain) MPLocation *currentStartLocation, *currentDestLocation;
@property (retain) MPSquare *currentStartSquare;
@property (retain) Route *completedRoute;
@property (retain) NSMutableArray *currentOpenList, *currentClosedList;
@property (retain) MPPathNode *foundPath;
@property (retain) NSMutableArray *currentListAllPathLocations, *currentListOptimizedLocations;

/*!
 * @function openMeshData
 * @abstract Opens (or creates) a link to the NavMesh Data storage
 * @discussion
 *	
 */
- (void) openMeshData: (NSString *) fileName;


/*!
 * @function listSquaresInView
 * @abstract Returns a list of MPSquares that will appear in the given navMeshView
 * @discussion
 *	
 */
- (NSArray *) listSquaresInView: (MPNavMeshView *) navMeshView aroundLocation: (MPLocation *)playerPosition ;


/*!
 * @function squareContainingLocation
 * @abstract Returns the MPSquare that contains the given location
 * @discussion
 *	If no square is found, then nil is returned.
 */
- (MPSquare *) squareContainingLocation: (MPLocation *) aLocation;


/*!
 * @function lowestSquareContainingLocation
 * @abstract Returns the lowest (z axis) MPSquare that contains the given (X,Y) location
 * @discussion
 *	If no square is found, then nil is returned.
 *  This method is used when trying to optimize the navigation graphs.
 */
- (MPSquare *) lowestSquareContainingLocation: (MPLocation *) aLocation;

- (void) resetSquareDisplay;

/*!
 * @function pointAtLocation
 * @abstract Returns the MPPoint that is at the given location
 * @discussion
 *	NOTE: this returns a match at the same x,y location.  if there are numerous
 *  points with this x,y then the one with the closest Z location is returned. if none
 *  are found, then return nil.
 */
- (MPPoint *) pointAtLocation: (MPLocation *) aLocation withinZTolerance: (float) zTolerance;
- (MPPoint *) findOrCreatePointAtLocation: (MPLocation *) aLocation withinZTolerance: (float) zTolerance;

/*!
 * @function updateMeshAtLocation
 * @abstract Updates the MPSquare at aLocation to be traversible.
 * @discussion
 *	If no square is found, then a new MPSquare is created that contains aLocation, and it
 *  will be marked traversible.
 */
- (void) updateMeshAtLocation: (MPLocation*)aLocation isTraversible:(BOOL)canTraverse;



- (void) loadInitialGraphChunkAroundLocation:(MPLocation *) location;
- (void) loadAllSquares;

#pragma mark -
#pragma mark Navigation and Routing


// The following methods implement a Non Blocking method of generating a Route
// ex:
//		[navCon setupRouteFromLocation:A toLocation:B];
//		while( ![navCon isRouteWorkComplete]) {
//			// do other work here
//		}
//		if ([navCon isCurrentRouteValid]) {
//			route = [navCon completeRoute];
//		// do something with Route now...
//		} else {
//			// handle error: no route from A to B
//		}
//
- (void) setupRouteFromLocation: (MPLocation *)startLocation toLocation:(MPLocation *)destLocation;
- (BOOL) isRouteWorkComplete;
- (BOOL) isRouteValid;
- (Route *) completedRoute;
- (Route *) bestCurrentRoute;

/*!
 * @function routeToLocation
 * @abstract Generates a Route from our current location to the given location
 */
- (Route *) routeFromLocation: (MPLocation*)startLocation toLocation: (MPLocation*)destLocation;


- (MPPathNode *) pathFromSquare: (MPSquare *)currentSquare toLocation:(MPLocation *)destLocation;
- (MPPathNode *) lowestCostNodeInArray:(NSMutableArray*) anArray;
- (BOOL ) isSquare: (MPSquare *)aSquare inNodeList: (NSArray*) nodeList;
- (MPPathNode *) nodeWithSquare: (MPSquare *)aSquare fromNodeList: (NSArray *) nodeList;


- (int) costFromNode: (MPPathNode *) currentNode  toNode:(MPPathNode *)aNode;
- (int) costFromNode: (MPPathNode *)currentNode  toLocation:(MPLocation *) location ;

- (void) updateRouteDisplay: (MPPathNode *)aNode;
- (NSMutableArray *) listLocationsFromPathNode:pathNode;
- (NSMutableArray *) reduceLocations: (NSMutableArray *)listAllLocations;

- (void) optimizeGraph;
- (void) optimizeGraphAtPoint:(MPPoint *)point;
- (BOOL) optimizeGraphAtSquare:(MPSquare *)currentSquare;




@end
