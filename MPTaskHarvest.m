//
//  MPTaskHarvest.m
//  Pocket Gnome
//
//  Created by codingMonkey on 9/22/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MPTaskHarvest.h"

#import "Node.h"
#import "NodeController.h"
#import "PatherController.h"
#import "PlayerDataController.h"
#import "MPActivityWalk.h"
#import "MPActivityWait.h"
#import "MPActivityPickup.h"






@interface MPTaskHarvest (Internal)


/*!
 * @function clearActivityApproach
 * @abstract Properly shuts down the Approach Activity.
 * @discussion
 */
- (void) clearActivityApproach;
- (void) clearActivityInteract;

- (Node *) bestNode;
- (BOOL) isNamedNode: (Node *) node;

@end


@implementation MPTaskHarvest

// Synthesize variables here:
@synthesize activityApproach;
@synthesize activityInteract;
@synthesize activityWait;
@synthesize nodeController;
@synthesize nodeToHarvest, workingNode;
@synthesize namesToHarvest;


- (id) initWithPather:(PatherController*)controller {
	if ((self = [super initWithPather:controller])) {
		name = @"Harvest";
		
		self.activityApproach = nil;
		self.activityInteract = nil;
		self.activityWait = nil;
		
		self.nodeController = [controller nodeController];
		
		self.nodeToHarvest = nil;
		self.workingNode = nil;
		
		distance = 30.0f;
		doHerbs = NO;
		doMining = NO;
		doClouds = NO;
		approachToDistance = 4.5f;
		
		self.namesToHarvest = [NSMutableArray array];
		
		state = HarvestStateSearching;

	}
	return self;
}



- (void) setup {
	
	NSArray *listTypes = [self arrayStringsFromVariable:@"type"];
	for(NSString *type in listTypes) {
		
		if ([[type lowercaseString] isEqualToString:@"herbs"]) doHerbs = YES;
		if ([[type lowercaseString] isEqualToString:@"mining"]) doMining = YES;
		if ([[type lowercaseString]	isEqualToString:@"clouds"]) doClouds = YES;
	}
	
	NSArray *tempNames = [self arrayStringsFromVariable:@"names"];
	for(NSString *tName in tempNames) {
		
//		PGLog (@"   ++++ name to harvest [%@]", [tName lowercaseString]);
		[namesToHarvest addObject:[tName lowercaseString]];
	}
	
	distance = [[self stringFromVariable:@"distance" orReturnDefault:@"30.0"] floatValue];
	
	[super setup];
}



- (void) dealloc
{
    [activityApproach release];
    [activityInteract release];
	[activityWait release];
	[nodeController release];
	[nodeToHarvest release];
	[workingNode release];
	[namesToHarvest release];
	
    [super dealloc];
}

#pragma mark -



- (BOOL) isFinished {
	return NO;
}



- (MPLocation *) location {
	
	Node *currentNode = [self bestNode];
	
	if ( currentNode == nil) 
		return nil;
	
	return (MPLocation *)[currentNode position];
}



- (void) restart {
	self.nodeToHarvest = nil;
}



- (BOOL) wantToDoSomething {
//    PGLog( @"[MPTaskHarvest wtds]: ");
	
	Node *currentNode = [self bestNode];
	float currentDistance;
	
	if (currentNode == nil) {
		state = HarvestStateSearching;
	}
	
	
	switch (state) {
			
		default:
		case HarvestStateSearching:
		
			// if currentNode != nil
			if (currentNode != nil) {
				
				// if distance to node > 4.5
				currentDistance = [[currentNode position] distanceToPosition:[self myPosition]];
				if (currentDistance > approachToDistance) {
					state = HarvestStateApproaching;
					
				} else {
					state = HarvestStateInteracting;
				}
				
				self.workingNode = currentNode;
			}
			break;
			
			
		case HarvestStateApproaching:
			// if distance to node < approachHowClose
			currentDistance = [[currentNode position] distanceToPosition:[self myPosition]];
			if (currentDistance <= approachToDistance) {
				state = HarvestStateInteracting;
			}
			break;
			
		case HarvestStateInteracting:
			// if node gone
				// state = searching
			// end if
			
			if (currentNode != workingNode) {
				state = HarvestStateSearching;
			}
			
			break;
			
	}
	
	// if we found a Node then we want to do something.
	return (currentNode != nil);
}



- (MPActivity *) activity {
	
	Node *currentNode = [self bestNode];
	
	switch (state) {
			
		default:
		case HarvestStateSearching:
			
			if (activityApproach != nil) {
				[self clearActivityApproach];
			}
			
			if (activityInteract != nil) {
				[self clearActivityInteract];
			}
			
			if (activityWait == nil) {
				self.activityWait = [MPActivityWait waitIndefinatelyForTask:self];
			}
			
			return activityWait;
			break;
			
			
			
		case HarvestStateApproaching:
			
			if (activityInteract != nil) {
				[self clearActivityInteract];
			}
			
			
			if (activityApproach == nil) {
				self.activityApproach = [MPActivityWalk	walkToLocation:(MPLocation *)[currentNode position] forTask:self useMount:NO];
			}
			return activityApproach;
			break;
			
			
			
		case HarvestStateInteracting:
			
			if (activityApproach != nil) {
				[self clearActivityApproach];
			}
			
			if (activityInteract == nil) {
				self.activityInteract = [MPActivityPickup pickupNode:currentNode forTask:self];
			}
			return activityInteract;
			break;
			
	}
	
	// we really shouldn't get here.
	// return 
	return nil;
}



- (BOOL) activityDone: (MPActivity*)activity {
	
	// that activity is done so release it 
	if (activity == activityApproach) {
		[self clearActivityApproach];
	}
	
	if (activity == activityInteract) {
		[self clearActivityInteract];
	}
	
	
	return YES; // ??
}


#pragma mark -
#pragma mark Helper Functions



- (void) clearBestTask {
	
	self.nodeToHarvest = nil;
	
}



- (Node *) bestNode {
	
	
	if (self.nodeToHarvest == nil) {
		NSMutableArray *nearbyNodes = [NSMutableArray array];
		
		if (doHerbs) {
			
			int herbalismLevel =[[patherController playerData] getHerbalismLevel];
			NSArray *herbNodes =[nodeController allHerbalismNodes];
			for (Node *node in herbNodes) {
				if ([nodeController nodeLevel:node] <= herbalismLevel) {
					[nearbyNodes addObject:node];
				}
			}
		}
		
		if (doMining) {
			
			int miningLevel = [[patherController playerData] getMiningLevel];
			NSArray *miningNodes = [nodeController allMiningNodes];
			for(Node *node in miningNodes) {
				if ([nodeController nodeLevel:node] <= miningLevel) {
					[nearbyNodes addObject:node];
				}
			}
		}
		
		if (doClouds) {
			[nearbyNodes addObjectsFromArray:[nodeController allGasClouds]];
		}
		
		if ([namesToHarvest count] > 0) {
			
			NSArray *allNodes = [nodeController	nodesWithinDistance:distance NodeIDs:nil position:[self myPosition]];
			for( Node *node in allNodes) {
				if ([self isNamedNode:node]) {
					if (![nearbyNodes containsObject:node]) {
						[nearbyNodes addObject:node];
					}
				}
				
			}
		
		}

		
		float minDist = INFINITY;
		for (Node* node in nearbyNodes) {
			
			float currDist = [[node position] distanceToPosition:[self myPosition]];
			if (currDist <= distance) {
				if (currDist < minDist) {
					minDist = currDist;
					self.nodeToHarvest = node;
				}
			}
		}
		
	} // end if nodeToHarvest == nil
	
	return nodeToHarvest;  // the closest node, or nil
	
}



- (BOOL) isNamedNode: (Node *) node {	
	// The names array should all be lowercase already.
	//
	NSString *nodeNameLowerCase = [[node name] lowercaseString];
	
	for( NSString *nodeName in namesToHarvest) {
		if ([nodeName isEqualToString: nodeNameLowerCase]) {
			return YES;
		}
	}
	return NO;
}







- (NSString *) description {
	NSMutableString *text = [NSMutableString string];
	Node *currentNode = [self bestNode];
	
	[text appendFormat:@"%@\n", self.name];
	if (currentNode != nil) {
		
		[text appendFormat:@"  node found: %@",[currentNode name]];
		
		switch (state){
			case HarvestStateSearching:
				[text appendFormat:@"  looking for nodes ..."];
				break;
				
			case HarvestStateApproaching:
				[text appendFormat:@"  approaching %@ : (%0.2f) / (%0.2f)", [currentNode name], [[self myPosition] distanceToPosition:[currentNode position]], approachToDistance];
				break;
				
			case HarvestStateInteracting:
				[text appendFormat:@"  harvesting %@!\n", [currentNode name]];
				break;
				

		}
		
	} else {
		[text appendString:@"No mobs of interest"];
	}
	
	return text;
}




- (void) clearActivityWait {
	[activityWait stop];
	[activityWait autorelease];
	self.activityWait = nil;
}




- (void) clearActivityInteract {
	[activityInteract stop];
	[activityInteract autorelease];
	self.activityInteract = nil;
}




- (void) clearActivityApproach {
	[activityApproach stop];
	[activityApproach autorelease];
	self.activityApproach = nil;
}




#pragma mark -

+ (id) initWithPather: (PatherController*)controller {
	return [[[MPTaskHarvest alloc] initWithPather:controller] autorelease];
}

@end
