//
//  MPActivitySetHearth.m
//  Pocket Gnome
//
//  Created by Coding Monkey on 1/10/11.
//  Copyright 2011 Savory Software, LLC
//
#import "MPActivitySetHearth.h"
#import "BotController.h"
#import "MacroController.h"
#import "Mob.h"
#import "MPMover.h"
#import "MPTask.h"
#import "MPTimer.h"
#import "PatherController.h"



@interface MPActivitySetHearth (Internal)

- (void) clickInnkeeper;
- (void) clickHearthOption;
- (void) confirmBinding;

@end


@implementation MPActivitySetHearth
@synthesize innkeeper, timeOutClick, mover; 


- (id)  initWithInnkeeper:(Mob *)npc andTask:(MPTask *)aTask  {
	
	if ((self = [super initWithName:@"SetHearth" andTask:aTask])) {
		
		self.innkeeper	= npc;
		self.timeOutClick = [MPTimer timer:1000];
		self.mover = [MPMover sharedMPMover];
		
		state = SetHearthActivityStarted;
		count = 0;
	}
	return self;
}


- (void) dealloc
{
    [innkeeper release];
	[timeOutClick release];
	[mover release];
	
    [super dealloc];
}


#pragma mark -



// ok Start gets called 1x when activity is started up.
- (void) start {
	
	if (innkeeper == nil) {
		PGLog( @"[ActivitySetHearth] Error: ActivitySetHearth called with innkeeper as NIL");
		return;
	}
	
	
	// if innkeeper is in Distance
	float distanceToInnkeeper = [task myDistanceToMob:innkeeper];
	if (distanceToInnkeeper <= 5.0 ) {
		
		
		PGLog( @"[ActivitySetHearth] [start] clicking on Innkeeper ... ");
		
		// face innkeeper
		[mover faceLocation:(MPLocation *)[innkeeper position]];
		
		// mouse click on mob
		[self clickInnkeeper];
		
		
		// timeOut start
		[timeOutClick start];
		
		
		state = SetHearthActivityOpeningInnkeeper;
		
		return;
		
	} else{
		
		PGLog( @"[ActivitySetHearth]  Error: too far away to attempt setting!  MPTaskSetHearth -> needs to do a better job on approach." );
		
	} // end if in distance
	
	// hmmmm ... if we get here then we shouldn't be training
	state = SetHearthActivityDone;
}



// work is called repeatedly every 100ms or so.
- (BOOL) work {
	
	// switch (state)
	switch (state) {
		case SetHearthActivityStarted:
			
			//// How did we get here???
			
			// face innkeeper
			[mover faceLocation:(MPLocation *)[innkeeper position]];
			
			// mouse click on mob
			[self clickInnkeeper];
			
			
			// timeOut start
			[timeOutClick start];
			
			
			state = SetHearthActivityOpeningInnkeeper;
			return NO;
			break;
			
			
			
		case SetHearthActivityOpeningInnkeeper:
			// NOTE: we really need a method to detect when the Innkeeper Window appears
			
			// if ([self innkeeperWindowOpen]) {
			//		state = SetHearthActivityClickingItems;
			//		[self clickNextItem];
			// }
			
			/// until then just wait for the timer to hope the window is open
			// if timeOut ready
			if ([timeOutClick ready]) {
				
				state = SetHearthActivityClickingOption;
				[self clickHearthOption];
				[timeOutClick start];
				
			} // end if
			
			return NO;
			break;
			
			
		case SetHearthActivityClickingOption:
			
			
			if ([timeOutClick ready]) {
				[self confirmBinding];
				state = SetHearthActivityAcceptBinding;
				[timeOutClick start];
			}
			return NO;
			break;
			
		case SetHearthActivityAcceptBinding:
			if ([timeOutClick ready]) {
				state = SetHearthActivityDone;
				[timeOutClick start];
				return YES;
			}
			return NO;
			break;
			
		default:
		case SetHearthActivityDone:
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
		case SetHearthActivityOpeningInnkeeper:
			[text appendString:@"   opening Innkeeper window."];
			break;
			
		case SetHearthActivityClickingOption:
			[text appendString:@"  clicking on home option "];
			break;
		
		case SetHearthActivityAcceptBinding:
			[text appendString:@"  Accepting Binding."];
			break;
			
		default:
		case SetHearthActivityDone:
			[text appendString:@"  Done!"];
			break;
			
	}
	
	return text;
}

#pragma mark -
#pragma mark Internal


// perform an interaction with the innkeeper
- (void) clickInnkeeper {
	[[[task patherController] botController] interactWithMouseoverGUID: [innkeeper GUID]];
}




- (void) clickHearthOption {
	
	
	// Should really clean this command up and see if I can put it in a loop ... 
	NSString *macroCommand = [NSString stringWithString:@"/run local t1, _, t2, _, t3, _ = GetGossipOptions(); local idx=0; if (string.find(t1,\"home\")) then idx=1; end; if (string.find(t2,\"home\")) then idx=2; end; if (string.find(t3,\"home\")) then idx=3; end; if (idx ~= 0) then SelectGossipOption(idx); end;"];
	[[[task patherController] macroController] useMacroOrSendCmd:macroCommand];
	
}


- (void) confirmBinding {
	
	NSString *macroCommand = [NSString stringWithString:@"/run ConfirmBinder();"];
	[[[task patherController] macroController] useMacroOrSendCmd:macroCommand];
	
}



#pragma mark -

+ (id) setHearthWith:(Mob *)npc forTask:(MPTask *)aTask {
	
	return [[[MPActivitySetHearth alloc] initWithInnkeeper:npc andTask:aTask] autorelease];
}


@end