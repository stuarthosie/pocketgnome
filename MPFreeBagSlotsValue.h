//
//  MPFreeBagSlotsValue.h
//  Pocket Gnome
//
//  Created by Coding Monkey on 1/11/11.
//  Copyright 2011 Savory Software, LLC
//
#import <Cocoa/Cocoa.h>
#import "MPValue.h"
@class PatherController;

/*!
 * @class MPFreeBagSlotsValue
 * @abstract An MPValue object that represents the # of open slots in your bags.
 * @discussion 
 *	An MPFreeBagSlotsValue is used in place of the pather $FreeBagSlots variable.  For example, 
 *  <pre>
 *	If 
 *  {
 *		$cond =  $FreeBagSlots <= 2; 
 *		Seq 
 *		{
 *			Vendor
 *			{
 *				// ...
 *			}
 *		}
 *		
 *	}
 *  </pre>
 *
 *  In the definition of $FreeBagSlots, an MPFreeBagSlotsValue would be used to represent $FreeBagSlots.
 */
@interface MPFreeBagSlotsValue : MPValue {
}


/*!
 * @function value
 * @abstract Return the actual # of Free Bag Slots.
 *
 */
- (NSInteger) value;


/*!
 * @function initWithPather
 * @abstract Convienience method to return an initialized object.
 *
 */
+ (MPFreeBagSlotsValue *) initWithPather: (PatherController *) controller;


@end
