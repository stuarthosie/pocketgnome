//
//  MPItemCount.h
//  Pocket Gnome
//
//  Created by Coding Monkey on 1/19/11.
//  Copyright 2011 Savory Software, LLC
//
#import <Cocoa/Cocoa.h>
#import "MPValue.h"

@class MPTimer;
@class PatherController;



/*!
 * @class MPItemCount
 * @abstract An MPValue object that represents the # of items(named) in your bags.
 * @discussion 
 *	An MPItemCount is used in place of the pather $ItemCount variable.  For example, 
 *  <pre>
 *	If 
 *  {
 *		$cond =  $ItemCount{"Mageweave Cloth"} >= 20; 
 *		Seq 
 *		{
 *			Mail
 *			{
 *				// ...
 *			}
 *		}
 *		
 *	}
 *  </pre>
 *
 *  In the definition of $ItemCount, an MPItemCount would be used to represent $ItemCount.
 */

@interface MPItemCount : MPValue {

	int cachedValue;
	MPTimer *cacheTimeOut;
}
@property (retain) MPTimer *cacheTimeOut;


/*!
 * @function value
 * @abstract Return the actual # of items found.
 *
 */
- (NSInteger) value;


/*!
 * @function initWithPather
 * @abstract Convienience method to return an initialized object.
 *
 */
+ (MPItemCount *) initWithPather: (PatherController *) controller;


@end
