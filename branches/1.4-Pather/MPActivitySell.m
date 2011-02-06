//
//  MPActivitySell.m
//  Pocket Gnome
//
//  Created by Coding Monkey on 1/10/11.
//  Copyright 2011 Savory Software, LLC
//
#import "MPActivitySell.h"



#import "MPActivityLoot.h"
#import "BotController.h"
#import "BlacklistController.h"
#import "Controller.h"
#import "Errors.h"
#import "InventoryController.h"
#import "Item.h"
#import "LootController.h"
#import "MacroController.h"
#import "MemoryAccess.h"
#import "Mob.h"
#import "MPMover.h"
#import "MPTask.h"
#import "MPTimer.h"
#import "Objects_Enum.h"
#import "OffsetController.h"
#import "PatherController.h"
#import "PlayerDataController.h"
#import "WoWObject.h"



@interface MPActivitySell (Internal)

- (BOOL) allItemsSold;
- (void) clickNextItem;
- (void) clickVendor;

- (void) buildListToSell;
- (BOOL) isSellableItem:(Item *)anItem;

@end


@implementation MPActivitySell
@synthesize vendor, listToKeep, listToSell, timeOut, timeOutClick, mover; 


- (id)  initWithVendor:(Mob *)npc andListKeep:(NSArray *)listProtectedItems andGrey:(BOOL)doGrey andWhite:(BOOL)doWhite andGreen:(BOOL)doGreen andTask:(MPTask *)aTask  {
	
	if ((self = [super initWithName:@"Sell" andTask:aTask])) {
		self.vendor	= npc;
		
		self.listToKeep = listProtectedItems;
		self.listToSell = nil;
		
		sellGrey = doGrey;
		sellWhite = doWhite;
		sellGreen = doGreen;
		
		
		state = SellActivityStarted;
		
		self.timeOut = [MPTimer timer:2150];
		self.timeOutClick = [MPTimer timer:1000];
		attemptCount = 0;
		self.mover = [MPMover sharedMPMover];

	}
	return self;
}


- (void) dealloc
{
    [vendor release];
	[listToKeep release];
	[listToSell release];
	[timeOut release];
	[timeOutClick release];
	[mover release];

    [super dealloc];
}


#pragma mark -



// ok Start gets called 1x when activity is started up.
- (void) start {
	
	if (vendor == nil) {
		PGLog( @"[ActivitySell] Error: ActivitySell called with vendor as NIL");
		return;
	}
	
	
	// if vendor is in Distance
	float distanceToVendor = [task myDistanceToMob:vendor];
	if (distanceToVendor <= 5.0 ) {
		
			
		PGLog( @"[ActivitySell] [start] clicking on Vendor ... ");
		
		// face vendor
		[mover faceLocation:(MPLocation *)[vendor position]];
		
		// mouse click on mob
		[self clickVendor];
		
		
		// timeOut start
		[timeOut start];
		
			
		state = SellActivityOpeningVendor;
			
		return;
		
	} else{
		
		PGLog( @"[ActivitySell]  Error: too far away to attempt selling!  MPTaskVendor -> needs to do a better job on approach." );
		
	} // end if in distance
	
	// hmmmm ... if we get here then we shouldn't be selling
	state = SellActivityDone;
}



// work is called repeatedly every 100ms or so.
- (BOOL) work {
//PGLog(@" ++++ sell->work() ");
	
	// switch (state)
	switch (state) {
		case SellActivityStarted:

			//// How did we get here???
			
			// face vendor
			[mover faceLocation:(MPLocation *)[vendor position]];
			
			// mouse click on mob
			[self clickVendor];
			
			
			// timeOut start
			[timeOut start];
			
			
			state = SellActivityOpeningVendor;
			return NO;
			break;
			
			
			
		case SellActivityOpeningVendor:
			// NOTE: we really need a method to detect when the Vendor Window appears
			
			// if ([self vendorWindowOpen]) {
			//		state = SellActivityClickingItems;
			//		[self clickNextItem];
			// }
			
			/// until then just wait for the timer to hope the window is open
			// if timeOut ready
			if ([timeOut ready]) {
				
				state = SellActivityClickingItems;
				[self clickNextItem];
				[timeOutClick start];
				
			} // end if
			
			return NO;
			break;
			
			
		case SellActivityClickingItems:
			if ([self allItemsSold]) {
				state = SellActivityDone;
				return YES;
			}
			if ([timeOutClick ready]) {
				[self clickNextItem];
				[timeOutClick start];
			}
			return NO;
			break;
			
			
		default:
		case SellActivityDone:
			return YES;
			break;

	}
	
	// otherwise, we exit (but we are not "done"). 
	return NO;
}



// we are interrupted before we arrived.  Make sure we stop moving.
- (void) stop{
	
	/// clear list of items to sell ... (we'll have to recalculate it when we get back)
	self.listToSell = nil;
	[mover stopAllMovement];
	
}

#pragma mark -


- (NSString *) description {
	NSMutableString *text = [NSMutableString string];
	
	[text appendFormat:@"%@\n", self.name];
	switch (state) {
		case SellActivityOpeningVendor:
			[text appendString:@"   opening Vendor window."];
			break;
			
		case SellActivityClickingItems:
//			[text appendFormat:@"  selling %d items ", [listItemsToSell count]];
			break;

		default:
		case SellActivityDone:
			[text appendString:@"  Done!"];
			break;

	}
	
	return text;
}

#pragma mark -
#pragma mark Internal


// perform an interaction with the vendor
- (void) clickVendor {
	[[[task patherController] botController] interactWithMouseoverGUID: [vendor GUID]];
}


- (BOOL) allItemsSold {
	
	if (listToSell == nil) return NO;
	
	// return ([listItemsToSell count] == 0);
	return ([listToSell count] == 0);
}



- (void) clickNextItem {
	
	// if we haven't built our list of items to sell then do so:
	if (listToSell == nil) {
		[self buildListToSell];
	}
	
	if ([listToSell count] > 0) {
		
		// send our stored command for that item
		NSString *macroCommand = [listToSell objectAtIndex:0];
		[[[task patherController] macroController] useMacroOrSendCmd:macroCommand];
		[listToSell removeObjectAtIndex:0];
	}
	
}


- (void) buildListToSell {
	
	NSMutableArray *tempList = [NSMutableArray array];
	NSMutableString *condCheck;
	NSString *command;
	
	
	// for each Bag
	int k = 0;
	for (; k<5; k++) {
		
		// for each Slot
		int j = 0;
		for (; j<= 40; j++) {
		
			// get item at bag,slot
			Item *item = [MPActivitySell itemInBag:k atSlot:j];
			if (item) {
				
				// if item is sellable
				if ([self isSellableItem:item]) {

					// add script to command list: UseContainerItem
//					[tempList addObject:[NSString stringWithFormat:@"/run UseContainerItem(%d, %d);", k, j]];
				
					

					//// Hack: to get working without item Quality available to me:
					////       Use lua macro to sell based on quality :
					
					condCheck = [NSMutableString string];
					
					// if doGrey  add grey quality check
					if (sellGrey) [condCheck appendString:@" ql==0 "];				
					
					// if doWhite add white quality check
					if (sellWhite) {
						if (sellGrey) [condCheck appendString:@"or"];
						[condCheck appendString:@" ql==1 "];
					}	
					
					
					// if doGreen add Green quality check
					if (sellGreen) {
						if ([condCheck length] > 0) [condCheck appendString:@"or"];
						[condCheck appendString:@" ql==2 "];
					}
					
					
					// compile and Add script command
					command = [NSString stringWithFormat:@"/run local iID = GetContainerItemID(%d,%d); if iID~= nil then  local nm, _, ql = GetItemInfo(iID);  if %@ then print(\"sell - n[\"..nm..\"] q[\"..ql..\"]\"); UseContainerItem(%d,%d); else print(\"skipped \"..nm..\" q[\"..ql..\"]\"); end;  end;", k, j, condCheck, k, j];					
					[tempList addObject:command];
						
					
				
				}
			}
			
		}
		
	}
	
	self.listToSell = tempList;
	
}



+ (Item*)itemInBag: (int)bag atSlot:(int)slot {
	
	// bag:  0 - 4,  0 == Backpack
	// slot: 1 - [maxSlotsInBag]
	
	MemoryAccess *memory = [[Controller sharedController] wowMemoryAccess];
	
	if ( memory && [memory isValid] ){
		
		// backpack!
		if ( bag == 0 ){
			
			if (slot <= 16) {
				UInt32 playerFieldMemAddress = [[[PlayerDataController sharedController] player] baseAddress] +  [[OffsetController sharedController] offset:@"PlayerField_Pointer"];
				UInt32 playerFieldsAddress = 0;
				if ([memory loadDataForObject: self atAddress:playerFieldMemAddress Buffer: (Byte *)&playerFieldsAddress BufLength: sizeof(playerFieldsAddress)]) {
				   
				
					GUID itemGUID = [memory readLongLong:(playerFieldsAddress + PLAYER_FIELD_PACK_SLOT_1 + (sizeof(GUID)*(slot-1)))];
					Item *item = [[InventoryController sharedInventory] itemForGUID:itemGUID];
					
					if ( item ){
						PGLog(@" {%d, %d} %@", bag, slot, [item name]);
						return [[item retain] autorelease];
					}
					
				} else {
					PGLog(@"  --- Error getting the playerFiledsAddress! ");
				}

			}
						  
		}
		
		else{
			
			UInt32 bagListOffset = [[OffsetController sharedController] offset:@"BagListOffset"];
			
			// valid bag?
			GUID bagGUID = [memory readLongLong:bagListOffset + ( (bag-1) * sizeof(GUID))];  // 'sizeof(GUID)' was '8'
			if ( bagGUID > 0x0 ){
				Item *itemBag = [[InventoryController sharedInventory] itemForGUID:bagGUID];
				
				if ( itemBag ){
					PGLog(@"Bag: %@", [itemBag name]);
					

					int bagSize = [itemBag bagSize];        // 1 read

					if (slot <= bagSize) {
						// valid item at this slot?
						GUID guid = [itemBag itemGUIDinSlot:slot];
						Item *item = [[InventoryController sharedInventory] itemForGUID:guid];
						if ( item ){
							PGLog(@" {%d, %d} %@", bag, slot, [item name]);
							return [[item retain] autorelease];
						}                                                       
					}
				}
			}
				
			
		}
	}
	
	return nil;
}
	
	
	
- (BOOL) isSellableItem:(Item *)anItem {
	
	
	// if itemName is like one of the names in our protectedList  return NO;
	for (NSString *keepItem in listToKeep) {
		
		if( [[anItem name] isCaseInsensitiveLike:keepItem] ) {
			return NO;
		}
	}
	
	
	//// OK, how do we check for Item Quality???
	
	// if itemQuality is Grey and !sellGrey, return NO;
	// if itemQuality is White and !sellWhite return NO;
	// if itemQuality is Green and !sellGreen return NO;
	
	return YES;
	
}


#pragma mark -

+ (id) sellTo:(Mob *)npc keepItems:(NSArray *)listProtectedItems greyItems: (BOOL)doGrey whiteItems:(BOOL)doWhite greenItems:(BOOL)doGreen forTask:(MPTask *)aTask {
 
	return [[[MPActivitySell alloc] initWithVendor:npc andListKeep:listProtectedItems andGrey:doGrey andWhite:doWhite andGreen:doGreen andTask:aTask] autorelease];
}


@end