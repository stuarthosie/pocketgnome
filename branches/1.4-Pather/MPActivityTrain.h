//
//  MPActivityTrain.h
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


typedef enum TrainActivity { 
    TrainActivityStarted		= 1,	// haven't done Squat!
	TrainActivityOpeningTrainer	= 2,	// attempting to open the Vendor Window
	TrainActivitySelectTraining = 3,    // select that we want to train (not always needed)
	TrainActivityClickingItems	= 4,	// clicking items to sell
	TrainActivityDone			= 5		// All Done
} MPTrainActivity; 



// This activity learns new things from a Trainer

@interface MPActivityTrain : MPActivity {
	Mob *trainer;
	
	MPTrainActivity state;
	MPTimer *timeOutClick;
	MPMover *mover;
	
	int count;
}
@property (retain) Mob *trainer;
@property (retain) MPMover *mover;
@property (retain) MPTimer *timeOutClick;



+ (id) trainWith:(Mob *)npc  forTask:(MPTask *)aTask;
@end
