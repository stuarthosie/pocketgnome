//
//  MPTaskSetHearth.m
//  Pocket Gnome
//
//  Created by Coding Monkey on 1/7/11.
//  Copyright 2011 Savory Software, LLC
//
#import "MPTaskSetHearth.h"

#import "MobController.h"
#import "MPActivitySetHearth.h"
#import "MPTask.h"
#import "MPValueInt.h"
#import "PatherController.h"
#import "PlayerDataController.h"
#import "InventoryController.h"







@interface MPTaskSetHearth (Internal)

- (void) clearActivitySetHearth;

@end


@implementation MPTaskSetHearth

// Synthesize variables here:
@synthesize  activitySetHearth;



- (id) initWithPather:(PatherController*)controller {
	if ((self = [super initWithPather:controller])) {
		name = @"SetHearth";
		
		self.activitySetHearth = nil;
		
		isDone = NO;
		
	}
	return self;
}


- (void) setup {
	// sethearth Task doesn't have any specific variables to setup ... 
	
	[super setup];
}



- (void) dealloc
{
	[activitySetHearth release];
    
	
    [super dealloc];
}

#pragma mark -



- (BOOL) isFinished {
	
	// NOTE:  Only need to set your hearthstone to this vendor 1 time
	return isDone;
}





- (void) restart {
	isDone = NO;
	[super restart];
}




- (BOOL) readyToStart {
	
	// we are ready as soon as this task is able to ...
	return !isDone;
}



- (MPActivity *) activityInteract {
	
	// if approachTask not created then
	if (activitySetHearth == nil) {
		
		// create approachTask
		Mob *npc = [self npc];
		self.activitySetHearth = [MPActivitySetHearth setHearthWith:npc forTask:self];
		
	}
	return activitySetHearth;
	
}



- (void) clearInteractActivity {
	
	if(activitySetHearth != nil) {
		[activitySetHearth stop];
		[activitySetHearth autorelease];
		self.activitySetHearth = nil;
	}
}


- (BOOL) finishedInteractActivity:(MPActivity *)activity {
	if (activity == activitySetHearth) {
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
	
	return [NSString stringWithString:@"  Setting Hearthstone ... "];
}




#pragma mark -

+ (id) initWithPather: (PatherController*)controller {
	return [[[MPTaskSetHearth alloc] initWithPather:controller] autorelease];
}

@end
