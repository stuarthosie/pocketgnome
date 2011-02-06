//
//  MPActivityClickUnit.m
//  Pocket Gnome
//
//  Created by Coding Monkey on 1/10/11.
//  Copyright 2011 Savory Software, LLC
//
#import "MPActivityClickUnit.h"
#import "BotController.h"
#import "MacroController.h"
#import "Mob.h"
#import "MPMover.h"
#import "MPTask.h"
#import "MPTimer.h"
#import "PatherController.h"



@interface MPActivityClickUnit (Internal)

- (void) clickUnit;

@end


@implementation MPActivityClickUnit
@synthesize unit, timeOutClick, mover; 


- (id)  initWithUnit:(Mob *)npc andTask:(MPTask *)aTask  {
	
	if ((self = [super initWithName:@"ClickUnit" andTask:aTask])) {
		
		self.unit	= npc;
		self.timeOutClick = [MPTimer timer:1000];
		self.mover = [MPMover sharedMPMover];
		
		state = ClickUnitActivityStarted;
	}
	return self;
}


- (void) dealloc
{
    [unit release];
	[timeOutClick release];
	[mover release];
	
    [super dealloc];
}


#pragma mark -



// ok Start gets called 1x when activity is started up.
- (void) start {
	
	if (unit == nil) {
		PGLog( @"[ActivityClickUnit] Error: ActivityClickUnit called with unit as NIL");
		return;
	}
	
	
	// if unit is in Distance
	float distanceToUnit = [task myDistanceToMob:unit];
	if (distanceToUnit <= 5.0 ) {
		
		
		PGLog( @"[ActivityClickUnit] [start] clicking on Innkeeper ... ");
		
		// face unit
		[mover faceLocation:(MPLocation *)[unit position]];
		
		// mouse click on mob
		[self clickUnit];
		
		
		// timeOut start
		[timeOutClick start];
		
		
		state = ClickUnitActivityClicking;
		
		return;
		
	} else{
		
		PGLog( @"[ActivityClickUnit]  Error: too far away to attempt clicking!  MPTaskClickUnit -> needs to do a better job on approach." );
		
	} // end if in distance
	
	// hmmmm ... if we get here then we shouldn't be training
	state = ClickUnitActivityDone;
}



// work is called repeatedly every 100ms or so.
- (BOOL) work {
	
	// switch (state)
	switch (state) {
		case ClickUnitActivityStarted:
			
			//// How did we get here???
			
			// face unit
			[mover faceLocation:(MPLocation *)[unit position]];
			
			// mouse click on mob
			[self clickUnit];
			
			
			// timeOut start
			[timeOutClick start];
			
			
			state = ClickUnitActivityClicking;
			return NO;
			break;
			
			
			
		case ClickUnitActivityClicking:
			
			// if timeOut ready
			if ([timeOutClick ready]) {
				state = ClickUnitActivityDone;
				return YES;
			} // end if
			
			return NO;
			break;

			
		default:
		case ClickUnitActivityDone:
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
		case ClickUnitActivityStarted:
			[text appendString:@"   starting."];
			break;
			
		case ClickUnitActivityClicking:
			[text appendString:@"  clicking on unit"];
			break;
			
		default:
		case ClickUnitActivityDone:
			[text appendString:@"  Done!"];
			break;
			
	}
	
	return text;
}

#pragma mark -
#pragma mark Internal


// perform an interaction with the unit
- (void) clickUnit {
	[[[task patherController] botController] interactWithMouseoverGUID: [unit GUID]];
}




#pragma mark -

+ (id) clickUnit:(Mob *)npc forTask:(MPTask *)aTask {
	
	return [[[MPActivityClickUnit alloc] initWithUnit:npc andTask:aTask] autorelease];
}


@end