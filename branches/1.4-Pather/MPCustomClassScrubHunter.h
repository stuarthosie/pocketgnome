//
//  MPCustomClassScrubPriest.h
//  Pocket Gnome
//
//  Created by codingMonkey on 4/26/10.
//  Copyright 2010 Savory Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MPCustomClassScrub.h"

@class MPSpell;
@class MPItem;
@class MPTimer;
@class MPLocation;

@interface MPCustomClassScrubHunter : MPCustomClassScrub {
	
	MPSpell *arcaneShot, *aspectHawk, *aspectViper, *autoShot, *mark, *mendPet, *raptorStrike, *serpentSting;
	MPItem *drink;
	BOOL shooting, manaRechargeMode;
	
	float moveToHowClose;
	MPLocation *moveToLocation, *moveToFacing;
	
	MPTimer *timerRunningAction, *timerManaRecharge;
	
}
@property (retain) MPSpell *arcaneShot, *aspectHawk, *aspectViper, *autoShot, *mark, *mendPet, *raptorStrike, *serpentSting;
@property (retain) MPItem *drink;
@property (retain) MPTimer *timerRunningAction, *timerManaRecharge;
@property (retain) MPLocation *moveToLocation, *moveToFacing;

- (void) openingMoveWith: (Mob *)mob;
- (MPCombatState) combatActionsWith: (Mob *) mob;

- (BOOL) hasAspect: (MPSpell *)aspect;

@end
