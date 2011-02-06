//
//  MPTaskLogout.h
//  Pocket Gnome
//
//  Created by Coding Monkey on 1/31/11.
//  Copyright 2011 Savory Software, LLC
//
#import <Cocoa/Cocoa.h>
#import "MPTask.h"

@class MPActivityLogout;
@class MPTimer;


/*!
 * @class      MPTaskLogout
 * @abstract   Attempt to Logout 
 * @discussion 
 * Logs out of our account and Quits WOW. 
 *
 * Example
 * <code>
 *	 Logout
 *	 {
 *		$Prio = 4;
 *	 }
 * </code>
 *		
 */
@interface MPTaskLogout : MPTask {
	BOOL isDone;
	MPActivityLogout *activityLogout;
}
@property (retain) MPActivityLogout *activityLogout;


#pragma mark -


/*!
 * @function initWithPather
 * @abstract Convienience method to return a new initialized task.
 * @discussion
 */
+ (id) initWithPather: (PatherController*)controller;


@end
