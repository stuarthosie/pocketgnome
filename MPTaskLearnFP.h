//
//  MPTaskLearnFP.h
//  Pocket Gnome
//
//  Created by Coding Monkey on 1/7/11.
//  Copyright 2011 Savory Software, LLC
//
#import <Cocoa/Cocoa.h>
#import "MPTaskInteractNPC.h"


@class MPActivityClickUnit;
@class PatherController;


/*!
 * @class      MPTaskLearnFP
 * @abstract   Learns the Flightpath for the given Taxi.
 * @discussion 
 * Approaches an Taxi and clicks on it to learn the Flight Path.
 * Parameters:
 *	$NPC       : the name of the Taxi guy.
 *	$Location  : the location of the npc [x, y, z];
 * Example
 * <code>
 *	LearnFP
 *	{	
 *		$Prio = 5;
 *		$NPC = "Mardant Strongoak";
 *		$Location = [10484.04, 814.92, 1322.75];
 *	}
 * </code>
 *		
 */



@interface MPTaskLearnFP : MPTaskInteractNPC {
	
	
	BOOL isDone;
	//	int lastLearnFPedLevel;
	
	MPActivityClickUnit *activityLearnFP;
}
@property (retain) MPActivityClickUnit *activityLearnFP;


+ (id) initWithPather: (PatherController*)controller;
@end

