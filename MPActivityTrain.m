//
//  MPActivityTrain.m
//  Pocket Gnome
//
//  Created by Coding Monkey on 1/10/11.
//  Copyright 2011 Savory Software, LLC
//
#import "MPActivityTrain.h"
#import "BotController.h"
#import "MacroController.h"
#import "Mob.h"
#import "MPMover.h"
#import "MPTask.h"
#import "MPTimer.h"
#import "PatherController.h"



@interface MPActivityTrain (Internal)

- (void) clickTrainer;
- (void) selectTraining;
- (void) trainItem;

@end


@implementation MPActivityTrain
@synthesize trainer, timeOutClick, mover; 


- (id)  initWithTrainer:(Mob *)npc andTask:(MPTask *)aTask  {
	
	if ((self = [super initWithName:@"Train" andTask:aTask])) {
		
		self.trainer	= npc;
		self.timeOutClick = [MPTimer timer:1000];
		self.mover = [MPMover sharedMPMover];
		
		state = TrainActivityStarted;
		count = 0;
	}
	return self;
}


- (void) dealloc
{
    [trainer release];
	[timeOutClick release];
	[mover release];
	
    [super dealloc];
}


#pragma mark -



// ok Start gets called 1x when activity is started up.
- (void) start {
	
	if (trainer == nil) {
		PGLog( @"[ActivityTrain] Error: ActivityTrain called with trainer as NIL");
		return;
	}
	
	
	// if trainer is in Distance
	float distanceToTrainer = [task myDistanceToMob:trainer];
	if (distanceToTrainer <= 5.0 ) {
		
		
		PGLog( @"[ActivityTrain] [start] clicking on Trainer ... ");
		
		// face trainer
		[mover faceLocation:(MPLocation *)[trainer position]];
		
		// mouse click on mob
		[self clickTrainer];
		
		
		// timeOut start
		[timeOutClick start];
		
		
		state = TrainActivityOpeningTrainer;
		
		return;
		
	} else{
		
		PGLog( @"[ActivityTrain]  Error: too far away to attempt selling!  MPTaskTrain -> needs to do a better job on approach." );
		
	} // end if in distance
	
	// hmmmm ... if we get here then we shouldn't be training
	state = TrainActivityDone;
}



// work is called repeatedly every 100ms or so.
- (BOOL) work {
	
	// switch (state)
	switch (state) {
		case TrainActivityStarted:
			
			//// How did we get here???
			
			// face trainer
			[mover faceLocation:(MPLocation *)[trainer position]];
			
			// mouse click on mob
			[self clickTrainer];
			
			
			// timeOut start
			[timeOutClick start];
			
			
			state = TrainActivityOpeningTrainer;
			return NO;
			break;
			
			
			
		case TrainActivityOpeningTrainer:
			// NOTE: we really need a method to detect when the Trainer Window appears
			
			// if ([self trainerWindowOpen]) {
			//		state = TrainActivityClickingItems;
			//		[self clickNextItem];
			// }
			
			/// until then just wait for the timer to hope the window is open
			// if timeOut ready
			if ([timeOutClick ready]) {
				
				state = TrainActivitySelectTraining;
				[self selectTraining];
				[timeOutClick start];
				
			} // end if
			
			return NO;
			break;
			
			
		case TrainActivitySelectTraining:
			
			// times up, start training:
			if ([timeOutClick ready]) {
				
				state = TrainActivityClickingItems;
				[self trainItem];
				count++;
				
				[timeOutClick start];
				
			} // end if
			
			return NO;
			break;
			
			
		case TrainActivityClickingItems:
			
			// so what is the max # of trainable items available at a time?  (guessing 6 at the moment)
			if (count >= 6) {
				state = TrainActivityDone;
				return YES;
			}
			if ([timeOutClick ready]) {
				[self trainItem];
				count++;
				[timeOutClick start];
			}
			return NO;
			break;
			
			
		default:
		case TrainActivityDone:
			return YES;
			break;
			
	}
	
	// otherwise, we exit (but we are not "done"). 
	return NO;
}



// we are interrupted before we arrived.  Make sure we stop moving.
- (void) stop{
	
	
	[mover stopAllMovement];
	
}

#pragma mark -


- (NSString *) description {
	NSMutableString *text = [NSMutableString string];
	
	[text appendFormat:@"%@\n", self.name];
	switch (state) {
		case TrainActivityOpeningTrainer:
			[text appendString:@"   opening Trainer window."];
			break;
			
		case TrainActivityClickingItems:
			[text appendFormat:@"  training attempt: %d / 6 ", count];
			break;
			
		default:
		case TrainActivityDone:
			[text appendString:@"  Done!"];
			break;
			
	}
	
	return text;
}

#pragma mark -
#pragma mark Internal


// perform an interaction with the trainer
- (void) clickTrainer {
	[[[task patherController] botController] interactWithMouseoverGUID: [trainer GUID]];
}



- (void) selectTraining {
	
	NSString *macroCommand = [NSString stringWithString:@"/run local t, g; t,g=GetGossipOptions(); if (string.find(t, \"train\")) then SelectGossipOption(1); end;"];
	[[[task patherController] macroController] useMacroOrSendCmd:macroCommand];
}

- (void) trainItem {
	
	NSString *macroCommand = [NSString stringWithString:@"/run BuyTrainerService(1);"];
	[[[task patherController] macroController] useMacroOrSendCmd:macroCommand];
	
}



#pragma mark -

+ (id) trainWith:(Mob *)npc forTask:(MPTask *)aTask {
	
	return [[[MPActivityTrain alloc] initWithTrainer:npc andTask:aTask] autorelease];
}


@end