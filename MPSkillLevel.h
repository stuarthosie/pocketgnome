//
//  MPSkillLevel.h
//  Pocket Gnome
//
//  Created by Coding Monkey on 2/06/11.
//  Copyright 2011 Savory Software, LLC
//
#import <Cocoa/Cocoa.h>
#import "MPValue.h"

/*!
 * @class MPSkillLevel
 * @abstract An MPValue object that returns the value of a specified Skill (profession).
 * @discussion 
 *	An MPSkillLevel is used in the place of the pather $SkillLevel variable.  For example, 
 *  <pre>
 *	If 
 *  {
 *		$cond =  $SkillLevel{"Herbalism"} < 75;  
 *		Par {
 *			Harvest {
 *				$Type = [ "Herbs" ];
 *			}
 *			Hotspots {
 *				$Locations = [ ... ];
 *			}
 *		}
 *	}
 *  </pre>
 *
 *  In the definition of $Cond, an MPSkillLevel would be used to represent $SkillLevel{}.
 */
@interface MPSkillLevel : MPValue {
	
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
+ (MPSkillLevel *) initWithPather: (PatherController *) controller;

@end
