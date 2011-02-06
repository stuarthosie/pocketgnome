//
//  MPTaskQuestHandin.m
//  Pocket Gnome
//
//  Created by Coding Monkey on 1/7/11.
//  Copyright 2011 Savory Software, LLC
//
#import "MPTaskQuestHandin.h"

#import "InventoryController.h"
#import "Item.h"
#import "MobController.h"
#import "MPActivityQuestHandin.h"
#import "MPTask.h"
#import "MPToonData.h"
#import "MPValueInt.h"
#import "Node.h"
#import "NodeController.h"
#import "PatherController.h"








@interface MPTaskQuestHandin (Internal)

- (Mob *) npc;
- (NSString *) questKey;

@end


@implementation MPTaskQuestHandin

// Synthesize variables here:
@synthesize questID;
@synthesize activityQuestHandin;



- (id) initWithPather:(PatherController*)controller {
	if ((self = [super initWithPather:controller])) {
		name = @"QuestHandin";
		
		self.questID = nil;

		self.activityQuestHandin = nil;
		
		isAutoAccept = NO;
		questReward = -1;
		
		isDone = NO;
		
	}
	return self;
}

- (void) setup {
	
	self.questID = [self stringFromVariable:@"id" orReturnDefault:@"000"];
	
	isAutoAccept = [self boolFromVariable:@"autoaccept" orReturnDefault:NO];
	
	questReward = [[self stringFromVariable:@"reward" orReturnDefault:@"0"] intValue];
	
	[super setup];
}



- (void) dealloc
{
	[questID release];
	[activityQuestHandin release];
    
	
    [super dealloc];
}

#pragma mark -



- (BOOL) isFinished {
	
	// NOTE:  QuestHandin is finished when a quest has been handed in.  (seems simple, huh?)
	//		  We know this when ToonState for "Quest"+$ID != "Done"
	if (!isDone) {
		NSString *value = [[[self patherController] toonData] valueForKey: [self questKey]];
		if ([value isEqualToString:@"Done"]) isDone = YES;
		
	}
	return isDone;
}





- (void) restart {
	//	isDone = NO;
	[super restart];
}




- (BOOL) readyToStart {
	
	// we are ready to start whenever we have the opportunity
	return !isDone;
}



- (MPActivity *) activityInteract {
	
	// if approachTask not created then
	if (activityQuestHandin == nil) {
		
		// create approachTask
		Mob *npc = [self npc];
		self.activityQuestHandin = [MPActivityQuestHandin handinQuestTo:npc withID:questID isAutoAccept:isAutoAccept withReward:questReward forTask:self];
		
	}
	return activityQuestHandin;
	
}



- (void) clearInteractActivity {
	
	if(activityQuestHandin != nil) {
		[activityQuestHandin stop];
		[activityQuestHandin autorelease];
		self.activityQuestHandin = nil;
	}
}


- (BOOL) finishedInteractActivity:(MPActivity *)activity {
	if (activity == activityQuestHandin) {
		[self clearInteractActivity];
		
		// mark this quest as "Accepted"
		[[[self patherController] toonData] setValue:@"Done" forKey:[self questKey]];
		isDone = YES;
		return YES;
	}
	return NO;
}



- (NSString *) textWaitingDescription {
	
	return [NSString stringWithFormat:@"  Waiting ... \n  questID[%@]", questID];
}



- (NSString *) textInteractionDescription {
	
	return [NSString stringWithString:@"  Attempting Quest Handin "];
}


#pragma mark -




- (NSString *) questKey {
	
	return [NSString stringWithFormat:@"Quest%@", questID];
}



#pragma mark -

+ (id) initWithPather: (PatherController*)controller {
	return [[[MPTaskQuestHandin alloc] initWithPather:controller] autorelease];
}

@end
