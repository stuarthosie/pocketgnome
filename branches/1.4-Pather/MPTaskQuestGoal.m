//
//  MPTaskQuestGoal.m
//  Pocket Gnome
//
//  Created by Coding Monkey on 1/31/11.
//  Copyright 2011 Savory Software, LLC
//
#import "MPTaskQuestGoal.h"
#import "MPTask.h"
#import "MPTaskPar.h"
#import "MPToonData.h"
#import "PatherController.h"



@interface MPTaskQuestGoal (Internal)

- (NSString *) questKey;

@end


@implementation MPTaskQuestGoal
@synthesize questID;

- (id) initWithPather:(PatherController*)controller {
	if ((self = [super initWithPather:controller])) {
		
		name = @"QuestGoal";
		
		self.questID = nil;
		
		isDone = NO;
		
	}
	return self;
}



- (void) setup {
	
	self.questID = [self stringFromVariable:@"id" orReturnDefault:@"000"];
	
	[super setup];
}



- (void) dealloc
{
    [questID release];
	
    [super dealloc];
}


#pragma mark -




- (BOOL) isFinished {
	
	if (!isDone) {
		
		// check to see what our current Quest Status is:
		NSString *value = [[[self patherController] toonData] valueForKey:[self questKey]];
		if ([value isEqualToString:@"Completed"]) isDone = YES;
		if ([value isEqualToString:@"Done"]) isDone = YES;
			
		// if not done due to current quest status then check status of child tasks:
		if (!isDone) {
		
			isDone = [super isFinished];
			
			if (isDone) {
				
				// ok, update our Quest Status to completed
				[[[self patherController] toonData] setValue:@"Completed" forKey:[self questKey]];
				
			}
		}
	}
	return isDone;
}





#pragma mark -


- (NSString *) questKey {
	
	
	// You know... I should really have a [MPQuestPickup questKey: (NSString *) questID] method...
	return [NSString stringWithFormat:@"Quest%@", questID];
}



#pragma mark -

+ (id) initWithPather: (PatherController*)controller {
	return [[[MPTaskQuestGoal alloc] initWithPather:controller] autorelease];
}

@end
