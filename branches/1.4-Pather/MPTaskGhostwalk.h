//
//  MPTaskGhostwalk.h
//  Pocket Gnome
//
//  Created by Coding Monkey on 12/28/10.
//  Copyright 2010 Savory Software, LLC
//
#import <Cocoa/Cocoa.h>
#import "MPTaskRunner.h"

@class MPLocation;
@class MPActivityWait;
@class MPActivityWalk;
@class MPTimer;
@class PlayerDataController;


 typedef enum GhostwalkState { 
 GhostwalkStateWaiting			 = 1, 
 GhostwalkStateApproachingCorpse = 2, 
 GhostwalkStateMovingSafeSpot	 = 3,
 GhostwalkStateRezzing			 = 4
 } MPGhostWalkState; 
 

/*!
 * @class      MPTaskGhostwalk
 * @abstract   Move to your Corpse
 * @discussion 
 * MPTaskGhostwalk walks your ghost back to your corpse.
 * <code>
 *	 Ghostwalk
 *	 {
 *		 $Prio = 1;
 *	 }
 * </code>
 *
 */
@interface MPTaskGhostwalk : MPTask {
	MPLocation *corpseLocation, *safeLocation;
	MPGhostWalkState state;
	MPActivityWait *activityWait;
	MPActivityWalk *activityWalkToCorpse;
	MPActivityWalk *activityWalkToSafeLocation;
	
	MPTimer *timerRetry;
}
@property (retain) MPLocation *corpseLocation, *safeLocation;
@property (retain) MPActivityWait *activityWait;
@property (retain) MPActivityWalk *activityWalkToCorpse, *activityWalkToSafeLocation;
@property (readonly, retain) MPTimer *timerRetry;

+ (id) initWithPather: (PatherController*)controller;
@end
