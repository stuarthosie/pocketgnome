//
//  MPTaskRepair.m
//  Pocket Gnome
//
//  Created by Coding Monkey on 1/7/11.
//  Copyright 2011 Savory Software, LLC
//
#import "MPTaskRepair.h"

#import "MobController.h"
#import "MPActivityRepair.h"
#import "MPTask.h"
#import "PatherController.h"
#import "InventoryController.h"
#import "Item.h"







@interface MPTaskRepair (Internal)

- (float) minInventoryDurability;

@end


@implementation MPTaskRepair

// Synthesize variables here:
@synthesize  activityRepair;



- (id) initWithPather:(PatherController*)controller {
	if ((self = [super initWithPather:controller])) {
		name = @"Repair";
		
		self.activityRepair = nil;
		
		isDone = NO;
		minDurability = 1.0f;
		
	}
	return self;
}


- (void) setup {
	minDurability = [[self stringFromVariable:@"mindurability" orReturnDefault:@"0.2"] floatValue];
	
	[super setup];
}



- (void) dealloc
{
	[activityRepair release];
    
	
    [super dealloc];
}

#pragma mark -



- (BOOL) isFinished {
	
	return isDone;
}





- (void) restart {
	isDone = NO;
	[super restart];
}




- (BOOL) readyToStart {
	
	// we are ready to do something once the player's current level is > our lastRepairedLevel
	if ([self minInventoryDurability] <= minDurability) {
		return YES;
	}
	return NO;
}



- (float) minInventoryDurability {
	float minD = INFINITY;
	float curDur;
	
	NSArray *items = [[InventoryController sharedInventory] itemsPlayerIsWearing];
	for(Item *item in items) {
        curDur = ([[item durability] unsignedIntValue] * 1.0f)/[[item maxDurability] unsignedIntValue];
        if (minD > curDur) {
			minD = curDur;
		}
    }	
	return minD;
}



- (MPActivity *) activityInteract {
	
	// if approachTask not created then
	if (activityRepair == nil) {
		
		// create approachTask
		Mob *npc = [self npc];
		self.activityRepair = [MPActivityRepair repairWith:npc forTask:self];
		
	}
	return activityRepair;
	
}



- (void) clearInteractActivity {
	
	if(activityRepair != nil) {
		[activityRepair stop];
		[activityRepair autorelease];
		self.activityRepair = nil;
	}
}


- (BOOL) finishedInteractActivity:(MPActivity *)activity {
	if (activity == activityRepair) {
		[self clearInteractActivity];
		isDone = YES;
		return YES;
	}
	return NO;
}



- (NSString *) textWaitingDescription {
	
	return [NSString stringWithFormat:@"  Waiting ... \n  minDurability[%0.2f]", [self minInventoryDurability]];
}



- (NSString *) textInteractionDescription {
	
	return [NSString stringWithFormat:@"  Repairing ... \n minDurability[%0.2f]", [self minInventoryDurability]];
}




#pragma mark -

+ (id) initWithPather: (PatherController*)controller {
	return [[[MPTaskRepair alloc] initWithPather:controller] autorelease];
}

@end
