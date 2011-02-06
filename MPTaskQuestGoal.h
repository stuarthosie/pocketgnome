//
//  MPTaskQuestGoal.h
//  Pocket Gnome
//
//  Created by Coding Monkey on 1/31/11.
//  Copyright 2011 Savory Software, LLC
//
#import <Cocoa/Cocoa.h>
#import "MPTaskPar.h"


/*!
 * @class      MPTaskQuestGoal
 * @abstract   This task marks when a Quest Goal is complete.
 * @discussion 
 * The QuestGoal task is used to indicate when a Quest Goal has been completed.  When the children 
 * of this task are all finished( or don't want to do something) then this goal is considered complete.  
 * This task will then update the Quest Status of the given $ID to "Completed".
 *
 * Example:
 * <code>
 *	 QuestGoal
 *	 {
 *		 $ID = 28713;    // The Balance of Nature
 *		 If {
 *			$cond = $KillCount{"Young Nightsabers"} < 6;
 *			Par {
 *				Hotspots {
 *					$Locations = [
 *									[ 10284.28, 815.61, 1338.11 ],
 *									[ 10376.98, 664.71, 1326.66 ]
 *								 ];
 *				}
 *				Pull {
 *					$Names = [ "Young Nightsabers" ];
 *					$Distance = 50;
 *				}
 *			}
 *		 }
 *	 }
 * </code>
 * In this example, once you have killed 6 or more "Young Nightsabers" the If {} will become finished 
 * and QuestGoal task will then mark the status of $ID to completed.
 *		
 */
@interface MPTaskQuestGoal : MPTaskPar {

	NSString *questID;
	BOOL isDone;
	
}
@property (retain) NSString *questID;


@end
