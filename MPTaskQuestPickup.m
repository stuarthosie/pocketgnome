//
//  MPTaskQuestPickup.m
//  Pocket Gnome
//
//  Created by Coding Monkey on 1/7/11.
//  Copyright 2011 Savory Software, LLC
//
#import "MPTaskQuestPickup.h"

#import "InventoryController.h"
#import "Item.h"
#import "MobController.h"
#import "MPActivityQuestPickup.h"
#import "MPTask.h"
#import "MPToonData.h"
#import "MPValueInt.h"
#import "Node.h"
#import "NodeController.h"
#import "PatherController.h"








@interface MPTaskQuestPickup (Internal)

- (Item *) item;
- (Node *) node;
- (Mob *) npc;
- (NSString *) questKey;

@end


@implementation MPTaskQuestPickup

// Synthesize variables here:
@synthesize nameNode, nameItem, questID;
@synthesize listProtectedItems,listMobNames;
@synthesize  activityQuestPickup;



- (id) initWithPather:(PatherController*)controller {
	if ((self = [super initWithPather:controller])) {
		name = @"QuestPickup";
		
		self.nameNode = nil;
		self.nameItem = nil;
		self.questID = nil;
		self.listProtectedItems = [NSMutableArray array];
		self.listMobNames = nil;
		self.activityQuestPickup = nil;

		isAutoAccept = NO;
		
		isDone = NO;
		hasSetup = NO;
		
	}
	return self;
}

- (void) setup {
	
	self.nameNode = [self stringFromVariable:@"node" orReturnDefault:nil];
	self.nameItem = [self stringFromVariable:@"item" orReturnDefault:nil];
	self.questID = [self stringFromVariable:@"id" orReturnDefault:@"000"];
	
	NSMutableArray *tempList = [NSMutableArray array];
	NSArray *itemList = [self arrayStringsFromVariable:@"protected"];
	
	for( NSString *itemName in itemList) {
		
		[tempList addObject:[NSString stringWithFormat:@"*%@*",[itemName lowercaseString]]];
	}
	self.listProtectedItems = [tempList copy];
	
	
	self.listMobNames = [self arrayStringsFromVariable:@"countmobs"];
	
	isAutoAccept = [self boolFromVariable:@"autoaccept" orReturnDefault:NO];

	[super setup];
}



- (void) dealloc
{
	[nameNode release];
	[nameItem release];
	[questID release];
	[listProtectedItems release];
	[listMobNames release];
	[activityQuestPickup release];
    
	
    [super dealloc];
}

#pragma mark -



- (BOOL) isFinished {
	
	// NOTE:  QuestPickup is finished when a quest has been picked up.  (seems simple, huh?)
	//		  We know this when ToonState for "Quest"+$ID != "Accepted", "Completed", "Done"
	if (!isDone) {
		NSString *value = [[[self patherController] toonData] valueForKey: [self questKey]];
		if ([value isEqualToString:@"Accepted"]) isDone = YES;
		if ([value isEqualToString:@"Completed"]) isDone = YES;
		if ([value isEqualToString:@"Done"]) isDone = YES;
		
		// if we are not done due to quest status, then make sure we do an initial setup:
		if (!isDone) {
		
			if (!hasSetup) {
			
				for( NSString *mobName in listMobNames) {
					
					[patherController addKillCountMob:mobName];
					[patherController resetKillCountMob:mobName]; // since we are just starting the quest, reset the counts to 0
				}
				
				hasSetup = YES;
			}
		}
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
	if (activityQuestPickup == nil) {
		
		// create approachTask
		Mob *npc = [self npc];
		Node *qNode = [self node];
		Item *qItem = [self item];
		self.activityQuestPickup = [MPActivityQuestPickup pickupQuestFrom:npc orNode:qNode orItem:qItem withID:questID isAutoAccept:isAutoAccept forTask:self];
		
	}
	return activityQuestPickup;
	
}



- (void) clearInteractActivity {
	
	if(activityQuestPickup != nil) {
		[activityQuestPickup stop];
		[activityQuestPickup autorelease];
		self.activityQuestPickup = nil;
	}
}


- (BOOL) finishedInteractActivity:(MPActivity *)activity {
	if (activity == activityQuestPickup) {
		[self clearInteractActivity];
		
		// mark this quest as "Accepted"
		[[[self patherController] toonData] setValue:@"Accepted" forKey:[self questKey]];
		isDone = YES;
		return YES;
	}
	return NO;
}



- (NSString *) textWaitingDescription {
	
	return [NSString stringWithFormat:@"  Waiting ... \n  questID[%@]", questID];
}



- (NSString *) textInteractionDescription {
	
	return [NSString stringWithString:@"  Attempting Quest Pickup "];
}


#pragma mark -


- (Item *) item {
	
	// TODO: implement item finding
	return nil;
}


- (Node *) node {

	return [[patherController nodeController] closestNodeWithName:@"wanted"];
}


- (NSString *) questKey {
	
	return [NSString stringWithFormat:@"Quest%@", questID];
}



#pragma mark -

+ (id) initWithPather: (PatherController*)controller {
	return [[[MPTaskQuestPickup alloc] initWithPather:controller] autorelease];
}

@end
