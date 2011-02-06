//
//  MPTaskTrain.h
//  Pocket Gnome
//
//  Created by Coding Monkey on 1/7/11.
//  Copyright 2011 Savory Software, LLC
//
#import <Cocoa/Cocoa.h>
#import "MPTaskInteractNPC.h"


@class MPActivityTrain;
@class PatherController;


/*!
 * @class      MPTaskTrain
 * @abstract   Learn new skills from a trainer.
 * @discussion 
 * Approaches a given trainer and learn all the currently available skills.
 * Parameters:
 *	$NPC       : the name of the Trainer to learn from.
 *	$Location  : the location of the trainer [x, y, z];
 *  $Type	   : (optional) Type of training.  (Default is class training.  Can put profession training here: "Herbalism", "Mining", etc...)
 * Example
 * <code>
 *	Train
 *	{	
 *		$Prio = 5;
 *		$NPC = "Mardant Strongoak";
 *		$Location = [10484.04, 814.92, 1322.75];
 *	}
 * </code>
 *		
 */



@interface MPTaskTrain : MPTaskInteractNPC {
	
	
	BOOL isDone;
	int lastTrainedLevel;
	
	NSString *type;
	
	MPActivityTrain *activityTrain;
}
@property (retain) NSString *type;
@property (retain) MPActivityTrain *activityTrain;


+ (id) initWithPather: (PatherController*)controller;
@end
