//
//  MPTaskSetState.m
//  Pocket Gnome
//
//  Created by Coding Monkey on 1/23/11.
//  Copyright 2011 Savory Software, LLC
//
#import "MPTaskSetState.h"
#import "MPTask.h"
#import "PatherController.h"

@implementation MPTaskSetState
@synthesize key, value;


- (id) initWithPather:(PatherController*)controller {
	if ((self = [super initWithPather:controller])) {
		name = @"SetState";
		
		self.key = nil;
		self.value = nil;
		
		isDone = NO;
		
	}
	return self;
}



- (void) setup {
	
	self.key = [self stringFromVariable:@"key" orReturnDefault:@"nokey"];
	self.value = [self stringFromVariable:@"value" orReturnDefault:@"novalue"];
	
	[super setup];
}



- (void) dealloc
{
    [key release];
    [value release];
	
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
	isDone = NO;
}



- (BOOL) wantToDoSomething {
		
	return !isDone;
}



- (MPActivity *) activity {
	
	// OK normal tasks return activities to do here, 
	// but this task just set's a value to the ToonData object.  
	[[patherController toonData] setValue:value forKey:key];
	
	isDone = YES;
	
	// The pather task controller routine can handle a nil activity so:
	return nil;
}



- (BOOL) activityDone: (MPActivity*)activity {
	
	return YES;
}






- (NSString *) description {
	NSMutableString *text = [NSMutableString stringWithFormat:@"%@\n", self.name];
	
	[text appendFormat:@" [%@] = [%@]\n",key, value];
	
	return text;
}




#pragma mark -

+ (id) initWithPather: (PatherController*)controller {
	return [[[MPTaskSetState alloc] initWithPather:controller] autorelease];
}

@end
