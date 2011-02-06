//
//  MPSkillLevel.m
//  Pocket Gnome
//
//  Created by Coding Monkey on 2/06/11.
//  Copyright 2011 Savory Software, LLC
//
#import "MPSkillLevel.h"
#import "PatherController.h"
#import "PlayerDataController.h"


@implementation MPSkillLevel

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
	
	int skillValue = 0;

	if ([parameter isEqualToString:@"Herbalism"]) {
		skillValue = [[PlayerDataController sharedController] getHerbalismLevel];
	}
	if ([parameter isEqualToString:@"Mining"]) {
		skillValue = [[PlayerDataController sharedController] getMiningLevel];
	}
	if ([parameter isEqualToString:@"Skinning"]) {
		skillValue = [[PlayerDataController sharedController] getSkinningLevel];
	}
	return skillValue;
}


+ (MPSkillLevel *) initWithPather:(PatherController*)controller {
	
	return  [[[MPSkillLevel alloc] initWithPather:controller] autorelease];
}

@end
