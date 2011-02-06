//
//  MPWhenTask.m
//  TaskParser
//
//  Created by Coding Monkey on 9/18/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MPTaskWhen.h"


@implementation MPTaskWhen

- (id) initWithPather:(PatherController*)controller {
	if ((self = [super initWithPather:controller])) {
		
		name = @"When";
		taskState = WhenTaskStateWaiting;
		doRepeat = NO;
	}
	return self;
}



- (void) setup {
		
	doRepeat = [self boolFromVariable:@"repeat" orReturnDefault:NO];
	
	[super setup];
}


#pragma	mark -





- (BOOL) isFinished {
	
	BOOL amI = (taskState == WhenTaskStateStopped);
	[self updateFinishedStatus:amI];
	return amI;
}



// restart my child and return to Waiting!
- (void) restart {
	taskState = WhenTaskStateWaiting;
	[child restart];
}



// I wantToDoSomething only if I'm RUNNING && my child wantsToDoSomething
- (BOOL) wantToDoSomething {
	
	if ((taskState == WhenTaskStateWaiting) && ((BOOL) [condition value])) {
		taskState = WhenTaskStateRunning;
	}
	
	if (taskState == WhenTaskStateRunning)  {
		if (![child wantToDoSomething]) {
		
			// if !repeat then
			if (!doRepeat) {
				
				taskState = WhenTaskStateStopped;
			} else {
				
				taskState = WhenTaskStateWaiting;
				[self restart];
			}
		}
	}
	BOOL doI = (taskState == WhenTaskStateRunning);
	[self updateWantSatus:doI];
	return doI;
}




#pragma mark -

+ (id) initWithPather: (PatherController*)controller {
	return [[[MPTaskWhen alloc] initWithPather:controller] autorelease];
}
@end
