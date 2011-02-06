//
//  MPActivityQuestHandin.h
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


typedef enum QuestHandinActivity { 
    QuestHandinActivityStarted				= 1,	// haven't done Squat!
	QuestHandinActivityOpeningQuestgiver	= 2,	// attempting to open the quest giver Window
	QuestHandinActivityClickingQuestItem	= 3,	// clicking quest to accept
	QuestHandinActivityClickContinue		= 4,	// clicking continue (for some quests)
	QuestHandinActivityAcceptQuest			= 5,	// clicking accept quest
	QuestHandinActivityDone					= 6		// All Done
} MPQuestHandinActivity; 



// This activity sets your Hearthstone with the given Questgiver

@interface MPActivityQuestHandin : MPActivity {
	Mob *questGiver;  // pickup from an npc
	
	NSString *questID;
	
	BOOL isAutoAccept; // is this quest automatically accepted ?
	
	MPQuestHandinActivity state;
	MPTimer *timeOutClick;
	MPMover *mover;
	
	int countEntries;
	
	int questReward;
}
@property (retain) Mob *questGiver;
@property (retain) NSString *questID;
@property (retain) MPMover *mover;
@property (retain) MPTimer *timeOutClick;



+ (id) handinQuestTo:(Mob *)npc withID:(NSString*)qID isAutoAccept:(BOOL)isAuto withReward:(int)optionReward forTask:(MPTask *)aTask;
@end
