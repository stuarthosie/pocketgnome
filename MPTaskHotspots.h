//
//  MPTaskHotspots.h
//  Pocket Gnome
//
//  Created by Coding Monkey on 12/28/10.
//  Copyright 2010 Savory Software, LLC
//
#import <Cocoa/Cocoa.h>
#import "MPTaskRunner.h"
@class MPLocation;


/*!
 * @class      MPTaskHotspots
 * @abstract   Move to specified spots around the map
 * @discussion 
 * MPTaskHotspots allows you to specify spots around the map to move between.
 * Parameters:
 *		$Locations : an array of locations to move between.
 *		$UseMount  : Use mount on longer runs
 *		$Order	   : How to choose points:
 *						- Random  : (Default) Randomly pick points in list
 *						- Order   : Progress between these points in given order.
 *						- Reverse : Progress between these points in reverse order.
 * <code>
 *	 Hotspots
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
 *		 $Order=Order; // Default = Random.  Values: Order, Random, Reverse
 *	 }
 * </code>
 *
 */
@interface MPTaskHotspots : MPTaskRunner {

	BOOL isRandom, isOrder, shouldUpdate;
	int currentIndex;
	MPLocation *nextLocation;
}
@property (retain) MPLocation *nextLocation;

- (MPLocation *) bestLocation;
+ (id) initWithPather: (PatherController*)controller;

@end
