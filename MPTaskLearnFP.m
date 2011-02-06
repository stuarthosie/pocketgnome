//
//  MPTaskLearnFP.m
//  Pocket Gnome
//
//  Created by Coding Monkey on 1/7/11.
//  Copyright 2011 Savory Software, LLC
//
#import "MPTaskLearnFP.h"

#import "MobController.h"
#import "MPActivityClickUnit.h"
#import "MPTask.h"
#import "MPValueInt.h"
#import "PatherController.h"
#import "PlayerDataController.h"
#import "InventoryController.h"







@interface MPTaskLearnFP (Internal)


@end


@implementation MPTaskLearnFP

// Synthesize variables here:
@synthesize  activityLearnFP;



- (id) initWithPather:(PatherController*)controller {
	if ((self = [super initWithPather:controller])) {
		name = @"LearnFP";
		
		self.activityLearnFP = nil;
		
		isDone = NO;
		
	}
	return self;
}


- (void) setup {
	// learn FP Task doesn't have any specific variables to setup ... 
	
	[super setup];
}



- (void) dealloc
{
	[activityLearnFP release];
    
	
    [super dealloc];
}

#pragma mark -



- (BOOL) isFinished {
	
	// NOTE:  Only need to learn this FP one time
	return isDone;
}





- (void) restart {
//	isDone = NO;   // even restarting wont enable you to relearn a FP
	[super restart];
}




- (BOOL) readyToStart {
	
	// we are ready as soon as this task is able to ...
	return !isDone;
}



- (MPActivity *) activityInteract {
	
	// if approachTask not created then
	if (activityLearnFP == nil) {
		
		// create approachTask
		Mob *npc = [self npc];
		self.activityLearnFP = [MPActivityClickUnit clickUnit:npc forTask:self];
		
	}
	return activityLearnFP;
	
}



- (void) clearInteractActivity {
	
	if(activityLearnFP != nil) {
		[activityLearnFP stop];
		[activityLearnFP autorelease];
		self.activityLearnFP = nil;
	}
}


- (BOOL) finishedInteractActivity:(MPActivity *)activity {
	if (activity == activityLearnFP) {
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
	
	return [NSString stringWithString:@"  Clicking on Taxi ... "];
}




#pragma mark -

+ (id) initWithPather: (PatherController*)controller {
	return [[[MPTaskLearnFP alloc] initWithPather:controller] autorelease];
}

@end
