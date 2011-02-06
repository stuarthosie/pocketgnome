//
//  MPTaskHearth.h
//  Pocket Gnome
//
//  Created by Coding Monkey on 1/31/11.
//  Copyright 2011 Savory Software, LLC
//
#import <Cocoa/Cocoa.h>
#import "MPTask.h"

@class Mob;
@class MobController;

@class MPActivityHearth;
@class MPTimer;


/*!
 * @class      MPTaskHearth
 * @abstract   Attempt to Hearth 
 * @discussion 
 * Attempt to our Hearthstone. 
 *
 * Example
 * <code>
 *	 Hearth
 *	 {
 *		$Prio = 4;
 *	 }
 * </code>
 *		
 */
@interface MPTaskHearth : MPTask {
	BOOL isDone;
	MPActivityHearth *activityHearth;
}
@property (retain) MPActivityHearth *activityHearth;


#pragma mark -


/*!
 * @function initWithPather
 * @abstract Convienience method to return a new initialized task.
 * @discussion
 */
+ (id) initWithPather: (PatherController*)controller;


@end
