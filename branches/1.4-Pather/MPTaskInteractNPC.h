//
//  MPTaskInteractNPC.h
//  Pocket Gnome
//
//  Created by Coding Monkey on 1/7/11.
//  Copyright 2011 Savory Software, LLC
//
#import <Cocoa/Cocoa.h>
#import "MPTask.h"

@class Mob;
@class MPLocation;
@class MPActivityWalk;
@class PatherController;


typedef enum InteractNPCTask {
	InteractNPCTaskWaiting		= 1,	// waiting for starting condition
    InteractNPCTaskApproachingLocation	= 2,	// moving in range of given Location
	InteractNPCTaskSelling		= 4 	// Interact with NPC
} MPInteractNPCTask;


/*!
 * @class      MPTaskInteractNPC
 * @abstract   A Generic Task to move to an NPC and perform an interaction with them
 * @discussion 
 * Approaches a given NPC and Interact with them.  This is a super class, it's children
 * handle the interaction itself.  The Task parameters that this super class handles are:
 * Parameters:
 *	$NPC       : the name of the vendor to sell to.
 *	$Location  : the location of the vendor [x, y, z];
 * 
 * Example
 * <code>
 *	Vendor
 *	{	
 *		$Prio = 5;
 *		$NPC = "Jeena Featherbow";
 *		$Location = [ 9826.92, 967.32, 1308.79];
 *
 *		$Protected = [
 *			"Cloth", "Juice", "Gnomish Army Knife", "Blacksmith Hammer", "Crystalized",
 *			"Mote Extractor", "Rune", "Arcane Powder", "Cobalt Frag Bomb", "Arclight Spanner",
 *			"Conjured", "Mining Pick", "Skinning Knife", "Leather", "Potion", "Stone", "Ore" 
 *		];
 *		
 *		$SellGrey  = true;
 *		$SellWhite = true;
 *		$SellGreen = false;
 *		// $MinDurability = 0.2;  // NOt implemented yet
 *		$MinFreeBagSlots = 3;     // default :  10000 
 *	}
 * </code>
 *		
 */



@interface MPTaskInteractNPC : MPTask {
	NSString *npcName;
	MPLocation *npcLocation;
		
	MPInteractNPCTask state;
	
	Mob *selectedNPC;
	
	BOOL shouldStayClose;
	
	MPActivityWalk *activityApproach;
}
@property (retain) NSString *npcName;
@property (retain) MPLocation *npcLocation;
@property (retain) MPActivityWalk *activityApproach;
@property (retain) Mob *selectedNPC;


- (Mob *) npc;
+ (id) initWithPather: (PatherController*)controller;
@end

