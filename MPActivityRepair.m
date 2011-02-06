//
//  MPActivityRepair.m
//  Pocket Gnome
//
//  Created by Coding Monkey on 1/10/11.
//  Copyright 2011 Savory Software, LLC
//
#import "MPActivityRepair.h"
#import "BotController.h"
#import "MacroController.h"
#import "Mob.h"
#import "MPMover.h"
#import "MPTask.h"
#import "MPTimer.h"
#import "PatherController.h"



@interface MPActivityRepair (Internal)

- (void) clickVendor;
- (void) repairStuff;

@end


@implementation MPActivityRepair
@synthesize vendor, timeOutClick, mover; 


- (id)  initWithVendor:(Mob *)npc andTask:(MPTask *)aTask  {
	
	if ((self = [super initWithName:@"Repair" andTask:aTask])) {
		
		self.vendor	= npc;
		self.timeOutClick = [MPTimer timer:1000];
		self.mover = [MPMover sharedMPMover];
		
		state = RepairActivityStarted;
		count = 0;
	}
	return self;
}


- (void) dealloc
{
    [vendor release];
	[timeOutClick release];
	[mover release];
	
    [super dealloc];
}


#pragma mark -



// ok Start gets called 1x when activity is started up.
- (void) start {
	
	if (vendor == nil) {
		PGLog( @"[ActivityRepair] Error: ActivityRepair called with vendor as NIL");
		return;
	}
	
	
	// if vendor is in Distance
	float distanceToVendor = [task myDistanceToMob:vendor];
	if (distanceToVendor <= 5.0 ) {
		
		
		PGLog( @"[ActivityRepair] [start] clicking on Vendor ... ");
		
		// face vendor
		[mover faceLocation:(MPLocation *)[vendor position]];
		
		// mouse click on mob
		[self clickVendor];
		
		
		// timeOut start
		[timeOutClick start];
		
		
		state = RepairActivityOpeningVendor;
		
		return;
		
	} else{
		
		PGLog( @"[ActivityRepair]  Error: too far away to attempt repairing!  MPTaskRepair -> needs to do a better job on approach." );
		
	} // end if in distance
	
	// hmmmm ... if we get here then we shouldn't be training
	state = RepairActivityDone;
}



// work is called repeatedly every 100ms or so.
- (BOOL) work {
	
	// switch (state)
	switch (state) {
		case RepairActivityStarted:
			
			//// How did we get here???
			
			// face vendor
			[mover faceLocation:(MPLocation *)[vendor position]];
			
			// mouse click on mob
			[self clickVendor];
			
			
			// timeOut start
			[timeOutClick start];
			
			
			state = RepairActivityOpeningVendor;
			return NO;
			break;
			
			
			
		case RepairActivityOpeningVendor:
			// NOTE: we really need a method to detect when the Repairer Window appears
			
			// if ([self vendorWindowOpen]) {
			//		state = RepairActivityClickingItems;
			//		[self clickNextItem];
			// }
			
			/// until then just wait for the timer to hope the window is open
			// if timeOut ready
			if ([timeOutClick ready]) {
				
				state = RepairActivityRepairing;
				[self repairStuff];
				count++;
				
				[timeOutClick start];
				
			} // end if
			
			return NO;
			break;
			
			
		case RepairActivityRepairing:
			
			
			if ([timeOutClick ready]) {
				state = RepairActivityDone;
				return YES;
			}
			return NO;
			break;
			
			
		default:
		case RepairActivityDone:
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
		case RepairActivityOpeningVendor:
			[text appendString:@"   opening vendor window."];
			break;
			
		case RepairActivityRepairing:
			[text appendString:@"  Repairing stuff "];
			break;
			
		default:
		case RepairActivityDone:
			[text appendString:@"  Done!"];
			break;
			
	}
	
	return text;
}

#pragma mark -
#pragma mark Internal


// perform an interaction with the vendor
- (void) clickVendor {
	[[[task patherController] botController] interactWithMouseoverGUID: [vendor GUID]];
}




- (void) repairStuff {
	
	[[[task patherController] macroController] useMacro:@"RepairAll"];
	
}



#pragma mark -

+ (id) repairWith:(Mob *)npc forTask:(MPTask *)aTask {
	
	return [[[MPActivityRepair alloc] initWithVendor:npc andTask:aTask] autorelease];
}


@end