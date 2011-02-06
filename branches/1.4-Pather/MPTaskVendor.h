//
//  MPTaskVendor.h
//  Pocket Gnome
//
//  Created by Coding Monkey on 1/7/11.
//  Copyright 2011 Savory Software, LLC
//
#import <Cocoa/Cocoa.h>
#import "MPTaskInteractNPC.h"


@class MPActivitySell;
@class PatherController;


/*!
 * @class      MPTaskVendor
 * @abstract   Sell your stuff to a vendor
 * @discussion 
 * Approaches a given vendor and sells items in your bags that match the given criteria.
 * Parameters:
 *	$NPC       : the name of the vendor to sell to.
 *	$Location  : the location of the vendor [x, y, z];
 *	$Protected : a list of names of items to NOT sell (note, this can be partial match)
 *	$SellGrey  : Sell Grey quality items? [true, false]
 *	$SellWhite : Sell White quality items? [true, false]
 *	$SellGreen : Sell Green quality items? [true, false]
 *	$MinFreeBagSlots : if set, this task wont want to do anything until you have less than this many free bag slots.
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



@interface MPTaskVendor : MPTaskInteractNPC {
	
	NSArray *listProtectedItems;
	BOOL sellGrey, sellWhite, sellGreen;
	
	BOOL isDone;
	
	
	NSInteger minFreeBagSlots;
	
	MPActivitySell *activitySell;
}
@property (retain) NSArray *listProtectedItems;
@property (retain) MPActivitySell *activitySell;


+ (id) initWithPather: (PatherController*)controller;
@end
