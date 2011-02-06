//
//  MPTaskSetHearth.h
//  Pocket Gnome
//
//  Created by Coding Monkey on 1/7/11.
//  Copyright 2011 Savory Software, LLC
//
#import <Cocoa/Cocoa.h>
#import "MPTaskInteractNPC.h"


@class MPActivitySetHearth;
@class PatherController;


/*!
 * @class      MPTaskSetHearth
 * @abstract   Set your hearthstone with the given Innkeeper.
 * @discussion 
 * Approaches an Innkeeper and set's your toon's hearthstone to that innkeeper.
 * Parameters:
 *	$NPC       : the name of the Innkeeper.
 *	$Location  : the location of the vendor [x, y, z];
 * Example
 * <code>
 *	SetHearth
 *	{	
 *		$Prio = 5;
 *		$NPC = "Mardant Strongoak";
 *		$Location = [10484.04, 814.92, 1322.75];
 *	}
 * </code>
 *		
 */



@interface MPTaskSetHearth : MPTaskInteractNPC {
	
	
	BOOL isDone;
//	int lastSetHearthedLevel;
	
	MPActivitySetHearth *activitySetHearth;
}
@property (retain) MPActivitySetHearth *activitySetHearth;


+ (id) initWithPather: (PatherController*)controller;
@end

