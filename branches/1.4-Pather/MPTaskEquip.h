//
//  MPTaskEquip.h
//  Pocket Gnome
//
//  Created by Coding Monkey on 1/31/11.
//  Copyright 2011 Savory Software, LLC
//
#import <Cocoa/Cocoa.h>
#import "MPTask.h"

@class Mob;
@class MobController;

@class MPActivityEquipItem;
@class MPTaskController;
@class MPTimer;
@class PlayerDataController;




/*!
 * @class      MPTaskEquip
 * @abstract   Attempt to Equip the given item.
 * @discussion 
 * Attempt to USE an item and equip it. 
 *
 * Example
 * <code>
 *	 Equip
 *	 {
 *		$Item = "Archery Training Gloves";
 *	 }
 * </code>
 *		
 */
@interface MPTaskEquip : MPTask {
	NSString *itemName;
	BOOL isDone;
	MPActivityEquipItem *activityEquip;
}
@property (retain) NSString *itemName;
@property (retain) MPActivityEquipItem *activityEquip;


#pragma mark -


/*!
 * @function initWithPather
 * @abstract Convienience method to return a new initialized task.
 * @discussion
 */
+ (id) initWithPather: (PatherController*)controller;


@end
