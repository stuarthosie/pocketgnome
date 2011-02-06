//
//  MPActivityPickup.h
//  Pocket Gnome
//
//  Created by Coding Monkey on 1/1/11.
//  Copyright 2011 Savory Software, LLC
//
#import <Cocoa/Cocoa.h>
#import "MPActivity.h"

@class MPMover;
@class MPTimer;
@class Node;


typedef enum PickupActivity { 
    PickupActivityStarted	= 1,	// haven't performed initial loot action
	PickupActivityLooting	= 2,	// In process of looting
	PickupActivityFinished	= 3		// All done.
} MPPickupActivity; 

// This activity pickups nodes along the ground. (Herbalism, mining, chests, etc... )

@interface MPActivityPickup : MPActivity {
	Node *pickupNode;
	NSInteger attemptCount;
	
	MPPickupActivity state;
	MPTimer *timeOut;
	MPMover *mover;
}
@property (retain) Node *pickupNode;
@property (retain) MPMover *mover;
@property (retain) MPTimer *timeOut;


+ (id)  pickupNode:(Node *)aNode forTask:(MPTask *)aTask;
@end
