//
//  MPTaskTaxi.h
//  Pocket Gnome
//
//  Created by Coding Monkey on 1/7/11.
//  Copyright 2011 Savory Software, LLC
//
#import <Cocoa/Cocoa.h>
#import "MPTaskInteractNPC.h"


@class MPActivityTaxi;
@class PatherController;


/*!
 * @class      MPTaskTaxi
 * @abstract   Use the given taxi to fly to another location.
 * @discussion 
 * Approaches an Taxi Driver and flys to a given destination.
 * Parameters:
 *	$NPC       : the name of the Innkeeper.
 *	$Location  : the location of the vendor [x, y, z];
 *	$Destination : the name of the destination you want to fly to.  (case sensitive, but partial match ok)
 * Example
 * <code>
 *	Taxi
 *	{	
 *		$Prio = 5;
 *		$NPC = "Mardant Strongoak";
 *		$Location = [10484.04, 814.92, 1322.75];
 *      $Destination = "Stormwind";  // bad:"stormwind", good: "ormwind", "Storm", "wind", etc...
 *	}
 * </code>
 *		
 */



@interface MPTaskTaxi : MPTaskInteractNPC {
	
	NSString *destination;
	BOOL isDone;
	
	MPActivityTaxi *activityTaxi;
}
@property (retain) NSString *destination;
@property (retain) MPActivityTaxi *activityTaxi;


+ (id) initWithPather: (PatherController*)controller;
@end

