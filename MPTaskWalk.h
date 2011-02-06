//
//  MPTaskWalk.h
//  Pocket Gnome
//
//  Created by Coding Monkey on 12/28/10.
//  Copyright 2010 Savory Software, LLC
//
#import <Cocoa/Cocoa.h>
#import "MPTaskRunner.h"
@class MPLocation;


/*!
 * @class      MPTaskWalk
 * @abstract   Move to specified spots around the map in order
 * @discussion 
 * MPTaskWalk allows you to specify spots around the map to move between.  Walk will walk that route
 * one time and then it will report finished.
 *
 * Parameters:
 *		$Locations : an array of locations to move between.
 *		$UseMount  : Use mount on longer runs
 *		$Order	   : How to choose points:
 *						- Order   : Progress between these points in given order.
 *						- Reverse : Progress between these points in reverse order.
 * <code>
 *	 Walk
 *	 {
 *		 $Prio = 1;
 *		 $Locations =	[
 *							// Mark the spots you are interested in
 *							[x1, y1, z1],
 *							[x2, y2, z2],
 *							[x3, y3, z3],
 *							...
 *							[xN, yN, zN]
 *						];
 *		 $UseMount = YES; // or NO
 *		 $Order=Order; // Default = Order.  Values: Order, Reverse
 *	 }
 * </code>
 *
 */
@interface MPTaskWalk : MPTaskRunner {
	
	BOOL isOrder, shouldUpdate;
	int currentIndex;
	MPLocation *nextLocation;
}
@property (retain) MPLocation *nextLocation;

- (MPLocation *) bestLocation;
+ (id) initWithPather: (PatherController*)controller;

@end
