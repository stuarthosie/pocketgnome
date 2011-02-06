//
//  MPTaskTrain.m
//  Pocket Gnome
//
//  Created by Coding Monkey on 1/7/11.
//  Copyright 2011 Savory Software, LLC
//
#import "MPTaskTrain.h"

#import "MobController.h"
#import "MPActivityTrain.h"
#import "MPCustomClass.h"
#import "MPTask.h"
#import "MPToonData.h"
#import "MPValueInt.h"
#import "PatherController.h"
#import "PlayerDataController.h"
#import "InventoryController.h"







@interface MPTaskTrain (Internal)

- (void) clearActivityTrain;
- (NSString *) key;

@end


@implementation MPTaskTrain

// Synthesize variables here:
@synthesize  type, activityTrain;



- (id) initWithPather:(PatherController*)controller {
	if ((self = [super initWithPather:controller])) {
		name = @"Train";
		
		self.type = nil;
		self.activityTrain = nil;
		
		isDone = NO;
		
		lastTrainedLevel = 0; 
		
		
	}
	return self;
}


- (void) setup {
	self.type = [self stringFromVariable:@"type" orReturnDefault:@"class"];
	
	
	// now that we know our Training Type, let's figure out our last trained level
	// NOTE: the idea is we only want to do training 1x every level, especially for class trainers.
	NSString *val = [[patherController toonData] valueForKey:[self key]];
	if (val == nil) {
		lastTrainedLevel = 0;  
	} else {
		lastTrainedLevel = [val intValue];
	}
	
	[super setup];
}



- (void) dealloc
{
	[type release];
	[activityTrain release];
    
	
    [super dealloc];
}

#pragma mark -



- (BOOL) isFinished {
	
	// NOTE:  Training should never be finished, there will always be another opportunity to train
	return NO;
}





- (void) restart {
	isDone = NO;
	[super restart];
}




- (BOOL) readyToStart {
	
	// we are ready to do something once the player's current level is > our lastTrainedLevel
	if ([[PlayerDataController sharedController] level] != lastTrainedLevel) {
		return YES;
	}
	return NO;
}



- (MPActivity *) activityInteract {
	
	// if approachTask not created then
	if (activityTrain == nil) {
		
		// create approachTask
		Mob *npc = [self npc];
		self.activityTrain = [MPActivityTrain trainWith:npc forTask:self];
		
	}
	return activityTrain;
	
}



- (void) clearInteractActivity {
	
	if(activityTrain != nil) {
		[activityTrain stop];
		[activityTrain autorelease];
		self.activityTrain = nil;
	}
}


- (BOOL) finishedInteractActivity:(MPActivity *)activity {
	if (activity == activityTrain) {
		[self clearInteractActivity];
		isDone = YES;
		lastTrainedLevel = [[PlayerDataController sharedController] level];
		
		[[patherController toonData] setValue:[NSString stringWithFormat:@"%d", lastTrainedLevel] forKey:[self key]];
		
		[[[PatherController sharedPatherController] customClass] updateTraining];
		return YES;
	}
	return NO;
}



- (NSString *) textWaitingDescription {
	
	return [NSString stringWithFormat:@"  Waiting ... \n  lastTrainedLevel[%d] level[%d]", lastTrainedLevel, [[PlayerDataController sharedController] level]];
}



- (NSString *) textInteractionDescription {
	
	return [NSString stringWithString:@"  Training ... "];
}



- (NSString *) key {
	
	return [NSString stringWithFormat:@"lastTrainedLevel[%@]", type];
}


#pragma mark -

+ (id) initWithPather: (PatherController*)controller {
	return [[[MPTaskTrain alloc] initWithPather:controller] autorelease];
}

@end
