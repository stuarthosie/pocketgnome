//
//  MPItem.m
//  Pocket Gnome
//
//  Created by codingMonkey on 4/24/10.
//  Copyright 2010 Savory Software, LLC. All rights reserved.
//

#import "MPItem.h"
#import "Item.h"
#import "InventoryController.h"
#import "BotController.h"
#import "PatherController.h"
#import "AuraController.h"


@implementation MPItem
@synthesize name, myItem, botController, inventoryController, listIDs, listBuffIDs;



- (id) init {
	
	if ((self = [super init])) {
		
		self.name = nil;
		self.myItem = nil;
		actionID = 0;
		currentID = 0;

		self.listIDs = [NSMutableArray array];
		self.listBuffIDs = [NSMutableDictionary dictionary];
		
		
		self.botController = [[PatherController	sharedPatherController] botController];
		self.inventoryController = [InventoryController sharedInventory];
	}
	return self;
}


- (void) dealloc
{
	[name release];
    [myItem release];
	[listIDs release];
	[listBuffIDs release];
	[botController release];
	[inventoryController release];
	
    [super dealloc];
}


#pragma mark -




- (void) addID: (int) anID {
	
	[self addID:anID withBuffID:0];
}
	
- (void) addID: (int) anID withBuffID: (int) buffID {
	
	[listIDs addObject:[NSNumber numberWithInt:anID]]; 
	
	if (buffID > 0) {
		[self addBuffID:buffID forID:anID];
	}
}


- (void) addBuffID: (int) buffID forID: (int) anID {

	NSNumber *valBuff = [NSNumber numberWithInt:buffID];
	NSNumber *valID = [NSNumber	numberWithInt:anID];
	[listBuffIDs setObject:valBuff forKey:valID];
	
}


-(BOOL) canUse {
	
	if (myItem == nil) {
		return NO;
	}
	
	
	return YES;
}


-(BOOL) use {
	
	return [botController performAction:(USE_ITEM_MASK + actionID)];
	
}



- (void) scanForItem {
	
	Item *foundItem = nil;
	
	int count = 0;
	
	// scan by registered ID's
//	int rank = 1;
//	int foundRank = 0;
	for( NSNumber *currID in listIDs ) {
		
		
		for(Item *item in  [inventoryController inventoryItems]) {
			
//			if ( [currID intValue] == [[item ID] intValue]) {
			if ( [currID isEqualToNumber:[NSNumber numberWithInt:[item entryID]]] ) {
				
				// we found this item
				PGLog( @"       --> item[%@]:: Found item [%@] id[%d] ",[self name], [item name], (int)[item entryID]);
				
				count = [inventoryController collectiveCountForItemInBags: item];
				if (count > 0) {
					
					foundItem = item;
				} else {
					PGLog (@"       --> item[%@]:: Out of Stock!!! looking for other.", [item name]);
				}
				break;
			}
		}
		
	}
	
	
	if (foundItem) {
		
		if (foundItem != myItem) {
			PGLog(@"   [%@]:: UPDATED Item:  [%@]", name, [foundItem name]);
		
			self.myItem = foundItem;
			actionID = [foundItem entryID];
		}
		
	} else {
		
		PGLog(@"     == Item[%@]:: no item found after scanning", name);
	}
	
	
}





- (void) loadPlayerItems {
	
	self.myItem = [inventoryController itemForName:name];
	
	
	if (myItem == nil) {
		
		
		PGLog( @" item[%@] not found by name ... scanning by IDs:", name);
		[self scanForItem];
		
	} else {
		
		actionID = [myItem entryID] ;

	}
	
	PGLog(@"     == item[%@] actionID[%d] ",name,  (int)actionID);
	// end if
}



#pragma mark -
#pragma mark Aura Checks


- (BOOL) unitHasBuff: (Unit *)unit {
	
	NSNumber *valBuff = [listBuffIDs objectForKey:[NSNumber numberWithInt:actionID]];
	
	if (valBuff == nil) return NO;
	
	int buffID = [valBuff intValue];
	return [[AuraController sharedController] unit:unit hasBuff:buffID];
	
}



#pragma mark -



+ (id) item {
	
	MPItem *newItem = [[MPItem alloc] init];
	return [newItem autorelease];
}




// attempt to compile a single item that scans for the best 
// drink you have in your inventory and drink that when resting:
+ (id) drink {
	
	MPItem *drink = [MPItem	item];
	[drink setName:@"Best Drink"];
	
	// add entries in the order from least to greatest,
	// because [loadPlayerSettings] will end with the last
	// match.
	
	// to find:
	// go to www.wowhead.com, look up a drink
	// on on the description of the drink, click the green text that tells you the effect
	// this gives you the buff.
	
	
	[drink addID:   159 withBuffID:   430];  // Refreshing Spring Water
	[drink addID:  5350 withBuffID:   430];  // Conjured Water
	
	[drink addID:  1179 withBuffID:   431];  // Ice Cold Milk  (lv 5)
	[drink addID:  2288 withBuffID:   431];  // Conjured Fresh Water (lv 5)
	
	[drink addID:  1205 withBuffID:   432];  // Melon Juice (lv 15)
	[drink addID:  2136 withBuffID:   432];  // Conjured Purified Water (lv 15)
	
	[drink addID:  1708 withBuffID:  1133];  // Sweet Nectar (lv 25)
	[drink addID:  3772 withBuffID:  1133];  // Conjured Spring Water (lv 25)
	
	[drink addID:  1645 withBuffID:  1135];  // Moonberry Juice (lv 35)
	[drink addID:  8077 withBuffID:  1135];  // Conjured Mineral Water (lv 35)
	
	[drink addID:  8766 withBuffID:  1137];  // Morning Glory Dew (lv 45)
	[drink addID:  8078 withBuffID:  1137];  // Conjured Sparkling Water (lv 45)
	
	[drink addID: 8079 withBuffID: 22734];  // Conjured Crystal Water (lv 55)
	
	[drink addID: 28399 withBuffID: 34291]; // Filtered Draenic Water (lv 60)
	[drink addID: 30703 withBuffID: 34291]; // Conjured Mountain Spring water (lv 60)
	
	[drink addID: 27860 withBuffID: 27089];  // Purified Draenic Water (lv 65)
	[drink addID: 22018 withBuffID: 27089];  // Conjured Glacier Water (lv 65)
	[drink addID: 35954 withBuffID: 27089];  // Sweetened Goats Milk (lv 65)
	
	[drink addID: 33444 withBuffID: 43182];  // Pungent Seal Whey (lv 70)
	
	[drink addID: 42777 withBuffID: 43183];  // Crusaders Waterskin (lv 75)
	[drink addID: 33445 withBuffID: 43183];  // Honey Mint Tea (lv 75)
	[drink addID: 41731 withBuffID: 43183];  // Yeti Milk (lv 75)
	
	
	

//	[drink addID: ];  // 
	

	[drink loadPlayerItems];
	
	return drink;
}



@end
