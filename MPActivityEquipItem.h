//
//  MPActiviyEquipItem.h
//  Pocket Gnome
//
//  Created by Coding Monkey on 1/1/11.
//  Copyright 2011 Savory Software, LLC
//
#import <Cocoa/Cocoa.h>
#import "MPActivity.h"

@class MPTimer;
@class Item;


typedef enum EquipActivity { 
    EquipActivityStarted		= 1,	// haven't done Squat!
	EquipActivityPickupItem		= 2,	// Find the item and pick it up
	EquipActivityEquipItem		= 3,	// Auto Equip the item
	EquipActivityDone			= 4		// All Done
} MPEquipActivity; 

// This activity equips things in your bags

@interface MPActivityEquipItem : MPActivity {

	NSString *itemName;
	
	int bag,slot;
	
	int attempt;
	
	MPEquipActivity state;
	MPTimer  *timeOutClick;
}
@property (retain) NSString *itemName;
@property (retain) MPTimer *timeOutClick;


+ (id)  equipItem:(NSString *)iName forTask:(MPTask *)aTask;
@end
