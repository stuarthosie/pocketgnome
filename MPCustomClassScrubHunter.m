//
//  MPCustomClassScrubHunter.m
//  Pocket Gnome
//
//  Created by Coding Monkey on 5/19/10.
//  Copyright 2010 Savory Software, LLC. All rights reserved.
//

#import "MPCustomClassScrubHunter.h"
#import "MPCustomClass.h"
#import "PatherController.h"
#import "Player.h"
#import "PlayerDataController.h"
#import "Mob.h"
#import "BlacklistController.h"
#import "MPLocation.h"
#import "MPSpell.h"
#import "MPItem.h"
#import "MPMover.h"
#import "Player.h"
#import "Unit.h"
#import "MPTimer.h"
#import "Errors.h"
#import "SpellController.h"

@implementation MPCustomClassScrubHunter
@synthesize arcaneShot, aspectHawk, aspectViper, autoShot, mark, mendPet, raptorStrike, serpentSting;
@synthesize drink;
@synthesize timerRunningAction, timerManaRecharge;
@synthesize moveToLocation, moveToFacing;

- (id) initWithController:(PatherController*)controller {
	if ((self = [super initWithController:controller])) {
		
		self.arcaneShot = nil;
		self.aspectHawk = nil;
		self.aspectViper = nil;
		self.autoShot = nil;
		self.mark = nil;
		self.mendPet = nil;
		self.raptorStrike = nil;
		self.serpentSting = nil;

		self.moveToLocation = nil;
		self.moveToFacing = nil;
		moveToHowClose = 1.0f;
		
		self.timerRunningAction = [MPTimer timer:1000];  // 1sec
		[timerRunningAction forceReady];
		
		self.timerManaRecharge = [MPTimer timer:12000]; // 12 sec (4 ticks minimum)
		[timerManaRecharge forceReady];
		
		self.drink = nil;
		
		manaRechargeMode = NO;
		
		
	}
	return self;
}



- (void) dealloc
{
	[arcaneShot release];
	[aspectHawk release];
	[aspectViper release];
	[autoShot release];
	[mark release];
	[mendPet release];
	[raptorStrike release];
	[serpentSting release];
	
	[moveToLocation release];
	[moveToFacing release];
	
	[drink release];
	
	[timerManaRecharge release];
	[timerRunningAction release];
	
    [super dealloc];
}

#pragma mark -



- (NSString *) name {
	return @"ScrUb Hunter";
}



- (void) preCombatWithMob: (Mob *) aMob atDistance:(float) distanceToMob {
	
	// preCombatWithMob:atDistance:  is called numerous times for 
	// your CC to determine what to do on approaching your target (at various distances)
/*	
	if (distanceToMob <= 35) {
		if ([listParty count] <1) {
			[self castHOT:pwShield on:(Unit *)[[PlayerDataController sharedController] player]];
		}
	}
 */
	
	state = CCCombatPreCombat;
}



- (void) openingMoveWith: (Mob *)mob {
	
	// open with Holy Fire
	shooting = NO;
	
	// or with Smite 
/*	if ([mob percentHealth] > 90) {
		if ([self cast:smite on:mob]){
			return;
		}
	}
*/
}



- (MPCombatState) combatActionsWith: (Mob *) mob {
	
	PlayerDataController *me = [PlayerDataController sharedController];
	
	// face target
	PGLog(@"     --> Facing Target");
	MPMover *mover = [MPMover sharedMPMover];
	MPLocation *targetLocation = (MPLocation *)[mob position];
	MPLocation *myLocation = (MPLocation *)[me position];
	[mover faceLocation:targetLocation];
	
	float distanceToMob = [myLocation distanceToPosition:targetLocation];
	
//	[mover moveTowards:targetLocation within:33.0f facing:targetLocation];
/*	
	if (moveToLocation != nil) {
	
		if ([mover shouldMoveTowards:moveToLocation within:moveToHowClose facing:moveToFacing]) {
			
			[mover moveTowards:moveToLocation within:moveToHowClose facing:moveToFacing];
			
		} else {
			self.moveToLocation = nil;
			self.moveToFacing = nil;
			moveToHowClose = 1.0f;
		}
			
	}
*/
	
	
	if (! [[SpellController sharedSpells] isGCDActive] ){
		//	if ([timerGCD ready]) {
		PGLog( @"   timerGGD ready");
		
		if( ![me isCasting] ) {
			PGLog( @"   me !casting");
			
			
			//// do my healing checks here:
			
			////
			//// Renew Checks
			////
/*			
			// Renew myself if health < 80%
			if ([me percentHealth] < 80) {
				if ([self castHOT:renew on:(Unit *)[me player]]) {
					return CombatStateInCombat;
				}
			}
*/			
			if ([[me player] hasPet]) {
				
				Unit *pet = [me pet];
				if (pet != nil) {
						
					if ([pet percentHealth] <= 50) {
						if ([self castHOT:mendPet on:pet]) {
							return CombatStateInCombat;
						}
					}
				}
			}
			
				
			////
			////  Attacks here
			////
			
			// if mob is in shooting Range
			if ((distanceToMob > 12.5f) && (distanceToMob <= 33.0f)) {
				
				PGLog(@" ---> Shooting Rules");
				
				if (![self hasAspect:aspectViper]) {
				
					// Serpent Sting DOT
					// if mobhealth >= 50% && myMana > 35%
					if (([mob percentHealth] >= 80) && ([me percentMana] > 30)){
						if ([self castMyDOT:serpentSting on:mob]) {
							return CombatStateInCombat;
						} 
					}
					

					
					// Arcane Shot
					if ([mob percentHealth] >= 20) {
						if ([self cast:arcaneShot on:mob]){
							return CombatStateInCombat;
						}
					}
					
					
					// switch to aspectViper near end of fight to recharge mana
					if ([mob percentHealth] <= 20) {
							
						if ([self cast:aspectViper on:mob]) { // can leave mob targeted
							return CombatStateInCombat;
						}
					}
					
				
				} else {
					
					if ([timerManaRecharge ready]) {
						if ([mob percentHealth] > 20) {
						
							if ([me percentMana] > 80) {
							
								if (![self hasAspect:aspectHawk]) {
									
									if ([self cast:aspectHawk on:mob]) {
										return CombatStateInCombat;
									}
								} 
							}
						}
					}
				}
				
				if (!autoShooting) {
					if ([self cast:autoShot on:mob]) {
						autoShooting = YES;
					}
				}
				
				if (errorLOS) {
					errorLOS = NO;
					return CombatStateBugged;
				}
			
			} else { 
			
				// if mob > shooting Range
				if (distanceToMob > 33.0f) {
				
					PGLog(@" ---> Moving into Range (too Far away)");
					
					// move to shooting range
					[mover moveTowards:targetLocation within:33.0f facing:targetLocation];
			
				} else {
					
					//// Mob has moved too close:
					PGLog(@" ---> Mob too close for shooting ... ");
					
					// if mob is !targeting me
					GUID mobTargetGUID = [mob targetID];
					if (mobTargetGUID != [me GUID]) {
			
						PGLog(@"    ---> Mob !targeting me so move back ");
						
					/*
						if (moveToLocation == nil) {
							
							// pick a randome direction
							int r = arc4random() % 3;
							float heading =0;
							switch( r) {
								case 0:
									// backwards
									heading = [me directionFacing] + M_PI;
									break;
								case 1:
									// back left	
									heading = [me directionFacing] - (0.75 * M_PI);
									break;
								case 2:
									// back right	
									heading = [me directionFacing] + (0.75 * M_PI);
									break;
								
							}
							
							
							
							
							// move back to shooting distance
							self.moveToLocation = [myLocation locationAtHeading:heading andDistance:(12.5f - distanceToMob)];
							self.moveToFacing = targetLocation;
							moveToHowClose = 1.0f;
							
						}
					*/
						MPLocation *newLocation = [MPLocation locationBehindTarget:(Mob *)[me player] atDistance:(12.5f - distanceToMob)];
						[mover moveTowards:newLocation within:1.0f facing:targetLocation];
						
						
						if ([self cast:arcaneShot on:mob]){
							return CombatStateInCombat;
						}
			
					} else {
						
						PGLog(@"    ---> Mob attacking me: Melee Combat");
						
						// if !aspectMonkey
							// cast aspectMonkey
							// return 
						// end if
						
						//// do melee combat rules
						[self cast:raptorStrike on:mob];
						
					} // end if
			
				} // end if
			} // end if
			
			
		}
		
	}
	
	return CombatStateInCombat;
}






- (BOOL) rest {
	
	PlayerDataController *player = [PlayerDataController sharedController];
	
	// if !inCombat
	if (![player isInCombat]) {
		
		// if health < healthTrigger  || mana < manaTrigger
		if ( ([player percentHealth] <= 99 ) || ([player percentMana] <= 99) ) {
			
			if ([player percentMana] <= 85) {
				
				if ([drink canUse]){
					if (![drink unitHasBuff:[player player]]) {
						PGLog(@"   Drinking ...");
						[drink use];
					}
				}
			}
			
			return NO; // must not be done yet ... 
			
		} // end if
	}
	return YES;
}




- (void) runningActionSpecial {
	
	PlayerDataController *me = [PlayerDataController sharedController];
	
	if ([timerRunningAction ready]) {
		
		
		
		// if mana < 80
		if ([me percentMana] < 80) {
			// aspectViper
			if (![self hasAspect:aspectViper]) {
				
				if ([self cast:aspectViper on:[me player]]) {
					[timerManaRecharge reset];
//					manaRechargeMode = YES;
					return;
				}
			}
		}
		
		
		
		[timerRunningAction reset];
	}
	
	
}




- (void) setup {
	
	[super setup];
	
	self.arcaneShot = [MPSpell arcaneShot];
	self.aspectHawk = [MPSpell aspectHawk];
	self.aspectViper = [MPSpell aspectViper];
	self.autoShot = [MPSpell autoShot];
	self.mark = [MPSpell huntersMark];
	self.mendPet = [MPSpell mendPet];
	self.raptorStrike = [MPSpell raptorStrike];
	self.serpentSting = [MPSpell serpentSting];
	
	
	NSMutableArray *spells = [NSMutableArray array];
	[spells addObject:arcaneShot];
	[spells addObject:aspectHawk];
	[spells addObject:aspectViper];
	[spells addObject:autoShot];
	[spells addObject:mark];
	[spells addObject:mendPet];
	[spells addObject:raptorStrike];
	[spells addObject:serpentSting];
	self.listSpells = [spells copy];

	

	self.drink = [MPItem drink];
}



#pragma mark -
#pragma mark Cast Helpers


- (BOOL) hasAspect: (MPSpell *)aspect {
	
	return [aspect unitHasBuff:[[PlayerDataController sharedController] player]];
}


#pragma mark -

+ (id) classWithController: (PatherController *) controller {
	
	return [[[MPCustomClassScrubHunter alloc] initWithController:controller] autorelease];
}
@end