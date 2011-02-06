//
//  MPFreeBagSlotsValue.m
//  Pocket Gnome
//
//  Created by Coding Monkey on 1/11/11.
//  Copyright 2011 Savory Software, LLC
//
#import "MPFreeBagSlotsValue.h"
#import "PatherController.h"
#import "InventoryController.h"

@implementation MPFreeBagSlotsValue


- (NSInteger) value {
	
	return [[InventoryController sharedInventory] bagSpacesAvailable]; 
}



+ (MPFreeBagSlotsValue *) initWithPather:(PatherController*)controller {
	
	return  [[[MPFreeBagSlotsValue alloc] initWithPather:controller] autorelease];
}
@end
