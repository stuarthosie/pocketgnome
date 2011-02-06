//
//  MPActivityPickup.m
//  Pocket Gnome
//
//  Created by codingMonkey on 9/29/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MPActivityPickup.h"

#import "BlacklistController.h"
#import "BotController.h"
#import "Errors.h"
#import "LootController.h"
#import "MPMover.h"
#import "MPTask.h"
#import "MPTimer.h"
#import "Node.h"
#import "PatherController.h"
#import "PlayerDataController.h"


@interface MPActivityPickup (Internal)

- (void) clickNode;
//- (void) blackListNode: (Node *)aNode;
- (BOOL) isCasting;
- (BOOL) isLootWindowOpen;

@end


@implementation MPActivityPickup
@synthesize pickupNode, mover, timeOut; 
//movementController;

- (id)  initWithNode:(Node *) aNode andTask:(MPTask*)aTask  {
	
	if ((self = [super initWithName:@"Pickup" andTask:aTask])) {
		self.pickupNode = aNode;
		
		state = PickupActivityFinished;
		
		self.timeOut = [MPTimer timer:2150];

		attemptCount = 0;
		self.mover = [MPMover sharedMPMover];
	
	}
	return self;
}


- (void) dealloc
{
    [pickupNode release];
	[timeOut release];
	[mover release];

	
    [super dealloc];
}


#pragma mark -



// ok Start gets called 1x when activity is started up.
- (void) start {
	
	if (pickupNode == nil) {
		PGLog( @"[ActivityPickup] Error: ActivityPickup called with Node as NIL");
		state = PickupActivityFinished;
		return;
	}
	// if Node is in Distance
	float distanceToNode = [[task myPosition] distanceToPosition:[pickupNode position]];
	if (distanceToNode <= 5.0 ) {
		
		// if pickupNode isLootable  
		if ([pickupNode validToLoot]) {
			
			PGLog( @"[ActivityPickup] [start] clicking on Mob ... ");
			
			// face mob
			[mover faceLocation:(MPLocation *)[pickupNode position]];

			
			// mouse click on mob
//			[self clickNode];
			
			
			// timeOut start
			[timeOut start];
			
			attemptCount = 0;
			state = PickupActivityStarted;
			return;
			
		} else {
			
			PGLog (@"[ActivityPickup] Error: we are in proper distance, but Node is not lootable [%d]", [pickupNode validToLoot]);
			
		} // end if
		
	} else{
		
		PGLog( @"[ActivityPickup]  Error: too far away to attempt pickup!  [%@] -> needs to do a better job on approach.", [task name] );
		
	} // end if in distance
	
	// hmmmm ... if we get here then we shouldn't be looting
	state = PickupActivityFinished;
}



// work is called repeatedly every 100ms or so.
- (BOOL) work {
	
	
	int lastErrorID;
	
	// switch (state)
	switch (state) {
		case PickupActivityStarted:
			
			// harvesting nodes cause a casting
			
			// if !iscasting => problem
			if (![self isCasting]) {
PGLog(@"   --- ! casting --- ");
				if ([timeOut ready]) {
					if (++attemptCount >= 3) {
						// logError (loot attempts timed out)
						PGLog(@"[ActivityPickup] Error: initial loot attempt failed after 3 tries ... no loot window appeared.");
						
						// state = finished
						state = PickupActivityFinished;
					}
					[self clickNode];
					[timeOut start];
				}
				
			} // end if
			
			// if lootWindow visible => move to next phase
			if ([self isLootWindowOpen]) {
				
				// Yeah! Got some lewt!
				PGLog(@"[ActivityPickup] loot Window Visible!");
				
				// state = looting
				state = PickupActivityLooting;
				
				attemptCount = 0;
				
				[timeOut reset];
				
				
			} // end if
			
			return NO;
			break;
			
		case PickupActivityLooting:
			// at this point, loot window appeared and we told it to loot all.  Now we wait until the loot window closes before 
			// moving on.
			
			
			lastErrorID = [[[task patherController] botController] errorValue:[[[task patherController] playerData] lastErrorMessage]];
			if ( lastErrorID == ErrInventoryFull ){
				// logError : unable to loot (perhaps inventory full?)
				PGLog( @"[ActivityPickup] Error: Looks like we have an INVENTORY FULL WARNING. --> finished.");
				
				// state = finished
				state = PickupActivityFinished;
				
				attemptCount = 2; // no waiting
				
				// blacklist mob
	//			[self blackListMob:lootMob];
			}
			
			// if !lootWindow visible
			if (![self isLootWindowOpen] ) {
				
				PGLog( @"[ActivityPickup] lootWindow closed now ...");
				
				// verify loot ???
				// log successfulLoot

					
				state = PickupActivityFinished;
				//[timeOut reset];
				attemptCount = 1; // no waiting ...
					
				
			} // end if
			
			// if timeOut ready
			if ([timeOut ready]) {
				
				// if attemptCount ++ > 3
				if (++attemptCount >= 3) {
					
					// logError : unable to loot (perhaps inventory full?)
					PGLog( @"[ActivityPickup] Error: loot window still open after 3 tries ... some problem");
					
					// state = finished
					state = PickupActivityFinished;
					
					// blacklist mob
//					[self blackListMob:lootMob];
					
					[timeOut reset];
					attemptCount = 0;
					
					return NO;
					
				} // end if
				
				// lootController lootItems : perhaps autoLoot isn't enabled, try the LootController then ...
				[[[task patherController] lootController] acceptLoot];
				
				[timeOut reset];
				
			} // end if
			
			return NO;
			break;
			
			
		case PickupActivityFinished:
			
			
			[mover stopAllMovement];
			return YES;
			break;
			
			
		default:
			break;
	}
	
	// otherwise, we exit (but we are not "done"). 
	return NO;
}



// we are interrupted before we arrived.  Make sure we stop moving.
- (void) stop{
	
	attemptCount = 0;
	[mover stopAllMovement];
	
}

#pragma mark -


- (NSString *) description {
	NSMutableString *text = [NSMutableString string];
	
	[text appendFormat:@"Pickup\n node[%@]\n", [pickupNode name]];
	/*	if (unit != nil) {
	 
	 Position *playerPosition = [playerDataController position];
	 float currentDistance = [playerPosition distanceToPosition: [unit position]];
	 
	 [text appendFormat:@"  approaching [%@]  [%0.2f / %0.2f]", [unit name], currentDistance, distance];
	 
	 } else {
	 [text appendString:@"  no unit to approach"];
	 }
	 */
	return text;
}

#pragma mark -
#pragma mark Internal


// perform an interaction with the lootMob
- (void) clickNode {
PGLog(@"   --- Clicking Node --- ");
	BOOL wasGood = [[[task patherController] botController] interactWithMouseoverGUID: [pickupNode cachedGUID]];
	if (!wasGood) {
		PGLog(@"   !!! was unable to click node!!! " );
	}
}


/*
// send a blacklist command to the botController
- (void) blackListMob: (Mob *)aMob {
	[[[task patherController] blacklistController] blacklistObject:aMob];
	[[task patherController] lootBlacklistUnit:aMob];
}

*/

// are we casting (like skinning?)
- (BOOL) isCasting {
	return [[[task patherController] playerData] isCasting];
}

// is the LootWindow open?
- (BOOL) isLootWindowOpen {
	return [[[task patherController] lootController] isLootWindowOpen];
}

#pragma mark -

+ (id)  pickupNode:(Node *)aNode forTask:(MPTask *)aTask {
	
	return [[[MPActivityPickup alloc] initWithNode:aNode andTask:aTask] autorelease];
}


@end
