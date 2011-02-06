//
//  MPState.h
//  Pocket Gnome
//
//  Created by Coding Monkey on 1/23/11.
//  Copyright 2011 Savory Software, LLC
//
#import <Cocoa/Cocoa.h>
#import "MPValue.h"

/*!
 * @class MPState
 * @abstract An MPValue object that returns the value of a given key.
 * @discussion 
 *	An MPState is used in the place of the pather $State variable.  For example, 
 *  <pre>
 *	If 
 *  {
 *		$Cond =  $State{"Phase"} = "Vendoring";  
 *	}
 *  </pre>
 *
 *  In the definition of $Cond, an MPState would be used to represent $State{}.
 */
@interface MPState : MPValue {

}



/*!
 * @function value
 * @abstract Return the actual value for the given key.
 *
 */
- (NSString *) value;


/*!
 * @function initWithPather
 * @abstract Convienience method to return an initialized object.
 *
 */
+ (MPState *) initWithPather: (PatherController *) controller;

@end
