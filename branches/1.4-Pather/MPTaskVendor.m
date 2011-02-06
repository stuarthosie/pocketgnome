//
//  MPTaskVendor.m
//  Pocket Gnome
//
//  Created by Coding Monkey on 1/7/11.
//  Copyright 2011 Savory Software, LLC
//
#import "MPTaskVendor.h"

#import "MobController.h"
#import "MPActivitySell.h"
#import "MPTask.h"
#import "MPValueInt.h"
#import "InventoryController.h"







@interface MPTaskVendor (Internal)

- (Mob *) npc;

@end


@implementation MPTaskVendor

// Synthesize variables here:
@synthesize listProtectedItems;
@synthesize  activitySell;



- (id) initWithPather:(PatherController*)controller {
	if ((self = [super initWithPather:controller])) {
		name = @"Vendor";

		self.listProtectedItems = [NSMutableArray array];
		self.activitySell = nil;
		
		sellGrey = YES;  // default : always sell trash
		sellWhite = YES; // 
		sellGreen = NO;  // default : only sell if told to
		
		isDone = NO;

	}
	return self;
}

- (void) setup {

	
	NSMutableArray *tempList = [NSMutableArray array];
	NSArray *itemList = [self arrayStringsFromVariable:@"protected"];

	for( NSString *itemName in itemList) {
		
		[tempList addObject:[NSString stringWithFormat:@"*%@*",[itemName lowercaseString]]];
	}
	self.listProtectedItems = [tempList copy];
	
	sellGrey = [self boolFromVariable:@"sellgrey" orReturnDefault:YES];
	sellWhite = [self boolFromVariable:@"sellwhite" orReturnDefault:YES];
	sellGreen = [self boolFromVariable:@"sellgreen" orReturnDefault:NO];
	
	
	minFreeBagSlots = (NSInteger)[[self integerFromVariable:@"minfreebagslots" orReturnDefault:10000] value];
	
	[super setup];
}



- (void) dealloc
{
	[listProtectedItems release];
	[activitySell release];
    

    [super dealloc];
}

#pragma mark -



- (BOOL) isFinished {
	
	// NOTE:  if a $MinFreeBagSlots value it given, then this task is never done, but always watching your bag state
	//        otherwise, this is a single shot task, and is finished when isDone it set.
	return (minFreeBagSlots < 10000)? NO: isDone;
}





- (void) restart {
	isDone = NO;
	[super restart];
}




- (BOOL) readyToStart {
	
	// if a minFreeBagSlots are set: then check to see if valid.
	if (minFreeBagSlots < 10000) {
		if (minFreeBagSlots >= [[InventoryController sharedInventory] bagSpacesAvailable]) {
			isDone = NO;
			return YES;  
		}
	} else {
		
		// no minFreeBagSlots given, so we want to do our thing if we are !Done
		// this makes this task a single shot task (good for SEQ{} tasks)
		if (!isDone) {
			return YES;
		}
		
	}
	return NO;
}



- (MPActivity *) activityInteract {
	
	// if approachTask not created then
	if (activitySell == nil) {
		
		// create approachTask
		Mob *npc = [self npc];
		self.activitySell = [MPActivitySell sellTo:npc keepItems:listProtectedItems greyItems:sellGrey whiteItems:sellWhite greenItems:sellGreen forTask:self];
		
	}
	return activitySell;
	
}



- (void) clearInteractActivity {
	
	if(activitySell != nil) {
		[activitySell stop];
		[activitySell autorelease];
		self.activitySell = nil;
	}
}


- (BOOL) finishedInteractActivity:(MPActivity *)activity {
	if (activity == activitySell) {
		[self clearInteractActivity];
		isDone = YES;
		return YES;
	}
	return NO;
}



- (NSString *) textWaitingDescription {
	
	return [NSString stringWithFormat:@"  Waiting ... \n  minBagSpace[%d] free[%d]", minFreeBagSlots, [[InventoryController sharedInventory] bagSpacesAvailable]];
}



- (NSString *) textInteractionDescription {
	
	return [NSString stringWithString:@"  Selling Items "];
}




#pragma mark -

+ (id) initWithPather: (PatherController*)controller {
	return [[[MPTaskVendor alloc] initWithPather:controller] autorelease];
}

@end
