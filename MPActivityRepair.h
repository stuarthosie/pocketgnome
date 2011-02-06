//
//  MPActivityRepair.h
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


typedef enum RepairActivity { 
    RepairActivityStarted		= 1,	// haven't done Squat!
	RepairActivityOpeningVendor	= 2,	// attempting to open the Vendor Window
	RepairActivityRepairing		= 3,	// clicking items to sell
	RepairActivityDone			= 4		// All Done
} MPRepairActivity; 



// This activity repairs your things from a vendor

@interface MPActivityRepair : MPActivity {
	Mob *vendor;
	
	MPRepairActivity state;
	MPTimer *timeOutClick;
	MPMover *mover;
	
	int count;
}
@property (retain) Mob *vendor;
@property (retain) MPMover *mover;
@property (retain) MPTimer *timeOutClick;



+ (id) repairWith:(Mob *)npc forTask:(MPTask *)aTask;
@end
