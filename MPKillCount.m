//
//  MPKillCount.m
//  Pocket Gnome
//
//  Created by Coding Monkey on 1/19/11.
//  Copyright 2011 Savory Software, LLC
//
#import "MPKillCount.h"
#import "MPTimer.h"
#import "PatherController.h"
#import "InventoryController.h"


@implementation MPKillCount

- (id) initWithPather:(PatherController *)controller {
	if ((self = [super initWithPather:controller])) {
		requiresParameter = YES;
	}
	return self;
}



- (void) dealloc
{
	
    [super dealloc];
}




- (NSInteger) value {
	
	return [[PatherController sharedPatherController] killCount:parameter];
}


+ (MPKillCount *) initWithPather:(PatherController*)controller {
	
	return  [[[MPKillCount alloc] initWithPather:controller] autorelease];
}

@end
