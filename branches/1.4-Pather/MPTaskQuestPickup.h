//
//  MPTaskQuestPickup.h
//  Pocket Gnome
//
//  Created by Coding Monkey on 1/7/11.
//  Copyright 2011 Savory Software, LLC
//
#import <Cocoa/Cocoa.h>
#import "MPTaskInteractNPC.h"


@class MPActivityQuestPickup;
@class PatherController;


/*!
 * @class      MPTaskQuestPickup
 * @abstract   Pickup a Quest
 * @discussion 
 * Approaches a given quest giver and get a quest.
 * Parameters:
 *	$NPC       : the name of the quest giver. (leave $Node, $Item empty)
 *  $Node	   : the name of a node giving a quest. (leave $NPC, $Item empty)
 *  $Item	   : the name of an inventory item with a quest. (leave $NPC, $Node empty)
 *	$Location  : the location of the questGiver / Node (leave blank if $Item);
 *	$Protected : a list of names of items to NOT sell (items you are collecting for this quest)
 *	$AutoAccept  : Default: false.  Set to true if just clicking the quest giver gives you the quest.
 *  $CountMobs : array of names of mobs you will need to kill for this quest (resets the counters to 0)
 *
 * Example
 * <code>
 *	QuestPickup
 *	{	
 *		$Prio = 5;
 *		$NPC = "Ilthalaine";
 *		$Location = [ 9826.92, 967.32, 1308.79];
 *      $ID=28713;  // The Balance of Nature
 *
 *		$AutoAccept = true;  // true/false;  (default = false);
 *
 *		//$Protected = [
 *		//	"Cloth", "Juice" 
 *		//];
 *		$CountMobs = [ "Young Nightsabers" ]; // exact matches
 *	}
 * </code>
 *		
 */



@interface MPTaskQuestPickup : MPTaskInteractNPC {
	
	NSString *nameNode;
	NSString *nameItem;
	
	NSString *questID;  // just keep it a string.
	
	NSArray *listProtectedItems;
	NSArray *listMobNames;
	
	BOOL isAutoAccept;
	BOOL isDone, hasSetup;
	
	MPActivityQuestPickup *activityQuestPickup;
}
@property (retain) NSString *nameNode, *nameItem, *questID;
@property (retain) NSArray *listProtectedItems, *listMobNames;
@property (retain) MPActivityQuestPickup *activityQuestPickup;


+ (id) initWithPather: (PatherController*)controller;
@end
