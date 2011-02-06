//
//  MPActivityLogout.m
//  Pocket Gnome
//
//  Created by Coding Monkey on 1/10/11.
//  Copyright 2011 Savory Software, LLC
//
#import "MPActivityLogout.h"

#import "BotController.h"
#import "MacroController.h"
#import "MPTask.h"
#import "MPTimer.h"
#import "PatherController.h"
#import "MPTaskController.h"




@interface MPActivityLogout (Internal)

- (void) logout;

@end


@implementation MPActivityLogout
@synthesize timeOutClick; 


- (id) initWithTask:(MPTask *)aTask  {
	
	if ((self = [super initWithName:@"Logout" andTask:aTask])) {
		
		
		state = LogoutActivityWaiting;
		
		self.timeOutClick = [MPTimer timer:1000];
		
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
	
	[self logout];
	state = LogoutActivityQuitting;
	[timeOutClick start];
	
}



// work is called repeatedly every 100ms or so.
- (BOOL) work {
	
	// switch (state)
	switch (state) {
		case LogoutActivityWaiting:
			
			[self start];
			return NO;
			break;
			
			
			
		case LogoutActivityQuitting:
			
			
			// wait before trying again
			if ([timeOutClick ready]) {
				
				// That should do it!
				
				state = LogoutActivityDone;
				return YES;
				
			} // end if
			
			return NO;
			break;

			
		default:
		case LogoutActivityDone:
			return YES;
			break;
			
	}
	
	// otherwise, we exit (but we are not "done"). 
	return NO;
}



// we are interrupted before we finished.  
- (void) stop{
	

}

#pragma mark -


- (NSString *) description {
	NSMutableString *text = [NSMutableString string];
	
	[text appendFormat:@"%@\n", self.name];
	switch (state) {
		case LogoutActivityWaiting:
			[text appendFormat:@"    waiting."];
			break;
			
		case LogoutActivityQuitting:
			[text appendString:@"    Logging Out."];
			break;
			
			
		default:
		case LogoutActivityDone:
			[text appendString:@"    Done!"];
			break;
			
	}
	
	return text;
}

#pragma mark -
#pragma mark Internal



- (void) logout {
	
	// Tell Pather we want to stop
	[[[task patherController] taskController] setWantedRunningState:RunningStateStopped];
	
	// Tell Bot controller to Logout.
	[[[task patherController] botController] logOut];
}


#pragma mark -

+ (id)  logoutForTask:(MPTask *)aTask {
	
	return [[[MPActivityLogout alloc] initWithTask:(MPTask *)aTask] autorelease];
}


@end