//
//  MPTaskRepair.h
//  Pocket Gnome
//
//  Created by Coding Monkey on 1/7/11.
//  Copyright 2011 Savory Software, LLC
//
#import <Cocoa/Cocoa.h>
#import "MPTaskInteractNPC.h"


@class MPActivityRepair;
@class PatherController;


/*!
 * @class      MPTaskRepair
 * @abstract   Repair your things from a Vendor.
 * @discussion 
 * Approaches a given vendor and repair all your items.
 * Parameters:
 *	$NPC       : the name of the vendor to repair at.
 *	$Location  : the location of the vendor [x, y, z];
 *  $MinDurability:  the minimum durability of an item before you want to repair.
 * Example
 * <code>
 *	Repair
 *	{	
 *		$Prio = 5;
 *		$NPC = "Mardant Strongoak";
 *		$Location = [10484.04, 814.92, 1322.75];
 *		$MinDurability = 0.2;
 *	}
 * </code>
 *		
 */



@interface MPTaskRepair : MPTaskInteractNPC {
	
	
	BOOL isDone;
	float minDurability;
	
	MPActivityRepair *activityRepair;
}
@property (retain) MPActivityRepair *activityRepair;


+ (id) initWithPather: (PatherController*)controller;
@end
