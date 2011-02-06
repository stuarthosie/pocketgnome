//
//  MPActivityQuestPickup.h
//  Pocket Gnome
//
//  Created by Coding Monkey on 1/1/11.
//  Copyright 2011 Savory Software, LLC
//
#import <Cocoa/Cocoa.h>
#import "MPActivity.h"

@class MPMover;
@class MPTimer;
@class Mob;
@class Node;
@class Item;


typedef enum QuestPickupActivity { 
    QuestPickupActivityStarted				= 1,	// haven't done Squat!
	QuestPickupActivityOpeningQuestgiver	= 2,	// attempting to open the quest giver Window
	QuestPickupActivityClickingQuestItem	= 3,	// clicking quest to accept
	QuestPickupActivityClickContinue		= 4,	// clicking continue (for some quests)
	QuestPickupActivityAcceptQuest			= 5,	// clicking accept quest
	QuestPickupActivityDone					= 6		// All Done
} MPQuestPickupActivity; 



// This activity sets your Hearthstone with the given Questgiver

@interface MPActivityQuestPickup : MPActivity {
	Mob *questGiver;  // pickup from an npc
	Node *questNode;  // pickup from a node (like a wanted sign)
	Item *questItem;  // pickup from an item in your inventory (dropped plans)
	
	NSString *questID;
	
	BOOL isAutoAccept; // is this quest automatically accepted ?
	
	MPQuestPickupActivity state;
	MPTimer *timeOutClick;
	MPMover *mover;
	
	int count;
}
@property (retain) Mob *questGiver;
@property (retain) Node *questNode;
@property (retain) Item *questItem;
@property (retain) NSString *questID;
@property (retain) MPMover *mover;
@property (retain) MPTimer *timeOutClick;



+ (id) pickupQuestFrom:(Mob *)npc  orNode: (Node*) qNode orItem:(Item *)qItem withID:(NSString*)qID isAutoAccept:(BOOL)isAuto forTask:(MPTask *)aTask;
@end
