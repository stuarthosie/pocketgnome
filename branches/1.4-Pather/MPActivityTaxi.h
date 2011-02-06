//
//  MPActivityTaxi.h
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


typedef enum TaxiActivity { 
    TaxiActivityStarted		= 1,	// haven't done Squat!
	TaxiActivityOpeningMap	= 2,	// attempting to open the Taxi map
	TaxiActivityFlying		= 3,	// flying 
	TaxiActivityDone		= 4		// All Done
} MPTaxiActivity; 



// This activity sets your Hearthstone with the given Innkeeper

@interface MPActivityTaxi : MPActivity {
	Mob *driver;
	NSString *destination;
	
	MPTaxiActivity state;
	MPTimer *timeOutClick;
	MPMover *mover;
	
	MPLocation *initialLocation, *lastLocation;
	
	int count;
	BOOL didFlushGraph;
}
@property (retain) Mob *driver;
@property (retain) NSString *destination;
@property (retain) MPMover *mover;
@property (retain) MPTimer *timeOutClick;
@property (retain) MPLocation *initialLocation, *lastLocation;


+ (id) taxiWith:(Mob *)npc to:(NSString *)destination  forTask:(MPTask *)aTask;
@end
