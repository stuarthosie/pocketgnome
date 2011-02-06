//
//  MPTaskLogout.m
//  Pocket Gnome
//
//  Created by Coding Monkey on 1/31/11.
//  Copyright 2011 Savory Software, LLC
//

#import "MPTaskLogout.h"

#import "MPActivityLogout.h"





@interface MPTaskLogout (Internal)

- (void) clearActivityLogout;
@end


@implementation MPTaskLogout

// Synthesize variables here:
@synthesize activityLogout;



- (id) initWithPather:(PatherController*)controller {
	if ((self = [super initWithPather:controller])) {
		name = @"Logout";
		
		self.activityLogout = nil;
		isDone = NO;
	}
	return self;
}

- (void) setup {
	
	
	[super setup];
}



- (void) dealloc
{
	[activityLogout release];
	
    [super dealloc];
}

#pragma mark -



- (BOOL) isFinished {
	return isDone;
}



- (MPLocation *) location {
	
	return (MPLocation *)[self myPosition];
}



- (void) restart {
	
}



- (BOOL) wantToDoSomething {
	
	return !isDone;
}



- (MPActivity *) activity {
	
	if (activityLogout == nil) {
		
		self.activityLogout = [MPActivityLogout logoutForTask:self];
	}
	return activityLogout;
	
}



- (BOOL) activityDone: (MPActivity*)activity {
	
	if (activity == activityLogout) {
		[self clearActivityLogout];
		isDone = YES;
	}
	return YES; // ??
}


#pragma mark -
#pragma mark Helper Functions


- (void) clearActivityLogout {
	
	if(activityLogout != nil) {
		[activityLogout stop];
		[activityLogout autorelease];
		self.activityLogout = nil;
	}
}


- (void) clearBestTask {
	
	
}



- (NSString *) description {
	NSMutableString *text = [NSMutableString string];
	
	[text appendFormat:@"%@", self.name];
	
	
	return text;
}






#pragma mark -

+ (id) initWithPather: (PatherController*)controller {
	return [[[MPTaskLogout alloc] initWithPather:controller] autorelease];
}

@end

