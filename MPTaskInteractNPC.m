//
//  MPTaskInteractNPC.m
//  Pocket Gnome
//
//  Created by Coding Monkey on 1/7/11.
//  Copyright 2011 Savory Software, LLC
//
#import "MPTaskInteractNPC.h"

#import "MobController.h"

#import "MPActivityWalk.h"
#import "MPLocation.h"
#import "MPTask.h"



@interface MPTaskInteractNPC (Internal)

- (void) clearActivityApproach;

- (BOOL) readyToStart;
- (MPActivity *) activityInteract;
- (void) clearInteractActivity;
- (BOOL) finishedInteractActivity:(MPActivity *)activity;

- (NSString *) textWaitingDescription;
- (NSString *) textInteractionDescription;

@end


@implementation MPTaskInteractNPC

// Synthesize variables here:
@synthesize npcName, npcLocation, selectedNPC;
@synthesize activityApproach;



- (id) initWithPather:(PatherController*)controller {
	if ((self = [super initWithPather:controller])) {
		name = @"InteractNPC";
		
		self.npcName = nil;
		self.npcLocation = nil;
		
		self.activityApproach = nil;

		self.selectedNPC = nil;
				
//		isDone = NO;
		shouldStayClose = YES;
		
		state = InteractNPCTaskWaiting;
		
	}
	return self;
}



- (void) setup {
	
	self.npcName = [self stringFromVariable:@"npc" orReturnDefault:@"noname"] ;
	self.npcLocation = [self locationFromVariable:@"location"]; 

}



- (void) dealloc
{
	[npcName release];
	[npcLocation release];
    [activityApproach release];
	
    [super dealloc];
}

#pragma mark -



- (BOOL) isFinished {
	
	// NOTE:  It is the child task that determines if we are finished, not this one.
	return YES;
}



- (MPLocation *) location {
	
	// TODO: if location not given, we need to do a DB lookup on the npcName and get their location.
	return npcLocation;
}



- (void) restart {
//	isDone = NO;
	state = InteractNPCTaskWaiting;
}



- (BOOL) wantToDoSomething {
	
	switch (state) {
		default:
		case InteractNPCTaskWaiting:
			//// Waiting until we want to go sell something.
			
			
			// if we are ready to start.
			if ([self readyToStart]) {
				
				state = InteractNPCTaskApproachingLocation;
				return YES;  
			
			} 
			return NO;
			break;
			
			
			
		case InteractNPCTaskApproachingLocation:
			//// Approaching our NPC to sell stuff to
			
			
			// if distance to location < 5
			if ([npcLocation distanceToPosition:[self myPosition]] < 3.5f ) {
				
				// make sure we approach the NPC properly
				Mob *npc = [self npc];
				if ([[self myPosition] distanceToPosition: [npc position]] < 3.5f) {
					
					// we are close enough so interact:
					
					// state = selling
					state = InteractNPCTaskSelling;
				} else {
					
					// else update locatin to be the npc's current location.
					self.npcLocation = (MPLocation *)[npc position];
					[self clearActivityApproach]; // <-- make sure activityApproach is cleared out so it gets the updated location
				}
				
			}// end if
			return YES;
			break;
			
			
			
		case InteractNPCTaskSelling:
			//// selling stuff to NPC
			//// NOTE:  let [activityDone]  reset our state to Waiting
			
			//// sanity check here:
			// if we are too far away, approch location
			if ((shouldStayClose) && ([npcLocation distanceToPosition:[self myPosition]] > 5.0f)) {
				// state = selling
				state = InteractNPCTaskApproachingLocation;
			}// end if
			return YES;
			break;
			
			
	}
	
	// shouldn't get here, but if I do: return NO.
	return NO;
	
	
}



- (MPActivity *) activity {
	
	switch (state) {
			
		case InteractNPCTaskWaiting:
			//// ok, really shouldn't get here on Waiting.
			
			break;
			
			
		default:
		case InteractNPCTaskApproachingLocation:

			[self clearInteractActivity];
			
			if (activityApproach == nil) {
				// Question: Did the old Pather have useMount set on InteractNPC task?
				self.activityApproach = [MPActivityWalk walkToLocation:npcLocation forTask:self useMount:NO];
			}
			return activityApproach;
			break;
			
			
		case InteractNPCTaskSelling:
			
			// if attackTask active then
			if (activityApproach != nil) {
				
				[self clearActivityApproach];
				
			} 
			
			return [self activityInteract];
			break;
			
	}
	
	// we really shouldn't get here.
	// return 
	return nil;
}



- (BOOL) activityDone: (MPActivity*)activity {
	
	// that activity is done so release it 
	if (activity == activityApproach) {
		[self clearActivityApproach];
	}
	
	if ([self finishedInteractActivity:activity]) {
//		isDone = YES;
		state = InteractNPCTaskWaiting;
	}
	return YES; // ??
}


#pragma mark -
#pragma mark Helper Functions



- (void) clearBestTask {
	
	//self.selectedMob = nil;
	
}



- (Mob *) npc {
	
	if (self.selectedNPC == nil) {
		
		self.selectedNPC = [[MobController sharedController] closestMobWithName:npcName];
		
		PGLog(@" ++++ returned name[%@], selectedNPC[%@]", npcName, selectedNPC);
		
		if (selectedNPC == nil) {
			
			NSArray *listMobs = [[MobController sharedController] allMobs];
			NSString *likeName = [NSString stringWithFormat:@"*%@*", npcName];
			for( Mob *mob in listMobs) {
				PGLog(@"  +++++ mobName[%@]  vs  npcName[%@]", [mob name], likeName);
				if ([[mob name] isCaseInsensitiveLike:likeName]) {
					PGLog(@"  +++++  Found it! ");
					self.selectedNPC = mob;
					break;
				}
			}
			
		}
		
	} // end if selectedMob == nil
	
	return selectedNPC;  
	
}








- (NSString *) description {
	NSMutableString *text = [NSMutableString string];
	
	[text appendFormat:@"%@\n", self.name];
	
	
	switch (state){
		case InteractNPCTaskWaiting:
			[text appendString:[self textWaitingDescription]];
			break;
			
		case InteractNPCTaskApproachingLocation:
			[text appendFormat:@"  Approaching InteractNPC [%@]\n   loc[%0.2f, %0.2f, %0.2f]", npcName, [npcLocation xPosition], [npcLocation yPosition], [npcLocation zPosition]];
			break;
			
		case InteractNPCTaskSelling:
			[text appendFormat:[self textInteractionDescription]];
			break;
			
	}
	
	
	return text;
}




- (void) clearActivityApproach {
	[activityApproach stop];
	[activityApproach autorelease];
	self.activityApproach = nil;
}




#pragma mark -
#pragma mark Child Methods


- (BOOL) readyToStart {
	
	// NOTE: this should be overwritten by our children classes to determine start conditions.
	return NO;
}



- (MPActivity *) activityInteract {
	
	// NOTE: this is for our child classes to return the activity they need to perform
	return nil;
	
}



- (void) clearInteractActivity {
	
	// NOTE: this method is for child classes to clear out their interaction activities while
	// we approach our target.
}


- (BOOL) finishedInteractActivity:(MPActivity *)activity {
	// NOTE: this method is also intended to be overwritten by our children classes to close off
	// their current activity
	return NO;
}



- (NSString *) textWaitingDescription {
	
	return @" waiting description ";
}


- (NSString *) textInteractionDescription {
	
	return @" interaction description ";
}


#pragma mark -

+ (id) initWithPather: (PatherController*)controller {
	return [[[MPTaskInteractNPC alloc] initWithPather:controller] autorelease];
}

@end
