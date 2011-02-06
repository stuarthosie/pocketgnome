//
//  MPTaskHearth.m
//  Pocket Gnome
//
//  Created by Coding Monkey on 1/31/11.
//  Copyright 2011 Savory Software, LLC
//

#import "MPTaskHearth.h"

#import "MPActivityHearth.h"





@interface MPTaskHearth (Internal)

	- (void) clearActivityHearth;
@end


@implementation MPTaskHearth

// Synthesize variables here:
@synthesize activityHearth;



- (id) initWithPather:(PatherController*)controller {
	if ((self = [super initWithPather:controller])) {
		name = @"Hearth";

		self.activityHearth = nil;
		isDone = NO;
	}
	return self;
}

- (void) setup {
	
	
	[super setup];
}



- (void) dealloc
{
	[activityHearth release];
	
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
	
	if (activityHearth == nil) {
		
		self.activityHearth = [MPActivityHearth hearthForTask:self];
	}
	return activityHearth;

}



- (BOOL) activityDone: (MPActivity*)activity {
	
	if (activity == activityHearth) {
		[self clearActivityHearth];
		isDone = YES;
	}
	return YES; // ??
}


#pragma mark -
#pragma mark Helper Functions


- (void) clearActivityHearth {
	
	if(activityHearth != nil) {
		[activityHearth stop];
		[activityHearth autorelease];
		self.activityHearth = nil;
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
	return [[[MPTaskHearth alloc] initWithPather:controller] autorelease];
}

@end

