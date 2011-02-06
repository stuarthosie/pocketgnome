//
//  MPActiviyHearth.h
//  Pocket Gnome
//
//  Created by Coding Monkey on 1/1/11.
//  Copyright 2011 Savory Software, LLC
//
#import <Cocoa/Cocoa.h>
#import "MPActivity.h"

@class MPTimer;
@class Item;


typedef enum HearthActivity { 
    HearthActivityWaiting			= 1,	// haven waiting to start
	HearthActivityClicking			= 2,	// Attempt to USE the hearthstone
	HearthActivityHearthing			= 3,	// Wait while we are casting 
	HearthActivityDone				= 4		// All Done
} MPHearthActivity; 

// This activity uses your hearthstone

@interface MPActivityHearth : MPActivity {
	
	int attempt;
	
	MPHearthActivity state;
	MPTimer  *timeOutClick;
}
@property (retain) MPTimer *timeOutClick;


+ (id)  hearthForTask:(MPTask *)aTask;
@end
