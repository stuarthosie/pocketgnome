//
//  MPActivityHearth.m
//  Pocket Gnome
//
//  Created by Coding Monkey on 1/10/11.
//  Copyright 2011 Savory Software, LLC
//
#import "MPActivityHearth.h"

#import "BotController.h"
#import "MacroController.h"
#import "MPActivitySell.h"
#import "MPTask.h"
#import "MPTimer.h"
#import "PatherController.h"


// Taken from BotController ... 
#define HearthstoneItemID		6948



@interface MPActivityHearth (Internal)

- (void) clickHearthstone;
- (BOOL) haveStone;
- (BOOL) isCasting;

@end


@implementation MPActivityHearth
@synthesize timeOutClick; 


- (id) initWithTask:(MPTask *)aTask  {
	
	if ((self = [super initWithName:@"Hearth" andTask:aTask])) {

		
		state = HearthActivityWaiting;
		
		self.timeOutClick = [MPTimer timer:1000];

		attempt = 0;
		
	}
	return self;
}


- (void) dealloc
{
	[timeOutClick release];
	
	
    [super dealloc];
}


#pragma mark -



// ok Start gets called 1x when activity is started up.
- (void) start {
		
	
	// if we have a hearthstone equipped
	if ([self haveStone]) {
		
		
		PGLog( @"[ActivityHearth] [start] Item Found ... ");
		
		
		[self clickHearthstone];
		
		state = HearthActivityClicking;
		
		[timeOutClick start];
		
		attempt ++;
		
		
	} else{
		
		PGLog( @"[ActivityHearth] Hearthstone not found ... done." );
		state = HearthActivityDone;
		
	} // end if in distance
	
	
	
}



// work is called repeatedly every 100ms or so.
- (BOOL) work {
	
	// switch (state)
	switch (state) {
		case HearthActivityWaiting:
			
			[self start];
			return NO;
			break;
			
			
			
		case HearthActivityClicking:
			
			if ([self isCasting]) {
			
				state = HearthActivityHearthing;
				return NO;
			}
			
			// wait before trying again
			if ([timeOutClick ready]) {
				
				if (attempt > 5) {
				
					PGLog(@" +++++ Still not hearthing after 5 attempts.  -> Done. ");
					state = HearthActivityDone;
					return YES;
				}
				
				[self clickHearthstone];
				attempt++;
				[timeOutClick start];
				
			} // end if
			
			return NO;
			break;
			
			
		case HearthActivityHearthing:
			// wait until we finish casting ...
			if (![self isCasting]) {
				state = HearthActivityDone;
				return YES;
			}
			return NO;
			break;
			
			
		default:
		case HearthActivityDone:
			return YES;
			break;
			
	}
	
	// otherwise, we exit (but we are not "done"). 
	return NO;
}



// we are interrupted before we finished.  
- (void) stop{
	
	attempt = 0;
	
}

#pragma mark -


- (NSString *) description {
	NSMutableString *text = [NSMutableString string];
	
	[text appendFormat:@"%@\n", self.name];
	switch (state) {
		case HearthActivityWaiting:
			[text appendFormat:@"    waiting."];
			break;
			
		case HearthActivityClicking:
			[text appendString:@"    clicking Hearthstone."];
			break;
			
		case HearthActivityHearthing:
			[text appendString:@"    casting ..."];
			break;
			
		default:
		case HearthActivityDone:
			[text appendString:@"    Done!"];
			break;
			
	}
	
	return text;
}

#pragma mark -
#pragma mark Internal








- (void) clickHearthstone {
	
	UInt32 actionID = (USE_ITEM_MASK + HearthstoneItemID);
	[[[task patherController] botController] performAction:actionID];
}


// are we casting (like skinning?)
- (BOOL) isCasting {
	return [[[task patherController] playerData] isCasting];
}


- (BOOL) haveStone {
	
	// for each Bag
	int k = 0;
	for (; k<5; k++) {
		
		// for each Slot
		int j = 0;
		for (; j<= 40; j++) {
			
			// get item at bag,slot
			Item *item = [MPActivitySell itemInBag:k atSlot:j];
			if (item) {
				
				// if names match
				if ([[item name] isEqualToString:@"Hearthstone"]) {

					return YES;
					
				}
			}
			
		}
		
	}
	
	return NO;
	
}



#pragma mark -

+ (id)  hearthForTask:(MPTask *)aTask {
	
	return [[[MPActivityHearth alloc] initWithTask:(MPTask *)aTask] autorelease];
}


@end