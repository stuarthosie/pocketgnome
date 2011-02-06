//
//  MPActivityTaxi.m
//  Pocket Gnome
//
//  Created by Coding Monkey on 1/10/11.
//  Copyright 2011 Savory Software, LLC
//
#import "MPActivityTaxi.h"
#import "BotController.h"
#import "MacroController.h"
#import "Mob.h"
#import "MPLocation.h"
#import "MPMover.h"
#import "MPNavigationController.h"
#import "MPTask.h"
#import "MPTimer.h"
#import "PatherController.h"
#import "Position.h"



@interface MPActivityTaxi (Internal)

- (void) clickDriver;
- (void) clickDestination;

- (BOOL) haventMoved;
- (BOOL) isFlying;

@end


@implementation MPActivityTaxi
@synthesize driver, destination, timeOutClick, mover, lastLocation, initialLocation; 


- (id)  initWithDriver:(Mob *)npc andDestination:(NSString *)destName andTask:(MPTask *)aTask  {
	
	if ((self = [super initWithName:@"Taxi" andTask:aTask])) {
		
		self.driver	= npc;
		self.destination = destName;
		
		self.timeOutClick = [MPTimer timer:1000];
		self.mover = [MPMover sharedMPMover];
		self.initialLocation = nil;
		self.lastLocation = nil;
		
		state = TaxiActivityStarted;
		count = 0;
		didFlushGraph = NO;
	}
	return self;
}


- (void) dealloc
{
    [driver release];
	[destination release];
	[timeOutClick release];
	[mover release];
	[lastLocation release];
	[initialLocation release];
	
    [super dealloc];
}


#pragma mark -



// ok Start gets called 1x when activity is started up.
- (void) start {
	
	if (driver == nil) {
		PGLog( @"[ActivityTaxi] Error: ActivityTaxi called with driver as NIL");
		return;
	}
	
	
	// if driver is in Distance
	float distanceToDriver = [task myDistanceToMob:driver];
	if (distanceToDriver <= 5.0 ) {
		
		
		PGLog( @"[ActivityTaxi] [start] clicking on Driver ... ");
		
		// face driver
		[mover faceLocation:(MPLocation *)[driver position]];
		
		// mouse click on mob
		[self clickDriver];
		
		
		// timeOut start
		[timeOutClick start];
		
		
		self.initialLocation = (MPLocation *)[task myPosition];
		self.lastLocation = (MPLocation *)[task myPosition];
		
		state = TaxiActivityOpeningMap;
		
		return;
		
	} else{
		
		PGLog( @"[ActivityTaxi]  Error: too far away to attempt Taxi!  MPTaskTaxi -> needs to do a better job on approach." );
		
	} // end if in distance
	
	// hmmmm ... if we get here then we shouldn't be training
	state = TaxiActivityDone;
}



// work is called repeatedly every 100ms or so.
- (BOOL) work {
	
	// switch (state)
	switch (state) {
		case TaxiActivityStarted:
			
			//// How did we get here???
			
			// face driver
			[mover faceLocation:(MPLocation *)[driver position]];
			
			// mouse click on mob
			[self clickDriver];
			
			
			// timeOut start
			[timeOutClick start];
			
			
			self.initialLocation = (MPLocation *) [task myPosition];
			self.lastLocation = (MPLocation *)[task myPosition];
			
			state = TaxiActivityOpeningMap;
			return NO;
			break;
			
			
			
		case TaxiActivityOpeningMap:
			
			
			/// wait for the timer to hope the window is open
			// if timeOut ready
			if ([timeOutClick ready]) {
				
				state = TaxiActivityFlying;
				[self clickDestination];
				[timeOutClick start];
				
			} // end if
			
			return NO;
			break;
			
			
		case TaxiActivityFlying:
			
			
			if ([timeOutClick ready]) {
				
				if ([self haventMoved]) {
					
					if (count > 3) {
						// bail: maybe we have a bad destination name
						state = TaxiActivityDone;
						return YES;
					} else {
						// clickDestination again (just to make sure)
						[self clickDestination];
						count++;
					}
				}
				
				// if !stillFlying 
				if (![self isFlying]) {
PGLog(@"++++++ Reload Graph around curent pos [%@]! ++++++++", [task myPosition]);
					// if we have arrived, then have the navController reset it's graph
					[[[task patherController] navigationController] loadInitialGraphChunkAroundLocation:(MPLocation *)[task myPosition]];
					state = TaxiActivityDone;
					return YES;
				}
				
				
				// while we are waiting during fligh, have navController remove it's current graph
				if (!didFlushGraph) {
					[[[task patherController] navigationController] flushGraph];
					didFlushGraph = YES;
				}
				
				[timeOutClick start];
			}
			return NO;
			break;
			
			
		default:
		case TaxiActivityDone:
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
		case TaxiActivityStarted:
			[text appendString:@"   starting ..."];
			break;
			
		case TaxiActivityOpeningMap:
			[text appendString:@"   opening flight map."];
			break;
			
		case TaxiActivityFlying:
			[text appendString:@"  flying ... "];
			break;

			
		default:
		case TaxiActivityDone:
			[text appendString:@"  Done!"];
			break;
			
	}
	
	return text;
}

#pragma mark -
#pragma mark Internal


// perform an interaction with the driver
- (void) clickDriver {
	[[[task patherController] botController] interactWithMouseoverGUID: [driver GUID]];
}




- (void) clickDestination {
	
	
	// Should really clean this command up and see if I can put it in a loop ... 
	NSString *macroCommand = [NSString stringWithFormat:@"/run local num = NumTaxiNodes(); local name;  for sl=1,num do  n=TaxiNodeName(sl); if (string.find(n, \"%@\")) then TakeTaxiNode(sl); end; end;", destination];
	
PGLog(@"  +++++ sending Macro [%@] +++++ ", macroCommand);
	
	[[[task patherController] macroController] useMacroOrSendCmd:macroCommand];
	
}


- (BOOL) haventMoved {
	
	return ([initialLocation distanceToPosition:[task myPosition]] <= 1.0f);
}


- (BOOL) isFlying {
	
	if ([lastLocation distanceToPosition:[task myPosition]] <= 1.0f) {
		// little change from 1sec ago so assume we have stopped flying!
		return NO;
	} else {
		self.lastLocation = (MPLocation *)[task myPosition];
		return YES;
	}
}



#pragma mark -

+ (id) taxiWith:(Mob *)npc to:(NSString *)destName forTask:(MPTask *)aTask {
	
	return [[[MPActivityTaxi alloc] initWithDriver:npc andDestination:destName andTask:aTask] autorelease];
}


@end