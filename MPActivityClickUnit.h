//
//  MPActivityClickUnit.h
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


typedef enum ClickUnitActivity { 
    ClickUnitActivityStarted	= 1,	// haven't done Squat!
	ClickUnitActivityClicking	= 2,	// clicking unit
	ClickUnitActivityDone		= 3		// All Done
} MPClickUnitActivity; 



// This activity learns new things from a ClickUniter

@interface MPActivityClickUnit : MPActivity {
	Mob *unit;
	
	MPClickUnitActivity state;
	MPTimer *timeOutClick;
	MPMover *mover;

}
@property (retain) Mob *unit;
@property (retain) MPMover *mover;
@property (retain) MPTimer *timeOutClick;



+ (id) clickUnit:(Mob *)npc  forTask:(MPTask *)aTask;
@end
