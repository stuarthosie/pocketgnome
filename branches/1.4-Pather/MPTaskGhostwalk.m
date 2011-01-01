//
//  MPTaskGhostwalk.m
//  Pocket Gnome
//
//  Created by Coding Monkey on 12/28/10.
//  Copyright 2010 Savory Software, LLC
//
#import "MPTaskGhostwalk.h"

#import "MPLocation.h"
#import "MPActivityWait.h"
#import "MPActivityWalk.h"
#import "MPNavigationController.h"
#import "PatherController.h"
#import "PlayerDataController.h"
#import "MacroController.h"

@interface MPTaskGhostwalk (Internal)

- (void) clearWaitActivity;
- (void) clearWalkToCorpse;
- (void) clearWalkToSafeLocation;

- (BOOL) isDead;
- (BOOL) isGhost;

- (MPLocation *) locationCorpse;
- (MPLocation *) locationSafeToRez;

- (void) rePop;
- (void) revive;


@end


@implementation MPTaskGhostwalk
@synthesize corpseLocation, safeLocation;
@synthesize activityWait;
@synthesize activityWalkToCorpse, activityWalkToSafeLocation;
@synthesize timerRetry;


- (id) initWithPather:(PatherController*)controller {
	if ((self = [super initWithPather:controller])) {
		name = @"Ghostwalk";
		
		state = GhostwalkStateWaiting;
		
		self.corpseLocation = nil;
		self.safeLocation = nil;
		
		self.activityWait = nil;
		self.activityWalkToCorpse = nil;
		self.activityWalkToSafeLocation = nil;
		
		timerRetry = [MPTimer timer:5000];
		
	}
	return self;
}



- (void) setup {
	
	// do anything?
	
	[super setup];
	
}




- (void) dealloc
{
	[corpseLocation release];
	[safeLocation release];
	[activityWait release];
	[activityWalkToCorpse release];
	[activityWalkToSafeLocation release];
	
	[timerRetry release];
	
    [super dealloc];
}


#pragma mark -



- (BOOL) isFinished {
	// never finished
	return NO;
}



- (MPLocation *) location {
	
	if (safeLocation != nil) return safeLocation;
	
	return corpseLocation;
}



- (void) restart {
	PGLog(@"   --- RESTART called ---");
	state = GhostwalkStateWaiting;
//	self.corpseLocation = nil;
//	self.safeLocation = nil;
	[timerRetry reset];
}



- (BOOL) wantToDoSomething {
//	PGLog( @"[Ghostwalk wtds]: ");
	
	float distance;
	
	// if !dead then 
	if (![self isDead]) {
		if (state != GhostwalkStateWaiting) {
			[self restart];
		}
		return NO;
	} 
	
	
	switch (state) {
		default:
		case GhostwalkStateWaiting:
			// this state is for waiting for transporting back to Graveyard
			
			// if !ghost
			if (![self isGhost]) {
				
				// if timerCommand ready
				if ([timerRetry ready]) {
					[self rePop];
					[timerRetry start];
				}

			}
			
			// if ghost == We are at graveyard
			if ([self isGhost]) {
				state = GhostwalkStateApproachingCorpse;
				self.corpseLocation = [self locationCorpse];
			}
			break;
			
			
		case GhostwalkStateApproachingCorpse:
			
			// if distance to corpseLocation < XX
			//distance = [self myDistanceToPosition2D:(Position *)[self locationCorpse]];
			distance = [self myDistanceToPosition2D:(Position *)corpseLocation];
			if (distance < 25) {
				// state = safeLocation
				state = GhostwalkStateMovingSafeSpot;
			}			
			
			break;
			
			
		case GhostwalkStateMovingSafeSpot:
			// once we are near the corpse, this state is for moving to a safe 
			// location around us.
			
			// if really close to rez location 
			//distance = [self myDistanceToPosition2D:(Position *)[self locationSafeToRez]];
			distance = [self myDistanceToPosition2D:(Position *)safeLocation];
			if (distance < 2) {
				state = GhostwalkStateRezzing;
				[self revive];
				[timerRetry start];
			}
			
			break;
			
			
		case GhostwalkStateRezzing:
			// now try to send the Resurrect command
			
			if ([self isGhost]) {
				if ([timerRetry ready]) {
					[self revive];
					[timerRetry start];
					
					
					// Question:  Should I put a counter here and abort if 
					//		too many tries?
				}
			}
			break;
	}
	
	
	return YES;
}



- (MPActivity *) activity {
//	PGLog(@"[Ghostwalk activity]");
	
	
	// switch state
	switch (state) {
		
		case GhostwalkStateWaiting:
		case GhostwalkStateRezzing:
		default:
			// if Activity->WalkToCorpse != nil
			if (activityWalkToCorpse != nil) {
				[self clearWalkToCorpse];
			}
			
			// if Activity->WalkToSafeLocation != nil
			if (activityWalkToSafeLocation != nil) {
				[self clearWalkToSafeLocation];
			}
			
			// if waitActivity == nil
			if (activityWait == nil ) {
				self.activityWait = [MPActivityWait waitIndefinatelyForTask:self];
			}
			return activityWait;
			break;
			
			
		case GhostwalkStateApproachingCorpse:
			
			// if activityWait != nil
//			if (activityWait != nil) {
//				[self clearWaitActivity];
//			}
			
			// if activityWalkToSafeLocation != nil
			if (activityWalkToSafeLocation != nil) {
				[self clearWalkToSafeLocation];
			}
			
			if (corpseLocation == nil) {
				self.corpseLocation = [self locationCorpse];
			}
			
			// if activityWalkToCorpse == nil
			if (activityWalkToCorpse == nil) {
				
				self.activityWalkToCorpse = [MPActivityWalk walkToLocation:corpseLocation forTask:self useMount:NO];
			}
			
			return activityWalkToCorpse;
			break;
			
			
		case GhostwalkStateMovingSafeSpot:
			// if activityWait != nil
//			if (activityWait != nil) {
//				[self clearWaitActivity];
//			}
			
			// if Activity->WalkToCorpse != nil
			if (activityWalkToCorpse != nil) {
				[self clearWalkToCorpse];
			}
			
			if (safeLocation == nil) {
				self.safeLocation = [self locationSafeToRez];
			}
			
			// if walk safe  == nil
			if (activityWalkToSafeLocation == nil) {
				self.activityWalkToSafeLocation = [MPActivityWalk walkToLocation:safeLocation forTask:self useMount:NO];
			}
			return activityWalkToSafeLocation;
			break;
	}
	
}



- (BOOL) activityDone: (MPActivity*)activity {
	PGLog(@"[Ghostwalk activityDone]");
	
	// that activity is done so release it 
	if (activity == activityWait) {
		[self clearWaitActivity];
	}
	
	if (activity == activityWalkToCorpse) {
		[self clearWalkToCorpse];
	}
	
	if (activity == activityWalkToSafeLocation) {
		[self clearWalkToSafeLocation];
	}
	
	return YES; // ??
}



- (NSString *) description {
	
	MPLocation *currLoc;
	
	NSMutableString *text = [NSMutableString stringWithString:@" Ghostwalk \n "];
	
	switch (state) {
		case GhostwalkStateWaiting:
			if ([self isDead]) {
				[text appendString:@"   not dead ...\n   waiting"];
			} else {
				[text appendString:@"  waiting for Repop\n"];
			}
			break;
			
		case GhostwalkStateApproachingCorpse:
			currLoc = [self locationCorpse];
			[text appendFormat:@"  approaching Corpse\n   loc[%0.2f, %0.2f, %0.2f]",[currLoc xPosition], [currLoc yPosition], [currLoc zPosition]];
			break;
			
		case GhostwalkStateMovingSafeSpot:
			currLoc = [self locationSafeToRez];
			[text appendFormat:@"  moving to safe spot\n  loc[%0.2f, %0.2f, %0.2f]",[currLoc xPosition], [currLoc yPosition], [currLoc zPosition]];
			break;
			
		case GhostwalkStateRezzing:
			[text appendString:@"  Rezzing ..."];
			break;
			
		default:
			[text appendString:@"  unknown state ... "];
			break;

	}
	return text;
}



		
		
#pragma mark -
#pragma mark Internal Helpers
	




- (void) clearWaitActivity {
	[activityWait stop];
	[activityWait autorelease];
	self.activityWait = nil;
}



- (void) clearWalkToCorpse {
	[activityWalkToCorpse stop];
	[activityWalkToCorpse autorelease];
	self.activityWalkToCorpse = nil;
}



- (void) clearWalkToSafeLocation {
	[activityWalkToSafeLocation stop];
	[activityWalkToSafeLocation autorelease];
	self.activityWalkToSafeLocation = nil;
}


		
- (BOOL) isDead {
	return [[patherController playerData] isDead];
}



- (BOOL) isGhost {
	return [[patherController playerData] isGhost];
}



- (MPLocation *) locationCorpse {
	return (MPLocation *) [[patherController playerData] corpsePosition];
}



- (MPLocation *) locationSafeToRez {
	
	// TO DO:
	// Figure out a location near the corpse that is safe to Rez, so we don't keep 
	// rezzing in the middle of the Gnoll Camp ... again!
	
	// idea: 
	//		40x40 array corresponding to locations around the corpse.
	//		ask navigationController if each location is traversible (mark !traversible ones)
	//		for each nearby mob,
	//			count mob square as 0
	//			expand ring and mark each square as (prev value +1)  < repeat until out of grid
	//				-- note: if a prev value was there, keep the MIN value.
	//		next mob
	//		pick hightest value square that is traversible and closest to current position.
	
	
	// but until then, just Kamikaze it! 
	return [self locationCorpse];
}



- (void) rePop {
	[[patherController macroController] useMacroOrSendCmd:@"ReleaseCorpse"];
	PGLog(@" ---- Ghostwalk : attempting RePop");
}



- (void) revive {
	[[patherController macroController] useMacroOrSendCmd:@"Resurrect"];
	PGLog(@" ---- Ghostwalk : attempting Revive");
}
		


#pragma mark -

+ (id) initWithPather: (PatherController*)controller {
	return [[[MPTaskGhostwalk alloc] initWithPather:controller] autorelease];
}

@end
