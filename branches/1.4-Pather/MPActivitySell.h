//
//  MPActivitySell.h
//  Pocket Gnome
//
//  Created by Coding Monkey on 1/1/11.
//  Copyright 2011 Savory Software, LLC
//
#import <Cocoa/Cocoa.h>
#import "MPActivity.h"

@class MPMover;
@class MPTimer;
@class Mob;
@class Item;


typedef enum SellActivity { 
    SellActivityStarted			= 1,	// haven't done Squat!
	SellActivityOpeningVendor	= 2,	// attempting to open the Vendor Window
	SellActivityClickingItems	= 3,	// clicking items to sell
	SellActivityDone			= 4		// All Done
} MPSellActivity; 

// This activity sells your things to a Vendor

@interface MPActivitySell : MPActivity {
	Mob *vendor;
	NSInteger attemptCount;
	
	NSArray *listToKeep;
	NSMutableArray *listToSell;
	
	BOOL sellGrey, sellWhite, sellGreen;
	
	MPSellActivity state;
	MPTimer *timeOut, *timeOutClick;
	MPMover *mover;
}
@property (retain) Mob *vendor;
@property (retain) MPMover *mover;
@property (retain) MPTimer *timeOut, *timeOutClick;
@property (retain) NSArray *listToKeep;
@property (retain) NSMutableArray *listToSell;


+ (Item*)itemInBag: (int)bag atSlot:(int)slot;

+ (id)  sellTo:(Mob *)npc keepItems:(NSArray *)listProtectedItems greyItems: (BOOL)doGrey whiteItems:(BOOL)doWhite greenItems:(BOOL)doGreen forTask:(MPTask *)aTask;
@end
