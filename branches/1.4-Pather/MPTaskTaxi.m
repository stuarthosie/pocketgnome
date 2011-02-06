//
//  MPTaskTaxi.m
//  Pocket Gnome
//
//  Created by Coding Monkey on 1/7/11.
//  Copyright 2011 Savory Software, LLC
//
#import "MPTaskTaxi.h"

#import "MobController.h"
#import "MPActivityTaxi.h"
#import "MPTask.h"
#import "MPValueInt.h"
#import "PatherController.h"
#import "PlayerDataController.h"
#import "InventoryController.h"




@interface MPTaskTaxi (Internal)


@end


@implementation MPTaskTaxi

// Synthesize variables here:
@synthesize  destination, activityTaxi;



- (id) initWithPather:(PatherController*)controller {
	if ((self = [super initWithPather:controller])) {
		name = @"Taxi";
		self.destination = nil;
		self.activityTaxi = nil;
		
		isDone = NO;
		shouldStayClose = NO; // we will fly away, so don't try to stay close to NPC;
		
	}
	return self;
}


- (void) setup {
	// sethearth Task doesn't have any specific variables to setup ... 
	self.destination = [self stringFromVariable:@"destination" orReturnDefault:@"Smallville"];
	
	[super setup];
}



- (void) dealloc
{
	[destination release];
	[activityTaxi release];
    
	
    [super dealloc];
}

#pragma mark -



- (BOOL) isFinished {
	
	// NOTE:  We are finisehd once we have flown to our dest.
	return isDone;
}





- (void) restart {
	isDone = NO;  // task is able to be reused again
	[super restart];
}




- (BOOL) readyToStart {
	
	// we are ready as soon as this task is able to ...
	return !isDone;
}



- (MPActivity *) activityInteract {
	
	// if approachTask not created then
	if (activityTaxi == nil) {
		
		// create approachTask
		Mob *npc = [self npc];
		self.activityTaxi = [MPActivityTaxi taxiWith:npc to:destination forTask:self];
		
	}
	return activityTaxi;
	
}



- (void) clearInteractActivity {
	
	if(activityTaxi != nil) {
		[activityTaxi stop];
		[activityTaxi autorelease];
		self.activityTaxi = nil;
	}
}


- (BOOL) finishedInteractActivity:(MPActivity *)activity {
	if (activity == activityTaxi) {
		[self clearInteractActivity];
		isDone = YES;
		return YES;
	}
	return NO;
}



- (NSString *) textWaitingDescription {
	
	return [NSString stringWithString:@"  Waiting ... "];
}



- (NSString *) textInteractionDescription {
	
	return [NSString stringWithString:@"  Taxiing ... "];
}




#pragma mark -

+ (id) initWithPather: (PatherController*)controller {
	return [[[MPTaskTaxi alloc] initWithPather:controller] autorelease];
}

@end
