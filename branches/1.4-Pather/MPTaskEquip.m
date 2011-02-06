//
//  MPTaskEquip.m
//  Pocket Gnome
//
//  Created by Coding Monkey on 1/31/11.
//  Copyright 2011 Savory Software, LLC
//

#import "MPTaskEquip.h"

#import "BlacklistController.h"
#import "BotController.h"
#import "CombatController.h"
#import "CombatProfile.h"
#import "InventoryController.h"
#import "Item.h"
#import "Mob.h"
#import "MobController.h"
#import "MPActivityEquipItem.h"
#import "MPCustomClass.h"
#import "MPMover.h"
#import "MPTask.h"
#import "MPTimer.h"
#import "MPValue.h"
#import "PatherController.h"
#import "PlayerDataController.h"





@interface MPTaskEquip (Internal)

- (void) clearActivityEquip;
@end


@implementation MPTaskEquip

// Synthesize variables here:
@synthesize itemName;
@synthesize activityEquip;



- (id) initWithPather:(PatherController*)controller {
	if ((self = [super initWithPather:controller])) {
		name = @"Equip";
		
		self.itemName = nil;
		self.activityEquip = nil;
		
		isDone = NO;
	}
	return self;
}

- (void) setup {
	
	self.itemName = [self stringFromVariable:@"item" orReturnDefault:@"noName"];
	
	[super setup];
}



- (void) dealloc
{
    [itemName release];
    [activityEquip release];
	
    [super dealloc];
}

#pragma mark -



- (BOOL) isFinished {
	return isDone;
}



- (MPLocation *) location {
	
	return (MPLocation *)[self myPosition];
}



- (void) restart {
	
}



- (BOOL) wantToDoSomething {

	return !isDone;
}



- (MPActivity *) activity {
	
	if (activityEquip == nil) {
		
		self.activityEquip = [MPActivityEquipItem equipItem:itemName forTask:self];
	}
	return activityEquip;
	
	/*
	// OK, I'm being asked for an activity, so try to simply do our action here:
	Item *item = [self item];
	
	if (item != nil) {
		UInt32 itemID = [item GUID];
		UInt32 actionID = (USE_ITEM_MASK + itemID);
		
		log(LOG_WAYPOINT, @"Using item %d", itemID);
		

		[[patherController botController] performAction:actionID];
		
		isDone = YES;
	
	} else {
		
		PGLog(@"   +++++  Equip error: itemName[%@] not found in inventory. ", itemName);
	}
	
	// we really shouldn't get here.
	// return 
	return nil;
	 */
}



- (BOOL) activityDone: (MPActivity*)activity {
	
	if (activity == activityEquip) {
		[self clearActivityEquip];
		isDone = YES;
	}
	return YES; // ??
}


#pragma mark -
#pragma mark Helper Functions


- (void) clearActivityEquip {
	
	if(activityEquip != nil) {
		[activityEquip stop];
		[activityEquip autorelease];
		self.activityEquip = nil;
	}
}


- (void) clearBestTask {
	
	
}



- (NSString *) description {
	NSMutableString *text = [NSMutableString string];
	
	[text appendFormat:@"%@\n  item=[%@]", self.name, itemName];
	
	
	return text;
}


- (Item *) item {
	
	
	return [[InventoryController sharedInventory] itemForName:itemName];
	
}




#pragma mark -

+ (id) initWithPather: (PatherController*)controller {
	return [[[MPTaskEquip alloc] initWithPather:controller] autorelease];
}

@end

