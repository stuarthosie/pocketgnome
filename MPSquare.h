//
//  MPSquare.h
//  Pocket Gnome
//
//  Created by Coding Monkey on 10/13/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class MPLocation;
@class MPPoint;
@class MPLine;

@interface MPSquare : NSObject {

	NSString *name;
	NSArray *points;
	NSMutableArray *topBorderConnections, *leftBorderConnections, 
			*bottomBorderConnections, *rightBorderConnections;
	
	NSBezierPath *myDrawRect;
	
	//	double  costG, costH, cost;
	float costAdjustment;
	BOOL isTraversible,onPath, isConsideredForPath;
	
	float zPos;
	int dbID;
	
	int zoneID;
	
	float width, height;
	
}
@property (retain) NSString *name;
@property (retain) NSArray *points;
@property (retain) NSArray *topBorderConnections, *leftBorderConnections, 
*bottomBorderConnections, *rightBorderConnections;
@property (retain) NSBezierPath *myDrawRect;
@property (readwrite) BOOL isTraversible, onPath, isConsideredForPath;
@property (readwrite) float zPos;
@property (readwrite) int dbID;
@property (readwrite) float costAdjustment;
@property (readwrite) float width, height;
@property (readwrite) int zoneID;


- (BOOL) containsLocation: (MPLocation *)aLocation;
- (MPSquare *) adjacentSquareContainingLocation: (MPLocation*)aLocation;
- (NSMutableArray *) adjacentSquares;
- (MPPoint *) pointAtPosition: (int) position;

- (NSArray *) points;

- (void) addTopBorderConnection: (MPSquare *) square;
- (void) addLeftBorderConnection: (MPSquare *) square;
- (void) addRightBorderConnection: (MPSquare *) square;
- (void) addBottomBorderConnection: (MPSquare *) square;


- (MPLocation *) topEdgeMidPointWithSquare: (MPSquare *)aSquare;
- (MPLocation *) bottomEdgeMidPointWithSquare: (MPSquare *)aSquare;
- (MPLocation *) leftEdgeMidPointWithSquare: (MPSquare *)aSquare;
- (MPLocation *) rightEdgeMidPointWithSquare: (MPSquare *)aSquare;
- (MPLocation *) locationOfIntersectionWithSquare: (MPSquare *) aSquare;
- (MPLocation *) locationOfMidPoint;
- (BOOL) hasClearPathFrom: (MPLocation *)startLocation to:(MPLocation *)endLocation;
- (BOOL) hasClearPathFrom: (MPLocation *)startLocation to:(MPLocation *)endLocation usingLine:(MPLine *) aLine;
- (BOOL) hasClearPathFrom: (MPLocation *)startLocation to:(MPLocation *)endLocation usingLine:(MPLine *) aLine ignoringSquares:(NSMutableArray *)listSquares;


/*!
 * @function nsrect
 * @abstract Returns an NSRect that represents the area of this Square.
 * @discussion
 */
- (NSRect) nsrect;
- (void)  display;
- (NSString *) describe;
- (NSString *) navViewDescription;

- (void) connectToAdjacentSquaresByPointReferences;  // internal?

- (void) compileAdjacentSquaresThatIntersectRect: (NSRect) viewRect  intoList: (NSMutableArray *)listSquares;

- (BOOL) isReduceable;
- (void) disconnectFromGraph;

- (float) maxAmountZIncreaseForTolerance:(float)zTolernace;
- (float) maxAmountZDecreaseForTolerance:(float)zTolerance;


/*!
 * @function stringDBFields
 * @abstract Returns the db fields for this square for inserting into the DB store.
 * @discussion
 */
- (NSString *) stringDBFields;



/*!
 * @function stringDBValues
 * @abstract Returns the string data of this square for inserting into the DB store.
 * @discussion
 */
- (NSString *) stringDBValues;


/*!
 * @function stringDBUpdateValues
 * @abstract Returns the string data of this square for UPDATEing in the DB store.
 * @discussion
 */
- (NSString *) stringDBUpdateValues;

#pragma mark -
#pragma mark Convienience Constructors

+ (id) squareWithPoints:(NSArray *) points;
+ (id) squareWithPoints:(NSArray *) points connectByPoints:(BOOL)pointReview;

@end
