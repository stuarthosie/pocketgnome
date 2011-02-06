//
//  MPTaskRunner.m
//  Pocket Gnome
//
//  Created by Coding Monkey on 12/28/10.
//  Copyright 2010 Savory Software, LLC
//

#import "MPTaskRunner.h"

#import "BlacklistController.h"
#import "BotController.h"
#import "CombatController.h"
#import "CombatProfile.h"
#import "Mob.h"
#import "MobController.h"
#import "MPActivityWait.h"
#import "MPActivityWalk.h"
#import "MPCustomClass.h"
#import "MPMover.h"
#import "MPNavigationController.h"
#import "MPTask.h"
#import "MPTimer.h"
#import "MPValue.h"
#import "PatherController.h"
#import "PlayerDataController.h"
#import	"Route.h"




@interface MPTaskRunner (Internal)


- (void) clearWalkActivity;

@end


@implementation MPTaskRunner

// Synthesize variables here:
@synthesize activityWalk, locations, currentLocation;



- (id) initWithPather:(PatherController*)controller {
	if ((self = [super initWithPather:controller])) {
		//name = @"MPTaskRunner";
		
		activityWalk = nil;
		useMount = NO;
		self.currentLocation = nil;

	}
	return self;
}

- (void) setup {
	
	self.locations = [self locationsFromVariable:@"locations"];
	useMount = [self boolFromVariable:@"usemount" orReturnDefault:NO];
	
	[super setup];
}



- (void) dealloc
{
	[locations release];
    [activityWalk release];
	[currentLocation release];
	
    [super dealloc];
}


#pragma mark -



- (BOOL) isFinished {
	return NO;
}



- (MPLocation *) location {
	
	if (currentLocation == nil) {
		currentLocation = [self bestLocation];
	}
	return currentLocation;
}



- (void) restart {
	
}



- (BOOL) wantToDoSomething {
		
//PGLog(@" +++ Runner[%@] countLocations[%d]", self.name, [locations count]);
	
	// if listLocations is empty, then no
	if ([locations count] < 1)  return NO;
	
	
	return YES;
}



- (MPActivity *) activity {
			
	if (currentLocation == nil)
		self.currentLocation = [self bestLocation];

	// if approachTask not created then
	if (activityWalk == nil) {
		// create walk activity
		self.activityWalk = [MPActivityWalk walkToLocation:currentLocation forTask:self useMount:useMount];
	}
	return activityWalk;
			
}



- (BOOL) activityDone: (MPActivity*)activity {
	
	// that activity is done so release it 
	if (activity == activityWalk) {
		self.currentLocation = nil;
		[self clearWalkActivity];
	}
	
	
	return YES; // ??
}


#pragma mark -
#pragma mark Helper Functions



- (void) clearBestTask {
	
//	self.selectedMob = nil;
	
}








- (NSString *) description {
	NSMutableString *text = [NSMutableString string];
	
	[text appendFormat:@"%@\n", self.name];
	
	if (currentLocation != nil) {
		
		[text appendFormat:@"   moving to [%0.2f, %0.2f, %0.2f]", [currentLocation xPosition], [currentLocation yPosition], [currentLocation zPosition]];
	}
	return text;
}


- (void) clearWalkActivity {
	[activityWalk stop];
	[activityWalk autorelease];
	self.activityWalk = nil;
}




#pragma mark -
#pragma mark Child Methods

- (MPLocation *) bestLocation {

	return nil;
}



#pragma mark -

+ (id) initWithPather: (PatherController*)controller {
	return [[[MPTaskRunner alloc] initWithPather:controller] autorelease];
}
 

@end
