//
//  MPActivityEquipItem.m
//  Pocket Gnome
//
//  Created by Coding Monkey on 1/10/11.
//  Copyright 2011 Savory Software, LLC
//
#import "MPActivityEquipItem.h"

#import "InventoryController.h"
#import "MacroController.h"
#import "MemoryAccess.h"
#import "MPActivitySell.h"
#import "MPTask.h"
#import "MPTimer.h"
#import "PatherController.h"




@interface MPActivityEquipItem (Internal)

- (BOOL) findItem;
- (void) pickupItem;
- (void) equipItem;


@end


@implementation MPActivityEquipItem
@synthesize timeOutClick, itemName; 


- (id) initWithName:(NSString *)iName  andTask:(MPTask *)aTask  {
	
	if ((self = [super initWithName:@"Equip Item" andTask:aTask])) {
		self.itemName	= iName;
		
		
		state = EquipActivityStarted;
		
		self.timeOutClick = [MPTimer timer:1000];
		
		bag = -1;
		slot = -1;
		
		attempt = 0;
		
	}
	return self;
}


- (void) dealloc
{
    [itemName release];
	[timeOutClick release];

	
    [super dealloc];
}


#pragma mark -



// ok Start gets called 1x when activity is started up.
- (void) start {
	
	if (itemName == nil) {
		PGLog( @"[ActivityEquipItem] Error: ActivityEquipItem called with itemName as NIL");
		state = EquipActivityDone;
		return;
	}
	
	
	// if item is found
	if ([self findItem]) {
		
		
		PGLog( @"[ActivityEquipItem] [start] Item Found ... ");
		

		
		// mouse click on mob
		[self pickupItem];
		
		
		state = EquipActivityPickupItem;
		
		
	} else{
		
		PGLog( @"[ActivityEquipItem]  Item[%@] not found ... waiting for retry.", itemName );
		attempt ++;
		
	} // end if in distance
	
	// timeOut start
	[timeOutClick start];
	
}



// work is called repeatedly every 100ms or so.
- (BOOL) work {
	//PGLog(@" ++++ sell->work() ");
	
	// switch (state)
	switch (state) {
		case EquipActivityStarted:
			
			if ([timeOutClick ready]) {
				
				// if item is found
				if ([self findItem]) {
					
					
					PGLog( @"[ActivityEquipItem] [start] Item Found ... ");
					
					
					
					// mouse click on mob
					[self pickupItem];
					
					
					state = EquipActivityPickupItem;
					
					
				} else{
					
					attempt ++;
					if (attempt > 5) {
						PGLog( @"[ActivityEquipItem]  Item[%@] not found ... too many attempts[%d] ... quitting", itemName, attempt );
						state = EquipActivityDone;
						return YES;
					}
					
					PGLog( @"[ActivityEquipItem]  Item[%@] not found ... waiting for retry. attempt[%d]", itemName, attempt );
					
				} // end if in distance
				
				// timeOut start
				[timeOutClick start];
				
			}
			return NO;
			break;
			
			
			
		case EquipActivityPickupItem:
			
			// give it a sec to register
			if ([timeOutClick ready]) {
				
				state = EquipActivityEquipItem;
				[self equipItem];
				[timeOutClick start];
				
			} // end if
			
			return NO;
			break;
			
			
		case EquipActivityEquipItem:
			// give the equip a sec to work
			if ([timeOutClick ready]) {
				state = EquipActivityDone;
				return YES;
			}
			return NO;
			break;
			
			
		default:
		case EquipActivityDone:
			return YES;
			break;
			
	}
	
	// otherwise, we exit (but we are not "done"). 
	return NO;
}



// we are interrupted before we arrived.  Make sure we stop moving.
- (void) stop{
	
	attempt = 0;
	
}

#pragma mark -


- (NSString *) description {
	NSMutableString *text = [NSMutableString string];
	
	[text appendFormat:@"%@\n", self.name];
	switch (state) {
		case EquipActivityStarted:
			[text appendFormat:@"   looking for item[%@].", itemName];
			break;
			
		case EquipActivityPickupItem:
			[text appendString:@"    picking up item from bag."];
			break;
			
		case EquipActivityEquipItem:
			[text appendString:@"    auto equipping item."];
			break;
			
		default:
		case EquipActivityDone:
			[text appendString:@"  Done!"];
			break;
			
	}
	
	return text;
}

#pragma mark -
#pragma mark Internal








- (void) pickupItem {
	
	NSString *macroCommand = [NSString stringWithFormat:@"/run PickupContainerItem(%d, %d);", bag, slot];
	PGLog(@"  +++++ pickupItem : name[%@] b[%d] s[%d] m[%@]",  itemName, bag, slot, macroCommand);
	[[[task patherController] macroController] useMacroOrSendCmd:macroCommand];
	
}


- (void) equipItem {
	
	NSString *macroCommand = [NSString stringWithString:@"/run AutoEquipCursorItem();"];
	PGLog(@"  +++++ equipItem : name[%@] b[%d] s[%d] m[%@]",  itemName, bag, slot, macroCommand);
	[[[task patherController] macroController] useMacroOrSendCmd:macroCommand];
	
}


- (BOOL) findItem {

	// for each Bag
	int k = 0;
	for (; k<5; k++) {
		
		// for each Slot
		int j = 0;
		for (; j<= 40; j++) {
			
			// get item at bag,slot
			Item *item = [MPActivitySell itemInBag:k atSlot:j];
			if (item) {
				
				// if names match
				if ([itemName isEqualToString:[item name]]) {
					
					bag = k;
					slot = j;
					
					return YES;
					
				}
			}
			
		}
		
	}
	
	return NO;
	
}



#pragma mark -

+ (id)  equipItem:(NSString *)iName forTask:(MPTask *)aTask {
	
	return [[[MPActivityEquipItem alloc] initWithName:(NSString *)iName  andTask:(MPTask *)aTask] autorelease];
}


@end