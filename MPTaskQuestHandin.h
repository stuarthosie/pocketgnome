//
//  MPTaskQuestHandin.h
//  Pocket Gnome
//
//  Created by Coding Monkey on 1/7/11.
//  Copyright 2011 Savory Software, LLC
//
#import <Cocoa/Cocoa.h>
#import "MPTaskInteractNPC.h"


@class MPActivityQuestHandin;
@class PatherController;


/*!
 * @class      MPTaskQuestHandin
 * @abstract   Handin a Quest
 * @discussion 
 * Approaches a given quest giver and turns in a quest.
 * Parameters:
 *	$NPC       : the name of the quest giver. (leave $Node, $Item empty)
 *	$Location  : the location of the questGiver / Node (leave blank if $Item);
 *  $ID		   : the quest id of the quest we are handing in.
 *	$AutoAccept  : Default: false.  Set to true if just clicking the quest giver gives you the quest.
 *  $Reward    : the reward option you want to choose (default: 0 no reward).
 *
 * Example
 * <code>
 *	QuestHandin
 *	{	
 *		$Prio = 5;
 *		$NPC = "Ilthalaine";
 *		$Location = [ 9826.92, 967.32, 1308.79];
 *      $ID=28713;  // The Balance of Nature
 *
 *		$AutoAccept = true;  
 *
 *		$Reward = 1;  // Archery Training Gloves
 *	}
 * </code>
 *		
 */



@interface MPTaskQuestHandin : MPTaskInteractNPC {
	
	NSString *questID;  // just keep it a string.
	
	
	BOOL isAutoAccept;
	BOOL isDone;
	
	int questReward;
	
	MPActivityQuestHandin *activityQuestHandin;
}
@property (retain) NSString *questID;
@property (retain) MPActivityQuestHandin *activityQuestHandin;


+ (id) initWithPather: (PatherController*)controller;
@end
