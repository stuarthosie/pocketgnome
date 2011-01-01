//
//  MPTaskRunner.h
//  Pocket Gnome
//
//  Created by Coding Monkey on 12/28/10.
//  Copyright 2010 Savory Software, 
//
//

#import <Cocoa/Cocoa.h>
#import "MPTask.h"

@class Mob;
@class MobController;
@class MPActivityWalk;
@class MPTaskController;
@class MPTimer;
@class PlayerDataController;
@class Route;






/*!
 * @class      MPTaskRunner
 * @abstract   Move around the Map
 * @discussion 
 * MPTaskRunner is a parent class for all our moving tasks (at least the ones that depend on MPActivityWalk.
 * It does not have a direct task itself, but the children do.
 *
 */
@interface MPTaskRunner : MPTask {
	
	NSArray *locations;
	MPActivityWalk *activityWalk;
	MPLocation *currentLocation;
	BOOL useMount;
	
	
	
//	MPPullState state;
}
@property (retain) NSArray *locations;
@property (retain) MPActivityWalk *activityWalk;
@property (retain) MPLocation *currentLocation;



- (MPLocation *) bestLocation;

#pragma mark -


/*!
 * @function initWithPather
 * @abstract Convienience method to return a new initialized task.
 * @discussion
 */
+ (id) initWithPather: (PatherController*)controller;


@end
