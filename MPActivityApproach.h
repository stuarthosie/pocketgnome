//
//  MPActivityApproach.h
//  Pocket Gnome
//
//  Created by codingMonkey on 9/23/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MPActivity.h"

@class MPTask;
@class Unit;
@class MPMover;


/*
@class MovementController;
@class PatherController;
@class PlayerDataController;
@class Position;
@class MPTimer;
 */

/*!
 * @class      MPActivityApproach
 * @abstract   This activity is intended to approace a unit.
 * @discussion 
 * Use this task when you are near a unit and need to get withing a certain distance of them. Used during
 * PullTask to move within attackDistance of a given unit.
 *
 * This activity can be created several ways:
 *
 * - [MPActivityApproach approachUnit: withinDistance:  useMount:  forTask:] : 
 *			given an in game unit, attempt to approach within a given distance.
 *
 */
@interface MPActivityApproach : MPActivity {

	Unit *unit; // the unit to approach
	float distance; // how close to approach
	BOOL useMount;  // mount to get there?
	MPMover *mover; // our mover object

}
@property (readwrite, retain) Unit *unit;
@property (readwrite) BOOL useMount;
@property (retain) MPMover *mover;




#pragma mark -

+ (id) approachUnit:(Unit*)aUnit withinDistance:(float) howClose forTask:(MPTask *)aTask;
 
@end
