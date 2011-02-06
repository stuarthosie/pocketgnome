//
//  MPItemCount.m
//  Pocket Gnome
//
//  Created by Coding Monkey on 1/19/11.
//  Copyright 2011 Savory Software, LLC
//
#import "MPItemCount.h"
#import "MPTimer.h"
#import "PatherController.h"
#import "InventoryController.h"


@implementation MPItemCount
@synthesize cacheTimeOut;

- (id) initWithPather:(PatherController *)controller {
	if ((self = [super initWithPather:controller])) {
		requiresParameter = YES;
		
		cachedValue = 0;
		self.cacheTimeOut = [MPTimer timer:3000];  // do we really need to update this faster than 3 sec?
		[cacheTimeOut start];
	}
	return self;
}



- (void) dealloc
{
	[cacheTimeOut release];
	
    [super dealloc];
}




- (NSInteger) value {
	
	if ([cacheTimeOut ready]) {
	
		Item *refItem = [[InventoryController sharedInventory] itemForName:parameter];		
		cachedValue = [[InventoryController sharedInventory] collectiveCountForItemInBags:refItem]; 
PGLog(@"++++ ItemCount.value[%d] ++++", cachedValue);
		[cacheTimeOut start];
	}
	return cachedValue;
}


+ (MPItemCount *) initWithPather:(PatherController*)controller {
	
	return  [[[MPItemCount alloc] initWithPather:controller] autorelease];
}

@end
