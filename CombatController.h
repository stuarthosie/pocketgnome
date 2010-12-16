/*
 * Copyright (c) 2007-2010 Savory Software, LLC, http://pg.savorydeviate.com/
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 * $Id$
 *
 */

#import <Cocoa/Cocoa.h>

@class Controller;
@class ChatController;
@class MobController;
@class BotController;
@class MovementController;
@class PlayerDataController;
@class PlayersController;
@class BlacklistController;
@class AuraController;
@class MacroController;
@class BindingsController;

@class Position;
@class Unit;

#define UnitDiedNotification		@"UnitDiedNotification"
#define UnitTappedNotification		@"UnitTappedNotification"
#define UnitEnteredCombat			@"UnitEnteredCombat"

@interface CombatController : NSObject {
    IBOutlet Controller				*controller;
    IBOutlet PlayerDataController	*playerData;
	IBOutlet PlayersController		*playersController;
    IBOutlet BotController			*botController;
    IBOutlet MobController			*mobController;
    IBOutlet ChatController			*chatController;
    IBOutlet MovementController		*movementController;
	IBOutlet BlacklistController	*blacklistController;
	IBOutlet AuraController			*auraController;
	IBOutlet MacroController		*macroController;
	IBOutlet BindingsController		*bindingsController;
	
	// three different types of units to be tracked at all times
	Unit *_attackUnit;
	Unit *_friendUnit;
	Unit *_addUnit;
	Unit *_castingUnit;		// the unit we're casting on!  This will be one of the above 3!
	
	IBOutlet NSPanel *combatPanel;
	IBOutlet NSTableView *combatTable;
	
	BOOL _inCombat;
	BOOL _hasStepped;
	
	NSDate *_enteredCombat;
	
	NSMutableArray *_unitsAttackingMe;
	NSMutableArray *_unitsAllCombat;		// meant for the display table ONLY!
	NSMutableArray *_unitsDied;
	NSMutableArray *_unitsMonitoring;
	
	NSMutableDictionary *_unitLeftCombatCount;
	NSMutableDictionary *_unitLeftCombatTargetCount;
	
	//// Pather Additions:
	BOOL patherCCEnabled;
}

@property BOOL inCombat;
@property (readonly, retain) Unit *attackUnit;
@property (readonly, retain) Unit *castingUnit;
@property (readonly, retain) Unit *addUnit;
@property BOOL patherCCEnabled;
@property (readonly, retain) NSMutableArray *unitsAttackingMe;
@property (readonly, retain) NSMutableArray *unitsDied;
@property (readonly, retain) NSMutableArray *unitsMonitoring;

// weighted units we're in combat with
- (NSArray*)combatList;

// OUTPUT: PerformProcedureWithState - used to determine which unit to act on!
//	Also used for Proximity Count check
- (NSArray*)validUnitsWithFriendly:(BOOL)includeFriendly onlyHostilesInCombat:(BOOL)onlyHostilesInCombat;

// OUTPUT: return all adds
- (NSArray*)allAdds;

// OUTPUT: find a unit to attack, or heal
-(Unit*)findUnitWithFriendly:(BOOL)includeFriendly onlyHostilesInCombat:(BOOL)onlyHostilesInCombat;
-(Unit*)findUnitWithFriendlyToEngage:(BOOL)includeFriendly onlyHostilesInCombat:(BOOL)onlyHostilesInCombat;

// INPUT: from CombatProcedure within PerformProcedureWithState
- (void)stayWithUnit:(Unit*)unit withType:(int)type;

// INPUT: called when combat should be over
- (void)cancelCombatAction;
- (void)cancelAllCombat;

// INPUT: called when we start/stop the bot
- (void)resetAllCombat;
- (void)resetUnitsDied;

// INPUT: from PlayerDataController when a user enters combat
- (void)doCombatSearch;

- (NSArray*)friendlyUnits;
- (NSArray*)friendlyCorpses;

// OUPUT: could also be using [playerController isInCombat]
- (BOOL)combatEnabled;

// OUPUT: returns the weight of a unit
- (int)weight: (Unit*)unit;
- (int)weight: (Unit*)unit PlayerPosition:(Position*)playerPosition;

// OUTPUT: valid targets in range based on combat profile
- (NSArray*)enemiesWithinRange:(float)range;

// UI
- (void)showCombatPanel;
- (void)updateCombatTable;

- (NSString*)unitHealthBar: (Unit*)unit;

@end
