//
//  MPTaskLoot.m
//  Pocket Gnome
//
//  Created by codingMonkey on 9/29/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MPTaskLoot.h"
#import "MPTask.h"
#import "Mob.h"
#import "PatherController.h"
#import "PlayerDataController.h"
#import "MobController.h"
#import "BotController.h"
#import "MPActivityApproach.h"
#import "MPActivityLoot.h"
#import "MPActivityWait.h"
#import "MPMover.h"



@interface MPTaskLoot (Internal)

- (void) clearBackupActivity;
- (void) clearLootActivity;
- (void) clearApproachActivity;

- (Mob *) mobToLoot;

@end


@implementation MPTaskLoot
@synthesize distance, selectedMob, approachActivity, backupActivity, lootActivity;



- (id) initWithPather:(PatherController*)controller {
	if ((self = [super initWithPather:controller])) {
		name = @"Loot";
		
		skin = NO;
		distance = 30.0;
		
		self.selectedMob = nil;
		
		self.approachActivity = nil;
		self.backupActivity = nil;
		self.lootActivity = nil;
		
		state = LootStateWaiting;
	}
	return self;
}


- (void) setup {

	distance = [[self stringFromVariable:@"distance" orReturnDefault:@"30.0"] floatValue];
	skin = [self boolFromVariable:@"skin" orReturnDefault:NO];
}
	

- (void) dealloc
{
    [selectedMob autorelease];
	[approachActivity autorelease];
	[backupActivity release];
	[lootActivity autorelease];
	
    [super dealloc];
}

#pragma mark -

- (BOOL) isFinished {
	return NO;
}



- (MPLocation *) location {

	Mob *currentMob = [self mobToLoot];
	
	if ( currentMob == nil) 
		return nil;
	
	return (MPLocation *)[currentMob position];
}


- (void) restart {
	state = LootStateWaiting;
 }
 
 
 
 
- (BOOL) wantToDoSomething {
	
	// if we are currently INCOMBAT we don't want to do looting...
	if ([[patherController playerData] isInCombat]) return NO;
	
	
	Mob *lootMob = [self mobToLoot];
	
	if (lootMob == nil) state = LootStateWaiting;   // <-- sanity check
	float distanceToMob = 0;
	
	switch (state) {
		default:
		case LootStateWaiting:
			if (lootMob != nil) {
			
				float distanceToMob = [self myDistanceToMob:lootMob];
				if (distanceToMob > 4.5f) {
					
					state = LootStateApproaching;
					
				} else if(distanceToMob < 3.0f) {
					
					state = LootStateBackingUp;
				} else {
					
					state = LootStateLooting;
				}
				return YES;
			}
			break;
			
			
			
		case LootStateApproaching:
			
			distanceToMob = [self myDistanceToMob:lootMob];
			if (distanceToMob < 4.5f) {
				state = LootStateLooting;
			}
			return YES;
			break;
			
			
		case LootStateBackingUp:
			distanceToMob = [self myDistanceToMob:lootMob];
			if (distanceToMob > 3.0f) {
				state = LootStateLooting;
			}
			return YES;
			break;
			
			
		case LootStateLooting:
			
			// sanity Checks: 
			distanceToMob = [self myDistanceToMob:lootMob];
			if (distanceToMob > 4.5f) state = LootStateApproaching;
			if (distanceToMob < 3.0f) state = LootStateBackingUp;
			
			// let the ActivityDone method break us out to Waiting
			if (lootMob == nil) state = LootStateWaiting;
			return YES;
			break;

	}
	
	
	return NO;
	
/*	
	
	// if we have a current lootActivity then we want to do something.
//	if (lootActivity != nil) return YES;
	
	Mob *lootMob = [self mobToLoot];
//	float currentDistance;
	
	// if mob found
	if (lootMob != nil) {

		BOOL wantToApproach = [[MPMover sharedMPMover] shouldMoveTowards:(MPLocation *)[lootMob position] within:4.5f facing:(MPLocation *)[lootMob position]];
		if (wantToApproach) {
			
			state = LootStateApproaching;
		} else {
			
			state = LootStateLooting;
		}
		
	
//		currentDistance = [self myDistanceToMob:lootMob];
//		if (currentDistance > 4.90) {
//		
//			state = LootStateApproaching;
//			
//		} else {
//		
//			state = LootStateLooting;
//		}
		
	}
	else {
		PGLog( @"[TaskLoot] No lootMob Found!  wtds = false");	
	}
	
		
	// if we found a mob then we want to do something.
	return (lootMob != nil);
 
	*/
}



- (MPActivity *) activity {

	Mob *lootMob = [self mobToLoot];
		
	switch (state) {
	
		default:
			break;
			
			
		case LootStateApproaching:
		
			// if attackTask active then
			if (lootActivity != nil) {
			
				[self clearLootActivity];
				
			} 
			
			if (backupActivity != nil) {
				[self clearBackupActivity];
			}
			
			// if approachTask not created then
			if (approachActivity == nil) {
			
				// create approachTask
				self.approachActivity = [MPActivityApproach approachUnit:lootMob withinDistance:4.2f forTask:self];
				
			}
			return approachActivity;
			break;
			
		case LootStateBackingUp:
			
			// if attackTask active then
			if (lootActivity != nil) {
				
				[self clearLootActivity];
				
			} 
			
			// if approachActivity created then
			if (approachActivity != nil) {
				[self clearApproachActivity];
			}
			
			if (backupActivity == nil) {
			
				// Hack Alert!!!  
				// OK, I'm breaking the rules here and actually getting my task to do the work.
				// This should really become an Activity:  MPActivityBackup  or something.
				
				
				// return a wait activity to prevent us doing anything else:
				backupActivity = [MPActivityWait waitIndefinatelyForTask:self];
				
			}
			
			// tell the mover to move backwards facing our lootMob:
			MPLocation *newDest = [MPLocation locationBehindTarget:(Mob *)[[PlayerDataController sharedController] player] atDistance:4.5f];
			[[MPMover sharedMPMover] moveTowards: newDest within:1.5f facing:(MPLocation *)[lootMob position] ];
			
			return backupActivity;
			break;
			
			
		case LootStateLooting:
		
			// if approachActivity created then
			if (approachActivity != nil) {
				[self clearApproachActivity];
			}
			
			
			if (backupActivity != nil) {
				[self clearBackupActivity];
			}
			
			// if attackTask not created then
			if (lootActivity == nil) {
				// create lootTask for lootMob
				self.lootActivity = [MPActivityLoot lootMob:lootMob andSkin:skin forTask:self];
			}
			
			return lootActivity;
			break;

	}
	
	// we really shouldn't get here.
	// return 
	return nil;
}



- (BOOL) activityDone: (MPActivity*)activity {

	PGLog(@"[TaskLoot] activityDone");
	
	// that activity is done so release it 
	if (activity == approachActivity) {
		[self clearApproachActivity];
		state = LootStateLooting; // switch to looting ... 
	}
	
	if (activity == backupActivity) {
		[self clearBackupActivity];
	}
	
	if (activity == lootActivity) {
		[self clearLootActivity];
		// if looting done, then clear our loot mob
		self.selectedMob = nil;
	}
	
	return YES; // ??
}

#pragma mark -
#pragma mark Helper Functions

- (void) clearBestTask {
	
	self.selectedMob = nil;
	
}


- (void) clearBackupActivity {
	[backupActivity stop];
	[backupActivity autorelease];
	self.backupActivity = nil;
}



- (void) clearLootActivity {
	[lootActivity stop];
	[lootActivity autorelease];
	self.lootActivity = nil;
}

- (void) clearApproachActivity {
	[approachActivity stop];
	[approachActivity autorelease];
	self.approachActivity = nil;
}

- (Mob *) mobToLoot {

	if (self.selectedMob == nil) {
			
		NSArray *localMobs = [[patherController mobController] allMobs];
		
		float selectedDistance = INFINITY;
		float currentDistance = INFINITY;
		
		for ( Mob* mob in localMobs) {
			
			if (([mob isLootable]) || (skin && [mob isSkinnable])) {
				
				if (![patherController isLootBlacklisted:mob]) {
				
					currentDistance = [self myDistanceToMob:mob];
					if (currentDistance <= distance) {
						if ( currentDistance < selectedDistance ) {
							
							selectedDistance = currentDistance;
							self.selectedMob = mob;
						}
					}
				}
			}
		}
		
		// it seems like the MobController data is refreshed every few seconds. It is possible that a valid lootable
		// mob exists, but 
		// attempt to see if a lootable mob was recorded by BotController (and hasn't been updated in movController)
		// TO DO: switch this to a PatherController routine (initiated by Pull Task)
		if (selectedMob == nil) {
			self.selectedMob = [[patherController botController] mobToLoot];
		}
			
	}
	
	return selectedMob;  // the closest mob, or nil

}



- (NSString *) description {
	NSMutableString *text = [NSMutableString string];
	
	[text appendFormat:@"%@\n", self.name];
	if (selectedMob != nil) {
		
		[text appendFormat:@"  lootable mob found: %@",[selectedMob name]];
		
		switch (state){
				
			case LootStateWaiting:
				[text appendString:@"  waiting for loot mob"];
				break;
				
			case LootStateApproaching:
				[text appendFormat:@"  approaching: (%0.2f) / 5.0", [self myDistanceToMob:selectedMob]];
				break;
				
			case LootStateBackingUp:
				[text appendFormat:@"  backing up: (%0.2f) / 3.0", [self myDistanceToMob:selectedMob]];
				break;
				
			case LootStateLooting:
				[text appendFormat:@"  looting!\n  (%0.2f)", [self myDistanceToMob:selectedMob]];
				break;
		}
		
	} else {
		[text appendString:@"No mobs of interest"];
	}
	
	return text;
}



#pragma mark -

+ (id) initWithPather: (PatherController*)controller {
	return [[[MPTaskLoot alloc] initWithPather:controller] autorelease];
}

@end
