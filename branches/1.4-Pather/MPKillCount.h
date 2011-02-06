//
//  MPKillCount.h
//  Pocket Gnome
//
//  Created by Coding Monkey on 1/23/11.
//  Copyright 2011 Savory Software, LLC
//
#import <Cocoa/Cocoa.h>
#import "MPValue.h"

/*!
 * @class MPKillCount
 * @abstract An MPValue object that returns the # of times you have killed a given mob.
 * @discussion 
 *	An MPKillCount is used in the place of the pather $KillCount variable.  For example, 
 *  <pre>
 *	If 
 *  {
 *		$cond =  $KillCount{"Young Nightsaber"} < 6;  
 *	}
 *  </pre>
 *
 *  In the definition of $Cond, an MPKillCount would be used to represent $KillCount{}.
 */
@interface MPKillCount : MPValue {
	
}



/*!
 * @function value
 * @abstract Return the kill count value for the given key.
 *
 */
- (NSInteger) value;


/*!
 * @function initWithPather
 * @abstract Convienience method to return an initialized object.
 *
 */
+ (MPKillCount *) initWithPather: (PatherController *) controller;

@end
