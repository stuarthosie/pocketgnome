//
//  MPActivitySetHearth.h
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


typedef enum SetHearthActivity { 
    SetHearthActivityStarted		= 1,	// haven't done Squat!
	SetHearthActivityOpeningInnkeeper	= 2,	// attempting to open the Vendor Window
	SetHearthActivityClickingOption	= 3,	// clicking items to sell
	SetHearthActivityAcceptBinding  = 4,
	SetHearthActivityDone			= 5		// All Done
} MPSetHearthActivity; 



// This activity sets your Hearthstone with the given Innkeeper

@interface MPActivitySetHearth : MPActivity {
	Mob *innkeeper;
	
	MPSetHearthActivity state;
	MPTimer *timeOutClick;
	MPMover *mover;
	
	int count;
}
@property (retain) Mob *innkeeper;
@property (retain) MPMover *mover;
@property (retain) MPTimer *timeOutClick;



+ (id) setHearthWith:(Mob *)npc  forTask:(MPTask *)aTask;
@end
