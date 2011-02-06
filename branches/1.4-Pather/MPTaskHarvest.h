//
//  MPTaskHarvest.h
//  Pocket Gnome
//
//  Created by Coding Monkey on 1/1/11.
//  Copyright 2011 Savory Software, LLC
//
#import <Cocoa/Cocoa.h>
#import "MPTask.h"
@class NodeController;
@class Node;
@class MPActivityWait;
@class MPActivityWalk;
@class MPActivityPickup;




typedef enum HarvestState { 
	HarvestStateSearching	= 1,
    HarvestStateApproaching = 2, 
    HarvestStateInteracting = 3
} MPHarvestState; 



/*!
 * @class      MPTaskHarvest
 * @abstract   Harvest Nearby Nodes
 * @discussion 
 * Approaches nearby nodes to harvest them.  Will only consider given $Types of nodes to harvest
 * that are within $Distance of the toon's current location.
 *
 *	$Type  : specify the type(s) of node you want to harvest.  "Herbs", "Mining", "Clouds"  (can choose > 1)
 *  $Names : specify the name(s) of the nodes you want to harvest.  "Silverleaf", Quest Nodes, etc... 
 *  $Distance : the distance away from you that you will travel to harvest a node.
 *
 * Note: a node much match all criteria you specify.  So you must at least specify either a $Type, or a $Name.  
 * If you specify BOTH, a node must match both criteria.
 *
 * Example
 * <code>
 *	Harvest
 *	{
 *		$Prio = 3;
 *	    $Type = ["Herbs", "Mining", "Clouds"];
 *	    $Distance = 50; // Go this far to harvest nodes
 *	}
 * </code>
 *		
 */
@interface MPTaskHarvest : MPTask {
	float distance, approachToDistance;
	BOOL doHerbs, doMining, doClouds;
	MPHarvestState state;
	
	NSMutableArray *namesToHarvest;
	
	Node* nodeToHarvest, *workingNode;
	
	MPActivityWait *activityWait;
	MPActivityWalk *activityApproach;
	MPActivityPickup *activityInteract;
	NodeController *nodeController;
}
@property (retain) Node *nodeToHarvest, *workingNode;
@property (retain) NodeController *nodeController;
@property (retain) MPActivityWait *activityWait;
@property (retain) MPActivityWalk *activityApproach;
@property (retain) MPActivityPickup *activityInteract;
@property (retain) NSMutableArray *namesToHarvest;



#pragma mark -
#pragma mark Helper Functions




#pragma mark -


/*!
 * @function initWithPather
 * @abstract Convienience method to return a new initialized task.
 * @discussion
 */
+ (id) initWithPather: (PatherController*)controller;


@end
